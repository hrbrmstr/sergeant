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
      as.logical = function(x) build_sql("CAST(", x, " AS BOOLEAN)"),
      cbrt = sql_prefix("CBRT", 1),
      degrees = sql_prefix("DEGREES", 1),
      e = sql_prefix("E", 0),
      lshift = sql_prefix("LSHIFT", 2),
      mod = sql_prefix("MOD", 2),
      negative = sql_prefix("NEGATIVE", 1),
      pi = sql_prefix("PI", 0),
      pow = sql_prefix("POW", 2),
      radians = sql_prefix("RADIANS", 1),
      rand = sql_prefix("RAND", 0),
      rshift = sql_prefix("RSHIFT", 2),
      trunc = sql_prefix("TRUNC", 2),
      convert_to = sql_prefix("CONVERT_TO", 2),
      convert_from = sql_prefix("CONVERT_FROM", 2),
      string_binary = sql_prefix("STRING_BINARY", 1),
      binary_string = sql_prefix("BINARY_STRING", 1),
      to_char = sql_prefix("TO_CHAR", 2),
      to_date = sql_prefix("TO_DATE", 2),
      to_number = sql_prefix("TO_NUMBER", 2),
      char_to_timestamp = sql_prefix("TO_TIMESTAMP", 2),
      double_to_timestamp = sql_prefix("TO_TIMESTAMP", 1),
      char_length = sql_prefix("CHAR_LENGTH", 1),
      flatten = sql_prefix("FLATTEN", 1),
      kvgen = sql_prefix("KVGEN", 1),
      repeated_count = sql_prefix("REPEATED_COUNT", 1),
      repeated_contains = sql_prefix("REPEATED_CONTAINS", 1),
      ilike = sql_prefix("ILIKE", 2),
      init_cap = sql_prefix("INIT_CAP", 1),
      length = sql_prefix("LENGTH", 1),
      lower = sql_prefix("LOWER", 1),
      ltrim = sql_prefix("LTRIM", 2),
      nullif = sql_prefix("NULLIF", 2),
      position = function(x, y) build_sql("POSITION(", x, " IN ", y, ")"),
      regexp_replace = sql_prefix("REGEXP_REPLACE", 3),
      rtrim = sql_prefix("RTRIM", 2),
      rpad = sql_prefix("RPAD", 2),
      rpad_with = sql_prefix("RPAD", 3),
      lpad = sql_prefix("LPAD", 2),
      lpad_with = sql_prefix("LPAD", 3),
      strpos = sql_prefix("STRPOS", 2),
      substr = sql_prefix("SUBSTR", 3),
      trim = function(x, y, z) build_sql("TRIM(", x, " ", y, " FROM ", z, ")"),
      upper = sql_prefix("UPPER", 1)
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
