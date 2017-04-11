#' Drill expressions / custom functions `dplyr` translation:
#'
#' - `as.character(x)` : `CAST( x AS CHARACTER)`
#' - `as.date(x)` : `CAST( x AS DATE)`
#' - `as.logical(x)` : `CAST( x AS BOOLEAN)`
#' - `as.numeric(x)` : `CAST( x AS DOUBLE)`
#' - `as.posixct(x)` : `CAST( x AS TIMESTAMP)`
#' - `binary_string(x)` : `BINARY_STRING( x )`
#' - `cbrt(x)` : `CBRT( x )`
#' - `char_to_timestamp(x, y)` : `TO_TIMESTAMP( x, y )`
#' - `contains(x, y)` : `CONTAINS  x, y )`
#' - `convert_to(x, y)` : `CONVERT_TO( x, y )`
#' - `convert_from(x, y)` : `CONVERT_FROM( x, y )`
#' - `degrees(x)` : `DEGREES( x )`
#' - `lshift(x, y)` : `DEGREES( x, y )`
#' - `negative(x)` : `NEGATIVE( x )`
#' - `pow(x, y)` : `MOD( x, y )`
#' - `sql_prefix(x, y)` : `POW( x, y )`
#' - `string_binary(x)` : `STRING_BINARY( x )`
#' - `radians(x)` : `RADIANS( x )`
#' - `rshift(x)` : `RSHIFT( x )`
#' - `to_char(x, y)` : `TO_CHAR  x, y )`
#' - `to_date(x, y)` : `TO_DATE( x, y )`
#' - `to_number(x, y)` : `TO_NUMBER( x, y )`
#' - `trunc(x)` : `TRUNC( x )`
#'
#' I'll get these converted into ^^ format:
#'
#' - `double_to_timestamp` = `sql_prefix("TO_TIMESTAMP", 1),`
#' - `char_length` = `sql_prefix("CHAR_LENGTH", 1),`
#' - `flatten` = `sql_prefix("FLATTEN", 1),`
#' - `kvgen` = `sql_prefix("KVGEN", 1),`
#' - `repeated_count` = `sql_prefix("REPEATED_COUNT", 1),`
#' - `repeated_contains` = `sql_prefix("REPEATED_CONTAINS", 1),`
#' - `ilike` = `sql_prefix("ILIKE", 2),`
#' - `init_cap` = `sql_prefix("INIT_CAP", 1),`
#' - `length` = `sql_prefix("LENGTH", 1),`
#' - `lower` = `sql_prefix("LOWER", 1),`
#' - `ltrim` = `sql_prefix("LTRIM", 2),`
#' - `nullif` = `sql_prefix("NULLIF", 2),`
#' - `position` = `function(x, y) build_sql("POSITION(", x, " IN ", y, ")"),`
#' - `regexp_replace` = `sql_prefix("REGEXP_REPLACE", 3),`
#' - `rtrim` = `sql_prefix("RTRIM", 2),`
#' - `rpad` = `sql_prefix("RPAD", 2),`
#' - `rpad_with` = `sql_prefix("RPAD", 3),`
#' - `lpad` = `sql_prefix("LPAD", 2),`
#' - `lpad_with` = `sql_prefix("LPAD", 3),`
#' - `strpos` = `sql_prefix("STRPOS", 2),`
#' - `substr` = `sql_prefix("SUBSTR", 3),`
#' - `trim` = `function(x, y, z) build_sql("TRIM(", x, " ", y, " FROM ", z, ")"),`
#' - `upper` = `sql_prefix("UPPER", 1)`
#'
#' @md
#' @name drill_custom_functions
NULL


