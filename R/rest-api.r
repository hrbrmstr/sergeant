s_head <- purrr::safely(function(...){httr::RETRY(verb = "HEAD", ...)})

#' Setup a Drill connection
#'
#' @md
#' @param host Drill host (will pick up the value from `DRILL_HOST` env var)
#' @param port Drill port (will pick up the value from `DRILL_PORT` env var)
#' @param ssl use ssl?
#' @param user,password (will pick up the values from `DRILL_USER`/`DRILL_PASSWORD` env vars)
#' @note If `user`/`password` are set this function will make a `POST` to the REST
#'       interface immediately to prime the cookie-jar with the session id.
#' @export
#' @family Drill direct REST API Interface
#' @examples
#' dc <- drill_connection()
drill_connection <- function(host=Sys.getenv("DRILL_HOST", "localhost"),
                             port=Sys.getenv("DRILL_PORT", 8047),
                             ssl=FALSE,
                             user=Sys.getenv("DRILL_USER", ""),
                             password=Sys.getenv("DRILL_PASSWORD", "")) {
  list(
    host = host,
    port = port,
    ssl = ssl,
    user = ifelse(user[1] == "", NA, user[1]),
    password = ifelse(password[1] == "", NA, password[1])
  ) -> out

  class(out) <- c("drill_conn", class(out))

  if (user != "") auth_drill(ssl, host, port, user, password)

  out

}

#' Test whether Drill HTTP Drill direct REST API Interface server is up
#'
#' This is a very simple test (performs \code{HEAD /} request on the Drill server/cluster)
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_active()
#' }
drill_active <- function(drill_con) {
  drill_server <- make_server(drill_con)
  !is.null(s_head(drill_server, httr::timeout(2))$result)
}

#' Get the status of Drill
#'
#' @note The output of this is in a "viewer" window
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_status()
#' }
drill_status <- function(drill_con) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/status", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  cnt <- htmltools::HTML(cnt)
  htmltools::browsable(cnt)
}

#' Get the current memory metrics
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_metrics()
#' }
drill_metrics <- function(drill_con) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/status/metrics", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt, flatten=TRUE)
}

#' Get information about threads
#'
#' @note The output of this is in a "viewer" window
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_threads()
#' }
drill_threads <- function(drill_con) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/status/threads", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  cnt <- htmltools::HTML(sprintf("<pre>%s</pre>", cnt))
  htmltools::browsable(cnt)
}

#' Get the profiles of running and completed queries
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_profiles()
#' }
drill_profiles <- function(drill_con) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/profiles.json", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Get the profile of the query that has the given queryid
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param query_id UUID of the query in standard UUID format that Drill assigns to each query
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @export
drill_profile <- function(drill_con, query_id) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/profiles/%s.json", drill_server, query_id), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Cancel the query that has the given queryid
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param query_id the UUID of the query in standard UUID format that Drill assigns to each query.
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @family Drill direct REST API Interface
#' @export
drill_cancel <- function(drill_con, query_id) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/profiles/cancel/%s", drill_server, query_id), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  message(httr::content(res, as="text", encoding="UTF-8"))
  invisible(TRUE)
}

#' Retrieve, modify or update storage plugin names and configurations
#'
#' Retrieve, modify or remove storage plugins from a Drill instance. If you intend
#' to modify an existing configuration it is suggested that you use the "`list`" or
#' "`raw`" values to the `as` parameter to make it easier to modify them.
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param plugin the assigned name in the storage plugin definition.
#' @param as one of "`tbl`" or "`list`" or "`raw`". The latter two are useful if you want
#'        modify an existing storage plugin (e.g. add a workspace) via
#'        [drill_mod_storage()].
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @export
#' @family Drill direct REST API Interface
#' @examples \dontrun{
#' drill_connection() %>% drill_storage()
#'
#' drill_connection() %>%
#'   drill_mod_storage(
#'     name = "drilldat",
#'     config = '
#' {
#'   "config" : {
#'     "connection" : "file:///",
#'     "enabled" : true,
#'     "formats" : null,
#'     "type" : "file",
#'     "workspaces" : {
#'       "root" : {
#'         "location" : "/Users/hrbrmstr/drilldat",
#'         "writable" : true,
#'         "defaultInputFormat": null
#'       }
#'     }
#'   },
#'   "name" : "drilldat"
#' }
#' ')
#' }
drill_storage <- function(drill_con, plugin=NULL, as=c("tbl", "list", "raw")) {

  as <- match.arg(as[1], c("tbl", "list", "raw"))

  drill_server <- make_server(drill_con)

  if (is.null(plugin)) {
    res <- httr::RETRY("GET", sprintf("%s/storage.json", drill_server), terminate_on = c(403, 404))
  } else {
    res <- httr::RETRY("GET", sprintf("%s/storage/%s.json", drill_server, plugin), terminate_on = c(403, 404))
  }

  httr::stop_for_status(res)

  out <- httr::content(res, as="text", encoding="UTF-8")

  switch(
    as,
    tbl = jsonlite::fromJSON(out, flatten=TRUE) %>% tibble::as_tibble(),
    list = jsonlite::fromJSON(
      out, simplifyVector = TRUE, simplifyDataFrame = FALSE, flatten = FALSE
    ),
    raw = out
  )

}

