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
#' @examples \dontrun{
#' drill_up(data_dir = "~/Data")
#' }
drill_up <- function(image = "drill/apache-drill:1.15.0",
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
