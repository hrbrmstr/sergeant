## Test environments
* local OS X install, R 3.4.1
* local ubuntu 14.04 install, R 3.4.1
* ubuntu 12.04 (on travis-ci), R 3.4.1 and oldrel
* win-builder

## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Reverse dependencies

This is a new release, so there are no reverse dependencies.

---

* WinBuilder and R-hub both are reporting httr and covr are not available so 
  I have not been able to get it to work successfully on those platforms as 
  a result of these errors which have nothing to do with the package
  configuration.

* The examples and tests are wrapped in \dontrun{} or testthat:::skip_on_cran()
  since they absolutely require a running Apache Drill server. Full tests
  are run on Travis (weekly, now) with results avaialble for review:
  https://travis-ci.org/hrbrmstr/sergeant
  
  The Travis tests install Apache Drill and test out the REST API calls
  as well as the dplyr/dbplyr interface with live queries.
  
* Code coverage is run and is currently at 40%
