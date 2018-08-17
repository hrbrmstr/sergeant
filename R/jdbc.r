#' @export
setClass(
  Class = "DrillJDBCDriver",
  contains = "JDBCDriver"
)

#' @export
setClass(
  Class = "DrillJDBCConnection",
  contains = "JDBCConnection"
)

#' @export
setMethod(
  f = "dbConnect",
  signature = "DrillJDBCDriver",
  definition = function(drv, url, user='', password='', ...) {

    .jcall(
      "java/sql/DriverManager",
      "Ljava/sql/Connection;",
      "getConnection",
      as.character(url)[1],
      as.character(user)[1],
      as.character(password)[1],
      check = FALSE
    ) -> jc

    if (is.jnull(jc) && !is.jnull(drv@jdrv)) {
      # ok one reason for this to fail is its interaction with rJava's
      # class loader. In that case we try to load the driver directly.
      oex <- .jgetEx(TRUE)

      p <- .jnew("java/util/Properties")

      if (length(user)==1 && nchar(user)) {
        .jcall(p,"Ljava/lang/Object;","setProperty","user",user)
      }

      if (length(password)==1 && nchar(password)) {
        .jcall(p,"Ljava/lang/Object;","setProperty","password",password)
      }

      l <- list(...)
      if (length(names(l))) for (n in names(l)) {
        .jcall(p, "Ljava/lang/Object;", "setProperty", n, as.character(l[[n]]))
      }

      jc <- .jcall(drv@jdrv, "Ljava/sql/Connection;", "connect", as.character(url)[1], p)

    }

    .verify.JDBC.result(jc, "Unable to connect JDBC to ",url)

    new("DrillJDBCConnection", jc=jc, identifier.quote=drv@identifier.quote)

  },

  valueClass = "DrillJDBCConnection"

)

#' @export
DrillJDBC <- function() {

  driverClass <-  "org.apache.drill.jdbc.Driver"

  ## expand all paths in the classPath
  classPath <- path.expand(unlist(strsplit(Sys.getenv("DRILL_JDBC_JAR"), .Platform$path.sep)))

  ## this is benign in that it's equivalent to .jaddClassPath if a JVM is running
  .jinit(classPath)

  .jaddClassPath(system.file("java", "RJDBC.jar", package="RJDBC"))
  .jaddClassPath(system.file("java", "slf4j-nop-1.7.25.jar", package = "sergeant"))

  if (nchar(driverClass) && is.jnull(.jfindClass(as.character(driverClass)[1]))) {
    stop("Cannot find JDBC driver class ",driverClass)
  }

  jdrv <- .jnew(driverClass, check=FALSE)

  .jcheck(TRUE)

  if (is.jnull(jdrv)) jdrv <- .jnull()

  new("DrillJDBCDriver", identifier.quote = "`", jdrv = jdrv)

}

#' Connect to Drill using JDBC
#'
#' The DRILL JDBC driver fully-qualified path must be placed in the
#' \code{DRILL_JDBC_JAR} environment variable. This is best done via \code{~/.Renviron}
#' for interactive work. e.g. \code{DRILL_JDBC_JAR=/usr/local/drill/jars/jdbc-driver/drill-jdbc-all-1.10.0.jar}
#'
#' @param nodes character vector of nodes. If more than one node, you can either have
#'              a single string with the comma-separated node:port pairs pre-made or
#'              pass in a character vector with multiple node:port strings and the
#'              function will make a comma-separated node string for you.
#' @param cluster_id the cluster id from \code{drill-override.conf}
#' @param schema an optional schema name to append to the JDBC connection string
#' @param use_zk are you connecting to a ZooKeeper instance (default: \code{TRUE}) or
#'               connecting to an individual DrillBit.
#' @return a JDBC connection object
#' @references \url{https://drill.apache.org/docs/using-the-jdbc-driver/#using-the-jdbc-url-for-a-random-drillbit-connection}
#' @export
#' @examples \dontrun{
#' con <- drill_jdbc("localhost:2181", "main")
#' drill_query(con, "SELECT * FROM cp.`employee.json`")
#'
#' # you can also use the connection with RJDBC calls:
#' dbGetQuery(con, "SELECT * FROM cp.`employee.json`")
#'
#' # for local/embedded mode with default configuration info
#' con <- drill_jdbc("localhost:31010", use_zk=FALSE)
#' }
drill_jdbc <- function(nodes = "localhost:2181", cluster_id = NULL,
                       schema = NULL, use_zk = TRUE) {

  try_require("rJava")
  try_require("RJDBC")

  jar_path <- Sys.getenv("DRILL_JDBC_JAR")
  if (!file.exists(jar_path)) {
    stop(sprintf("Cannot locate DRILL JDBC JAR [%s]", jar_path))
  }

  drill_jdbc_drv <- DrillJDBC()

  conn_type <- "drillbit"
  if (use_zk) conn_type <- "zk"

  if (length(nodes) > 1) nodes <- paste0(nodes, collapse=",")

  conn_str <- sprintf("jdbc:drill:%s=%s", conn_type, nodes)

  if (!is.null(cluster_id)) {
    conn_str <- sprintf("%s%s", conn_str, sprintf("/drill/%s", cluster_id))
  }

  if (!is.null(schema)) conn_str <- sprintf("%s;%s", schema)

  message(sprintf("Using [%s]...", conn_str))

  dbConnect(drill_jdbc_drv, conn_str)

}

#' Drill internals
#'
#' @rdname drill_jdbc_internals
#' @keywords internal
#' @export
db_data_type.DrillJDBCConnection <- function(con, fields, ...) {
  print("\n\n\ndb_data_type\n\n\n")
  data_type <- function(x) {
    switch(
      class(x)[1],
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

#' @rdname drill_jdbc_internals
#' @keywords internal
#' @export
sql_escape_ident.DrillJDBCConnection <- function(con, x) {
  ifelse(grepl(con@identifier.quote, x), sql_quote(x, ' '), sql_quote(x, con@identifier.quote))
}

#' @rdname drill_jdbc_internals
#' @keywords internal
#' @export
sql_translate_env.DrillJDBCConnection <- function(con) {

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
