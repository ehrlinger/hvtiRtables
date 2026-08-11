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
  `list(Demography = c("age", "female"), Symptoms = c("nyha"))`. Each
  section must name at least one variable; a section holding
  `character(0)` is an error, not an empty section. Every variable named
  here must appear in exactly one of `continuous`, `binary`, or
  `categorical`, and every classified variable must appear in `groups`.

- continuous:

  Character vector of continuous variable names (`%summarytable` `CON1=`
  equivalent), summarized as `median (P<low>, P<high>)`. Each named
  column must be numeric.

- binary:

  Character vector of 0/1 variable names (`%summarytable` `CAT1=`
  equivalent), summarized as `n (%)` on a single row. Each named column
  must have at most 2 distinct non-`NA` values, and must be logical,
  `0`/`1`, or `Yes`/`No` data, so that the "event" the single row counts
  is unambiguous. Anything else belongs in `categorical`, which shows
  every level. The event is the `TRUE`, `1`, or `Yes` side, and is
  stated to `gtsummary` explicitly rather than inferred, so columns read
  from SAS with
  [`haven::read_sas()`](https://haven.tidyverse.org/reference/read_sas.html)
  summarize the same as their plain-vector equivalents.

- categorical:

  Character vector of multi-level variable names (`%summarytable`
  `CAT2=` equivalent), summarized as `n (%)` per level. No type rule
  applies: factors, characters, and small-integer codes are all
  accepted. Ordinal variables belong here too; this function does not
  run a trend test (`%summarytable`'s `ORD1=` distinction is not
  preserved).

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

## Common mistakes

**"`<var>` appears in more than one of `continuous`, `binary`, and
`categorical`."** Each variable is classified exactly once. A 0/1
variable is `binary`; a multi-level factor is `categorical`.

**"`continuous` lists `<var>`, but `<var>` is factor data ..."** The
bucket has to suit the data, not just be free of overlaps. A non-numeric
variable in `continuous` used to reach `gtsummary`, which only
*messages* about it, and produced a complete, correctly styled table
whose every statistic was `NA`.

**"`binary` lists `<var>`, but `<var>` has ..."** `binary` renders one
`n (%)` row, so it takes at most two distinct values and needs an
unambiguous event value: logical, `0`/`1`, or `Yes`/`No`. A three-level
factor, or a two-level one like `F`/`M`, belongs in `categorical`.

**"Variable(s) in `groups` not classified ..."** Every variable listed
in `groups` also needs a type bucket, and every classified variable
needs to appear in `groups`. The two lists must match.

**"`compare = "smd"` requires exactly two groups."** A standardized mean
difference is defined between two groups. Use `compare = "pvalue"` for
three or more. If `by` is a factor with an unused level,
[`droplevels()`](https://rdrr.io/r/base/droplevels.html) is usually what
you want.

**"`by` must not also be listed in `groups`."** `by` is the grouping
variable being compared across, not a row to summarize. Before this
check existed, the combination reached `gtsummary` and failed several
calls later with "`names` must be `NULL` or a character vector, not an
empty integer vector.", a message that never mentioned `by`. Remove the
variable from `groups`.

## See also

[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
to render the result.
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
for the percentile-footnote house convention.

## Examples

``` r
# A baseline-characteristics table of the kind a study manuscript
# actually carries: demography and disease sections, compared
# across treatment arms.
hv_tbl_summary(
  gtsummary::trial,
  by = "trt",
  groups = list(
    Demography = c("age", "marker"),
    Disease = c("stage", "grade")
  ),
  continuous = c("age", "marker"),
  categorical = c("stage", "grade")
)


  

Characteristic
```
