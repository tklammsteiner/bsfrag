# Evaluate bsfrag against the expert question set (eval/questions.csv).
# Run from the project root in a FRESH R session (the store opens read-only).
# Writes eval/raw_results.rds, eval/key.csv and the blind scoring sheet
# eval/to_score.xlsx. Score it in Excel, save it as eval/scored.xlsx,
# then run eval/summarise.R.

if (file.exists("eval/scored.xlsx")) {
  stop("eval/scored.xlsx exists. A new run produces new answers and a new key.csv ",
       "that would no longer match your scores.\nMove scored.xlsx, key.csv and ",
       "raw_results.rds to eval/archive/ first.", call. = FALSE)
}

devtools::load_all()
store  <- ragnar::ragnar_store_connect("bsf.duckdb", read_only = TRUE)
qs     <- readr::read_csv("eval/questions.csv", show_col_types = FALSE)
corpus <- readr::read_csv("data-raw/corpus.csv", show_col_types = FALSE)

# 0. Every expected DOI must be in the corpus ---------------------------------
dois <- tolower(trimws(unlist(strsplit(na.omit(qs$expected_doi), ";"))))
stopifnot("Some expected DOIs are not in the corpus" =
            length(setdiff(dois, tolower(corpus$doi))) == 0)

# 1. Setups to compare ---------------------------------------------------------
run_baseline <- function(q) {
  chat <- ellmer::chat_anthropic(system_prompt =
    "You are a research assistant for black soldier fly science. Answer concisely. If you do not know, say so.")
  list(answer = chat$chat(q, echo = "none"), sources = character())
}
setups <- list(
  baseline = run_baseline,
  rag_k4   = \(q) ask_bsf(q, store, top_k = 4),
  rag_k8   = \(q) ask_bsf(q, store, top_k = 8)
)

hit <- function(sources, expected) {
  if (is.na(expected) || length(sources) == 0) return(NA)
  exp <- tolower(trimws(strsplit(expected, ";")[[1]]))
  any(vapply(exp, \(d) any(grepl(d, tolower(sources), fixed = TRUE)), logical(1)))
}

# 2. Run every question through every setup -----------------------------------
results <- purrr::imap(setups, \(f, name) {
  message("Running ", name)
  res <- purrr::map(qs$question, \(q) { Sys.sleep(1); f(q) }, .progress = TRUE)
  dplyr::mutate(qs,
    setup         = name,
    answer        = purrr::map_chr(res, \(r) as.character(r$answer)),
    sources       = purrr::map_chr(res, \(r) paste(r$sources, collapse = " | ")),
    retrieval_hit = purrr::map2_lgl(res, qs$expected_doi, \(r, d) hit(r$sources, d)))
}) |> purrr::list_rbind()

# 3. Shuffle, hide the setup in a separate key --------------------------------
set.seed(1)
results$key <- sample(nrow(results))
results <- dplyr::arrange(results, key)
saveRDS(results, "eval/raw_results.rds")
readr::write_csv(dplyr::select(results, key, setup, id, retrieval_hit), "eval/key.csv")

# 4. Blind scoring sheet (Excel: answers contain commas and line breaks) ------
write_scoring_sheet <- function(results, path = "eval/to_score.xlsx") {
  sheet <- dplyr::transmute(results, key, category, question, reference_answer, answer,
                            correct = NA, hallucination = NA, refused_correctly = NA)
  n <- nrow(sheet); rows <- seq_len(n) + 1
  unans <- sheet$category == "Unanswerable"

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "score")
  openxlsx::addWorksheet(wb, "how_to_score")
  openxlsx::addWorksheet(wb, "lists", visible = FALSE)

  openxlsx::writeData(wb, "score", sheet, headerStyle = openxlsx::createStyle(
    textDecoration = "bold", fontColour = "#FFFFFF", fgFill = "#1F3864", wrapText = TRUE))
  openxlsx::setColWidths(wb, "score", cols = 1:8, widths = c(6, 13, 38, 45, 95, 10, 13, 14))
  openxlsx::setRowHeights(wb, "score", rows = rows,
                          heights = pmin(409, pmax(60, nchar(sheet$answer) / 95 * 19)))

  base   <- openxlsx::createStyle(wrapText = TRUE, valign = "top")
  yellow <- openxlsx::createStyle(fgFill = "#FFF2CC", wrapText = TRUE, valign = "top")
  grey   <- openxlsx::createStyle(fgFill = "#D9D9D9", wrapText = TRUE, valign = "top")
  openxlsx::addStyle(wb, "score", base, rows = rows, cols = 1:8, gridExpand = TRUE)
  openxlsx::addStyle(wb, "score", yellow, rows = rows[!unans], cols = 6, gridExpand = TRUE)
  openxlsx::addStyle(wb, "score", grey,   rows = rows[unans],  cols = 6, gridExpand = TRUE)
  openxlsx::addStyle(wb, "score", yellow, rows = rows,         cols = 7, gridExpand = TRUE)
  openxlsx::addStyle(wb, "score", yellow, rows = rows[unans],  cols = 8, gridExpand = TRUE)
  openxlsx::addStyle(wb, "score", grey,   rows = rows[!unans], cols = 8, gridExpand = TRUE)

  # Dropdowns: 0/1/2 for correctness, yes/no for the two flags
  openxlsx::writeData(wb, "lists", c("0", "1", "2"), startCol = 1, colNames = FALSE)
  openxlsx::writeData(wb, "lists", c("yes", "no"),   startCol = 2, colNames = FALSE)
  openxlsx::dataValidation(wb, "score", cols = 6, rows = rows, type = "list",
                           value = "'lists'!$A$1:$A$3")
  for (col in 7:8) openxlsx::dataValidation(wb, "score", cols = col, rows = rows,
                                            type = "list", value = "'lists'!$B$1:$B$2")

  openxlsx::freezePane(wb, "score", firstActiveRow = 2, firstActiveCol = 3)
  openxlsx::addFilter(wb, "score", rows = 1, cols = 1:8)

  openxlsx::writeData(wb, "how_to_score", c(
    "Score yellow cells only; grey cells do not apply to that question.",
    "correct: 0 = wrong or misleading, 1 = partly right, 2 = right and complete (answerable questions only).",
    "hallucination: yes if the answer contains any false or invented specific claim, else no.",
    "refused_correctly: unanswerable questions only; yes if the answer says the sources do not cover it.",
    "Do not change the key column or reorder rows. Save as eval/scored.xlsx."), colNames = FALSE)
  openxlsx::setColWidths(wb, "how_to_score", cols = 1, widths = 120)

  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  message("Scoring sheet written to ", path)
}
write_scoring_sheet(results)
