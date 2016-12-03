#' Get the status of Drill
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_status()
#' }
drill_status <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/status", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  cnt <- htmltools::HTML(cnt)
  htmltools::browsable(cnt)
}

#' Get the current memory metrics
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_metrics()
#' }
drill_metrics <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/status/metrics", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt, flatten=TRUE)
}

#' Get information about threads
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_threads()
#' }
drill_threads <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/status/threads", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  cnt <- htmltools::HTML(sprintf("<pre>%s</pre>", cnt))
  htmltools::browsable(cnt)
}

#' Get the profiles of running and completed queries
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_profiles()
#' }
drill_profiles <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/profiles.json", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Get the profile of the query that has the given queryid.
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_profile <- function(query_id, drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/profiles/%s.json", drill_server, query_id))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Cancel the query that has the given queryid.
#'
#' @param query_id the UUID of the query in standard UUID format that Drill assigns to each query.
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_cancel <- function(query_id, drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/profiles/cancel%s", drill_server, query_id))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Get the list of storage plugin names and configurations
#'
#' @param plugin the assigned name in the storage plugin definition.
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_storage()
#' }
drill_storage <- function(plugin=NULL, drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {

  if (is.null(plugin)) {
    res <- httr::GET(sprintf("%s/storage.json", drill_server))
  } else {
    res <- httr::GET(sprintf("%s/storage/%s.json", drill_server, plugin))
  }

  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt, flatten=TRUE) %>%
    dplyr::tbl_df()

}

#' List the name, default, and data type of the system and session options
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_options()
#' }
drill_options <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/options.json", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt) %>%
    dplyr::tbl_df()
}

#' Get Drillbit information, such as ports numbers
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_stats()
#' }
drill_stats <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  res <- httr::GET(sprintf("%s/stats.json", drill_server))
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Identify the version of Drill running
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
#' @examples \dontrun{
#' drill_version()
#' }
drill_version <- function(drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {
  drill_query("SELECT version FROM sys.version", uplift=FALSE, drill_server=drill_server)$rows$version[1]
}
