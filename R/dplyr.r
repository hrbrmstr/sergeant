#' Connect to Drill (dplyr)
#'
#' Use \code{src_drill()} to connect to a Drill cluster and `tbl()` to connect to a
#' fully-qualified "table reference". The vast majority of Drill SQL functions have
#' also been made available to the \code{dplyr} interface. If you have custom Drill
#' SQL functions that need to be implemented please file an issue on GitHub.
#'
#' @md
#' @param host Drill host (will pick up the value from \code{DRILL_HOST} env var)
#' @param port Drill port (will pick up the value from \code{DRILL_PORT} env var)
#' @param ssl use ssl?
#' @family Drill REST `dplyr` API
#' @param username,password if not `NULL` the credentials for the Drill service.
#' @note This is a DBI wrapper around the Drill REST API.
#' @export
#' @examples
#' try({
#' db <- src_drill("localhost", 8047L)
#'
#' print(db)
#' ## src:  DrillConnection
#' ## tbls: INFORMATION_SCHEMA, cp.default, dfs.default, dfs.root, dfs.tmp, sys
#'
#' emp <- tbl(db, "cp.`employee.json`")
#'
#' count(emp, gender, marital_status)
#' ## # Source:   lazy query [?? x 3]
#' ## # Database: DrillConnection
#' ## # Groups:   gender
#' ##   marital_status gender     n
#' ##            <chr>  <chr> <int>
#' ## 1              S      F   297
#' ## 2              M      M   278
#' ## 3              S      M   276
#'
#' # Drill-specific SQL functions are also available
#' select(emp, full_name) %>%
#'   mutate(        loc = strpos(full_name, "a"),
#'          first_three = substr(full_name, 1L, 3L),
#'                  len = length(full_name),
#'                   rx = regexp_replace(full_name, "[aeiouAEIOU]", "*"),
#'                  rnd = rand(),
#'                  pos = position("en", full_name),
#'                  rpd = rpad(full_name, 20L),
#'                 rpdw = rpad_with(full_name, 20L, "*"))
#' ## # Source:   lazy query [?? x 9]
#' ## # Database: DrillConnection
#' ##      loc         full_name   len                 rpdw   pos                rx
#' ##    <int>             <chr> <int>                <chr> <int>             <chr>
#' ##  1     0      Sheri Nowmer    12 Sheri Nowmer********     0      Sh*r* N*wm*r
#' ##  2     0   Derrick Whelply    15 Derrick Whelply*****     0   D*rr*ck Wh*lply
#' ##  3     5    Michael Spence    14 Michael Spence******    11    M*ch**l Sp*nc*
#' ##  4     2    Maya Gutierrez    14 Maya Gutierrez******     0    M*y* G*t**rr*z
#' ##  5     7   Roberta Damstra    15 Roberta Damstra*****     0   R*b*rt* D*mstr*
#' ##  6     7  Rebecca Kanagaki    16 Rebecca Kanagaki****     0  R*b*cc* K*n*g*k*
#' ##  7     0       Kim Brunner    11 Kim Brunner*********     0       K*m Br*nn*r
#' ##  8     6   Brenda Blumberg    15 Brenda Blumberg*****     3   Br*nd* Bl*mb*rg
#' ##  9     2      Darren Stanz    12 Darren Stanz********     5      D*rr*n St*nz
#' ## 10     4 Jonathan Murraiin    17 Jonathan Murraiin***     0 J*n*th*n M*rr***n
#' ## # ... with more rows, and 3 more variables: rpd <chr>, rnd <dbl>, first_three <chr>
#' }, silent=TRUE)
src_drill <- function(host  = Sys.getenv("DRILL_HOST", "localhost"),
                      port = as.integer(Sys.getenv("DRILL_PORT", 8047L)),
                      ssl = FALSE, username = NULL, password = NULL) {

  dr <- Drill()

  con <- dbConnect(
    dr, host = host, port = port, ssl = ssl,
    username = username, password = password
  )

  src_sql("drill", con)

}

#' src tbls
#'
#' "SHOW DATABASES"
#'
#' @rdname src_tbls
#' @param x x
#' @family Drill REST `dplyr` API
#' @export
src_tbls.src_drill <- function(x) {
  tmp <- dbGetQuery(x$con, "SHOW DATABASES")
  paste0(unlist(tmp$SCHEMA_NAME, use.names=FALSE), collapse=", ")
}

#' @rdname src_tbls
#' @keywords internal
#' @export
db_desc.src_drill <- function(x) {

  tmp <- dbGetQuery(x$con, "SELECT * FROM sys.version")
  version <- tmp$version
  tmp <- dbGetQuery(x$con, "SELECT (direct_max / 1024 / 1024 / 1024) AS direct_max FROM sys.memory")
  memory <- tmp$direct_max

  sprintf("Drill %s [%s:%d] [%dGB direct memory]", version, x$con@host, x$con@port, memory)

}

#' @rdname src_tbls
#' @keywords internal
#' @export
sql_escape_ident.DrillConnection <- function(con, x) {
  ifelse(grepl("`", x), sql_quote(x, ' '), sql_quote(x, '`'))
}

