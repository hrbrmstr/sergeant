#' Generate a Drill CTAS Statement from a Query
#'
#' When working with CSV\[H] files in Drill 1.15.0+ everything comes back
#' `VARCHAR` since that's the way it should be. The old behaviour of
#' `sergeant` to auto-type convert was kinda horribad wrong. However,
#' it's a royal pain to make [`CTAS`](https://drill.apache.org/docs/create-table-as-ctas/)
#' queries from a giant list of `VARCHAR` field by hand. So, this is a
#' helper function to do that, inspired by David Severski.
#'
#' @note WIP!
#' @md
#' @param x a `tbl`
#' @param new_table_name a new Drill data source spec (e.g. \code{dfs.xyz.`a.parquet`})
#' @export
#' @examples \dontrun{
#' db <- src_drill("localhost")
#'
#' # Test with bare data source
#' flt1 <- tbl(db, "dfs.d.`/flights.csvh`")
#'
#' cat(ctas_profile(flt1))
#'
#' # Test with SELECT
#' flt2 <- tbl(db, sql("SELECT `year`, tailnum, time_hour FROM dfs.d.`/flights.csvh`"))
#'
#' cat(ctas_profile(flt2, "dfs.d.`flights.parquet`"))
#'
#' }
ctas_profile <- function(x, new_table_name = "CHANGE____ME") {

  stopifnot(inherits(x, "tbl_drill"))

  vals_orig <- dplyr::collect(head(x))

  vals <- suppressMessages(readr::type_convert(vals_orig))

  data_type <- function(x) {
    switch(
      class(x)[1],
      integer64 = "BIGINT",
      logical = "BOOLEAN",
      integer = "INTEGER",
      numeric = "DOUBLE",
      factor =  "VARCHAR",
      character = "VARCHAR",
      Date = "DATE",
      POSIXct = "TIMESTAMP",
      stop("Can't map type ", paste(class(x), collapse = "/"),
           " to a supported database type.")
    )
  }

  field_types <- vapply(vals, data_type, character(1))

  ctr <- 0

  mapply(function(fn, ft) {

    if (ft %in% c("DATE", "TIMESTAMP")) {

      ctr <<- ctr + 1
      cmt <- "*NOTE* You need to specify the format string. Sample character data is: [%s]. "
      cmt <- sprintf(cmt, vals_orig[[fn]][[1]])

      sprintf("  TO_TIMESTAMP(`%s`, 'FORMATSTRING') AS `%s` -- %s", fn, fn, cmt)

    } else {
      sprintf("  CAST(`%s` AS %s) AS `%s`", fn, ft, fn)
    }

  }, names(field_types), field_types, SIMPLIFY = TRUE, USE.NAMES = FALSE) -> casts

  casts <- unlist(strsplit(paste0(casts, collapse=",\n"), "\n"))

  orig_query <- x$ops$x

  if (!grepl("select", orig_query, ignore.case=TRUE)) {
    orig_query <- sprintf("SELECT * FROM %s", orig_query)
  }

  sprintf(
    "CREATE TABLE %s AS\nSELECT\n%s\nFROM (%s)\n",
    new_table_name,
    paste0(casts, collapse="\n"),
    orig_query
  ) -> out

  paste0(c(
    "-- ** Created by ctas_profile() in the R sergeant package, version ",
    toString(packageVersion("sergeant")), " **\n\n", out
  ), collapse="") -> out

  if (ctr > 0) {
    sprintf(
      paste0(c(
        "%s\n\n-- TIMESTAMP and/or DATE columns were detected.\n",
        "Drill's date/time format string reference can be found at:\n--\n",
        "-- <http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html>"
      ), collapse=""),
      out
    ) -> out
  }

  out

}
