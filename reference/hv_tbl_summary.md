# Build a gtsummary table from a SAS %summarytable-style grouped variable list

Thin wrapper over
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
modeled on the interface biostats team members already know from the
`%summarytable` SAS macro: a grouped, ordered variable list (`groups`,
the macro's `LIST=` equivalent) and variable-type buckets
(`continuous`/`binary`/ `categorical`, the `CON1=`/`CAT1=`/`CAT2=`
equivalents), rather than gtsummary's own tidyselect-based interface.
Returns a plain `gtsummary` object, ready for
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).

## Usage

``` r
hv_tbl_summary(
  data,
  by = NULL,
  groups,
  continuous = character(0),
  binary = character(0),
  categorical = character(0),
  compare = c("pvalue", "smd", "both", "none"),
  percentiles = c(15, 85)
)
```

## Arguments

- data:

  A data frame.

- by:

  Grouping variable name as a string (`%summarytable` `CLASS=`
  equivalent), or `NULL` for a single ungrouped "Overall" column.

- groups:

  Named list, section label -\> variable names in display order
  (`%summarytable` `LIST=` equivalent), e.g.
  `list(Demography = c("age", "female"), Symptoms = c("nyha"))`. Every
  variable named here must appear in exactly one of `continuous`,
  `binary`, or `categorical`, and every classified variable must appear
  in `groups`.

- continuous:

  Character vector of continuous variable names (`%summarytable` `CON1=`
  equivalent), summarized as `median (P<low>, P<high>)`.

- binary:

  Character vector of 0/1 variable names (`%summarytable` `CAT1=`
  equivalent), summarized as `n (%)` on a single row.

- categorical:

  Character vector of multi-level variable names (`%summarytable`
  `CAT2=` equivalent), summarized as `n (%)` per level. Ordinal
  variables belong here too; this function does not run a trend test
  (`%summarytable`'s `ORD1=` distinction is not preserved).

- compare:

  One of `"pvalue"` (default), `"smd"`, `"both"`, or `"none"`. Ignored
  (treated as `"none"`) when `by` is `NULL`, since there is nothing to
  compare. `"smd"` and `"both"` require `by` to have exactly two groups,
  because a standardized mean difference is defined between two of them;
  they error otherwise. `"pvalue"` and `"none"` work at any number of
  groups. `%summarytable` `PVALUES=`/`ASD=` equivalent.

- percentiles:

  Numeric vector of length 2, the low/high percentile pair for
  continuous summaries, as increasing whole numbers between 0 and 100.
  Default `c(15, 85)`, the
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  house convention (`%summarytable` `PP=` equivalent).

## Value

A `gtsummary` object, ready for
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).
See Details for the `hv_stat_label`/`hv_trailing` attributes.

## Details

Every continuous variable is summarized as `median (P<low>, P<high>)`
using a blanket non-parametric test (Wilcoxon rank-sum for 2 groups,
Kruskal-Wallis for 3+) — this function does not classify variables as
Gaussian/non-Gaussian the way `%summarytable` does; that is
[`gtsummary::add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)'s
own default continuous test already. `percentiles` defaults to the house
convention documented in
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
(15th/85th), overridable per study (`%summarytable` equivalent: `PP=`).

The returned object carries two attributes for
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md):
`hv_stat_label`, the percentile-aware sub-header text
(`"No. (%) or Median (<low>th, <high>th percentile)"`), and
`hv_trailing`, a named character vector ready to pass as
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)'s
`trailing` argument when `compare` produced a comparison column (`NULL`
when `compare = "none"`).

## See also

[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
to render the result.
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
for the percentile-footnote house convention.

## Examples

``` r
hv_tbl_summary(
  mtcars,
  groups = list(Engine = c("mpg", "cyl")),
  continuous = "mpg",
  categorical = "cyl"
)


  

Characteristic
```
