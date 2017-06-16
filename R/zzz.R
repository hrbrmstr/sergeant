.onLoad <- function(libname, pkgname) {
  if (requireNamespace("rJava")) rJava::.jpackage(pkgname, lib.loc = libname)
}
