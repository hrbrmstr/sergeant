library(dbplyr)
library(dplyr)

test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

context("basic d[b]plyr API")
test_that("Core d[b]plyr ops work", {

  testthat::skip_on_cran()

  db <- src_drill(test_host)

  expect_that(db, is_a("src_drill"))

  test_dplyr <- tbl(db, "cp.`employee.json`")

  expect_that(test_dplyr, is_a("tbl"))

})

context("extended d[b]plyr API")
test_that("Extended d[b]plyr ops work", {

  testthat::skip_on_cran()

  db <- src_drill(test_host)

  test_dplyr <- tbl(db, "cp.`employee.json`")

  expect_that(dplyr::count(test_dplyr, gender), is_a("tbl"))
  expect_true(sum(dplyr::collect(dplyr::count(test_dplyr, gender))[["n"]]) > 100)

  emp_partial <- tbl(db, sql("SELECT full_name from cp.`employee.json`"))
  expect_is(emp_partial, "tbl_drill")

  fields <- db_query_fields(emp_partial$src$con, sql("SELECT full_name from cp.`employee.json`"))
  expect_true(all(fields %in% c("full_name", "filename", "filepath", "fqn", "suffix")))

  expln <- db_explain(emp_partial$src$con, sql("SELECT full_name from cp.`employee.json`"))
  expect_true(grepl("groupscan", expln))

  res <- select(emp_partial, full_name)

})


