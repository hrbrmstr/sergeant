test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

if (at_home()) {

  expect_visible <- function(code) {
    ret <- withVisible(code)
    expect_true(ret$visible)
    ret$value
  }

  connect <- function (drv) {
    connect_call <- as.call(c(list(quote(dbConnect), drv)))
    connect_fun <- function() {}
    body(connect_fun) <- connect_call
    connect_fun()
  }

  dr <- Drill()

  expect_true(inherits(dr, "DBIDriver"))
  expect_true(inherits(dbGetInfo(dr), "list"))
  expect_true(all(names(dbGetInfo(dr)) %in% c("driver.version", "client.version")))

  expect_equal(names(formals(dbConnect)), c("drv", "..."))
  expect_equal(names(formals(dbDisconnect)), c("conn", "..."))

  con <- expect_visible(dbConnect(dr, test_host))
  expect_true(inherits(con, "DBIConnection"))
  expect_true(dbDisconnect(con))

  expect_true(inherits(dbGetInfo(con), "list"))

  expect_true(inherits(format(con), "character"))

  expect_equal(names(formals(dbDataType)), c("dbObj", "obj", "..."))

  expect_error(dbDataType(con, NULL))

  expect_identical(dbDataType(con, letters), dbDataType(con, factor(letters)))
  expect_identical(dbDataType(con, letters), dbDataType(con, ordered(letters)))

  expect_true(
    all(c("db.version", "dbname", "username", "host", "port") %in% names(dbGetInfo(con)))
  )

  expect_false("password" %in% names(dbGetInfo(con)))

  expect_equal(names(formals(dbListFields)), c("conn", "name", "..."))

  fields <- dbListFields(con, "cp.`employee.json`")
  expect_true(inherits(fields, "character"))

  expect_warning(dbListFields(con, "missing"))

}
