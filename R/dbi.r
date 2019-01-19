s_head <- purrr::safely(httr::HEAD)

#' Driver for Drill database.
#'
#' @keywords internal
#' @family Drill REST DBI API
#' @export
setClass(
  "DrillDriver",
  contains = "DBIDriver"
)

#' Unload driver
#'
#' @rdname DrilDriver-class
#' @param drv driver
#' @param ... Extra optional parameters
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbUnloadDriver",
  "DrillDriver",
  function(drv, ...) { TRUE }
)

setMethod("show", "DrillDriver", function(object) {
  cat("<DrillDriver>\n")
})

#' Drill
#'
#' @family Drill REST DBI API
#' @export
Drill <- function() {
  new("DrillDriver")
}

#' Drill connection class.
#'
#' @export
#' @keywords internal
setClass(
  "DrillConnection",
  contains = "DBIConnection",
  slots = list(
    host = "character",
    port = "integer",
    ssl = "logical",
    username = "character",
    password = "character",
    implicits = "character"
  )
)

#' Connect to Drill
#'
#' @param drv An object created by \code{Drill()}
#' @rdname Drill
#' @param host host
#' @param port port
#' @param ssl use ssl?
#' @param username,password credentials
#' @param ... Extra optional parameters
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbConnect",
  "DrillDriver", function(drv, host = "localhost", port = 8047L, ssl = FALSE,
                          username = NULL, password = NULL, ...) {


    if (!is.null(username)) {
      auth_drill(ssl, host, port, username, password)
    } else {
      username <- ""
      password <- ""
    }

    dc <- drill_connection(host, port, ssl, username, password)
    dops <- drill_options(dc, "drill.exec.storage.implicit")

    new(
      "DrillConnection",
      host = host, port = port, ssl = ssl,
      username = username, password = password,
      implicits = dops$value,
      ...
    )

  }
)

#' Disconnect from Drill
#'
#' @keywords internal
#' @export
setMethod(
  "dbDisconnect",
  "DrillConnection", function(conn, ...) {
    invisible(TRUE)
  },
  valueClass = "logical"
)

#' Drill results class.
#'
#' @keywords internal
#' @export
setClass(
  "DrillResult",
  contains = "DBIResult",
  slots = list(
    drill_server = "character",
    statement = "character"
  )
)

# Create the drill server connection string
cmake_server <- function(conn) {
  sprintf("%s://%s:%s", ifelse(conn@ssl[1], "https", "http"), conn@host, conn@port)
}

#' Send a query to Drill
#'
#' @rdname DrillConnection-class
#' @param conn connection
#' @param statement SQL statement
#' @param ... passed on to methods
#' @export
#' @family Drill REST DBI API
#' @aliases dbSendQuery,DrillConnection,character-method
setMethod(
  "dbSendQuery",
  "DrillConnection",
  function(conn, statement, ...) {

    drill_server <- cmake_server(conn)

    new("DrillResult", drill_server=drill_server, statement=statement, ...)

  }
)

#' Clear
#'
#' @rdname DrillResult-class
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbClearResult",
  "DrillResult",
  function(res, ...) { TRUE }
)

#' Retrieve records from Drill query
#'
#' @rdname DrillResult-class
#' @param .progress show data transfer progress?
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbFetch",
  "DrillResult",
  function(res, .progress=FALSE, ...) {

    if (.progress) {

      httr::POST(
        url = res@drill_server,
        path = "/query.json",
        encode = "json",
        progress(),
        body = list(
          queryType = "SQL",
          query = res@statement
        )
      ) -> resp

    } else {

      httr::POST(
        url = res@drill_server,
        path = "/query.json",
        encode = "json",
        body = list(
          queryType = "SQL",
          query = res@statement
        )
      ) -> resp

    }

    if (httr::status_code(resp) != 200) {

      resp <- httr::content(resp, as="parsed")
      resp <- resp$errorMessage
      resp <- unlist(strsplit(resp, "\n"))

      err <- resp[grepl("Error Id", resp)]

      resp <- resp[resp != ""]
      resp <- resp[!grepl("Error Id", resp)]

      err <- sub("^.*: ", "", err)
      err <- unlist(strsplit(err, "[[:space:]]+"))[1]

      oq <- unlist(strsplit(res@statement, "\n"))

      c(
        resp,
        "\nOriginal Query:\n",
        sprintf("%3d: %s", 1:length(oq), oq),
        sprintf(
          "\nQuery Profile Error Link:\n%s/profiles/%s",
          res@drill_server, err
        )
      ) -> resp

      resp <- paste0(resp, collapse="\n")

      warning(resp, call.=FALSE)

      return(dplyr::data_frame())

    } else {

      orig <- httr::content(resp, as="text", encoding="UTF-8")

      out <- jsonlite::fromJSON(orig, flatten=TRUE)

      xdf <- out$rows

      # ** only available in Drill 1.15.0+ **
      # properly arrange columns
      if (length(out$columns) != 0) {
        if (is.data.frame(xdf)) {
          if (nrow(xdf) > 0) xdf <- xdf[,out$columns,drop=FALSE]
        }
      }

      # ** only available in Drill 1.15.0+ **
      # be smarter about type conversion now that the REST API provides
      # the necessary metadata
      if (length(out$metadata)) {

        if ("BIGINT" %in% out$metadata) {
          if (!.pkgenv$bigint_warn_once) {
            if (getOption("sergeant.bigint.warnonce", TRUE)) {
              warning(
                "One or more columns are of type BIGINT. ",
                "The sergeant package currently uses jsonlite::fromJSON() ",
                "to process Drill REST API result sets. Since jsonlite does not ",
                "support 64-bit integers BIGINT columns are initially converted ",
                "to numeric since that's how jsonlite::fromJSON() works. This is ",
                "problematic for many reasons, including trying to use 'dplyr' idioms ",
                "with said converted BIGINT-to-numeric columns. It is recommended that ",
                "you 'CAST' BIGINT columns to 'VARCHAR' prior to working with them from ",
                "R/'dplyr'.\n\n",
                "If you really need BIGINT/integer64 support, consider using the ",
                "R ODBC interface to Apache Drill with the MapR ODBC drivers.\n\n",
                "This informational warning will only be shown once per R session and ",
                "you can disable them from appearing by setting the 'sergeant.bigint.warnonce' ",
                "option to 'FALSE' (i.e. options(sergeant.bigint.warnonce = FALSE)).",
                call.=FALSE
              )
            }
            .pkgenv$bigint_warn_once <- TRUE
          }
        }

        sapply(1:length(out$columns), function(col_idx) {

          cname <- out$columns[col_idx]
          ctype <- out$metadata[col_idx]

          case_when(
            ctype == "INT" ~ "i",
            ctype == "VARCHAR" ~ "c",
            ctype == "TIMESTAMP" ~ "?",
            ctype == "BIGINT" ~ "?",
            ctype == "BINARY" ~ "c",
            ctype == "BOOLEAN" ~ "l",
            ctype == "DATE" ~ "?",
            ctype == "FLOAT" ~ "d",
            ctype == "DOUBLE" ~ "d",
            ctype == "TIME" ~ "c",
            ctype == "INTERVAL" ~ "?",
            TRUE ~ "?"
          )

        }) -> col_types

        suppressMessages(
          dplyr::tbl_df(
            readr::type_convert(
              df = xdf,
              col_types = paste0(col_types, collapse=""),
              na = character()
            )
          )
        ) -> xdf

      } else {

        suppressMessages(
          dplyr::tbl_df(
            readr::type_convert(df = xdf, na = character())
          )
        ) -> xdf

      }

      xdf

    }

  }

)

