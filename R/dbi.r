s_head <- purrr::safely(httr::HEAD)

#' Driver for Drill database.
#'
#' @keywords internal
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
    password = "character"
  )
)

#' Connect to Drill
#'
#' @param drv An object created by \code{Drill()}
#' @rdname Drill
#' @param host host
#' @param port port
#' @param ssl use ssl?
#' @param ... Extra optional parameters
#' @export
setMethod(
  "dbConnect",
  "DrillDriver", function(drv, host = "localhost", port = 8047L, ssl = FALSE, ...) {
    new("DrillConnection", host = host, port = port, ssl = ssl, ...)
  }
)

#' Disconnect from Drill
#'
#' @keywords internal
#' @export
setMethod(
  "dbDisconnect",
  "DrillConnection", function(conn, ...) {
    TRUE
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
#' @export
setMethod(
  "dbFetch",
  "DrillResult",
  function(res, .progress=FALSE, ...) {

    if (.progress) {
      res <- httr::POST(sprintf("%s/query.json", res@drill_server),
                        encode="json", progress(),
                        body=list(queryType="SQL", query=res@statement))
    } else {
      res <- httr::POST(sprintf("%s/query.json", res@drill_server),
                        encode="json",
                        body=list(queryType="SQL", query=res@statement))
    }

    if (httr::status_code(res) != 200) {
      warning(content(res, as="parsed"))
      dplyr::data_frame()
    } else {
      out <- jsonlite::fromJSON(httr::content(res, as="text", encoding="UTF-8"), flatten=TRUE)
      out <- suppressMessages(dplyr::tbl_df(readr::type_convert(out$rows)))
      out
    }

  }
)

#' Drill dbDataType
#'
#' @param dbObj A \code{\linkS4class{DrillDriver}} object
#' @param obj Any R object
#' @param ... Extra optional parameters
#' @export
setMethod(
  "dbDataType",
  "DrillConnection",
  function(dbObj, obj, ...) {
    if (is.integer(obj)) "INTEGER"
    else if (inherits(obj, "Date")) "DATE"
    else if (identical(class(obj), "times")) "TIME"
    else if (inherits(obj, "POSIXct")) "TIMESTAMP"
    else if (is.numeric(obj)) "DOUBLE"
    else "VARCHAR(255)"
  },
  valueClass = "character"
)

#' Completed
#'
#' @rdname DrillResult-class
#' @export
setMethod(
  "dbHasCompleted",
  "DrillResult",
  function(res, ...) { TRUE }
)

#' @rdname DrillConnection-class
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
#' @export
setMethod(
  'dbListFields',
  c('DrillConnection', 'character'),
  function(conn, name, ...) {
    quoted.name <- dbQuoteIdentifier(conn, name)
    names(dbGetQuery(conn, paste('SELECT * FROM', quoted.name, 'LIMIT 1')))
  }
)

#' @rdname DrillResult-class
#' @export
setMethod(
  'dbListFields',
  signature(conn='DrillResult', name='missing'),
  function(conn, name) {
    res <- httr::POST(sprintf("%s/query.json", conn@drill_server),
                      encode="json",
                      body=list(queryType="SQL", query=conn@statement))
    out <- jsonlite::fromJSON(httr::content(res, as="text", encoding="UTF-8"), flatten=TRUE)
    out <- suppressMessages(dplyr::tbl_df(readr::type_convert(out$rows)))
    colnames(out)
  }
)

#' Statement
#'
#' @rdname DrillResult-class
#' @export
setMethod(
  'dbGetStatement',
  'DrillResult',
  function(res, ...) { return(res@statement) }
)
