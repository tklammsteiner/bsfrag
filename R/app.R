#' Launch the BSF-RAG chat app
#'
#' Opens a Shiny chat interface in which the model searches the store as a
#' tool before answering. Run in a fresh R session from the project folder.
#'
#' @param store_path Path to the DuckDB store built by [build_store()].
#' @export
run_app <- function(store_path = "bsf.duckdb") {
  options(bsfrag.store_path = normalizePath(store_path, mustWork = TRUE))
  shiny::runApp(system.file("app", package = "bsfrag"))
}