#' @md
#' @rdname drill_storage
#' @param name name of the storage plugin configuration to create/update/remove
#' @param config a raw 1-element character vector containing valid JSON of a
#'        complete storage spec
#' @export
drill_mod_storage <- function(drill_con, name, config) {

  drill_server <- make_server(drill_con)

  httr::RETRY(
    verb = "POST",
    url = sprintf("%s/storage/%s.json", drill_server, name),
    httr::content_type_json(),
    body = config,
    encode = "raw",
    terminate_on = c(403, 404)
  ) -> res

  httr::stop_for_status(res)

  out <- httr::content(res, as="text", encoding="UTF-8")

  invisible(jsonlite::fromJSON(out, flatten=TRUE)$result == "success")

}

#' @md
#' @rdname drill_storage
#' @export
drill_rm_storage <- function(drill_con, name) {

  drill_server <- make_server(drill_con)

  httr::RETRY(
    verb = "DELETE",
    url = sprintf("%s/storage/%s.json", drill_server, name),
    httr::content_type_json(),
    terminate_on = c(403, 404)
  ) -> res

  httr::stop_for_status(res)

  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt, flatten=TRUE)

}

#' List the name, default, and data type of the system and session options
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param pattern pattern to filter results by
#' @export
#' @family Drill direct REST API Interface
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_options()
#' }
drill_options <- function(drill_con, pattern=NULL) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/options.json", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt) %>%
    tibble::as_tibble() -> out
  if (!is.null(pattern)) out <- dplyr::filter(out, grepl(pattern, name))
  out
}

#' Get Drillbit information, such as ports numbers
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_stats()
#' }
drill_stats <- function(drill_con) {
  drill_server <- make_server(drill_con)
  res <- httr::RETRY("GET", sprintf("%s/cluster.json", drill_server), terminate_on = c(403, 404))
  httr::stop_for_status(res)
  cnt <- httr::content(res, as="text", encoding="UTF-8")
  jsonlite::fromJSON(cnt)
}

#' Identify the version of Drill running
#'
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @export
#' @family Drill direct REST API Interface
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_version()
#' }
drill_version <- function(drill_con) {
  if (inherits(drill_con, "src_drill")) {
    dplyr::collect(
      dplyr::tbl(drill_con, dplyr::sql("(SELECT version FROM sys.version)"))
    )$version[1]
  } else {
    drill_query(drill_con, "SELECT version FROM sys.version", uplift=FALSE, .progress=FALSE)$rows$version[1]
  }
}

#' Show all the available Drill built-in functions & UDFs
#'
#' @md
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param browse if `TRUE` display an HTML interacrtive HTML widget with the functions
#'        as well as reutrn the data frame with the functions. Default if `FALSE`.
#' @note You _must_ be using Drill 1.15.0+ to use this function
#' @export
#' @return data frame
#' @family Drill direct REST API Interface
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_functions()
#' }
drill_functions <- function(drill_con, browse=FALSE) {

  stopifnot(utils::compareVersion(drill_version(drill_con), "1.15.0") >= 0)

  if (inherits(drill_con, "src_drill")) {
    dplyr::collect(
      dplyr::tbl(drill_con, dplyr::sql("(SELECT * FROM sys.functions)"))
    ) -> out
  } else {
    drill_query(
      drill_con = drill_con,
      query = "SELECT * FROM sys.functions",
      uplift = TRUE,
      .progress = FALSE
    ) -> out
  }

  if (browse) {
    if (!requireNamespace("DT", quietly = TRUE)) {
      warning("The DT must be installed to use this function")
    } else {
      print(DT::datatable(out, options = list(pageLength = 100)))
    }
  }

  out

}

#' Show all the available Drill options
#'
#' @md
#' @param drill_con drill server connection object setup by \code{drill_connection()}
#' @param browse if `TRUE` display an HTML interacrtive HTML widget with the options
#'        as well as reutrn the data frame with the options Default if `FALSE`.
#' @note You _must_ be using Drill 1.15.0+ to use this function
#' @export
#' @return data frame
#' @family Drill direct REST API Interface
#' @references \href{https://drill.apache.org/docs/querying-system-tables/#querying-the-options-table}{Drill documentation}
#' @examples \dontrun{
#' drill_connection() %>% drill_opts()
#' }
drill_opts <- function(drill_con, browse=FALSE) {

  stopifnot(utils::compareVersion(drill_version(drill_con), "1.15.0") >= 0)

  if (inherits(drill_con, "src_drill")) {
    dplyr::collect(
      dplyr::tbl(drill_con, dplyr::sql("(SELECT * FROM sys.options)"))
    ) -> out
  } else {
    drill_query(
      drill_con = drill_con,
      query = "SELECT * FROM sys.options",
      uplift = TRUE,
      .progress = FALSE
    ) -> out
  }

  if (browse) {
    if (!requireNamespace("DT", quietly = TRUE)) {
      warning("The DT must be installed to use this function")
    } else {
      print(DT::datatable(out, options = list(pageLength = 100)))
    }
  }

  out

}

#' Print function for `drill_conn` objects
#'
#' @md
#' @param x a `drill_conn` object made with [drill_connection()]
#' @param ... unused
#' @export
print.drill_conn <- function(x, ...) {
  cat(sprintf("<Drill REST API Direct Connection to %s:%s>\n", x$host, x$port))
}
