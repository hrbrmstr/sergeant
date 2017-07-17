## Test environments
* local macOS install, R 3.4.1
* local ubuntu 14.04 install, R 3.4.1
* ubuntu 12.04 (on travis-ci), R 3.4.1 and oldrel
* win-builder

## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.

## Reverse dependencies

This is a new release, so there are no reverse dependencies.

---

* WinBuilder seems to be working now (it found httr and covr in the last build).

* Removed png causing WinBuilder pandoc problems.

* R-hub is reporting httr and covr are not available so 
  I have not been able to get it to work successfully on that platform.

* The examples and tests are wrapped in \dontrun{} or testthat:::skip_on_cran()
  since they absolutely require a running Apache Drill server. Full tests
  are run on Travis (weekly) with results avaialble for review:
  https://travis-ci.org/hrbrmstr/sergeant
  
  The Travis tests install Apache Drill and test out the REST API calls
  as well as the dplyr/dbplyr interface with live queries.
  
* Code coverage is run and is currently at 40%
