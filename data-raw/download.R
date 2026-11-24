# Build the corpus: open-access (CC BY / CC0) black soldier fly articles
# from Europe PMC, with NCBI PMC as fallback for full texts.
# Writes data-raw/corpus.csv (committed) and data-raw/xml/*.xml (not committed).
# Run from the project root. Takes about 30-60 minutes for ~1,100 articles.

library(httr2)
library(purrr)
library(dplyr)

epmc  <- "https://www.ebi.ac.uk/europepmc/webservices/rest"
query <- '(TITLE_ABS:"Hermetia illucens" OR TITLE_ABS:"black soldier fly") AND OPEN_ACCESS:y AND HAS_FT:y'

# 1. Search (cursor-based paging) --------------------------------------------
search_page <- function(cursor = "*") {
  request(paste0(epmc, "/search")) |>
    req_url_query(query = query, format = "json", resultType = "core",
                  pageSize = 100, cursorMark = cursor) |>
    req_retry(max_tries = 5, retry_on_failure = TRUE) |>
    req_perform() |>
    resp_body_json()
}

hits <- list(); cursor <- "*"
repeat {
  res <- search_page(cursor)
  hits <- c(hits, res$resultList$result)
  if (is.null(res$nextCursorMark) || res$nextCursorMark == cursor) break
  cursor <- res$nextCursorMark
}

# 2. Metadata table, CC BY / CC0 only -----------------------------------------
corpus <- map(hits, \(h) tibble(
  pmcid   = h$pmcid %||% NA,
  doi     = h$doi %||% NA,
  title   = h$title %||% NA,
  authors = h$authorString %||% NA,
  journal = h$journalInfo$journal$isoabbreviation %||% NA,
  year    = h$pubYear %||% NA,
  license = h$license %||% NA
)) |>
  list_rbind() |>
  filter(!is.na(pmcid), grepl("^cc[ -]?by|^cc0", tolower(license)))

readr::write_csv(corpus, "data-raw/corpus.csv")

# 3. Full texts from Europe PMC -----------------------------------------------
dir.create("data-raw/xml", showWarnings = FALSE)

fetch_xml <- function(req, f) {
  ok <- tryCatch({
    req |> req_retry(max_tries = 5, retry_on_failure = TRUE) |> req_perform(path = f)
    length(xml2::xml_find_all(xml2::read_xml(f), "//body/sec")) > 0
  }, error = \(e) FALSE)
  if (!ok && file.exists(f)) file.remove(f)   # never keep broken or body-less files
  ok
}

walk(corpus$pmcid, \(id) {
  f <- file.path("data-raw/xml", paste0(id, ".xml"))
  if (file.exists(f)) return()
  fetch_xml(request(paste0(epmc, "/", id, "/fullTextXML")), f)
  Sys.sleep(1)
})

# 4. Fallback: NCBI PMC for articles Europe PMC would not serve ---------------
missing <- setdiff(corpus$pmcid, sub("\\.xml$", "", list.files("data-raw/xml")))
walk(missing, \(id) {
  f <- file.path("data-raw/xml", paste0(id, ".xml"))
  req <- request("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi") |>
    req_url_query(db = "pmc", id = sub("^PMC", "", id), retmode = "xml")
  if (!fetch_xml(req, f)) message("Still missing ", id)
  Sys.sleep(0.4)   # NCBI allows 3 requests/s without an API key
})

message(length(list.files("data-raw/xml")), " of ", nrow(corpus), " full texts downloaded.")
