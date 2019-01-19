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

context("DBI")
test_that("core DBI ops work", {

  testthat::skip_on_cran()

  con <- dbConnect(Drill(), "localhost")
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

  expect_true(is.null(dbGetInfo(Drill())))

  inf <- dbGetInfo(con)
  expect_equal(inf$port, 8047)

})

context("REST API")
test_that("REST API works", {

  testthat::skip_on_cran()

  dc <- drill_connection(test_host)
  expect_that(drill_active(dc), equals(TRUE))

  suppressMessages(
    drill_query(dc, "SELECT * FROM cp.`employee.json` limit 10", .progress = FALSE)
  ) -> test_rest

  expect_that(test_rest, is_a("data.frame"))

  expect_that(drill_version(dc), is_a("character"))
  expect_that(drill_metrics(dc), is_a("list"))
  expect_that(drill_options(dc), is_a("tbl"))

  dp <- drill_profiles(dc)

  expect_that(dp, is_a("list"))
  expect_that(drill_profile(dc, dp$finishedQueries[1]$queryId[1]), is_a("list"))
  suppressMessages(
    expect_that(drill_cancel(dc, dp$finishedQueries[1]$queryId[1]), equals(TRUE))
  )
  suppressMessages(
    suppressWarnings(
      expect_that(drill_show_files(dc, schema_spec = "dfs"), is_a("tbl"))
    )
  )
  expect_that(drill_show_schemas(dc), is_a("tbl"))
  expect_that(drill_storage(dc), is_a("tbl"))
  expect_that(drill_stats(dc), is_a("list"))
  expect_that(drill_status(dc), is_a("html"))
  expect_that(drill_threads(dc), is_a("html"))
  expect_that(drill_use(dc, "cp"), is_a("tbl"))
  expect_that(
    drill_set(
      dc,
      exec.errors.verbose=TRUE,
      store.format="parquet",
      web.logs.max_lines=20000),
    is_a("tbl")
  )

})
