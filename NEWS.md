# sergeant 0.6.0

- Authentication support for DBI/dplyr and `drill_connection()` pure REST interface

# sergeant 0.5.2

- Make rJava & RJDBC optional (WIP)
- Hack to remove ";" at end of queries sent to `drill_query()`
- Added `dbplyr` windows functions to `sql_translate_env`

# sergeant 0.4.0

- Getting ready for new `dplyr` (thx to Edward Visel)
- Cleaned up roxygen docs so that `src_drill` is exported now.

# sergeant 0.3.2

- Finally got quoting done. I thought I had before but I guess I hadn't.
- Added documnentation for built-in and custom Drill function that are supported.

# sergeant 0.3.1.9000

* fixed `src_drill()` example
* JDBC driver still in github repo but no longer included in pkg builds. See 
  README.md or `drill_jdbc()` help for more information on using the JDBC 
  driver with sergeant.

# sergeant 0.3.0.9000

* New DBI interface (to the REST API)
* dplyr interface now uses the DBI interace to the REST API
* CRAN checks pass besides size (removing JDBC driver in next dev iteration)

# sergeant 0.2.1.9000

* implemented a large subset of Drill SQL Functions <https://drill.apache.org/docs/about-sql-function-examples/>

# sergeant 0.2.0.9000

* experimental alpha dplyr driver

# sergeant 0.1.2.9000

* can pass RJDBC connections made with `drill_jdbc()` to `drill_query()`
* finally enaled `nodes` parameter to be a multi-element character vector as it said
  in the function description

# sergeant 0.1.2.9000

* support embedded drill JDBC connection

# sergeant 0.1.1.9000

* tweaked `drill_query()` and `drill_version()`

# sergeant 0.1.0.9000

* Added JDBC connector and included JDBC driver in the package (for now)
* Changed idiom to piping in a connection object
* Added a `NEWS.md` file to track changes to the package.



