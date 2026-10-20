
# hvtiRtables

<!-- badges: start -->
[![R-CMD-check](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/ehrlinger/hvtiRtables/graph/badge.svg)](https://app.codecov.io/gh/ehrlinger/hvtiRtables)
[![active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/badges/latest/active.svg)
[![pkgdown](https://github.com/ehrlinger/hvtiRtables/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/pkgdown.yaml)

[![R package version](https://img.shields.io/github/r-package/v/ehrlinger/hvtiRtables)](https://github.com/ehrlinger/hvtiRtables)

[![lint](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml)
<!-- badges: end -->

Full reference documentation and worked examples: [ehrlinger.github.io/hvtiRtables](https://ehrlinger.github.io/hvtiRtables/)

You already know the drill: hand-copy a `gtsummary` table into a Word
template, or run it through the SAS table macro, and by the third revision
a footnote wording has drifted, a header has re-merged itself, or the font
quietly changed. hvtiRtables closes that gap. Give it a `gtsummary` table
object and you get back a `.docx` that already matches HVTI CORR's
"Table Construction for Manuscripts" rules (house font and rounding,
footnotes and an abbreviation key as text below the table, no hidden
spacer columns), the same way every time.

Tables are drawn in a style named by its role. A report table
(`hv_man_table()`) is the working table of an analysis report. A manuscript
table (`hv_man_table(style = "manuscript")`) is what a journal receives,
laid out by what it does: `"compare"` for groups it compares, `"describe"`
for cohorts or repeated measures it describes side by side.
The [Table styles](https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
article draws one table in each and lists what differs.

## Installation

hvtiRtables is part of the HVTI R family. Install it with the rest of
the family through [hvtiR](https://github.com/ehrlinger/hvtiR):

```r
# install.packages("pak")
pak::pak("ehrlinger/hvtiR")
hvtiR::install()
```

`hvtiR::install()` installs every member in one call, so the versions the
members require of one another resolve together. Update later with
`hvtiR::update()`, from a fresh R session: it will not overwrite a package
that is already loaded.

To install hvtiRtables on its own:

```r
pak::pak("ehrlinger/hvtiRtables")
```

## Example

``` r
library(gtsummary)
library(hvtiRtables)

tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
ft <- hv_man_table(tbl)
hv_man_table_save(ft, "table1.docx")
```

For a manuscript submission, build the table with `hv_tbl_summary()`,
which the manuscript style needs, name the style when shaping it, and give
the saver the caption, which that style requires:

``` r
tbl <- hv_tbl_summary(
  trial, by = "trt",
  groups = list(Demography = "age", Disease = c("stage", "grade")),
  continuous = "age", categorical = c("stage", "grade")
)
ft <- hv_man_table(tbl, style = "manuscript")
hv_man_table_save(ft, "table1.docx", caption = "Table 1. Baseline Characteristics")
```

## Describing cohorts side by side

A table that describes separate cohorts, or the same patients at several
times, gives each group its own count. Name the layout:

``` r
ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
hv_man_table_save(ft, "table2.docx", caption = "Table 2. Cohorts")
```

`hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()` and
`hv_test_footnotes_jtcvs()` are deprecated and go in the next release;
their layout is this one.

## Migrating from the `%summarytable` SAS macro

`%summarytable` computes the table and writes the document in one call.
This package splits that into stages, so the parameters you know are
spread across separate calls:

| Stage | Function | Macro parameters |
|---|---|---|
| Compute | `hv_tbl_summary()` | `CLASS=`, `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=`, `TOTALCOL=` |
| Shape | `hv_man_table()` | `STYLE=` is `style =`; `PAGE=` has none (pages are US Letter) |
| Write | `hv_man_table_save*()` | `RTFFILE=`, `ADDFN=`, `TBLTITLE=` (`caption`) |
| Verify | `hv_check_docx()` | *(no analogue)* |

The one thing worth knowing before you start: `CON1=` variables change
statistic by default. The macro reported them as mean +/- SD with one-way
ANOVA; every continuous variable here defaults to a median with a
non-parametric test, which is the `CON3=` behavior. List a `CON1=` variable
in `normal` as well as `continuous` to get the macro's mean +/- SD and
ANOVA back. It's the largest of four defaults that produce different
numbers from a faithful-looking port; the vignette's "Defaults that differ"
table lists all four.

For CORR tables, the standard dagger footnote follows `continuous_stat` and
`percentiles` automatically through `hv_man_table()` and
`hv_man_table_save()`. A mean table therefore says `No. (%) or Mean±SD`; a
table showing both statistics names both. The `(%)` lives there and in the
describe layout's second header row, not in the cells, which print `12 (39)`
as the SAS macro does.

Mean±SD cells follow Eugene H. Blackstone's (EHB's) paired rounding rule.
The mean is rounded to the SD's first-significant-digit place and the SD one
place finer; an SD beginning with 1 gives both one additional place. Exact
ties round to even, and so do those of medians and percentiles (62.5 shows as
62, where gtsummary and SAS showed 63). Medians and percentiles follow the house notation instead:
brackets, 2 significant digits, and a value of 10 or more to the units place
(`102 [63, 170]`). P values print without a leading zero (`.013`, `<.001`). A
table that mixes mean and median marks the cells of the statistic fewer rows use
(`§` on medians, `¶` on means), with a note for each.

Full parameter map, the four defaults that differ, and the `QNTLDEF`
quantile trap: **[Porting a `%summarytable` program to R](https://ehrlinger.github.io/hvtiRtables/articles/sas-migration.html)**.
