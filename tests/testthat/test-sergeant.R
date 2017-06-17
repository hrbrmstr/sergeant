context("basic functionality")
test_that("we can do something", {

  testthat::skip_on_cran()
#  testthat::skip_on_travis()

  src_drill("localhost") %>%
    tbl("cp.`employee.json`") -> test_dplyr

  drill_connection("localhost") %>%
    drill_query("SELECT * FROM cp.`employee.json` limit 10") -> test_rest

  expect_that(test_dplyr, is_a("tbl"))
  expect_that(test_rest, is_a("data.frame"))

})
