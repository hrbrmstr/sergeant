#' Returns a list of available schemas.
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_show_schemas <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  drill_query("SHOW SCHEMAS", drill_server=drill_server)$rows$SCHEMA_NAME
}

#' Change to a particular schema.
#'
#' @param schema_name A unique name for a Drill schema. A schema in Drill is a configured
#'                   storage plugin, such as hive, or a storage plugin and workspace.
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_use <- function(schema_name, drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  query <- sprintf("USE `%s`", schema_name)
  out <- drill_query(query, drill_server=drill_server)
  if (!("errorMessage" %in% names(out))) message(out$rows$summary[1])
  invisible(out)
}

#' Identify the version of Drill running
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_version <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  drill_query("SELECT version FROM sys.version", drill_server=drill_server)$rows$version[1]
}

#' Show files in a file system schema.
#'
#' @param schema_spec properly quoted "filesystem.directory_name" reference path
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_show_files("dfs.tmp")
#' drill_show_files("dfs.tmp")
#' }
drill_show_files <- function(schema_spec, drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  query <- sprintf("SHOW FILES IN %s", schema_spec)
  drill_query(query, uplift=TRUE, drill_server=drill_server) %>%
    dplyr::select(name, isDirectory, permissions, everything())
}
