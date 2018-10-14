#' Submit a query and return results
#'
#' This function can handle REST API connections or JDBC connections. There is a benefit to
#' calling this function for JDBC connections vs a straight call to \code{dbGetQuery()} in
#' that the function result is a `tbl_df` vs a plain \code{data.frame} so you get better
#' default printing (which can be helpful if you accidentally execute a query and the result
#' set is huge).
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()} or
#'                  \code{drill_jdbc()})
#' @param query query to run
#' @param uplift automatically run \code{drill_uplift()} on the result? (default: \code{TRUE},
#'               ignored if \code{drill_con} is a \code{JDBCConnection} created by
#'               \code{drill_jdbc()})
#' @param .progress if \code{TRUE} (default if in an interactive session) then ask
#'                  \code{httr::POST} to display a progress bar
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Dill direct REST API Interface
#' @export
#' @examples
#' try({
#' drill_connection() %>%
#'   drill_query("SELECT * FROM cp.`employee.json` limit 5")
#' }, silent=TRUE)
drill_query <- function(drill_con, query, uplift=TRUE, .progress=interactive()) {

  query <- trimws(query)
  query <- gsub(";$", "", query)

  if (inherits(drill_con, "JDBCConnection")) {

    try_require("rJava")
    try_require("RJDBC")
    try_require("sergeant.caffeinated")

    dplyr::tbl_df(dbGetQuery(drill_con, query))

  } else {

    drill_server <- make_server(drill_con)

    if (.progress) {
      res <- httr::POST(sprintf("%s/query.json", drill_server),
                        encode="json",
                        progress(),
                        body=list(queryType="SQL", query=query))
    } else {
      res <- httr::POST(sprintf("%s/query.json", drill_server),
                        encode="json",
                        body=list(queryType="SQL", query=query))
    }

    out <- jsonlite::fromJSON(httr::content(res, as="text", encoding="UTF-8"), flatten=TRUE)

    if ("errorMessage" %in% names(out)) {
      message(sprintf("Query ==> %s\n%s\n", gsub("[\r\n]", " ", query), out$errorMessage))
      invisible(out)
    } else {
      if (uplift) out <- drill_uplift(out)
      out
    }

  }

}

#' Turn columnar query results into a type-converted tbl
#'
#' If you know the result of `drill_query()` will be a data frame, then
#' you can pipe it to this function to pull out `rows` and automatically
#' type-convert it.
#'
#' Not really intended to be called directly, but useful if you accidentally ran
#' \code{drill_query()} without `uplift=TRUE` but want to then convert the structure.
#'
#' @param query_result the result of a call to `drill_query()`
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
drill_uplift <- function(query_result) {
  dplyr::tbl_df(readr::type_convert(query_result$rows))
}
