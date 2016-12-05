#' Submit a query and return results
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param query query to run
#' @param uplift automatically run \code{drill_uplift()} on the result? (default: \code{TRUE})
#' @param .progress if \code{TRUE} (default if in an interactive session) then ask
#'                  \code{httr::POST} to display a progress bar
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
#' @examples \dontrun{
#' drill_con() %>%
#'   drill_query("SELECT * FROM cp.`employee.json` limit 5")
#' }
drill_query <- function(drill_con, query, uplift=TRUE, .progress=interactive()) {

  drill_server <- make_server(drill_con)

  if (.progress) {
    res <- httr::POST(sprintf("%s/query.json", drill_server),
                      encode="json",
                      progress(),
                      body=list(queryType="SQL",
                                query=query))
  } else {
    res <- httr::POST(sprintf("%s/query.json", drill_server),
                      encode="json",
                      body=list(queryType="SQL",
                                query=query))
  }

  out <- jsonlite::fromJSON(httr::content(res, as="text", encoding="UTF-8"), flatten=TRUE)

  if ("errorMessage" %in% names(out)) {
    message(sprintf("Query ==> %s\n%s\n", gsub("[\r\n]", " ", query), out$errorMessage))
    invisible(out)
  } else {
    if (uplift) drill_uplift(out)
  }

}

#' Turn a columnar query results into a type-converted tbl
#'
#' If you know the result of `drill_query()` will be a data frame, then
#' you can pipe it to this function to pull out `rows` and automatically
#' type-convert it.
#'
#' Not really intended to be called directly, but useful if you ran \code{drill_query()}
#' without `uplift=TRUE` but want to then convert the structure.
#'
#' @param query_result the result of a call to `drill_query()`
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
drill_uplift <- function(query_result) {
  dplyr::tbl_df(readr::type_convert(query_result$rows))
}
