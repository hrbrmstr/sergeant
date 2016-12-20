#' Connect to Drill (using dplyr).
#'
#' Use \code{src_drill()} to connect to a Drill cluster and `tbl()` to connect to a
#' fully-qualified "table reference".
#'
#' Presently, this is a hack-ish wrapper around the RJDBC JDBCConnection presented by Drill.
#' While basic functionality works, Drill needs it's own DBI driver to avoid collisions withy
#' any other JDBC connections you might have open and more work needs to be done under the covers
#' to deal with quoting properly and exposing more Drill built-in functions.
#'
#' @note A copy of the Drill JDBC driver comes with this package but this is only temporary.
#'       It will have to be removed before a CRAN submission.
#'
#' @param nodes character vector of nodes. If more than one node, you can either have
#'              a single string with the comma-separated node:port pairs pre-made or
#'              pass in a character vector with multiple node:port strings and the
#'              function will make a comma-separated node string for you.
#' @param cluster_id the cluster id from \code{drill-override.conf}
#' @param schema an optional schema name to append to the JDBC connection string
#' @param use_zk are you connecting to a ZooKeeper instance (default: \code{TRUE}) or
#'               connecting to an individual DrillBit.
#' @export
#' @examples \dontrun{
#' library(RJDBC)
#' library(dplyr)
#' library(sergeant)
#'
#' ds <- src_drill("localhost:31010", use_zk=FALSE)
#' print(ds)
#' db <- tbl(ds, "cp.`employee.json`")
#' count(db, gender, marital_status)
#' }
src_drill <- function(nodes="localhost:2181", cluster_id=NULL, schema=NULL, use_zk=TRUE) {

  drill_jdbc_drv <- RJDBC::JDBC(driverClass="org.apache.drill.jdbc.Driver",
                                system.file("jars", "drill-jdbc-all-1.9.0.jar", package="sergeant", mustWork=TRUE))

  conn_type <- "drillbit"
  if (use_zk) conn_type <- "zk"

  if (length(nodes) > 1) nodes <- paste0(nodes, collapse=",")

  conn_str <- sprintf("jdbc:drill:%s=%s", conn_type, nodes)

  if (!is.null(cluster_id)) conn_str <- sprintf("%s%s", conn_str, sprintf("/drill/%s", cluster_id))

  if (!is.null(schema)) conn_str <- sprintf("%s;%s", schema)

  message(sprintf("Using [%s]...", conn_str))

  con <- RJDBC::dbConnect(drill_jdbc_drv, conn_str)

  src_sql("drill", con)

}

#' @export
src_tbls.src_drill <- function(x) {
  tmp <- dbGetQuery(x$con, "SHOW DATABASES")
  paste0(unlist(tmp$SCHEMA_NAME, use.names=FALSE), collapse=", ")
}

#' @export
src_desc.src_drill <- function(con) {

  #info <- RJDBC::dbGetInfo(con$con)
  tmp <- dbGetQuery(con$con, "select * from sys.version")
  version <- tmp$version
  tmp <- dbGetQuery(con$con, "select direct_max from sys.memory")
  memory <- scales::comma(tmp$direct_max)

  sprintf("Version: %s; Direct memory: %s bytes", version, memory)

}

#' @export
tbl.src_drill <- function(src, from, ...) {
  tbl_sql("drill", src=src, from=from, ...)
}

#' @export
sql_escape_ident.JDBCConnection <- function(con, x) {
  sql_quote(x, ' ')
}

#' @export
db_data_type <- function(con, fields) UseMethod("db_data_type")

#' @export
db_data_type.JDBCConnection <- function(con, fields, ...) {
  print("\n\n\nHERE\n\n\n")
  data_type <- function(x) {
    switch(class(x)[1],
      logical = "BOOLEAN",
      integer = "INTEGER",
      numeric = "DOUBLE",
      factor =  "CHARACTER",
      character = "CHARACTER",
      Date = "DATE",
      POSIXct = "TIMESTAMP",
      stop("Can't map type ", paste(class(x), collapse = "/"),
           " to a supported database type.")
    )
  }
  vapply(fields, data_type, character(1))
}

#' @export
sql_translate_env.JDBCConnection <- function(x) {
  dplyr::sql_variant(
    scalar=dplyr::sql_translator(
      .parent = dplyr::base_scalar,
      `!=` = dplyr::sql_infix("<>"),
      as.numeric = function(x) build_sql("CAST(", x, " AS DOUBLE)"),
      as.character = function(x) build_sql("CAST(", x, " AS CHARACTER)"),
      as.date = function(x) build_sql("CAST(", x, " AS DATE)"),
      as.posixct = function(x) build_sql("CAST(", x, " AS TIMESTAMP)"),
      as.logical = function(x) build_sql("CAST(", x, " AS BOOLEAN)")
    ),
    aggregate=dplyr::sql_translator(.parent = dplyr::base_agg,
                          n = function() dplyr::sql("COUNT(*)"),
                          cor = dplyr::sql_prefix("CORR"),
                          cov = dplyr::sql_prefix("COVAR_SAMP"),
                          sd =  dplyr::sql_prefix("STDDEV_SAMP"),
                          var = dplyr::sql_prefix("VAR_SAMP"),
                          n_distinct = function(x) {
                            dplyr::build_sql(dplyr::sql("COUNT(DISTINCT "), x, dplyr::sql(")"))
                          }
    )
  )
}

#' @export
db_analyze.JDBCConnection <- function(con, table) {
  return(TRUE)
}

#' @export
db_create_index.JDBCConnectionn <- function(con, table, columns, name = NULL, ...) {
  return(TRUE)
}
