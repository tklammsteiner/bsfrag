# Summarise the hand-scored evaluation (eval/scored.xlsx + eval/key.csv)
# and write the results table to eval/results_table.md.

scored <- readxl::read_excel("eval/scored.xlsx", sheet = "score") |>
  dplyr::left_join(readr::read_csv("eval/key.csv", show_col_types = FALSE), by = "key") |>
  dplyr::mutate(correct           = as.numeric(correct),
                hallucination     = tolower(hallucination) == "yes",
                refused_correctly = tolower(refused_correctly) == "yes")

n_unans <- length(unique(scored$id[scored$category == "Unanswerable"]))

summary <- scored |>
  dplyr::group_by(Setup = setup) |>
  dplyr::summarise(
    `Retrieval hit rate`           = mean(retrieval_hit, na.rm = TRUE),
    `Mean correctness (0-2)`       = mean(correct[category != "Unanswerable"], na.rm = TRUE),
    `Share fully correct`          = mean(correct[category != "Unanswerable"] == 2, na.rm = TRUE),
    `Answers with hallucination`   = sum(hallucination, na.rm = TRUE),
    `Correct refusals`             = paste0(sum(refused_correctly, na.rm = TRUE), " / ", n_unans)) |>
  dplyr::mutate(`Retrieval hit rate` = ifelse(is.nan(`Retrieval hit rate`), NA, `Retrieval hit rate`))

by_category <- scored |>
  dplyr::filter(category != "Unanswerable") |>
  dplyr::group_by(Setup = setup, category) |>
  dplyr::summarise(correct = mean(correct, na.rm = TRUE), .groups = "drop") |>
  tidyr::pivot_wider(names_from = category, values_from = correct)

out <- c("## Overall", "",
         knitr::kable(summary, digits = 2, format = "pipe"), "",
         "## Mean correctness (0-2) by question category", "",
         knitr::kable(by_category, digits = 2, format = "pipe"))
writeLines(out, "eval/results_table.md")
print(summary); print(by_category)
