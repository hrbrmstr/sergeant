#' @export
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
src_desc.src_drill <- function(con) {

  info <- RJDBC::dbGetInfo(con$con)

  cat("drill", toString(info))

}

#' @export
tbl.src_drill <- function(src, from, ...) {
  tbl_sql("drill", src = src, from = from, ...)
}

#' @export
sql_escape_ident.JDBCConnection <- function(con, x) {
  sql_quote(x, ' ')
}

#' @export
sql_translate_env.JDBCConnection <- function(x) {
  dplyr::sql_variant(
    dplyr::sql_translator(
      .parent = dplyr::base_scalar,
      `!=` = dplyr::sql_infix("<>")
    ),
    dplyr::sql_translator(.parent = dplyr::base_agg,
                          n = function() dplyr::sql("COUNT(*)"),
                          cor = dplyr::sql_prefix("CORR"),
                          cov = dplyr::sql_prefix("COVAR_SAMP"),
                          sd =  dplyr::sql_prefix("STDDEV_SAMP"),
                          var = dplyr::sql_prefix("VAR_SAMP"),
                          n_distinct = function(x) {
                            dplyr::build_sql(dplyr::sql("count(distinct "), x, dplyr::sql(")"))
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
