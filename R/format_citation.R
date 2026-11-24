#' Build a short citation string for a paper
#'
#' Used as the `origin` of every chunk in the store, so the model can cite
#' "Klammsteiner et al. (2020) ..." instead of a file name. HTML tags and
#' escaped tags in titles (e.g. `&lt;i&gt;`) are removed.
#'
#' @param authors Author string as returned by Europe PMC ("Last A, Last B, ...").
#' @param year Publication year.
#' @param title Article title.
#' @param journal Journal abbreviation.
#' @param doi DOI without the `https://doi.org/` prefix.
#' @return A character vector of citation strings.
#' @export
#' @examples
#' format_citation("Klammsteiner T, Walter A, Insam H.", 2020,
#'                 "The core gut microbiome of &lt;i&gt;Hermetia illucens&lt;/i&gt; larvae",
#'                 "Front Microbiol", "10.3389/fmicb.2020.00993")
format_citation <- function(authors, year, title, journal, doi) {
  clean <- function(x) {
    x <- gsub("&lt;[^&]*&gt;", "", x)
    x <- gsub("<[^>]+>", "", x)
    trimws(gsub("\\s+", " ", x))
  }
  first <- sub(",.*", "", clean(authors))
  first <- sub("\\.$", "", first)
  lead  <- ifelse(grepl(",", authors), paste(first, "et al."), first)
  sprintf("%s (%s) %s %s. doi:%s",
          lead, year, sub("([^.?!])$", "\\1.", clean(title)), clean(journal), doi)
}
