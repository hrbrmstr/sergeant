
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Travis-CI Build Status](https://travis-ci.org/hrbrmstr/sergeant.svg?branch=master)](https://travis-ci.org/hrbrmstr/sergeant)

<img src="sergeant.png" width="33" align="left" style="padding-right:20px"/>

`sergeant` : Tools to Transform and Query Data with the 'Apache Drill' 'REST API', JDBC Interface, Plus 'dplyr' and 'DBI' Interfaces

Drill + `sergeant` is (IMO) a nice alternative to Spark + `sparklyr` if you don't need the ML components of Spark (i.e. just need to query "big data" sources, need to interface with parquet, need to combine disperate data source types — json, csv, parquet, rdbms - for aggregation, etc). Drill also has support for spatial queries.

I find writing SQL queries to parquet files with Drill on a local 64GB Linux workstation to be more performant than doing the data ingestion work with R (for large or disperate data sets). I also work with many tiny JSON files on a daily basis and Drill makes it much easier to do so. YMMV.

You can download Drill from <https://drill.apache.org/download/> (use "Direct File Download"). I use `/usr/local/drill` as the install directory. `drill-embedded` is a super-easy way to get started playing with Drill on a single workstation and most of my workflows can get by using Drill this way. If there is sufficient desire for an automated downloader and a way to start the `drill-embedded` server from within R, please file an issue.

There are a few convenience wrappers for various informational SQL queries (like `drill_version()`). Please file an PR if you add more.

The package has been written with retrieval of rectangular data sources in mind. If you need/want a version of `drill_query()` that will enable returning of non-rectangular data (which is possible with Drill) then please file an issue.

Some of the more "controlling vs data ops" REST API functions aren't implemented. Please file a PR if you need those.

Finally, I run most of this locally and at home, so it's all been coded with no authentication or encryption in mind. If you want/need support for that, please file an issue. If there is demand for this, it will change the R API a bit (I've already thought out what to do but have no need for it right now).

The following functions are implemented:

**`DBI`**

-   As complete of an R `DBI` driver has been implmented using the Drill REST API, mostly to facilitate the `dplyr` interface. Use the `RJDBC` driver interface if you need more `DBI` functionality.

***`RJDBC`***

-   `drill_jdbc`: Connect to Drill using JDBC, enabling use of said idioms. See `RJDBC` for more info.
-   NOTE: The DRILL JDBC driver fully-qualified path must be placed in the `DRILL_JDBC_JAR` environment variable. This is best done via `~/.Renviron` for interactive work. i.e. `DRILL_JDBC_JAR=/usr/local/drill/jars/drill-jdbc-all-1.9.0.jar`

**`dplyr`**:

-   `src_drill`: Connect to Drill (using dplyr) + supporting functions

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

ds <- src_drill("drill.local") 
ds
#> src:  Version: 1.9.0; Direct memory: 34,359,738,368 bytes
#> tbls: INFORMATION_SCHEMA, cp.default, dfs.default, dfs.pq, dfs.root, dfs.samsung, dfs.tmp, mongo.local,
#>   my.information_schema, my.mysql, my.performance_schema, my.test, my, sys

db <- tbl(ds, "cp.`employee.json`") 

