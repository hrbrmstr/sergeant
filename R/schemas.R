#' Returns a list of available schemas.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
drill_show_schemas <- function(drill_con) {
  drill_query(drill_con, "SHOW SCHEMAS")$rows$SCHEMA_NAME
}

#' Change to a particular schema.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param schema_name A unique name for a Drill schema. A schema in Drill is a configured
#'                   storage plugin, such as hive, or a storage plugin and workspace.
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
drill_use <- function(drill_con, schema_name) {
  query <- sprintf("USE `%s`", schema_name)
  out <- drill_query(drill_con, query)
  if (!("errorMessage" %in% names(out))) message(out$rows$summary[1])
  invisible(out)
}

#' Show files in a file system schema.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param schema_spec properly quoted "filesystem.directory_name" reference path
#' @export
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_show_files("dfs.tmp")
#' }
drill_show_files <- function(drill_con, schema_spec) {
  query <- sprintf("SHOW FILES IN %s", schema_spec)
  drill_query(drill_con, query, uplift=TRUE) %>%
    dplyr::select(name, isDirectory, permissions, everything())
}