#' @rdname src_tbls
#' @keywords internal
#' @export
copy_to.src_drill <- function(dest, df, name, overwrite, ...) {
  stop("Not implemented.", call.=FALSE)
}

#' @rdname src_drill
#' @param src A Drill "src" created with \code{src_drill()}
#' @param from A Drill view or table specification
#' @family Drill REST `dplyr` API
#' @param ... Extra parameters
#' @export
tbl.src_drill <- function(src, from, ...) {
  tbl_sql("drill", src=src, from=from, ...)
}

#' @rdname src_tbls
#' @keywords internal
#' @export
db_explain.DrillConnection <- function(con, sql, ...) {
  explain_sql <- dbplyr::build_sql("EXPLAIN PLAN FOR ", sql)
  explanation <- dbGetQuery(con, explain_sql)
  return(paste(explanation[[1]], collapse = "\n"))
}

#' @rdname src_tbls
#' @keywords internal
#' @export
db_query_fields.DrillConnection <- function(con, sql, ...) {

  fields <- dbplyr::build_sql(
    "SELECT * FROM ", sql, " LIMIT 1",
    con = con
  )
  result <- dbSendQuery(con, fields)
  return(unique(c(dbListFields(result), con@implicits)))

}

#' @rdname src_tbls
#' @keywords internal
#' @export
db_data_type.DrillConnection <- function(con, fields, ...) {
  print("\n\n\ndb_data_type\n\n\n")
  data_type <- function(x) {
    switch(
      class(x)[1],
      integer64 = "BIGINT",
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

#' @rdname src_tbls
#' @keywords internal
#' @export
sql_translate_env.DrillConnection <- function(con) {

  x <- con

  dbplyr::sql_variant(

    scalar = dbplyr::sql_translator(
      .parent = dbplyr::base_scalar,
      `!=` = dbplyr::sql_infix("<>"),
      as.numeric = function(x) build_sql("CAST(", x, " AS DOUBLE)"),
      as.character = function(x) build_sql("CAST(", x, " AS CHARACTER)"),
      as.date = function(x) build_sql("CAST(", x, " AS DATE)"),
      as.posixct = function(x) build_sql("CAST(", x, " AS TIMESTAMP)"),
      as.logical = function(x) build_sql("CAST(", x, " AS BOOLEAN)"),
      date_part = function(x, y) build_sql("DATE_PART(", x, ",", y ,")"),
      grepl = function(x, y) build_sql("CONTAINS(", y, ", ", x, ")"),
      gsub = function(x, y, z) build_sql("REGEXP_REPLACE(", z, ", ", x, ",", y ,")"),
      trimws = function(x) build_sql("TRIM(both ' ' FROM ", x, ")"),
      cbrt = sql_prefix("CBRT", 1),
      degrees = sql_prefix("DEGREES", 1),
      e = sql_prefix("E", 0),
      row_number = sql_prefix("row_number", 0),
      lshift = sql_prefix("LSHIFT", 2),
      mod = sql_prefix("MOD", 2),
      age = sql_prefix("AGE", 1),
      negative = sql_prefix("NEGATIVE", 1),
      pi = sql_prefix("PI", 0),
      pow = sql_prefix("POW", 2),
      radians = sql_prefix("RADIANS", 1),
      rand = sql_prefix("RAND", 0),
      rshift = sql_prefix("RSHIFT", 2),
      trunc = sql_prefix("TRUNC", 2),
      contains = sql_prefix("CONTAINS", 2),
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
      repeated_contains = sql_prefix("REPEATED_CONTAINS", 2),
      ilike = sql_prefix("ILIKE", 2),
      init_cap = sql_prefix("INIT_CAP", 1),
      length = sql_prefix("LENGTH", 1),
      lower = sql_prefix("LOWER", 1),
      tolower = sql_prefix("LOWER", 1),
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
      upper = sql_prefix("UPPER", 1),
      toupper = sql_prefix("UPPER", 1)
    ),

    aggregate = dbplyr::sql_translator(
      .parent = dbplyr::base_agg,
      n = function() dbplyr::sql("COUNT(*)"),
      cor = dbplyr::sql_prefix("CORR"),
      cov = dbplyr::sql_prefix("COVAR_SAMP"),
      sd =  dbplyr::sql_prefix("STDDEV_SAMP"),
      var = dbplyr::sql_prefix("VAR_SAMP"),
      n_distinct = function(x) {
        dbplyr::build_sql(dbplyr::sql("COUNT(DISTINCT "), x, dbplyr::sql(")"))
      }
    ),

    window = dbplyr::sql_translator(
      .parent = dbplyr::base_win,
      n = function() { dbplyr::win_over(dbplyr::sql("count(*)"),
                                        partition = dbplyr::win_current_group()) },
      cor = dbplyr::win_recycled("corr"),
      cov = dbplyr::win_recycled("covar_samp"),
      sd =  dbplyr::win_recycled("stddev_samp"),
      var = dbplyr::win_recycled("var_samp"),
      all = dbplyr::win_recycled("bool_and"),
      any = dbplyr::win_recycled("bool_or")
    )

  )

}
