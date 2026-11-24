#' Ask a question and answer it from retrieved literature
#'
#' Retrieves the `top_k` most relevant chunks (vector + BM25 search), passes
#' them to the model as numbered excerpts and asks for a cited answer.
#' Returns the retrieved sources too, so results can be evaluated.
#'
#' Requires an `ANTHROPIC_API_KEY` in `.Renviron`.
#'
#' @param question A question in plain language.
#' @param store A ragnar store, e.g. from `ragnar::ragnar_store_connect()`.
#' @param top_k Number of chunks to retrieve.
#' @return A list with `question`, `answer`, `sources` and `chunks`.
#' @export
ask_bsf <- function(question, store, top_k = 8) {
  hits <- ragnar::ragnar_retrieve(store, question, top_k = top_k)
  context <- paste0("[", seq_len(nrow(hits)), "] ", hits$origin, "\n",
                    hits$text, collapse = "\n\n---\n\n")
  chat <- ellmer::chat_anthropic(system_prompt = system_prompt())
  answer <- chat$chat(paste0("Source excerpts:\n\n", context,
                             "\n\nQuestion: ", question), echo = "none")
  list(question = question, answer = answer,
       sources = hits$origin, chunks = hits$text)
}

#' The system prompt shipped with the package
#'
#' @return The contents of `inst/prompts/system.md` as one string.
#' @export
system_prompt <- function() {
  path <- system.file("prompts/system.md", package = "bsfrag")
  if (path == "") stop("System prompt not found: inst/prompts/system.md", call. = FALSE)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
