#' Returns a list of available schemas.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @export
drill_show_schemas <- function(drill_con) {
  drill_query(drill_con, "SHOW SCHEMAS", .progress=FALSE)
}

#' Change to a particular schema.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param schema_name A unique name for a Drill schema. A schema in Drill is a configured
#'                   storage plugin, such as hive, or a storage plugin and workspace.
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @export
drill_use <- function(drill_con, schema_name) {
  query <- sprintf("USE `%s`", schema_name)
  out <- drill_query(drill_con, query, .progress=FALSE)
  if (!("errorMessage" %in% names(out))) message(out)
  invisible(out)
}

#' Show files in a file system schema.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param schema_spec properly quoted "filesystem.directory_name" reference path
#' @export
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @examples
#' try({
#' drill_connection() %>% drill_show_files("dfs.tmp")
#' }, silent=TRUE)
drill_show_files <- function(drill_con, schema_spec) {
  query <- sprintf("SHOW FILES IN %s", schema_spec)
  drill_query(drill_con, query, uplift=TRUE, .progress=FALSE) %>%
    dplyr::select(name, isDirectory, permissions, dplyr::everything())
}
