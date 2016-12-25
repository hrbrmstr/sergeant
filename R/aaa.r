utils::globalVariables(c("error", "everything", "isDirectory", "name",
                         "params", "permissions", "query"))

make_server <- function(drill_con) {

  sprintf("%s://%s:%s",
          ifelse(drill_con$ssl[1], "https", "http"),
          drill_con$host, drill_con$port)

}
