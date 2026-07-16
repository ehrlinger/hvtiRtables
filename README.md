
# hvtiRtables

<!-- badges: start -->
[![R package version](https://img.shields.io/github/r-package/v/ehrlinger/hvtiRtables)](https://github.com/ehrlinger/hvtiRtables)
[![R-CMD-check](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiRtables/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiRtables)
<!-- badges: end -->

hvtiRtables turns `gtsummary` table objects into MS Word tables complying
with HVTI CORR manuscript table-construction rules: flat (non-merged)
headers, no hidden spacer columns, footnotes and abbreviation keys as text
below the table, house font and rounding conventions.

## Installation

You can install the development version of hvtiRtables from
[GitHub](https://github.com/ehrlinger/hvtiRtables) with:

``` r
remotes::install_github("ehrlinger/hvtiRtables")
```

## Example

``` r
library(gtsummary)
library(hvtiRtables)

tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
ft <- manuscript_flextable(tbl)
save_manuscript_table(ft, "table1.docx")
```

