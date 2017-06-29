#' Drill expressions / custom functions `dplyr` translation:
#'
#' - `as.character(x)` : `CAST( x AS CHARACTER )`
#' - `as.date(x)` : `CAST( x AS DATE )`
#' - `as.logical(x)` : `CAST( x AS BOOLEAN) `
#' - `as.numeric(x)` : `CAST( x AS DOUBLE )`
#' - `as.posixct(x)` : `CAST( x AS TIMESTAMP )`
#' - `binary_string(x)` : `BINARY_STRING( x )`
#' - `cbrt(x)` : `CBRT( x )`
#' - `char_to_timestamp(x, y)` : `TO_TIMESTAMP( x, y )`
#' - `grepl(y, x)` : `CONTAINS( x, y )`
#' - `contains(x, y)` : `CONTAINS( x, y )`
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
#' - `double_to_timestamp(x)` = `TO_TIMESTAMP( x )`
#' - `char_length(x)` = `CHAR_LENGTH( x )`
#' - `flatten(x)` = `FLATTEN( x )`
#' - `kvgen(x)` = `KVGEN( x )`
#' - `repeated_count(x)` = `REPEATED_COUNT( x )`
#' - `repeated_contains(x)` = `REPEATED_CONTAINS( x )`
#' - `ilike(x, y)` = `ILIKE( x, y )`
#' - `init_cap(x)` = `INIT_CAP( x )`
#' - `length(x)` = `LENGTH( x )`
#' - `lower(x)` = `LOWER( x )`
#' - `tolower(x)` = `LOWER( x )`
#' - `ltrim(x, y)` = `LTRIM( x, y )`
#' - `nullif(x, y` = `NULLIF( x, y )`
#' - `position(x, y)` = `POSITION( x IN  y )`
#' - `gsub(x, y, z)` = `REGEXP_REPLACE( z, x, y )`
#' - `regexp_replace(x, y, z)` = `REGEXP_REPLACE( x, y, z )`
#' - `rtrim(x, y)` = `RTRIM( x, y )`
#' - `rpad(x, y)` = `RPAD( x, y )`
#' - `rpad_with(x, y, z)` = `RPAD( x, y, z )`
#' - `lpad(x, y)` = `LPAD( x, y )`
#' - `lpad_with(x, y, z)` = `LPAD( x, y, z )`
#' - `strpos(x, y)` = `STRPOS( x, y )`
#' - `substr(x, y, z)` = `SUBSTR( x, y, z )`
#' - `upper(x)` = `UPPER(1)`
#' - `toupper(x)` = `UPPER(1)`
#'
#' @md
#' @name drill_custom_functions
NULL


