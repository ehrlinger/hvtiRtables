# hvtiRtables

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
statistic to follow the `{N_obs} ||| {stat}` convention, and requires a
`caption` string at save time. The merged spanning header and lettered
footnotes match the journal’s own submission template, so once those
three things are supplied you’re not hand-reformatting the table a
second time after the flat-header version is already done:

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
statistic. The macro reported them as mean +/- SD with one-way ANOVA;
every continuous variable here is a median with a non-parametric test,
which is the `CON3=` behavior. It’s the largest of five defaults that
produce different numbers from a faithful-looking port; the vignette’s
“Defaults that differ” table lists all five.

Full parameter map, the five defaults that differ, and the `QNTLDEF`
quantile trap: **[Porting a `%summarytable` program to
R](https://ehrlinger.github.io/hvtiRtables/articles/sas-migration.html)**.