#' Drill dbDataType
#'
#' @param dbObj A \code{\linkS4class{DrillDriver}} object
#' @param obj Any R object
#' @param ... Extra optional parameters
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbDataType",
  "DrillConnection",
  function(dbObj, obj, ...) {

    stopifnot(!is.null(obj))

    if (is.integer(obj)) "INTEGER"
    else if (inherits(obj, "Date")) "DATE"
    else if (identical(class(obj), "times")) "TIME"
    else if (inherits(obj, "POSIXct")) "TIMESTAMP"
    else if (inherits(obj, "integer64")) "BIGINT"
    else if (is.numeric(obj)) "DOUBLE"
    else "VARCHAR"
  },
  valueClass = "character"
)

#' Completed
#'
#' @rdname DrillResult-class
#' @family Drill REST DBI API
#' @export
setMethod(
  "dbHasCompleted",
  "DrillResult",
  function(res, ...) { TRUE }
)

#' @rdname DrillConnection-class
#' @family Drill REST DBI API
#' @export
setMethod(
  'dbIsValid',
  'DrillConnection',
  function(dbObj, ...) {
    drill_server <- cmake_server(dbObj)
    !is.null(s_head(drill_server, httr::timeout(2))$result)
  }
)

#' @rdname DrillConnection-class
#' @family Drill REST DBI API
#' @export
setMethod(
  'dbListFields',
  c('DrillConnection', 'character'),
  function(conn, name, ...) {
    #quoted.name <- dbQuoteIdentifier(conn, name)
    quoted.name <- name
    names(dbGetQuery(conn, paste('SELECT * FROM', quoted.name, 'LIMIT 1')))
  }
)

#' @rdname DrillResult-class
#' @family Drill REST DBI API
#' @export
setMethod(
  'dbListFields',
  signature(conn='DrillResult', name='missing'),
  function(conn, name) {
    httr::POST(
      sprintf("%s/query.json", conn@drill_server),
      encode = "json",
      body = list(queryType="SQL", query=conn@statement
      )
    ) -> res

    # fatal query error on the Drill side so return no fields
    if (httr::status_code(res) != 200)  return(character())

    out <- httr::content(res, as = "text", encoding = "UTF-8")

    out <- jsonlite::fromJSON(out, flatten = TRUE)

    if (length(out$columns) != 0) {
      return(out$columns)
    } else {
      return(colnames(out$rows))
    }

  }
)

#' Statement
#'
#' @rdname DrillResult-class
#' @family Drill REST DBI API
#' @export
setMethod(
  'dbGetStatement',
  'DrillResult',
  function(res, ...) { return(res@statement) }
)


#' Metadata about database objects
#' @rdname dbGetInfo
#' @param dbObj A \code{\linkS4class{DrillDriver}} or \code{\linkS4class{DrillConnection}} object
#' @export
setMethod(
  "dbGetInfo",
  "DrillDriver",
  function(dbObj) {
    return(
      list(
        driver.version = packageVersion("sergeant"),
        client.version = packageVersion("sergeant")
      )
    )
  }
)

#' @rdname dbGetInfo
#' @export
setMethod(
  "dbGetInfo",
  "DrillConnection",
  function(dbObj) {
    return(list(
      host = dbObj@host,
      port = dbObj@port,
      username = dbObj@username,
      ssl = dbObj@ssl,
      implicits = dbObj@implicits,
      db.version = dbGetQuery(dbObj, "SELECT version FROM sys.version")[["version"]],
      dbname = ""
    ))
  }
)

#' A concise character representation (label) for a `DrillConnection`
#'
#' @param x a `DrillConnection`
#' @param ... ignored
#' @export
format.DrillConnection <- function(x, ...) {
  if (dbIsValid(x)) {
    sprintf("<DrillConnection %s:%s>", x@host, x@port)
  }
}







