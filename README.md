
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1248912.svg)](https://doi.org/10.5281/zenodo.1248912)
[![Travis-CI Build
Status](https://travis-ci.org/hrbrmstr/sergeant.svg?branch=master)](https://travis-ci.org/hrbrmstr/sergeant)
[![Coverage
Status](https://codecov.io/gh/hrbrmstr/sergeant/branch/master/graph/badge.svg)](https://codecov.io/gh/hrbrmstr/sergeant)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/sergeant)](https://cran.r-project.org/package=sergeant)

# 💂 sergeant

Tools to Transform and Query Data with ‘Apache’ ‘Drill’

## \*\* IMPORTANT \*\*

Version 0.7.0 splits off the JDBC interface into a separate package
`sergeant.caffeinated`
([sr.ht](https://git.sr.ht/~hrbrmstr/sergeant);
([GitLab](https://gitlab.com/hrbrmstr/sergeant-caffeinated);
[GitHub](https://github.com/hrbrmstr/sergeant-caffeinated)).

If you want to try all the new features coming in 0.8.0 please install from the 0.8.0 branch via:

``` r
# sr.ht
devtools::install_git("https://git.sr.ht/~hrbrmstr/sergeant", ref="0.8.0")

# GitLab
devtools::install_git("https://gitlab.com/hrbrmstr/sergeant", ref="0.8.0")

# GitHub
devtools::install_git("https://github.com/hrbrmstr/sergeant", ref="0.8.0")
```

## Description

Drill + `sergeant` is (IMO) a streamlined alternative to Spark +
`sparklyr` if you don’t need the ML components of Spark (i.e. just need
to query “big data” sources, need to interface with parquet, need to
combine disparate data source types — json, csv, parquet, rdbms - for
aggregation, etc). Drill also has support for spatial queries.

Using Drill SQL queries that reference parquet files on a local linux or
macOS workstation can often be more performant than doing the same data
ingestion & wrangling work with R (especially for large or disperate
data sets). Drill can often help further streaming workflows that
infolve wrangling many tiny JSON files on a daily basis.

Drill can be obtained from <https://drill.apache.org/download/> (use
“Direct File Download”). Drill can also be installed via
[Docker](https://drill.apache.org/docs/running-drill-on-docker/). For
local installs on Unix-like systems, a common/suggestion location for
the Drill directory is `/usr/local/drill` as the install directory.

Drill embedded (started using the `$DRILL_BASE_DIR/bin/drill-embedded`
script) is a super-easy way to get started playing with Drill on a
single workstation and most of many workflows can “get by” using Drill
this way.

There are a few convenience wrappers for various informational SQL
queries (like `drill_version()`). Please file an PR if you add more.

Some of the more “controlling vs data ops” REST API functions aren’t
implemented. Please file a PR if you need those.

The following functions are implemented:

**`DBI`** (REST)

  - A “just enough” feature complete R `DBI` driver has been implemented
    using the Drill REST API, mostly to facilitate the `dplyr`
    interface. Use the `RJDBC` driver interface if you need more `DBI`
    functionality.
  - This also means that SQL functions unique to Drill have also been
    “implemented” (i.e. made accessible to the `dplyr` interface). If
    you have custom Drill SQL functions that need to be implemented
    please file an issue on GitHub. Many should work without it, but
    some may require a custom interface.

**`dplyr`**: (REST)

  - `src_drill`: Connect to Drill (using `dplyr`) + supporting functions

Note that a number of Drill SQL functions have been mapped to R
functions (e.g. `grepl`) to make it easier to transition from
non-database-backed SQL ops to Drill. See the help on
`drill_custom_functions` for more info on these helper Drill custom
function mappings.

**Drill APIs**:

  - `drill_connection`: Setup parameters for a Drill server/cluster
    connection
  - `drill_active`: Test whether Drill HTTP REST API server is up
  - `drill_cancel`: Cancel the query that has the given queryid
  - `drill_jdbc`: Connect to Drill using JDBC
  - `drill_metrics`: Get the current memory metrics
  - `drill_options`: List the name, default, and data type of the system
    and session options
  - `drill_profile`: Get the profile of the query that has the given
    query id
  - `drill_profiles`: Get the profiles of running and completed queries
  - `drill_query`: Submit a query and return results
  - `drill_set`: Set Drill SYSTEM or SESSION options
  - `drill_settings_reset`: Changes (optionally, all) session settings
    back to system defaults
  - `drill_show_files`: Show files in a file system schema.
  - `drill_show_schemas`: Returns a list of available schemas.
  - `drill_stats`: Get Drillbit information, such as ports numbers
  - `drill_status`: Get the status of Drill
  - `drill_storage`: Get the list of storage plugin names and
    configurations
  - `drill_system_reset`: Changes (optionally, all) system settings back
    to system defaults
  - `drill_threads`: Get information about threads
  - `drill_uplift`: Turn a columnar query results into a type-converted
    tbl
  - `drill_use`: Change to a particular schema.
  - `drill_version`: Identify the version of Drill running

## Installation

``` r
devtools::install_github("hrbrmstr/sergeant")
```

## Usage

### `dplyr` interface

``` r
library(sergeant)
library(tidyverse)

# use localhost if running standalone on same system otherwise the host or IP of your Drill server
ds <- src_drill("localhost")  #ds
db <- tbl(ds, "cp.`employee.json`") 

# without `collect()`:
count(db, gender, marital_status)
## # Source:   lazy query [?? x 3]
## # Database: DrillConnection
## # Groups:   gender
##   marital_status gender     n
##   <chr>          <chr>  <int>
## 1 S              F        297
## 2 M              M        278
## 3 S              M        276
## 4 M              F        304

count(db, gender, marital_status) %>% collect()
## # A tibble: 4 x 3
## # Groups:   gender [2]
##   marital_status gender     n
## * <chr>          <chr>  <int>
## 1 S              F        297
## 2 M              M        278
## 3 S              M        276
## 4 M              F        304

group_by(db, position_title) %>% 
  count(gender) -> tmp2

group_by(db, position_title) %>% 
  count(gender) %>% 
  ungroup() %>% 
  mutate(full_desc=ifelse(gender=="F", "Female", "Male")) %>% 
  collect() %>% 
  select(Title=position_title, Gender=full_desc, Count=n)
## # A tibble: 30 x 3
##    Title                  Gender Count
##  * <chr>                  <chr>  <int>
##  1 President              Female     1
##  2 VP Country Manager     Male       3
##  3 VP Country Manager     Female     3
##  4 VP Information Systems Female     1
##  5 VP Human Resources     Female     1
##  6 Store Manager          Female    13
##  7 VP Finance             Male       1
##  8 Store Manager          Male      11
##  9 HQ Marketing           Female     2
## 10 HQ Information Systems Female     4
## # ... with 20 more rows

arrange(db, desc(employee_id)) %>% print(n=20)
## # Source:     table<cp.`employee.json`> [?? x 20]
## # Database:   DrillConnection
## # Ordered by: desc(employee_id)
##    store_id gender department_id birth_date supervisor_id last_name  position_title hire_date           management_role
##       <int> <chr>          <int> <date>             <int> <chr>      <chr>          <dttm>              <chr>          
##  1       18 F                 18 1914-02-02          1140 Stand      Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
##  2       18 M                 18 1914-02-02          1140 Burnham    Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
##  3       18 F                 18 1914-02-02          1139 Doolittle  Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
##  4       18 M                 18 1914-02-02          1139 Pirnie     Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
##  5       18 M                 17 1914-02-02          1140 Younce     Store Permane… 1998-01-01 00:00:00 Store Full Tim…
##  6       18 F                 17 1914-02-02          1140 Biltoft    Store Permane… 1998-01-01 00:00:00 Store Full Tim…
##  7       18 M                 17 1914-02-02          1139 Detwiler   Store Permane… 1998-01-01 00:00:00 Store Full Tim…
##  8       18 F                 17 1914-02-02          1139 Ciruli     Store Permane… 1998-01-01 00:00:00 Store Full Tim…
##  9       18 F                 16 1914-02-02          1140 Bishop     Store Tempora… 1998-01-01 00:00:00 Store Full Tim…
## 10       18 F                 16 1914-02-02          1140 Cutwright  Store Tempora… 1998-01-01 00:00:00 Store Full Tim…
## 11       18 F                 16 1914-02-02          1139 Anderson   Store Tempora… 1998-01-01 00:00:00 Store Full Tim…
## 12       18 F                 16 1914-02-02          1139 Swartwood  Store Tempora… 1998-01-01 00:00:00 Store Full Tim…
## 13       18 M                 15 1914-02-02          1140 Curtsinger Store Permane… 1998-01-01 00:00:00 Store Full Tim…
## 14       18 F                 15 1914-02-02          1140 Quick      Store Permane… 1998-01-01 00:00:00 Store Full Tim…
## 15       18 M                 15 1914-02-02          1139 Souza      Store Permane… 1998-01-01 00:00:00 Store Full Tim…
## 16       18 M                 15 1914-02-02          1139 Compagno   Store Permane… 1998-01-01 00:00:00 Store Full Tim…
## 17       18 M                 11 1961-09-24          1139 Jaramillo  Store Shift S… 1998-01-01 00:00:00 Store Manageme…
## 18       18 M                 11 1972-05-12            17 Belsey     Store Assista… 1998-01-01 00:00:00 Store Manageme…
## 19       12 M                 18 1914-02-02          1069 Eichorn    Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
## 20       12 F                 18 1914-02-02          1069 Geiermann  Store Tempora… 1998-01-01 00:00:00 Store Temp Sta…
## # ... with more rows, and 7 more variables: salary <dbl>, marital_status <chr>, full_name <chr>, employee_id <int>,
## #   education_level <chr>, first_name <chr>, position_id <int>

mutate(db, position_title=tolower(position_title)) %>%
  mutate(salary=as.numeric(salary)) %>% 
  mutate(gender=ifelse(gender=="F", "Female", "Male")) %>%
  mutate(marital_status=ifelse(marital_status=="S", "Single", "Married")) %>% 
  group_by(supervisor_id) %>% 
  summarise(underlings_count=n()) %>% 
  collect()
## # A tibble: 112 x 2
##    supervisor_id underlings_count
##  *         <int>            <int>
##  1             0                1
##  2             1                7
##  3             5                9
##  4             4                2
##  5             2                3
##  6            20                2
##  7            21                4
##  8            22                7
##  9             6                4
## 10            36                2
## # ... with 102 more rows
```

### REST API

``` r
dc <- drill_connection("localhost") 

drill_active(dc)
## [1] TRUE

drill_version(dc)
## [1] "1.13.0"

drill_storage(dc)$name
## [1] "cp"    "dfs"   "hbase" "hive"  "kudu"  "mongo" "s3"

drill_query(dc, "SELECT * FROM cp.`employee.json` limit 100")
## Parsed with column specification:
## cols(
##   store_id = col_integer(),
##   gender = col_character(),
##   department_id = col_integer(),
##   birth_date = col_date(format = ""),
##   supervisor_id = col_integer(),
##   last_name = col_character(),
##   position_title = col_character(),
##   hire_date = col_datetime(format = ""),
##   management_role = col_character(),
##   salary = col_double(),
##   marital_status = col_character(),
##   full_name = col_character(),
##   employee_id = col_integer(),
##   education_level = col_character(),
##   first_name = col_character(),
##   position_id = col_integer()
## )
## # A tibble: 100 x 16
##    store_id gender department_id birth_date supervisor_id last_name position_title  hire_date           management_role
##  *    <int> <chr>          <int> <date>             <int> <chr>     <chr>           <dttm>              <chr>          
##  1        0 F                  1 1961-08-26             0 Nowmer    President       1994-12-01 00:00:00 Senior Managem…
##  2        0 M                  1 1915-07-03             1 Whelply   VP Country Man… 1994-12-01 00:00:00 Senior Managem…
##  3        0 M                  1 1969-06-20             1 Spence    VP Country Man… 1998-01-01 00:00:00 Senior Managem…
##  4        0 F                  1 1951-05-10             1 Gutierrez VP Country Man… 1998-01-01 00:00:00 Senior Managem…
##  5        0 F                  2 1942-10-08             1 Damstra   VP Information… 1994-12-01 00:00:00 Senior Managem…
##  6        0 F                  3 1949-03-27             1 Kanagaki  VP Human Resou… 1994-12-01 00:00:00 Senior Managem…
##  7        9 F                 11 1922-08-10             5 Brunner   Store Manager   1998-01-01 00:00:00 Store Manageme…
##  8       21 F                 11 1979-06-23             5 Blumberg  Store Manager   1998-01-01 00:00:00 Store Manageme…
##  9        0 M                  5 1949-08-26             1 Stanz     VP Finance      1994-12-01 00:00:00 Senior Managem…
## 10        1 M                 11 1967-06-20             5 Murraiin  Store Manager   1998-01-01 00:00:00 Store Manageme…
## # ... with 90 more rows, and 7 more variables: salary <dbl>, marital_status <chr>, full_name <chr>, employee_id <int>,
## #   education_level <chr>, first_name <chr>, position_id <int>

drill_query(dc, "SELECT COUNT(gender) AS gender FROM cp.`employee.json` GROUP BY gender")
## Parsed with column specification:
## cols(
##   gender = col_integer()
## )
## # A tibble: 2 x 1
##   gender
## *  <int>
## 1    601
## 2    554

drill_options(dc)
## # A tibble: 138 x 5
##    name                                              value    accessibleScopes kind    optionScope
##  * <chr>                                             <chr>    <chr>            <chr>   <chr>      
##  1 debug.validate_iterators                          FALSE    ALL              BOOLEAN BOOT       
##  2 debug.validate_vectors                            FALSE    ALL              BOOLEAN BOOT       
##  3 drill.exec.functions.cast_empty_string_to_null    FALSE    ALL              BOOLEAN BOOT       
##  4 drill.exec.hashagg.fallback.enabled               FALSE    ALL              BOOLEAN BOOT       
##  5 drill.exec.memory.operator.output_batch_size      16777216 SYSTEM           LONG    BOOT       
##  6 drill.exec.storage.file.partition.column.label    dir      ALL              STRING  BOOT       
##  7 drill.exec.storage.implicit.filename.column.label filename ALL              STRING  BOOT       
##  8 drill.exec.storage.implicit.filepath.column.label filepath ALL              STRING  BOOT       
##  9 drill.exec.storage.implicit.fqn.column.label      fqn      ALL              STRING  BOOT       
## 10 drill.exec.storage.implicit.suffix.column.label   suffix   ALL              STRING  BOOT       
## # ... with 128 more rows

drill_options(dc, "json")
## # A tibble: 9 x 5
##   name                                                  value accessibleScopes kind    optionScope
##   <chr>                                                 <chr> <chr>            <chr>   <chr>      
## 1 store.json.all_text_mode                              FALSE ALL              BOOLEAN BOOT       
## 2 store.json.extended_types                             FALSE ALL              BOOLEAN BOOT       
## 3 store.json.read_numbers_as_double                     FALSE ALL              BOOLEAN BOOT       
## 4 store.json.reader.allow_nan_inf                       TRUE  ALL              BOOLEAN BOOT       
## 5 store.json.reader.print_skipped_invalid_record_number FALSE ALL              BOOLEAN BOOT       
## 6 store.json.reader.skip_invalid_records                FALSE ALL              BOOLEAN BOOT       
## 7 store.json.writer.allow_nan_inf                       TRUE  ALL              BOOLEAN BOOT       
## 8 store.json.writer.skip_null_fields                    TRUE  ALL              BOOLEAN BOOT       
## 9 store.json.writer.uglify                              FALSE ALL              BOOLEAN BOOT
```

## Working with parquet files

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nation.parquet` LIMIT 5")
## Parsed with column specification:
## cols(
##   N_COMMENT = col_character(),
##   N_NAME = col_character(),
##   N_NATIONKEY = col_integer(),
##   N_REGIONKEY = col_integer()
## )
## # A tibble: 5 x 4
##   N_COMMENT            N_NAME    N_NATIONKEY N_REGIONKEY
## * <chr>                <chr>           <int>       <int>
## 1 haggle. carefully f  ALGERIA             0           0
## 2 al foxes promise sly ARGENTINA           1           1
## 3 y alongside of the p BRAZIL              2           1
## 4 eas hang ironic, sil CANADA              3           1
## 5 y above the carefull EGYPT               4           4
```

Including multiple parquet files in different directories (note the
wildcard
support):

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nations*/nations*.parquet` LIMIT 5")
## Parsed with column specification:
## cols(
##   N_COMMENT = col_character(),
##   N_NAME = col_character(),
##   N_NATIONKEY = col_integer(),
##   dir0 = col_character(),
##   N_REGIONKEY = col_integer()
## )
## # A tibble: 5 x 5
##   N_COMMENT            N_NAME    N_NATIONKEY dir0      N_REGIONKEY
## * <chr>                <chr>           <int> <chr>           <int>
## 1 haggle. carefully f  ALGERIA             0 nationsSF           0
## 2 al foxes promise sly ARGENTINA           1 nationsSF           1
## 3 y alongside of the p BRAZIL              2 nationsSF           1
## 4 eas hang ironic, sil CANADA              3 nationsSF           1
## 5 y above the carefull EGYPT               4 nationsSF           4
```

### Drill has built-in support for spatial ops

Via: <https://github.com/k255/drill-gis>

A common use case is to select data within boundary of given polygon:

``` r
drill_query(dc, "
select columns[2] as city, columns[4] as lon, columns[3] as lat
    from cp.`sample-data/CA-cities.csv`
    where
        ST_Within(
            ST_Point(columns[4], columns[3]),
            ST_GeomFromText(
                'POLYGON((-121.95 37.28, -121.94 37.35, -121.84 37.35, -121.84 37.28, -121.95 37.28))'
                )
            )
")
## Parsed with column specification:
## cols(
##   city = col_character(),
##   lon = col_double(),
##   lat = col_double()
## )
## # A tibble: 7 x 3
##   city          lon   lat
## * <chr>       <dbl> <dbl>
## 1 Burbank     -122.  37.3
## 2 San Jose    -122.  37.3
## 3 Lick        -122.  37.3
## 4 Willow Glen -122.  37.3
## 5 Buena Vista -122.  37.3
## 6 Parkmoor    -122.  37.3
## 7 Fruitdale   -122.  37.3
```

### Test Results

``` r
library(sergeant)
library(testthat)
## 
## Attaching package: 'testthat'
## The following object is masked from 'package:dplyr':
## 
##     matches
## The following object is masked from 'package:purrr':
## 
##     is_null

date()
## [1] "Sun Oct 14 08:27:29 2018"

devtools::test()
## Loading sergeant
## Testing sergeant
## ✔ | OK F W S | Context
## 
⠏ |  0       | dplyr API
⠋ |  1       | dplyr API
⠙ |  2       | dplyr API
⠹ |  3       | dplyr API
✔ |  3       | dplyr API [0.3 s]
## 
⠏ |  0       | REST API
⠋ |  1       | REST API
⠙ |  2       | REST API
⠹ |  3       | REST API
⠸ |  4       | REST API
⠼ |  5       | REST API
⠴ |  6       | REST API
⠦ |  7       | REST API
⠧ |  8       | REST API
⠇ |  9       | REST API
⠏ | 10       | REST API
⠋ | 11       | REST API
⠙ | 12       | REST API
⠹ | 13       | REST API
⠸ | 14       | REST API
⠼ | 15       | REST API
⠴ | 16       | REST API
✔ | 16       | REST API [2.2 s]
## 
## ══ Results ═══════════════════════════════════════════════════
## Duration: 2.5 s
## 
## OK:       19
## Failed:   0
## Warnings: 0
## Skipped:  0
```

## sergeant Metrics

| Lang | \# Files |  (%) | LoC |  (%) | Blank lines |  (%) | \# Lines |  (%) |
| :--- | -------: | ---: | --: | ---: | ----------: | ---: | -------: | ---: |
| R    |       12 | 0.92 | 625 | 0.92 |         173 | 0.75 |      562 | 0.87 |
| Rmd  |        1 | 0.08 |  55 | 0.08 |          58 | 0.25 |       86 | 0.13 |

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](CONDUCT.md). By participating in this project you agree to
abide by its terms.
