
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!--
[![Build Status](https://travis-ci.org/hrbrmstr/sergeant.svg)](https://travis-ci.org/hrbrmstr/sergeant) 
![Project Status: Concept - Minimal or no implementation has been done yet.](http://www.repostatus.org/badges/0.1.0/concept.svg)](http://www.repostatus.org/#concept)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/sergeant)](http://cran.r-project.org/web/packages/sergeant) 
![downloads](http://cranlogs.r-pkg.org/badges/grand-total/sergeant)
-->
`sergeant` : Tools to Transform and Query Data with the 'Apache' 'Drill' 'API'

The following functions are implemented:

-   `drill_cancel`: Cancel the query that has the given queryid.
-   `drill_metrics`: Get the current memory metrics
-   `drill_options`: List the name, default, and data type of the system and session options
-   `drill_profile`: Get the profile of the query that has the given queryid.
-   `drill_profiles`: Get the profiles of running and completed queries
-   `drill_query`: Submit a query and return results
-   `drill_set`: Set Drill SYSTEM or SESSION options
-   `drill_setting_reset`: Changes (optionally, all) session settings back to system defaults
-   `drill_show_files`: Show files in a file system schema.
-   `drill_show_schemas`: Returns a list of available schemas.
-   `drill_stats`: Get Drillbit information, such as ports numbers
-   `drill_status`: Get the status of Drill
-   `drill_storage`: Get the list of storage plugin names and configurations
-   `drill_system_reset`: Changes (optionally, all) system settings back to system defaults
-   `drill_threads`: Get information about threads
-   `drill_uplift`: Turn a columnar query results into a type-converted tbl
-   `drill_use`: Change to a particular schema.
-   `drill_version`: Identify the version of Drill running

### Installation

``` r
devtools::install_github("hrbrmstr/sergeant")
```

### Usage

``` r
library(sergeant)

# current verison
packageVersion("sergeant")
#> [1] '0.1.0.9000'
```

### Test Results

``` r
library(sergeant)
library(testthat)

date()
#> [1] "Sat Dec  3 11:28:51 2016"

test_dir("tests/")
#> testthat results ========================================================================================================
#> OK: 0 SKIPPED: 0 FAILED: 0
#> 
#> DONE ===================================================================================================================
```

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
