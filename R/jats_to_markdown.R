#' Convert a JATS full-text XML article to Markdown
#'
#' Keeps the title, abstract and the nested section structure (as Markdown
#' headings), so that chunks can carry the heading they come from.
#' References, figures, tables and supplementary material are dropped.
#'
#' @param path Path to one JATS XML file (from Europe PMC or NCBI PMC).
#' @return A single character string of Markdown.
#' @export
jats_to_markdown <- function(path) {
  x <- xml2::read_xml(path)
  title    <- xml2::xml_text(xml2::xml_find_first(x, "//article-title"))
  abstract <- xml2::xml_text(xml2::xml_find_all(x, "//abstract//p"))
  render_sec <- function(sec, level = 2) {
    head  <- xml2::xml_text(xml2::xml_find_first(sec, "./title"))
    paras <- xml2::xml_text(xml2::xml_find_all(sec, "./p"))
    subs  <- xml2::xml_find_all(sec, "./sec")
    c(paste(strrep("#", level), head), paras,
      unlist(lapply(subs, render_sec, level = level + 1)))
  }
  body <- unlist(lapply(xml2::xml_find_all(x, "//body/sec"), render_sec))
  paste(c(paste("#", title), "## Abstract", abstract, body), collapse = "\n\n")
}
