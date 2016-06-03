#' Get the status of Drill
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_status <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/status", drill_server))
  cnt <- content(res, as="text")
  cnt <- htmltools::HTML(cnt)
  htmltools::browsable(cnt)
}

#' Get the current memory metrics
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_metrics <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/status/metrics", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}

#' Get information about threads
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_threads <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/status/threads", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}

#' Get the profiles of running and completed queries
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_profiles <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/profiles.json", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}

#' Get the list of storage plugin names and configurations
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_storage <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/storage.json", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}

#' List the name, default, and data type of the system and session options
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_options <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/options.json", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}

#' Get Drillbit information, such as ports numbers
#'
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_stats <- function(drill_server=Sys.getenv("DRILL_URL")) {
  res <- httr::GET(sprintf("%s/stats.json", drill_server))
  cnt <- content(res, as="text")
  jsonlite::fromJSON(cnt)
}
