test_host <- Sys.getenv("DRILL_TEST_HOST", "localhost")

options(sergeant.bigint.warnonce = FALSE)

if (at_home()) {

  dc <- drill_connection(test_host)
  expect_true(drill_active(dc))

  suppressMessages(
    drill_query(dc, "SELECT * FROM cp.`employee.json` limit 10", .progress = FALSE)
  ) -> test_rest

  expect_true(inherits(test_rest, "data.frame"))

  expect_true(inherits(drill_version(dc), "character"))
  expect_true(inherits(drill_metrics(dc), "list"))
  expect_true(inherits(drill_options(dc), "tbl"))

  dp <- drill_profiles(dc)

  expect_true(inherits(dp, "list"))

  expect_true(
    inherits(
      drill_profile(dc, dp$finishedQueries[1]$queryId[1]),
      "list"
    )
  )

  suppressMessages(
    expect_true(
      drill_cancel(dc, dp$finishedQueries[1]$queryId[1])
    )
  )

  suppressMessages(
    suppressWarnings(
      expect_true(
        inherits(
          drill_show_files(dc, schema_spec = "dfs"),
          "tbl"
        )
      )
    )
  )

  expect_true(inherits(drill_show_schemas(dc), "tbl"))
  expect_true(inherits(drill_storage(dc), "tbl"))
  expect_true(inherits(drill_stats(dc), "list"))
  expect_true(inherits(drill_status(dc), "html"))
  expect_true(inherits(drill_threads(dc), "html"))
  expect_true(inherits(drill_use(dc, "cp"), "tbl"))

  expect_true(
    inherits(
      drill_set(
        dc,
        exec.errors.verbose = TRUE,
        store.format = "parquet",
        web.logs.max_lines = 20000
      ),
      "tbl"
    )
  )

}
