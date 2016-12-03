#' Tools to Transform and Query Data with the the 'Apache Drill' 'REST API'
#'
#' Drill is an innovative distributed SQL engine designed to enable data exploration
#' and analytics on non-relational datastores. Users can query the data using standard
#' SQL and BI tools without having to create and manage schemas. Some of the key features
#' are:
#'
#' \itemize{
#'   \item{Schema-free JSON document model similar to MongoDB and Elasticsearch}
#'   \item{Industry-standard APIs: ANSI SQL, ODBC/JDBC, RESTful APIs}
#'   \item{Extremely user and developer friendly}
#'   \item{Pluggable architecture enables connectivity to multiple datastores}
#' }
#'
#' @name sergeant
#' @references \href{https://drill.apache.org/docs/}{Drill documentation}
#' @docType package
#' @author Bob Rudis (bob@@rud.is)
#' @import httr jsonlite htmltools
#' @importFrom purrr map map2 map2_df %>%
#' @importFrom dplyr mutate select left_join bind_cols bind_rows data_frame tbl
#' @import utils
NULL
