
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!--
[![Build Status](https://travis-ci.org/hrbrmstr/sergeant.svg)](https://travis-ci.org/hrbrmstr/sergeant) 
![Project Status: Concept - Minimal or no implementation has been done yet.](http://www.repostatus.org/badges/0.1.0/concept.svg)](http://www.repostatus.org/#concept)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/sergeant)](http://cran.r-project.org/web/packages/sergeant) 
![downloads](http://cranlogs.r-pkg.org/badges/grand-total/sergeant)
-->
`sergeant` : Tools to Transform and Query Data with the 'Apache' 'Drill' 'API'

The following functions are implemented:

-   `drill_metrics`: Get the current memory metrics
-   `drill_options`: List the name, default, and data type of the system and session options
-   `drill_profiles`: Get the profiles of running and completed queries
-   `drill_query`: Submit a query and return results
-   `drill_stats`: Get Drillbit information, such as ports numbers
-   \`drill\_status Get the status of Drill
-   `drill_storage`: Get the list of storage plugin names and configurations
-   `drill_threads`: Get information about threads

### News

-   Version 0.1.0 released

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

drill_query("SELECT * FROM dfs.`/usr/local/drill/sample-data/nation.parquet`")
#> No encoding supplied: defaulting to UTF-8.
#> $columns
#> [1] "N_NATIONKEY" "N_NAME"      "N_REGIONKEY" "N_COMMENT"  
#> 
#> $rows
#>               N_COMMENT         N_NAME N_NATIONKEY N_REGIONKEY
#> 1   haggle. carefully f        ALGERIA           0           0
#> 2  al foxes promise sly      ARGENTINA           1           1
#> 3  y alongside of the p         BRAZIL           2           1
#> 4  eas hang ironic, sil         CANADA           3           1
#> 5  y above the carefull          EGYPT           4           4
#> 6  ven packages wake qu       ETHIOPIA           5           0
#> 7  refully final reques         FRANCE           6           3
#> 8  l platelets. regular        GERMANY           7           3
#> 9  ss excuses cajole sl          INDIA           8           2
#> 10  slyly express asymp      INDONESIA           9           2
#> 11 efully alongside of            IRAN          10           4
#> 12 nic deposits boost a           IRAQ          11           4
#> 13 ously. final, expres          JAPAN          12           2
#> 14 ic deposits are blit         JORDAN          13           4
#> 15  pending excuses hag          KENYA          14           0
#> 16 rns. blithely bold c        MOROCCO          15           0
#> 17 s. ironic, unusual a     MOZAMBIQUE          16           0
#> 18 platelets. blithely            PERU          17           1
#> 19 c dependencies. furi          CHINA          18           2
#> 20 ular asymptotes are         ROMANIA          19           3
#> 21 ts. silent requests    SAUDI ARABIA          20           4
#> 22 hely enticingly expr        VIETNAM          21           2
#> 23  requests against th         RUSSIA          22           3
#> 24 eans boost carefully UNITED KINGDOM          23           3
#> 25 y final packages. sl  UNITED STATES          24           1
```

### Test Results

``` r
library(sergeant)
library(testthat)

date()
#> [1] "Thu Jun  2 22:01:36 2016"

test_dir("tests/")
#> testthat results ========================================================================================================
#> OK: 0 SKIPPED: 0 FAILED: 0
#> 
#> DONE ===================================================================================================================
```

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
