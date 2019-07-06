test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

context("dbi")
test_that("core DBI ops work", {

  testthat::skip_on_cran()

  con <- dbConnect(Drill(), test_host)
  expect_is(con, "DrillConnection")

  expect_true(dbIsValid(con))

  fields <- dbListFields(con, "cp.`employee.json`")
  expect_true(
    all(
      fields %in%
        c(
          "employee_id", "full_name", "first_name", "last_name", "position_id",
          "position_title", "store_id", "department_id", "birth_date",
          "hire_date", "salary", "supervisor_id", "education_level", "marital_status",
          "gender", "management_role"
        )
    )
  )

  res <- dbSendQuery(con, "SELECT full_name from cp.`employee.json` LIMIT 1")
  expect_is(res, "DrillResult")

  xdf <- dbFetch(res)
  expect_identical(dim(xdf), c(1L, 1L))

  expect_true(dbClearResult(res))

  expect_true(dbHasCompleted(res))

  expect_equal(dbDataType(con, character(0)), "VARCHAR")
  expect_equal(dbDataType(con, integer(0)), "INTEGER")
  expect_equal(dbDataType(con, Sys.Date()), "DATE")
  expect_equal(dbDataType(con, Sys.time()), "TIMESTAMP")
  expect_equal(dbDataType(con, bit64::integer64(0)), "BIGINT")
  expect_equal(dbDataType(con, numeric(0)), "DOUBLE")

  expect_is(dbGetInfo(Drill()), "list")

  inf <- dbGetInfo(con)
  expect_equal(inf$port, 8047)

})
