search_page <- function(cursor = "*") {
  request(paste0(epmc, "/search")) |>
    req_url_query(query = query, format = "json", resultType = "core",
                  pageSize = 100, cursorMark = cursor) |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_json()
}
