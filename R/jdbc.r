#' Connect to Drill using JDBC
#'
#' A copy of the Drill JDBC driver comes with this package. You can bypass the REST API
#' if you use the JDBC connection.
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
drill_jdbc <- function(nodes="localhost:2181", cluster_id=NULL, schema=NULL, use_zk=TRUE) {

  drill_jdbc_drv <- RJDBC::JDBC(driverClass="org.apache.drill.jdbc.Driver",
                                system.file("jars", "drill-jdbc-all-1.9.0.jar", package="sergeant", mustWork=TRUE))

  conn_type <- "drillbit"
  if (use_zk) conn_type <- "zk"

  if (length(nodes) > 1) nodes <- paste0(nodes, collapse=",")

  conn_str <- sprintf("jdbc:drill:%s=%s", conn_type, nodes)

  if (!is.null(cluster_id)) conn_str <- sprintf("%s%s", conn_str, sprintf("/drill/%s", cluster_id))

  if (!is.null(schema)) conn_str <- sprintf("%s;%s", schema)

  message(sprintf("Using [%s]...", conn_str))

  RJDBC::dbConnect(drill_jdbc_drv, conn_str)

}

#' A DBI driver that uses the Drill JDBC driver to access databases.
#' @export
setClass("DrillDriver", contains = "JDBCDriver")

#' Class representing a (DBI) database connection which uses JDBC to connect to Drill.
#' @export
setClass("DrillConnection", contains = "JDBCConnection")

#' Representation of a DBI result set returned from a JDBC Drill connection
#' @export
setClass("DrillResult", contains = "JDBCResult")

#' Drill dbConnect
#' @export
setMethod(
  f="dbConnect",
  signature="DrillDriver",
  definition=function(drv="JDBCDriver", nodes="localhost:2181", cluster_id=NULL, schema=NULL, use_zk=TRUE, ...) {
    conn_type <- "drillbit"
    if (use_zk) conn_type <- "zk"
    if (length(nodes) > 1) nodes <- paste0(nodes, collapse=",")
    conn_str <- sprintf("jdbc:drill:%s=%s", conn_type, nodes)
    if (!is.null(cluster_id)) conn_str <- sprintf("%s%s", conn_str, sprintf("/drill/%s", cluster_id))
    if (!is.null(schema)) conn_str <- sprintf("%s;%s", schema)
    message(sprintf("Using [%s]...", conn_str))
    RJDBC::dbConnect(drill_jdbc_drv, conn_str)
  },
  valueClass="DrillConnection"
)

#' Drill dbDataType
#' @export
setMethod(
  f="dbDataType",
  signature=signature(dbObj="DrillConnection", obj = "ANY"),
  definition=function(dbObj, obj, ...) {
    if (is.integer(obj)) "INTEGER"
    else if (inherits(obj, "Date")) "DATE"
    else if (identical(class(obj), "times")) "TIME"
    else if (inherits(obj, "POSIXct")) "TIMESTAMP"
    else if (is.numeric(obj)) "DOUBLE"
    else "VARCHAR(255)"
  },
  valueClass = "character"
)