# without `collect()`:
count(db, gender, marital_status)
#> Source:   query [?? x 3]
#> Database: Version: 1.9.0; Direct memory: 34,359,738,368 bytes
#> Groups: gender
#> 
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
#> Source: local data frame [4 x 3]
#> Groups: gender [2]
#> 
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
#> # A tibble: 30 × 3
#>                     Title Gender Count
#> *                   <chr>  <chr> <int>
#> 1               President Female     1
#> 2      VP Country Manager   Male     3
#> 3      VP Country Manager Female     3
#> 4  VP Information Systems Female     1
#> 5      VP Human Resources Female     1
#> 6           Store Manager Female    13
#> 7              VP Finance   Male     1
#> 8           Store Manager   Male    11
#> 9            HQ Marketing Female     2
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
#> Source:   query [?? x 20]
#> Database: Version: 1.9.0; Direct memory: 34,359,738,368 bytes
#> 
#>    store_id gender department_id birth_date supervisor_id last_name          position_title  hire_date
#>       <int>  <chr>         <int>     <date>         <int>     <chr>                   <chr>     <dttm>
#> 1         8      M            17 1914-02-02           949   Dittmar Store Permanent Stocker 1998-01-01
#> 2         8      F            17 1914-02-02           949   Jantzer Store Permanent Stocker 1998-01-01
#> 3         8      F            17 1914-02-02           949     Sweet Store Permanent Stocker 1998-01-01
#> 4         8      M            17 1914-02-02           949    Murphy Store Permanent Stocker 1998-01-01
#> 5         8      M            17 1914-02-02           948   Lindsay Store Permanent Stocker 1998-01-01
#> 6         8      M            17 1914-02-02           948     Burke Store Permanent Stocker 1998-01-01
#> 7         8      M            17 1914-02-02           948   Bunosky Store Permanent Stocker 1998-01-01
#> 8         8      F            17 1914-02-02           948   Cabrera Store Permanent Stocker 1998-01-01
#> 9         8      F            17 1914-02-02           948     Terry Store Permanent Stocker 1998-01-01
#> 10        8      F            17 1914-02-02           947      Case Store Permanent Stocker 1998-01-01
#> 11        6      F            18 1976-10-05            56     Horne Store Temporary Stocker 1997-01-01
#> 12        8      F            17 1914-02-02           947    Nutter Store Permanent Stocker 1998-01-01
#> 13        8      F            17 1914-02-02           947 Willeford Store Permanent Stocker 1998-01-01
#> 14        8      M            17 1914-02-02           947 Clendenen Store Permanent Stocker 1998-01-01
#> 15        8      F            17 1914-02-02           947      Wall Store Permanent Stocker 1998-01-01
#> 16        8      F            16 1914-02-02           949    Morrow Store Temporary Checker 1998-01-01
#> 17        8      M            16 1914-02-02           949    Wilson Store Temporary Checker 1998-01-01
#> 18        8      F            16 1914-02-02           949    Duncan Store Temporary Checker 1998-01-01
#> 19        8      F            16 1914-02-02           949  Anderson Store Temporary Checker 1998-01-01
#> 20        8      M            16 1914-02-02           949    Watson Store Temporary Checker 1998-01-01
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
#> # A tibble: 112 × 2
#>    supervisor_id underlings_count
#> *          <int>            <int>
#> 1              0                1
#> 2              1                7
#> 3              5                9
#> 4              4                2
#> 5              2                3
#> 6             20                2
#> 7             21                4
#> 8             22                7
#> 9              6                4
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
#> [1] '0.3.0.9000'

dc <- drill_connection("localhost") 

drill_active(dc)
#> [1] TRUE

drill_version(dc)
#> [1] "1.9.0"

drill_storage(dc)$name
#> [1] "cp"    "dfs"   "hbase" "hive"  "kudu"  "mongo" "my"    "s3"
```

Working with the built-in JSON data sets:

``` r
drill_query(dc, "SELECT * FROM cp.`employee.json` limit 100")
#> Parsed with column specification:
#> cols(
#>   .default = col_character(),
#>   store_id = col_integer(),
#>   department_id = col_integer(),
#>   birth_date = col_date(format = ""),
#>   supervisor_id = col_integer(),
#>   hire_date = col_datetime(format = ""),
#>   salary = col_double(),
#>   employee_id = col_integer(),
#>   position_id = col_integer()
#> )
#> See spec(...) for full column specifications.
#> # A tibble: 100 × 20
#>    store_id            fqn gender department_id birth_date supervisor_id last_name         position_title  hire_date
#> *     <int>          <chr>  <chr>         <int>     <date>         <int>     <chr>                  <chr>     <dttm>
#> 1         0 /employee.json      F             1 1961-08-26             0    Nowmer              President 1994-12-01
#> 2         0 /employee.json      M             1 1915-07-03             1   Whelply     VP Country Manager 1994-12-01
#> 3         0 /employee.json      M             1 1969-06-20             1    Spence     VP Country Manager 1998-01-01
#> 4         0 /employee.json      F             1 1951-05-10             1 Gutierrez     VP Country Manager 1998-01-01
#> 5         0 /employee.json      F             2 1942-10-08             1   Damstra VP Information Systems 1994-12-01
#> 6         0 /employee.json      F             3 1949-03-27             1  Kanagaki     VP Human Resources 1994-12-01
#> 7         9 /employee.json      F            11 1922-08-10             5   Brunner          Store Manager 1998-01-01
#> 8        21 /employee.json      F            11 1979-06-23             5  Blumberg          Store Manager 1998-01-01
#> 9         0 /employee.json      M             5 1949-08-26             1     Stanz             VP Finance 1994-12-01
#> 10        1 /employee.json      M            11 1967-06-20             5  Murraiin          Store Manager 1998-01-01
#> # ... with 90 more rows, and 11 more variables: management_role <chr>, suffix <chr>, salary <dbl>,
#> #   marital_status <chr>, filename <chr>, full_name <chr>, filepath <chr>, employee_id <int>, education_level <chr>,
#> #   first_name <chr>, position_id <int>

drill_query(dc, "SELECT COUNT(gender) AS gender FROM cp.`employee.json` GROUP BY gender")
#> Parsed with column specification:
#> cols(
#>   gender = col_integer()
#> )
#> # A tibble: 2 × 1
#>   gender
#> *  <int>
#> 1    601
#> 2    554

