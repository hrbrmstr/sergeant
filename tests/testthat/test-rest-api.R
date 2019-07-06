test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

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
