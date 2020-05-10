library(dbplyr)
library(dplyr)

test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

if (at_home()) {

  db <- src_drill(test_host)

  expect_true(inherits(db, "src_drill"))

  test_dplyr <- tbl(db, "cp.`employee.json`")

  expect_true(inherits(test_dplyr, "tbl"))

  db <- src_drill(test_host)

  test_dplyr <- tbl(db, "cp.`employee.json`")

  expect_true(inherits(dplyr::count(test_dplyr, gender), "tbl"))
  expect_true(sum(dplyr::collect(dplyr::count(test_dplyr, gender))[["n"]]) > 100)

  emp_partial <- tbl(db, sql("SELECT full_name from cp.`employee.json`"))
  expect_true(inherits(emp_partial, "tbl_drill"))

  fields <- db_query_fields(emp_partial$src$con, sql("SELECT full_name from cp.`employee.json`"))
  expect_true(all(c("full_name", "filename", "filepath", "fqn", "suffix") %in% fields))

  expln <- db_explain(emp_partial$src$con, sql("SELECT full_name from cp.`employee.json`"))
  expect_true(grepl("groupscan", expln))

  res <- select(emp_partial, full_name)

}


