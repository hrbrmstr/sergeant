#' Submit a query and return results
#'
#' @param query query to run
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_query <- function(query, drill_server=Sys.getenv("DRILL_URL")) {

  res <- httr::POST(sprintf("%s/query.json", drill_server),
                    encode="json",
                    body=list(queryType="SQL",
                              query=query))

  jsonlite::fromJSON(content(res, as="text"), flatten=TRUE)

}

