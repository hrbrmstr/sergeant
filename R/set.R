#' Set Drill SYSTEM or SESSION options
#'
#' Helper function to make it more R-like to set Drill SESSION or SYSTEM optons. It
#' handles the conversion of R types (like \code{TRUE}) to SQL types and automatically
#' quotes parameter values (when necessary).
#'
#' If any query errors result, error messages will be presented to the console.
#'
#' @param ... named parameters to be sent to \code{ALTER [SYSTEM|SESSION]}
#' @param type set the \code{session} or \code{system} parameter
#' @param drill_server base URL of the \code{drill} server
#' @return a \code{tbl} (invisibly) with the \code{ALTER} queries sent and results, including errors.
#' @export
#' @examples \dontrun{
#' drill_set(exec.errors.verbose=TRUE, store.format="parquet", web.logs.max_lines=20000)
#' }
drill_set <- function(..., type=c("session", "system"),
                      drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {

  type <- toupper(match.arg(tolower(type), choices=c("session", "system")))

  as.list(substitute(list(...)))[-1L] %>%
    purrr::map(jsonlite::toJSON, auto_unbox=TRUE) %>%
    purrr::map(~gsub('^"|"$', "'", .)) -> params

  purrr::map2(names(params), params, ~sprintf("ALTER %s SET `%s` = %s", type, .x, .y)) %>%
    purrr::map_df(function(x) {
    y <- drill_query(x, drill_server=drill_server)
    if (length(y) == 2) {
      dplyr::data_frame(query=x, param=y[[2]]$summary, value=y[[2]]$ok, error=NA)
    } else {
      dplyr::data_frame(query=x, param=NA, value=NA, error=y[[1]])
    }
  }) -> res

  if (sum(!is.na(res$error))>0) {

    dplyr::filter(res, !is.na(error)) %>%
      dplyr::mutate(msg=sprintf("QUERY => %s\n%s\n", query, error)) -> msgs

    msgs <- paste0(msgs$msg, collapse="\n")

    message(sprintf("%d errors:\n\n%s", sum(!is.na(res$error)), msgs))

  }

  invisible(res)

}

#' Changes (optionally, all) system settings back to system defaults
#'
#' @param ... bare name of system options to reset
#' @param all if \code{TRUE}, all parameters are reset (\code{...} is ignored)
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_system_reset <- function(..., all=FALSE,
                               drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {

  if (all) return(invisible(drill_query("ALTER SYSTEM RESET ALL", drill_server=drill_server)))

  as.list(substitute(list(...)))[-1L] %>%
  purrr::map(params, ~sprintf("ALTER SYSTEM RESET `%s`", .)) %>%
    purrr::map_df(function(x) {
    y <- drill_query(x, drill_server=drill_server)
    if (length(y) == 2) {
      dplyr::data_frame(query=x, param=y[[2]]$summary, value=y[[2]]$ok, error=NA)
    } else {
      dplyr::data_frame(query=x, param=NA, value=NA, error=y[[1]])
    }
  }) -> res

  if (sum(!is.na(res$error))>0) {

    dplyr::filter(res, !is.na(error)) %>%
      dplyr::mutate(msg=sprintf("QUERY => %s\n%s\n", query, error)) -> msgs

    msgs <- paste0(msgs$msg, collapse="\n")

    message(sprintf("%d errors:\n\n%s", sum(!is.na(res$error)), msgs))

  }

  invisible(res)

}


#' Changes (optionally, all) session settings back to system defaults
#'
#' @param ... bare name of system options to reset
#' @param drill_server base URL of the \code{drill} server
#' @export
drill_setting_reset <- function(...,
                               drill_server=Sys.getenv("DRILL_URL", unset="http://localhost:8047")) {


  as.list(substitute(list(...)))[-1L] %>%
  purrr::map(params, ~sprintf("ALTER SESSION RESET `%s`", .)) %>%
    purrr::map_df(function(x) {
    y <- drill_query(x, drill_server=drill_server)
    if (length(y) == 2) {
      dplyr::data_frame(query=x, param=y[[2]]$summary, value=y[[2]]$ok, error=NA)
    } else {
      dplyr::data_frame(query=x, param=NA, value=NA, error=y[[1]])
    }
  }) -> res

  if (sum(!is.na(res$error))>0) {

    dplyr::filter(res, !is.na(error)) %>%
      dplyr::mutate(msg=sprintf("QUERY => %s\n%s\n", query, error)) -> msgs

    msgs <- paste0(msgs$msg, collapse="\n")

    message(sprintf("%d errors:\n\n%s", sum(!is.na(res$error)), msgs))

  }

  invisible(res)

}

