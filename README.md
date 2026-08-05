
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

## Migrating from the `%summarytable` SAS macro

If you already know `%summarytable`, you give `hv_tbl_summary()` the same
thing you gave the macro: a grouped, ordered variable list (the shape of
the macro's `LIST=` block). You get back a `gtsummary` object you hand
straight to `hv_man_table_jtcvs()`. Two defaults differ from the macro
and are worth knowing up front: we always use a blanket non-parametric
test, so there is no per-variable Gaussian classification to maintain,
and continuous variables report as `median (P15, P85)` rather than
`mean ± SD`.

| `%summarytable` parameter | `hv_tbl_summary()` argument |
|---|---|
| `DATA=` | `data` |
| `CLASS=` | `by` |
| `LIST=` | `groups` |
| `CON1=` | `continuous` |
| `CAT1=` | `binary` |
| `CAT2=` | `categorical` |
| `PVALUES=` / `ASD=` | `compare` |
| `PP=` | `percentiles` |
| `TOTALCOL=` / `NCOL=` | handled automatically |

Not supported in this first pass: `WEIGHT=` (weighted summaries), `PROPENMT=`
(propensity-matched mode), `CON2=`/`CON3=` (Gaussian-classification split,
superseded by the blanket-nonparametric default), `SUBSET=`, `SORTBY=`
(ordering comes directly from `groups`). Ordinal variables (`ORD1=` in the
macro) fold into `categorical` here; no trend test is run.

A real `%summarytable` call, next to its `hv_tbl_summary()` equivalent:

``` sas
%summarytable(data=built,
              class=grp_res,
              con1=&gaussian.,
              cat1=&binary.,
              cat2=&catg.,
              pp=16 84,
              pvalues=1,
              list=
    /* Demography */
       female AGE BSA race_gp

    /* Symptoms */
       surgstat nyha_pr
);
```

``` r
library(gtsummary)
library(hvtiRtables)

tbl <- hv_tbl_summary(
  built,
  by = "grp_res",
  groups = list(
    Demography = c("female", "AGE", "BSA", "race_gp"),
    Symptoms   = c("surgstat", "nyha_pr")
  ),
  continuous  = c("AGE", "BSA"),
  binary      = c("female", "surgstat"),
  categorical = c("race_gp", "nyha_pr"),
  compare     = "pvalue",
  percentiles = c(16, 84)
)
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(
    stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"
  ),
  trailing = attr(tbl, "hv_trailing"),
  stat_label = attr(tbl, "hv_stat_label")
)
hv_man_table_save_jtcvs(
  ft, "table1.docx",
  caption = "Table 1. Baseline Characteristics by Tissue Type"
)
```

