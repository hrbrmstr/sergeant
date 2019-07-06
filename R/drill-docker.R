#' Start a Dockerized Drill Instance
#'
#' This is a "get you up and running quickly" helper function as it only
#' runs a standalone mode Drill instance and is optionally removed after the container
#' is stopped. You should customize your own Drill containers based on the
#' one at [Drill's Docker Hub](https://hub.docker.com/u/drill).
#'
#' The path specified in `data_dir` will be mapped inside the container as
#' `/data` and a new `dfs` storage workspace will created (`dfs.d`) that
#' maps to `/data` and is writable.
#'
#' Use [drill_down()] to stop a running Drill container by container id
#' (full or partial).
#'
#' @md
#' @note this requires a working Docker setup on your system and it is *highly suggested*
#'       you `docker pull` it yourself before running this function.
#' @param image Drill image to use. Must be a valid image from
#'        [Drill's Docker Hub](https://hub.docker.com/u/drill). Defaults
#'        to most recent Drill docker image.
#' @param container_name naem for the container. Defaults to "`drill`".
#' @param data_dir valid path to a place where your data is stored; defaults to the
#'        value of [getwd()]. This will be [path.expand()]ed and mapped to `/data`
#'        in the container. This will be mapped to the `dfs` storage plugin as the
#'        `dfs.d` workspace.
#' @param remove remove the Drill container instance after it's stopped?
#'        Defaults to `TRUE` since you shouldn't be relying on this in production.
#' @return a `stevedore` docker object (invisibly) which *you* are responsible
#'         for killing with the `$stop()`  function or from the Docker command
#'         line (in interactive mode the docker container ID is printed as well).
#' @export
#' @family Drill Docker functions
#' @examples \dontrun{
#' drill_up(data_dir = "~/Data")
#' }
drill_up <- function(image = "drill/apache-drill:1.16.0",
                     container_name = "drill",
                     data_dir = getwd(), remove = TRUE) {

  data_dir <- path.expand(data_dir)

  stopifnot(dir.exists(data_dir))

  if (!requireNamespace("stevedore", quietly = TRUE)) {
    stop("The stevedore package must be installed to use this function")
  }

  docker <- stevedore::docker_client()

  docker$container$run(
    image = image,
    name = container_name,
    ports = "8047:8047",
    detach = TRUE,
    rm = remove,
    tty = TRUE,
    cmd = "/bin/bash",
    volumes = sprintf("%s:/data", data_dir)
  ) -> drill

  if (interactive()) {
    message(
      "Drill container started. Waiting for the service to become active (this may take up to 30s)."
    )
  }

  drill_con <- drill_connection("localhost")

  for (i in 1:30) {
    if (drill_active(drill_con)) break
    Sys.sleep(1L)
  }

  if (!drill_active(drill_con)) {
    stop("Could not connect to Drill container.")
  }

  r <- drill_storage(drill_con, "dfs", "raw")

  # ugly but the jsonlite targeted "unboxing" code would be uglier
  gsub(
    '"workspaces" : \\{',
    '"workspaces" : \\{\n  "d" : { "location" : "/data", "writable" : true, "defaultInputFormat" : null, "allowAccessOutsideWorkspace" : false },',
    r
  ) -> r

  drill_mod_storage(drill_con, "dfs", r)

  if (interactive()) message("Drill container ID: ", drill$id())

  invisible(drill)

}

#' @rdname drill_up
#' @param id the id of the Drill container
#' @export
drill_down <- function(id) {

  docker <- stevedore::docker_client()
  docker$container$get(id)$stop()

}

#' Show all dead and running Drill Docker containers
#'
#' This function will show _all_ Docker containers that are based on an
#' image matching a runtime command of "`bin/drill-embedded`".
#'
#' @family Drill Docker functions
#' @export
showall_drill <- function() {

  docker <- stevedore::docker_client()

  x <- docker$container$list(all=TRUE)

  x <- x[grepl("bin/drill-embedded", x$command, fixed = TRUE),]
  if (nrow(x) > 0) {
    message(sprintf(
      "Drill containers found: [%s]\nReturning data frame of container metadata (invisibly).",
      paste0(substr(x$id, 1, 16), collapse=", ")
    ))
    return(invisible(x))
  } else {
    message("No Drill containers running matching target command found.")
  }

}

#' Prune all dead and running Drill Docker containers
#'
#' _This is a destructive function._ It will stop **any** Docker container that
#' is based on an image matching a runtime command of "`bin/drill-embedded`".
#' It's best used when you had a session forcefully interuppted and had been
#' using the R helper functions to start/stop the Drill Docker container.
#' You may want to consider using the Docker command-line interface to perform
#' this work manually.
#'
#' @family Drill Docker functions
#' @export
killall_drill <- function() {

  docker <- stevedore::docker_client()
  x <- docker$container$list(all=TRUE)
  for (i in 1:nrow(x)) {
    if (grepl("bin/drill-embedded", x$command[i], fixed = TRUE)) {
      message(sprintf("Pruning: %s...", x$id[i]))
      if (x$state[i] == "running") {
        cntnr <- docker$container$get(x$id[i])
        suppressWarnings(try(cntnr$stop(), silent = TRUE))
        suppressWarnings(try(cntnr$remove()(), silent = TRUE))
      }
    }
  }
}
