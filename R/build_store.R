#' Build (or resume building) the retrieval store
#'
#' Converts every downloaded article to Markdown, splits it into
#' heading-aware chunks, embeds them with a local Ollama model and stores
#' them in a DuckDB file. Progress is logged, so an interrupted run can be
#' resumed by calling the function again (restart R first).
#'
#' Requires Ollama running locally with the `nomic-embed-text` model.
#'
#' @param corpus_csv Metadata table written by `data-raw/download.R`.
#' @param xml_dir Folder with one JATS XML file per article.
#' @param store_path Path of the DuckDB store to create.
#' @param log_path File listing PMCIDs already indexed.
#' @param fresh If `TRUE`, delete the store and log and start from scratch.
#' @return The ragnar store, invisibly.
#' @export
build_store <- function(corpus_csv = "data-raw/corpus.csv",
                        xml_dir    = "data-raw/xml",
                        store_path = "bsf.duckdb",
                        log_path   = "data-raw/indexed.txt",
                        fresh      = FALSE) {
  corpus <- readr::read_csv(corpus_csv, show_col_types = FALSE)

  if (fresh || !file.exists(store_path)) {
    store <- ragnar::ragnar_store_create(
      store_path,
      embed = \(x) ragnar::embed_ollama(x, model = "nomic-embed-text"),
      overwrite = TRUE
    )
    if (file.exists(log_path)) file.remove(log_path)
  } else {
    store <- ragnar::ragnar_store_connect(store_path, read_only = FALSE)
  }

  done <- if (file.exists(log_path)) readLines(log_path) else character()
  message(length(done), " papers already indexed; continuing.")

  for (i in seq_len(nrow(corpus))) {
    row <- corpus[i, ]
    f <- file.path(xml_dir, paste0(row$pmcid, ".xml"))
    if (!file.exists(f) || row$pmcid %in% done) next
    md <- tryCatch(jats_to_markdown(f), error = \(e) {
      message("Skipping unreadable file ", basename(f), ": ", conditionMessage(e))
      NULL
    })
    if (is.null(md)) next
    cite <- format_citation(row$authors, row$year, row$title, row$journal, row$doi)
    doc <- ragnar::MarkdownDocument(md, origin = cite)
    ragnar::ragnar_store_insert(store, ragnar::markdown_chunk(doc))
    cat(row$pmcid, "\n", sep = "", file = log_path, append = TRUE)
    message(i, "/", nrow(corpus), "  ", row$pmcid)
  }

  ragnar::ragnar_store_build_index(store)
  invisible(store)
}