drill_options(dc)
#> # A tibble: 105 × 4
#>                                              name value   type    kind
#> *                                           <chr> <chr>  <chr>   <chr>
#> 1                  planner.enable_hash_single_key  TRUE SYSTEM BOOLEAN
#> 2              planner.enable_limit0_optimization FALSE SYSTEM BOOLEAN
#> 3               store.json.read_numbers_as_double FALSE SYSTEM BOOLEAN
#> 4                 planner.enable_constant_folding  TRUE SYSTEM BOOLEAN
#> 5                       store.json.extended_types FALSE SYSTEM BOOLEAN
#> 6    planner.memory.non_blocking_operators_memory    64 SYSTEM    LONG
#> 7                   planner.enable_multiphase_agg  TRUE SYSTEM BOOLEAN
#> 8  planner.filter.max_selectivity_estimate_factor     1 SYSTEM  DOUBLE
#> 9                     planner.enable_mux_exchange  TRUE SYSTEM BOOLEAN
#> 10                   store.parquet.use_new_reader FALSE SYSTEM BOOLEAN
#> # ... with 95 more rows

drill_options(dc, "json")
#> # A tibble: 7 × 4
#>                                                    name value   type    kind
#>                                                   <chr> <chr>  <chr>   <chr>
#> 1                     store.json.read_numbers_as_double FALSE SYSTEM BOOLEAN
#> 2                             store.json.extended_types FALSE SYSTEM BOOLEAN
#> 3                              store.json.writer.uglify  TRUE SYSTEM BOOLEAN
#> 4                store.json.reader.skip_invalid_records  TRUE SYSTEM BOOLEAN
#> 5 store.json.reader.print_skipped_invalid_record_number  TRUE SYSTEM BOOLEAN
#> 6                              store.json.all_text_mode  TRUE SYSTEM BOOLEAN
#> 7                    store.json.writer.skip_null_fields  TRUE SYSTEM BOOLEAN
```

Working with parquet files
--------------------------

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nation.parquet` LIMIT 5")
#> Parsed with column specification:
#> cols(
#>   fqn = col_character(),
#>   filename = col_character(),
#>   N_COMMENT = col_character(),
#>   filepath = col_character(),
#>   N_NAME = col_character(),
#>   N_NATIONKEY = col_integer(),
#>   N_REGIONKEY = col_integer(),
#>   suffix = col_character()
#> )
#> # A tibble: 5 × 8
#>                                           fqn       filename            N_COMMENT                     filepath
#> *                                       <chr>          <chr>                <chr>                        <chr>
#> 1 /usr/local/drill/sample-data/nation.parquet nation.parquet  haggle. carefully f /usr/local/drill/sample-data
#> 2 /usr/local/drill/sample-data/nation.parquet nation.parquet al foxes promise sly /usr/local/drill/sample-data
#> 3 /usr/local/drill/sample-data/nation.parquet nation.parquet y alongside of the p /usr/local/drill/sample-data
#> 4 /usr/local/drill/sample-data/nation.parquet nation.parquet eas hang ironic, sil /usr/local/drill/sample-data
#> 5 /usr/local/drill/sample-data/nation.parquet nation.parquet y above the carefull /usr/local/drill/sample-data
#> # ... with 4 more variables: N_NAME <chr>, N_NATIONKEY <int>, N_REGIONKEY <int>, suffix <chr>
```

Including multiple parquet files in different directories (note the wildcard support):

``` r
drill_query(dc, "SELECT * FROM dfs.`/usr/local/drill/sample-data/nations*/nations*.parquet` LIMIT 5")
#> Parsed with column specification:
#> cols(
#>   fqn = col_character(),
#>   filename = col_character(),
#>   N_COMMENT = col_character(),
#>   filepath = col_character(),
#>   N_NAME = col_character(),
#>   N_NATIONKEY = col_integer(),
#>   N_REGIONKEY = col_integer(),
#>   dir0 = col_character(),
#>   suffix = col_character()
#> )
#> # A tibble: 5 × 9
#>                                                        fqn          filename            N_COMMENT
#> *                                                    <chr>             <chr>                <chr>
#> 1 /usr/local/drill/sample-data/nationsMF/nationsMF.parquet nationsMF.parquet  haggle. carefully f
#> 2 /usr/local/drill/sample-data/nationsMF/nationsMF.parquet nationsMF.parquet al foxes promise sly
#> 3 /usr/local/drill/sample-data/nationsMF/nationsMF.parquet nationsMF.parquet y alongside of the p
#> 4 /usr/local/drill/sample-data/nationsMF/nationsMF.parquet nationsMF.parquet eas hang ironic, sil
#> 5 /usr/local/drill/sample-data/nationsMF/nationsMF.parquet nationsMF.parquet y above the carefull
#> # ... with 6 more variables: filepath <chr>, N_NAME <chr>, N_NATIONKEY <int>, N_REGIONKEY <int>, dir0 <chr>,
#> #   suffix <chr>
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
#>   ITEM = col_character(),
#>   ITEM2 = col_double(),
#>   ITEM1 = col_double()
#> )
#> # A tibble: 7 × 3
#>          ITEM    ITEM2     ITEM1
#> *       <chr>    <dbl>     <dbl>
#> 1     Burbank 37.32328 -121.9316
#> 2    San Jose 37.33939 -121.8950
#> 3        Lick 37.28716 -121.8458
#> 4 Willow Glen 37.30855 -121.8897
#> 5 Buena Vista 37.32133 -121.9166
#> 6    Parkmoor 37.32105 -121.9308
#> 7   Fruitdale 37.31086 -121.9327
```

### JDBC

``` r
library(RJDBC)
#> Loading required package: rJava

