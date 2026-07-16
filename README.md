
# hvtiRtables

<!-- badges: start -->
[![R package version](https://img.shields.io/github/r-package/v/ehrlinger/hvtiRtables)](https://github.com/ehrlinger/hvtiRtables)
[![R-CMD-check](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiRtables/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiRtables)
<!-- badges: end -->

You already know the drill: hand-copy a `gtsummary` table into a Word
template, or run it through the SAS table macro, and by the third revision
a footnote wording has drifted, a header has re-merged itself, or the font
quietly changed. hvtiRtables closes that gap. Give it a `gtsummary` table
object and you get back a `.docx` that already matches HVTI CORR's
"Table Construction for Manuscripts" rules (house font and rounding,
footnotes and an abbreviation key as text below the table, no hidden
spacer columns), the same way every time.

Two house styles exist because two audiences want different things from
the same header row. Most CORR reports and manuscripts use a flat, single
header row (`hv_man_table()`); a JTCVS submission wants the traditional
two-row spanning header instead (`hv_man_table_jtcvs()`). Use whichever
matches where the table is headed.

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
ft <- hv_man_table(tbl)
hv_man_table_save(ft, "table1.docx")
```

## JTCVS submission format

When you're submitting to JTCVS, swap in `hv_man_table_jtcvs()` /
`hv_man_table_save_jtcvs()` for `hv_man_table()` / `hv_man_table_save()`.
The merged spanning header and lettered footnotes match the journal's own
submission template, so you're not hand-reformatting the table a second
time after the flat-header version is already done:

``` r
library(gtsummary)
library(hvtiRtables)

tbl <- trial |>
  tbl_summary(
    by = trt,
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    include = c(age, grade)
  )

ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
)
hv_man_table_save_jtcvs(ft, "table1.docx", caption = "Table 1. Baseline Characteristics")
```

