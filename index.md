# hvtiRtables

[![R package
version](https://img.shields.io/github/r-package/v/ehrlinger/hvtiRtables)](https://github.com/ehrlinger/hvtiRtables)

[![lint](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml/badge.svg)](https://github.com/ehrlinger/hvtiRtables/actions/workflows/lint.yaml)

Full reference documentation and worked examples:
[ehrlinger.github.io/hvtiRtables](https://ehrlinger.github.io/hvtiRtables/)

You already know the drill: hand-copy a `gtsummary` table into a Word
template, or run it through the SAS table macro, and by the third
revision a footnote wording has drifted, a header has re-merged itself,
or the font quietly changed. hvtiRtables closes that gap. Give it a
`gtsummary` table object and you get back a `.docx` that already matches
HVTI CORR’s “Table Construction for Manuscripts” rules (house font and
rounding, footnotes and an abbreviation key as text below the table, no
hidden spacer columns), the same way every time.

Two house styles exist because two audiences want different things from
the same header row. Most CORR reports and manuscripts use a flat,
single header row
([`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md));
a JTCVS submission wants the traditional two-row spanning header instead
([`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)).
Use whichever matches where the table is headed.

## Installation

hvtiRtables is part of the HVTI R family. Install it with the rest of
the family through [hvtiR](https://github.com/ehrlinger/hvtiR):

``` r

# install.packages("pak")
pak::pak("ehrlinger/hvtiR")
hvtiR::install()
```

`hvtiR::install()` installs every member in one call, so the versions
the members require of one another resolve together. Update later with
`hvtiR::update()`, from a fresh R session: it will not overwrite a
package that is already loaded.

To install hvtiRtables on its own:

``` r

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

## JTCVS submission format

When you’re submitting to JTCVS, use
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
/
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
instead of
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
/
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).
This is not a drop-in swap: the JTCVS pair requires a `groups` argument
naming each `stat_<k>` column (no default), requires the table’s
statistic to follow the `{N_nonmiss} ||| {stat}` convention, and
requires a `caption` string at save time. The merged spanning header and
lettered footnotes match the journal’s own submission template, so once
those three things are supplied you’re not hand-reformatting the table a
second time after the flat-header version is already done:

``` r

library(gtsummary)
library(hvtiRtables)

tbl <- trial |>
  tbl_summary(
    by = trt,
    statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean}±{sd}"),
    include = c(age, grade)
  )

ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
)
hv_man_table_save_jtcvs(ft, "table1.docx", caption = "Table 1. Baseline Characteristics")
```

## Migrating from the `%summarytable` SAS macro

`%summarytable` computes the table and writes the document in one call.
This package splits that into stages, so the parameters you know are
spread across separate calls:

| Stage | Function | Macro parameters |
|----|----|----|
| Compute | [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md) | `CLASS=`, `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=`, `TOTALCOL=` |
| Shape | [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md) / [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md) | *(none - house style is fixed)* |
| Write | `hv_man_table_save*()` | `RTFFILE=`, `ADDFN=`, `TBLTITLE=` (JTCVS only) |
| Verify | [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md) | *(no analogue)* |

The one thing worth knowing before you start: `CON1=` variables change
statistic by default. The macro reported them as mean +/- SD with
one-way ANOVA; every continuous variable here defaults to a median with
a non-parametric test, which is the `CON3=` behavior. List a `CON1=`
variable in `normal` as well as `continuous` to get the macro’s mean +/-
SD and ANOVA back. It’s the largest of four defaults that produce
different numbers from a faithful-looking port; the vignette’s “Defaults
that differ” table lists all four.

For CORR tables, the standard dagger footnote follows `continuous_stat`
and `percentiles` automatically through
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
and
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).
A mean table therefore says `No. (%) or Mean±SD`; a table showing both
statistics names both. The `(%)` lives there and in the JTCVS
sub-header, not in the cells, which print `12 (39)` as the SAS macro
does.

Mean±SD cells follow Eugene H. Blackstone’s (EHB’s) paired rounding
rule. The mean is rounded to the SD’s first-significant-digit place and
the SD one place finer; an SD beginning with 1 gives both one additional
place. Exact ties round to even, and so do those of medians and
percentiles (62.5 shows as 62, where gtsummary and SAS showed 63).
Medians and percentiles follow the house notation instead: brackets, 2
significant digits, and a value of 10 or more to the units place
(`102 [63, 170]`). P values print without a leading zero (`.013`,
`<.001`). A table that mixes mean and median marks the cells of the
statistic fewer rows use (`§` on medians, `¶` on means), with a note for
each.

Full parameter map, the four defaults that differ, and the `QNTLDEF`
quantile trap: **[Porting a `%summarytable` program to
R](https://ehrlinger.github.io/hvtiRtables/articles/sas-migration.html)**.
