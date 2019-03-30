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
#' @family Drill direct REST API Interface
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
      httr::POST(
        url = sprintf("%s/query.json", drill_server),
        encode = "json",
        httr::progress(),
        body = list(
          queryType = "SQL",
          query = query
        )
      ) -> res
    } else {
      httr::POST(
        url = sprintf("%s/query.json", drill_server),
        encode = "json",
        body = list(
          queryType = "SQL",
          query = query
        )
      ) -> res
    }

    jsonlite::fromJSON(
      httr::content(res, as="text", encoding="UTF-8"),
      flatten=TRUE
    ) -> out

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

  if (length(query_result$columns) != 0) {
    query_result$rows <- query_result$rows[,query_result$columns,drop=FALSE]
  }

  if (length(query_result$columns) != 0) {
    if (is.data.frame(query_result$rows)) {
      if (nrow(query_result$rows) > 0) query_result$rows <-
          query_result$rows[,query_result$columns,drop=FALSE]
    } else {
      lapply(1:length(query_result$columns), function(col_idx) {
        ctype <- query_result$metadata[col_idx]
        if (ctype == "INT") {
          integer(0)
        } else if (ctype == "VARCHAR") {
          character(0)
        } else if (ctype == "TIMESTAMP") {
          cx <- integer(0)
          class(cx) <- "POSIXct"
          cx
        } else if (ctype == "BIGINT") {
          integer64(0)
        } else if (ctype == "BINARY") {
          character(0)
        } else if (ctype == "BOOLEAN") {
          logical(0)
        } else if (ctype == "DATE") {
          cx <- integer(0)
          class(cx) <- "Date"
          cx
        } else if (ctype == "FLOAT") {
          numeric(0)
        } else if (ctype == "DOUBLE") {
          double(0)
        } else if (ctype == "TIME") {
          character(0)
        } else if (ctype == "INTERVAL") {
          character(0)
        } else {
          character(0)
        }
      }) -> xdf
      xdf <- set_names(xdf, query_result$columns)
      class(xdf) <- c("data.frame")
      return(xdf)
    }
  }


  # ** only available in Drill 1.15.0+ **
  # be smarter about type conversion now that the REST API provides
  # the necessary metadata
  if (length(query_result$metadata)) {

    if ("BIGINT" %in% query_result$metadata) {
      if (!.pkgenv$bigint_warn_once) {
        if (getOption("sergeant.bigint.warnonce", TRUE)) {
          warning(
            "One or more columns are of type BIGINT. ",
            "The sergeant package currently uses jsonlite::fromJSON() ",
            "to process Drill REST API result sets. Since jsonlite does not ",
            "support 64-bit integers BIGINT columns are initially converted ",
            "to numeric since that's how jsonlite::fromJSON() works. This is ",
            "problematic for many reasons, including trying to use 'dplyr' idioms ",
            "with said converted BIGINT-to-numeric columns. It is recommended that ",
            "you 'CAST' BIGINT columns to 'VARCHAR' prior to working with them from ",
            "R/'dplyr'.\n\n",
            "If you really need BIGINT/integer64 support, consider using the ",
            "R ODBC interface to Apache Drill with the MapR ODBC drivers.\n\n",
            "This informational warning will only be shown once per R session and ",
            "you can disable them from appearing by setting the 'sergeant.bigint.warnonce' ",
            "option to 'FALSE' (i.e. options(sergeant.bigint.warnonce = FALSE)).",
            call.=FALSE
          )
        }
        .pkgenv$bigint_warn_once <- TRUE
      }
    }

    sapply(1:length(query_result$columns), function(col_idx) {

      cname <- query_result$columns[col_idx]
      ctype <- query_result$metadata[col_idx]

      case_when(
        ctype == "INT" ~ "i",
        ctype == "VARCHAR" ~ "c",
        ctype == "TIMESTAMP" ~ "?",
        ctype == "BIGINT" ~ "?",
        ctype == "BINARY" ~ "c",
        ctype == "BOOLEAN" ~ "l",
        ctype == "DATE" ~ "?",
        ctype == "FLOAT" ~ "d",
        ctype == "DOUBLE" ~ "d",
        ctype == "TIME" ~ "c",
        ctype == "INTERVAL" ~ "?",
        TRUE ~ "?"
      )

    }) -> col_types

    suppressMessages(
      dplyr::tbl_df(
        readr::type_convert(
          df = query_result$rows,
          col_types = paste0(col_types, collapse=""),
          na = character()
        )
      )
    ) -> xdf

  } else {

    suppressMessages(
      dplyr::tbl_df(
        readr::type_convert(df = query_result$rows, na = character())
      )
    ) -> xdf

  }

  xdf

}
