
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1248912.svg)](https://doi.org/10.5281/zenodo.1248912) 
[![Travis-CI Build Status](https://travis-ci.org/hrbrmstr/sergeant.svg?branch=master)](https://travis-ci.org/hrbrmstr/sergeant) 
[![Coverage Status](https://codecov.io/gh/hrbrmstr/sergeant/branch/master/graph/badge.svg)](https://codecov.io/gh/hrbrmstr/sergeant)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/sergeant)](https://cran.r-project.org/package=sergeant)

# sergeant

Tools to Transform and Query Data with 'Apache' 'Drill'

## NOTE

Version 0.7.0 re-introduces an `RJDBC` (and, as such, an `rJava` depedency). If you desire this to be put into a sibling package, [cast your vote](https://github.com/hrbrmstr/sergeant/issues/20).

## Description

Drill + `sergeant` is (IMO) a nice alternative to Spark + `sparklyr` if you don't need the ML components of Spark (i.e. just need to query "big data" sources, need to interface with parquet, need to combine disparate data source types — json, csv, parquet, rdbms - for aggregation, etc). Drill also has support for spatial queries.

I find writing SQL queries to parquet files with Drill on a local linux or macOS workstation to be more performant than doing the data ingestion work with R (especially for large or disperate data sets). I also work with many tiny JSON files on a daily basis and Drill makes it much easier to do so. YMMV.

You can download Drill from <https://drill.apache.org/download/> (use "Direct File Download"). I use `/usr/local/drill` as the install directory. `drill-embedded` is a super-easy way to get started playing with Drill on a single workstation and most of my workflows can get by using Drill this way. If there is sufficient desire for an automated downloader and a way to start the `drill-embedded` server from within R, please file an issue.

There are a few convenience wrappers for various informational SQL queries (like `drill_version()`). Please file an PR if you add more.

The package has been written with retrieval of rectangular data sources in mind. If you need/want a version of `drill_query()` that will enable returning of non-rectangular data (which is possible with Drill) then please file an issue.

Some of the more "controlling vs data ops" REST API functions aren't implemented. Please file a PR if you need those.

The following functions are implemented:

**`DBI`** (REST)

- A "just enough" feature complete R `DBI` driver has been implemented using the Drill REST API, mostly to facilitate the `dplyr` interface. Use the `RJDBC` driver interface if you need more `DBI` functionality.
- This also means that SQL functions unique to Drill have also been "implemented" (i.e. made accessible to the `dplyr` interface). If you have custom Drill SQL functions that need to be implemented please file an issue on GitHub. Many should work without it, but some may require a custom interface. 

**`DBI`** (RJDBC)

- `drill_jdbc`:	Connect to Drill using JDBC, enabling use of said idioms. See `RJDBC` for more info.
- NOTE: The DRILL JDBC driver fully-qualified path must be placed in the `DRILL_JDBC_JAR` environment variable. This is best done via `~/.Renviron` for interactive work. i.e. `DRILL_JDBC_JAR=/usr/local/drill/jars/drill-jdbc-all-1.14.0.jar`

**`dplyr`**: (REST)

- `src_drill`: Connect to Drill (using dplyr) + supporting functions

See `dplyr` for the `dplyr` operations (light testing shows they work in basic SQL use-cases but Drill's SQL engine has issues with more complex queries).

**`dplyr`**: (RJDBC)

- `src_drill_jdbc`: Connect to Drill (using dplyr & RJDBC) + supporting functions

See `dplyr` for the `dplyr` operations (light testing shows they work in basic SQL use-cases but Drill's SQL engine has issues with more complex queries).

**Drill APIs**:

-   `drill_connection`: Setup parameters for a Drill server/cluster connection
-   `drill_active`: Test whether Drill HTTP REST API server is up
-   `drill_cancel`: Cancel the query that has the given queryid
-   `drill_jdbc`: Connect to Drill using JDBC
-   `drill_metrics`: Get the current memory metrics
-   `drill_options`: List the name, default, and data type of the system and session options
-   `drill_profile`: Get the profile of the query that has the given query id
-   `drill_profiles`: Get the profiles of running and completed queries
-   `drill_query`: Submit a query and return results
-   `drill_set`: Set Drill SYSTEM or SESSION options
-   `drill_settings_reset`: Changes (optionally, all) session settings back to system defaults
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

### Experimental `dplyr` interface

``` r
library(sergeant)
```

``` r
ds <- src_drill("localhost")  # use localhost if running standalone on same system otherwise the host or IP of your Drill server
ds
```

    #> src:  DrillConnection
    #> tbls: INFORMATION_SCHEMA, cp.default, dfs.d, dfs.default, dfs.h, dfs.natexp, dfs.p, dfs.root, dfs.tmp, sys

``` r
db <- tbl(ds, "cp.`employee.json`") 

# without `collect()`:
count(db, gender, marital_status)
#> # Source:   lazy query [?? x 3]
#> # Database: DrillConnection
#> # Groups:   gender
#>   marital_status gender     n
#>            <chr>  <chr> <int>
#> 1              S      F   297
#> 2              M      M   278
#> 3              S      M   276
#> 4              M      F   304

# ^^ gets translated to:
# 
# SELECT *
# FROM (SELECT  gender ,  marital_status , COUNT(*) AS  n 
#       FROM  cp.`employee.json` 
#       GROUP BY  gender ,  marital_status )  govketbhqb 
# LIMIT 1000

count(db, gender, marital_status) %>% collect()
#> # A tibble: 4 x 3
#> # Groups:   gender [2]
#>   marital_status gender     n
#> *          <chr>  <chr> <int>
#> 1              S      F   297
#> 2              M      M   278
#> 3              S      M   276
#> 4              M      F   304

# ^^ gets translated to:
# 
# SELECT  gender ,  marital_status , COUNT(*) AS  n 
# FROM  cp.`employee.json` 
# GROUP BY  gender ,  marital_status 

group_by(db, position_title) %>% 
  count(gender) -> tmp2

group_by(db, position_title) %>% 
  count(gender) %>% 
  ungroup() %>% 
  mutate(full_desc=ifelse(gender=="F", "Female", "Male")) %>% 
  collect() %>% 
  select(Title=position_title, Gender=full_desc, Count=n)
#> # A tibble: 30 x 3
#>                     Title Gender Count
#>  *                  <chr>  <chr> <int>
#>  1              President Female     1
#>  2     VP Country Manager   Male     3
#>  3     VP Country Manager Female     3
#>  4 VP Information Systems Female     1
#>  5     VP Human Resources Female     1
#>  6          Store Manager Female    13
#>  7             VP Finance   Male     1
#>  8          Store Manager   Male    11
#>  9           HQ Marketing Female     2
#> 10 HQ Information Systems Female     4
#> # ... with 20 more rows

# ^^ gets translated to:
# 
# SELECT  position_title ,  gender ,  n ,
#         CASE WHEN ( gender  = 'F') THEN ('Female') ELSE ('Male') END AS  full_desc 
# FROM (SELECT  position_title ,  gender , COUNT(*) AS  n 
#       FROM  cp.`employee.json` 
#       GROUP BY  position_title ,  gender )  dcyuypuypb 

arrange(db, desc(employee_id)) %>% print(n=20)
#> # Source:     table<cp.`employee.json`> [?? x 16]
#> # Database:   DrillConnection
#> # Ordered by: desc(employee_id)
#>    store_id gender department_id birth_date supervisor_id  last_name          position_title  hire_date
#>       <int>  <chr>         <int>     <date>         <int>      <chr>                   <chr>     <dttm>
#>  1       18      F            18 1914-02-02          1140      Stand Store Temporary Stocker 1998-01-01
#>  2       18      M            18 1914-02-02          1140    Burnham Store Temporary Stocker 1998-01-01
#>  3       18      F            18 1914-02-02          1139  Doolittle Store Temporary Stocker 1998-01-01
#>  4       18      M            18 1914-02-02          1139     Pirnie Store Temporary Stocker 1998-01-01
#>  5       18      M            17 1914-02-02          1140     Younce Store Permanent Stocker 1998-01-01
#>  6       18      F            17 1914-02-02          1140    Biltoft Store Permanent Stocker 1998-01-01
#>  7       18      M            17 1914-02-02          1139   Detwiler Store Permanent Stocker 1998-01-01
#>  8       18      F            17 1914-02-02          1139     Ciruli Store Permanent Stocker 1998-01-01
#>  9       18      F            16 1914-02-02          1140     Bishop Store Temporary Checker 1998-01-01
#> 10       18      F            16 1914-02-02          1140  Cutwright Store Temporary Checker 1998-01-01
#> 11       18      F            16 1914-02-02          1139   Anderson Store Temporary Checker 1998-01-01
#> 12       18      F            16 1914-02-02          1139  Swartwood Store Temporary Checker 1998-01-01
#> 13       18      M            15 1914-02-02          1140 Curtsinger Store Permanent Checker 1998-01-01
#> 14       18      F            15 1914-02-02          1140      Quick Store Permanent Checker 1998-01-01
#> 15       18      M            15 1914-02-02          1139      Souza Store Permanent Checker 1998-01-01
#> 16       18      M            15 1914-02-02          1139   Compagno Store Permanent Checker 1998-01-01
#> 17       18      M            11 1961-09-24          1139  Jaramillo  Store Shift Supervisor 1998-01-01
#> 18       18      M            11 1972-05-12            17     Belsey Store Assistant Manager 1998-01-01
#> 19       12      M            18 1914-02-02          1069    Eichorn Store Temporary Stocker 1998-01-01
#> 20       12      F            18 1914-02-02          1069  Geiermann Store Temporary Stocker 1998-01-01
#> # ... with more rows, and 8 more variables: management_role <chr>, salary <dbl>, marital_status <chr>, full_name <chr>,
#> #   employee_id <int>, education_level <chr>, first_name <chr>, position_id <int>

# ^^ gets translated to:
# 
# SELECT *
# FROM (SELECT *
#       FROM  cp.`employee.json` 
#       ORDER BY  employee_id  DESC)  lvpxoaejbc 
# LIMIT 5

mutate(db, position_title=tolower(position_title)) %>%
  mutate(salary=as.numeric(salary)) %>% 
  mutate(gender=ifelse(gender=="F", "Female", "Male")) %>%
  mutate(marital_status=ifelse(marital_status=="S", "Single", "Married")) %>% 
  group_by(supervisor_id) %>% 
  summarise(underlings_count=n()) %>% 
  collect()
#> # A tibble: 112 x 2
#>    supervisor_id underlings_count
#>  *         <int>            <int>
#>  1             0                1
#>  2             1                7
#>  3             5                9
#>  4             4                2
#>  5             2                3
#>  6            20                2
#>  7            21                4
#>  8            22                7
#>  9             6                4
#> 10            36                2
#> # ... with 102 more rows

# ^^ gets translated to:
# 
# SELECT  supervisor_id , COUNT(*) AS  underlings_count 
# FROM (SELECT  employee_id ,  full_name ,  first_name ,  last_name ,  position_id ,  position_title ,  store_id ,  department_id ,  birth_date ,  hire_date ,  salary ,  supervisor_id ,  education_level ,  gender ,  management_role , CASE WHEN ( marital_status  = 'S') THEN ('Single') ELSE ('Married') END AS  marital_status 
#       FROM (SELECT  employee_id ,  full_name ,  first_name ,  last_name ,  position_id ,  position_title ,  store_id ,  department_id ,  birth_date ,  hire_date ,  salary ,  supervisor_id ,  education_level ,  marital_status ,  management_role , CASE WHEN ( gender  = 'F') THEN ('Female') ELSE ('Male') END AS  gender 
#             FROM (SELECT  employee_id ,  full_name ,  first_name ,  last_name ,  position_id ,  position_title ,  store_id ,  department_id ,  birth_date ,  hire_date ,  supervisor_id ,  education_level ,  marital_status ,  gender ,  management_role , CAST( salary  AS DOUBLE) AS  salary 
#                   FROM (SELECT  employee_id ,  full_name ,  first_name ,  last_name ,  position_id ,  store_id ,  department_id ,  birth_date ,  hire_date ,  salary ,  supervisor_id ,  education_level ,  marital_status ,  gender ,  management_role , LOWER( position_title ) AS  position_title 
#                         FROM  cp.`employee.json` )  cnjsqxeick )  bnbnjrubna )  wavfmhkczv )  zaxeyyicxo 
# GROUP BY  supervisor_id 
```

### Usage

``` r
library(sergeant)

# current verison
packageVersion("sergeant")
#> [1] '0.5.2'
```

``` r
dc <- drill_connection("localhost") 
```

``` r
drill_active(dc)
#> [1] TRUE

drill_version(dc)
#> [1] "1.11.0"

drill_storage(dc)$name
#> [1] "cp"    "dfs"   "hbase" "hive"  "kudu"  "mongo" "s3"
```

Working with the built-in JSON data sets:

``` r
drill_query(dc, "SELECT * FROM cp.`employee.json` limit 100")
#> Parsed with column specification:
#> cols(
#>   store_id = col_integer(),
#>   gender = col_character(),
#>   department_id = col_integer(),
#>   birth_date = col_date(format = ""),
#>   supervisor_id = col_integer(),
#>   last_name = col_character(),
#>   position_title = col_character(),
#>   hire_date = col_datetime(format = ""),
#>   management_role = col_character(),
#>   salary = col_double(),
#>   marital_status = col_character(),
#>   full_name = col_character(),
#>   employee_id = col_integer(),
#>   education_level = col_character(),
#>   first_name = col_character(),
#>   position_id = col_integer()
#> )
#> # A tibble: 100 x 16
#>    store_id gender department_id birth_date supervisor_id last_name         position_title  hire_date   management_role
#>  *    <int>  <chr>         <int>     <date>         <int>     <chr>                  <chr>     <dttm>             <chr>
#>  1        0      F             1 1961-08-26             0    Nowmer              President 1994-12-01 Senior Management
#>  2        0      M             1 1915-07-03             1   Whelply     VP Country Manager 1994-12-01 Senior Management
#>  3        0      M             1 1969-06-20             1    Spence     VP Country Manager 1998-01-01 Senior Management
#>  4        0      F             1 1951-05-10             1 Gutierrez     VP Country Manager 1998-01-01 Senior Management
#>  5        0      F             2 1942-10-08             1   Damstra VP Information Systems 1994-12-01 Senior Management
#>  6        0      F             3 1949-03-27             1  Kanagaki     VP Human Resources 1994-12-01 Senior Management
#>  7        9      F            11 1922-08-10             5   Brunner          Store Manager 1998-01-01  Store Management
#>  8       21      F            11 1979-06-23             5  Blumberg          Store Manager 1998-01-01  Store Management
#>  9        0      M             5 1949-08-26             1     Stanz             VP Finance 1994-12-01 Senior Management
#> 10        1      M            11 1967-06-20             5  Murraiin          Store Manager 1998-01-01  Store Management
#> # ... with 90 more rows, and 7 more variables: salary <dbl>, marital_status <chr>, full_name <chr>, employee_id <int>,
#> #   education_level <chr>, first_name <chr>, position_id <int>

drill_query(dc, "SELECT COUNT(gender) AS gender FROM cp.`employee.json` GROUP BY gender")
#> Parsed with column specification:
#> cols(
#>   gender = col_integer()
#> )
#> # A tibble: 2 x 1
#>   gender
#> *  <int>
#> 1    601
#> 2    554

drill_options(dc)
#> # A tibble: 124 x 4
#>                                              name value   type    kind
#>  *                                          <chr> <chr>  <chr>   <chr>
#>  1                 planner.enable_hash_single_key  TRUE SYSTEM BOOLEAN
#>  2      store.parquet.reader.pagereader.queuesize     2 SYSTEM    LONG
#>  3             planner.enable_limit0_optimization FALSE SYSTEM BOOLEAN
#>  4              store.json.read_numbers_as_double FALSE SYSTEM BOOLEAN
#>  5                planner.enable_constant_folding  TRUE SYSTEM BOOLEAN
#>  6                      store.json.extended_types FALSE SYSTEM BOOLEAN
#>  7   planner.memory.non_blocking_operators_memory    64 SYSTEM    LONG
#>  8                  planner.enable_multiphase_agg  TRUE SYSTEM BOOLEAN
#>  9                  exec.query_profile.debug_mode FALSE SYSTEM BOOLEAN
#> 10 planner.filter.max_selectivity_estimate_factor     1 SYSTEM  DOUBLE
#> # ... with 114 more rows

drill_options(dc, "json")
#> # A tibble: 7 x 4
#>                                                    name value   type    kind
#>                                                   <chr> <chr>  <chr>   <chr>
#> 1                     store.json.read_numbers_as_double FALSE SYSTEM BOOLEAN
#> 2                             store.json.extended_types FALSE SYSTEM BOOLEAN
#> 3                              store.json.writer.uglify FALSE SYSTEM BOOLEAN
#> 4                store.json.reader.skip_invalid_records FALSE SYSTEM BOOLEAN
#> 5 store.json.reader.print_skipped_invalid_record_number FALSE SYSTEM BOOLEAN
#> 6                              store.json.all_text_mode FALSE SYSTEM BOOLEAN
#> 7                    store.json.writer.skip_null_fields  TRUE SYSTEM BOOLEAN
```

Working with parquet files
--------------------------

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nation.parquet` LIMIT 5")
#> Parsed with column specification:
#> cols(
#>   N_COMMENT = col_character(),
#>   N_NAME = col_character(),
#>   N_NATIONKEY = col_integer(),
#>   N_REGIONKEY = col_integer()
#> )
#> # A tibble: 5 x 4
#>              N_COMMENT    N_NAME N_NATIONKEY N_REGIONKEY
#> *                <chr>     <chr>       <int>       <int>
#> 1  haggle. carefully f   ALGERIA           0           0
#> 2 al foxes promise sly ARGENTINA           1           1
#> 3 y alongside of the p    BRAZIL           2           1
#> 4 eas hang ironic, sil    CANADA           3           1
#> 5 y above the carefull     EGYPT           4           4
```

Including multiple parquet files in different directories (note the wildcard support):

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nations*/nations*.parquet` LIMIT 5")
#> Parsed with column specification:
#> cols(
#>   N_COMMENT = col_character(),
#>   N_NAME = col_character(),
#>   N_NATIONKEY = col_integer(),
#>   N_REGIONKEY = col_integer(),
#>   dir0 = col_character()
#> )
#> # A tibble: 5 x 5
#>              N_COMMENT    N_NAME N_NATIONKEY N_REGIONKEY      dir0
#> *                <chr>     <chr>       <int>       <int>     <chr>
#> 1  haggle. carefully f   ALGERIA           0           0 nationsSF
#> 2 al foxes promise sly ARGENTINA           1           1 nationsSF
#> 3 y alongside of the p    BRAZIL           2           1 nationsSF
#> 4 eas hang ironic, sil    CANADA           3           1 nationsSF
#> 5 y above the carefull     EGYPT           4           4 nationsSF
```

### A preview of the built-in support for spatial ops

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
#> Parsed with column specification:
#> cols(
#>   city = col_character(),
#>   lon = col_double(),
#>   lat = col_double()
#> )
#> # A tibble: 7 x 3
#>          city       lon      lat
#> *       <chr>     <dbl>    <dbl>
#> 1     Burbank -121.9316 37.32328
#> 2    San Jose -121.8950 37.33939
#> 3        Lick -121.8458 37.28716
#> 4 Willow Glen -121.8897 37.30855
#> 5 Buena Vista -121.9166 37.32133
#> 6    Parkmoor -121.9308 37.32105
#> 7   Fruitdale -121.9327 37.31086
```

### JDBC

``` r
library(RJDBC)
#> Loading required package: rJava

# Use this if connecting to a cluster with zookeeper
# con <- drill_jdbc("drill-node:2181", "drillbits1") 

# Use the following if running drill-embedded
```

``` r
con <- drill_jdbc("localhost:31010", use_zk=FALSE)
```

    #> Using [jdbc:drill:drillbit=bigd:31010]...

``` r
drill_query(con, "SELECT * FROM cp.`employee.json`")
#> # A tibble: 1,155 x 16
#>    employee_id         full_name first_name last_name position_id         position_title store_id department_id
#>  *       <dbl>             <chr>      <chr>     <chr>       <dbl>                  <chr>    <dbl>         <dbl>
#>  1           1      Sheri Nowmer      Sheri    Nowmer           1              President        0             1
#>  2           2   Derrick Whelply    Derrick   Whelply           2     VP Country Manager        0             1
#>  3           4    Michael Spence    Michael    Spence           2     VP Country Manager        0             1
#>  4           5    Maya Gutierrez       Maya Gutierrez           2     VP Country Manager        0             1
#>  5           6   Roberta Damstra    Roberta   Damstra           3 VP Information Systems        0             2
#>  6           7  Rebecca Kanagaki    Rebecca  Kanagaki           4     VP Human Resources        0             3
#>  7           8       Kim Brunner        Kim   Brunner          11          Store Manager        9            11
#>  8           9   Brenda Blumberg     Brenda  Blumberg          11          Store Manager       21            11
#>  9          10      Darren Stanz     Darren     Stanz           5             VP Finance        0             5
#> 10          11 Jonathan Murraiin   Jonathan  Murraiin          11          Store Manager        1            11
#> # ... with 1,145 more rows, and 8 more variables: birth_date <chr>, hire_date <chr>, salary <dbl>, supervisor_id <dbl>,
#> #   education_level <chr>, marital_status <chr>, gender <chr>, management_role <chr>

# but it can work via JDBC function calls, too
dbGetQuery(con, "SELECT * FROM cp.`employee.json`") %>% 
  tibble::as_tibble()
#> # A tibble: 1,155 x 16
#>    employee_id         full_name first_name last_name position_id         position_title store_id department_id
#>  *       <dbl>             <chr>      <chr>     <chr>       <dbl>                  <chr>    <dbl>         <dbl>
#>  1           1      Sheri Nowmer      Sheri    Nowmer           1              President        0             1
#>  2           2   Derrick Whelply    Derrick   Whelply           2     VP Country Manager        0             1
#>  3           4    Michael Spence    Michael    Spence           2     VP Country Manager        0             1
#>  4           5    Maya Gutierrez       Maya Gutierrez           2     VP Country Manager        0             1
#>  5           6   Roberta Damstra    Roberta   Damstra           3 VP Information Systems        0             2
#>  6           7  Rebecca Kanagaki    Rebecca  Kanagaki           4     VP Human Resources        0             3
#>  7           8       Kim Brunner        Kim   Brunner          11          Store Manager        9            11
#>  8           9   Brenda Blumberg     Brenda  Blumberg          11          Store Manager       21            11
#>  9          10      Darren Stanz     Darren     Stanz           5             VP Finance        0             5
#> 10          11 Jonathan Murraiin   Jonathan  Murraiin          11          Store Manager        1            11
#> # ... with 1,145 more rows, and 8 more variables: birth_date <chr>, hire_date <chr>, salary <dbl>, supervisor_id <dbl>,
#> #   education_level <chr>, marital_status <chr>, gender <chr>, management_role <chr>
```

### Test Results

``` r
library(sergeant)
library(testthat)
#> 
#> Attaching package: 'testthat'
#> The following object is masked from 'package:dplyr':
#> 
#>     matches

date()
#> [1] "Sun Sep 17 13:31:23 2017"

devtools::test()
#> Loading sergeant
#> Testing sergeant
#> dplyr: ...
#> rest: ................
#> 
#> DONE ===================================================================================================================
```

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