con <- drill_jdbc("drill.local:2181", "jla") 
#> Using [jdbc:drill:zk=drill.local:2181/drill/jla]...
# or the following if running drill-embedded
# con <- drill_jdbc("localhost:31010", use_zk=FALSE)

drill_query(con, "SELECT * FROM cp.`employee.json`")
#> # A tibble: 1,155 × 20
#>               fqn      filename filepath suffix employee_id         full_name first_name last_name position_id
#> *           <chr>         <chr>    <chr>  <chr>       <chr>             <chr>      <chr>     <chr>       <chr>
#> 1  /employee.json employee.json        /   json           1      Sheri Nowmer      Sheri    Nowmer           1
#> 2  /employee.json employee.json        /   json           2   Derrick Whelply    Derrick   Whelply           2
#> 3  /employee.json employee.json        /   json           4    Michael Spence    Michael    Spence           2
#> 4  /employee.json employee.json        /   json           5    Maya Gutierrez       Maya Gutierrez           2
#> 5  /employee.json employee.json        /   json           6   Roberta Damstra    Roberta   Damstra           3
#> 6  /employee.json employee.json        /   json           7  Rebecca Kanagaki    Rebecca  Kanagaki           4
#> 7  /employee.json employee.json        /   json           8       Kim Brunner        Kim   Brunner          11
#> 8  /employee.json employee.json        /   json           9   Brenda Blumberg     Brenda  Blumberg          11
#> 9  /employee.json employee.json        /   json          10      Darren Stanz     Darren     Stanz           5
#> 10 /employee.json employee.json        /   json          11 Jonathan Murraiin   Jonathan  Murraiin          11
#> # ... with 1,145 more rows, and 11 more variables: position_title <chr>, store_id <chr>, department_id <chr>,
#> #   birth_date <chr>, hire_date <chr>, salary <chr>, supervisor_id <chr>, education_level <chr>, marital_status <chr>,
#> #   gender <chr>, management_role <chr>

# but it can work via JDBC function calls, too
dbGetQuery(con, "SELECT * FROM cp.`employee.json`") %>% 
  tibble::as_tibble()
#> # A tibble: 1,155 × 20
#>               fqn      filename filepath suffix employee_id         full_name first_name last_name position_id
#> *           <chr>         <chr>    <chr>  <chr>       <chr>             <chr>      <chr>     <chr>       <chr>
#> 1  /employee.json employee.json        /   json           1      Sheri Nowmer      Sheri    Nowmer           1
#> 2  /employee.json employee.json        /   json           2   Derrick Whelply    Derrick   Whelply           2
#> 3  /employee.json employee.json        /   json           4    Michael Spence    Michael    Spence           2
#> 4  /employee.json employee.json        /   json           5    Maya Gutierrez       Maya Gutierrez           2
#> 5  /employee.json employee.json        /   json           6   Roberta Damstra    Roberta   Damstra           3
#> 6  /employee.json employee.json        /   json           7  Rebecca Kanagaki    Rebecca  Kanagaki           4
#> 7  /employee.json employee.json        /   json           8       Kim Brunner        Kim   Brunner          11
#> 8  /employee.json employee.json        /   json           9   Brenda Blumberg     Brenda  Blumberg          11
#> 9  /employee.json employee.json        /   json          10      Darren Stanz     Darren     Stanz           5
#> 10 /employee.json employee.json        /   json          11 Jonathan Murraiin   Jonathan  Murraiin          11
#> # ... with 1,145 more rows, and 11 more variables: position_title <chr>, store_id <chr>, department_id <chr>,
#> #   birth_date <chr>, hire_date <chr>, salary <chr>, supervisor_id <chr>, education_level <chr>, marital_status <chr>,
#> #   gender <chr>, management_role <chr>
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
#> [1] "Sat Dec 31 10:47:44 2016"

test_dir("tests/")
#> testthat results ========================================================================================================
#> OK: 3 SKIPPED: 0 FAILED: 0
#> 
#> DONE ===================================================================================================================
```

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
