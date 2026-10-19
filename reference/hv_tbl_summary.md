# Build a gtsummary table from a SAS %summarytable-style grouped variable list

Thin wrapper over
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
modeled on the interface biostats team members already know from the
`%summarytable` SAS macro: a grouped, ordered variable list (`groups`,
the macro's `LIST=` equivalent) and variable-type buckets
(`continuous`/`binary`/ `categorical`, the `CON3=`/`CAT1=`/`CAT2=`
equivalents), rather than gtsummary's own tidyselect-based interface.
Returns a plain `gtsummary` object, ready for
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
or
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
  percentiles = c(15, 85),
  overall = TRUE,
  continuous_stat = c("median", "mean", "both"),
  normal = character(0),
  mean_sd = character(0),
  show_variable = TRUE,
  cutexact = "any",
  ...
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

  Character vector of continuous variable names (`%summarytable` `CON3=`
  equivalent), summarized as set by `continuous_stat`. Variables the
  macro classified as `CON1=` (mean +/- SD, one-way ANOVA) or `CON2=`
  (median with min and max) belong here too; list `CON1=` variables in
  `normal` as well to keep the macro's mean +/- SD and ANOVA. Each named
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
  groups. `%summarytable` `PVALUES=` equivalent, and `ASD=` only in
  part: the `"smd"` number is gtsummary's generic standardized mean
  difference
  ([`gtsummary::add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)),
  a proportion computed alike for every continuous variable.
  `%summarytable`'s column came from the `%stddiff` macro, which treats
  non-Gaussian and ordinal variables differently and prints a
  percentage, so the two disagree for those variables (by 30% on one
  skewed test variable). To show `%stddiff`'s number, compute it with
  `hvtiRpropensity::ps_stddiff()` and add it with
  [`hv_tbl_compare()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_compare.md),
  beside `compare = "pvalue"` if wanted.

- percentiles:

  Numeric vector of length 2, the low/high percentile pair for
  continuous summaries, as increasing whole numbers between 0 and 100.
  Default `c(15, 85)`, the
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  house convention (`%summarytable` `PP=` equivalent).

- overall:

  Single `TRUE`/`FALSE`. When `TRUE` (default), prepends an Overall
  column across all groups (`%summarytable` `TOTALCOL=1`, the macro's
  default). Ignored when `by` is `NULL`, since the single column already
  is the overall one.
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  lays out only the columns its `groups` argument names, so name
  `stat_0` there to show it.

- continuous_stat:

  One of `"median"` (default), `"mean"`, or `"both"`: how continuous
  variables not listed in `normal` are summarized. `"median"` gives
  `median [P<low>, P<high>]`; `"mean"` gives mean +/- SD, with no spaces
  around the plus-minus sign and EHB/Blackstone paired rounding;
  `"both"` puts the two side by side: each group's statistic column
  shows mean +/- SD (or `n (%)` for a categorical row), and a median
  column beside it shows `median [P<low>, P<high>]`, blank on rows with
  no median. Both renderers lay it out the same way. Choosing one for
  the manuscript is then a matter of dropping a column. The test does
  not change with the statistic: only `normal` selects ANOVA. The CORR
  footnote carried through
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  to
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  follows this choice automatically. Placed after `overall` so calls
  passing `overall` by position keep working.

- normal:

  Character vector, a subset of `continuous`: the variables to treat as
  normally distributed (`%summarytable` `CON1=` equivalent). Each is
  summarized as mean +/- SD whatever `continuous_stat` says, and, under
  `compare = "pvalue"` or `"both"`, tested with classical
  (pooled-variance) one-way ANOVA, the test the macro ran. Default none.
  Each name must also appear in `continuous`. Placed after
  `continuous_stat` so positional calls keep working. To show mean +/-
  SD without the ANOVA, use `mean_sd`.

- mean_sd:

  Character vector, a subset of `continuous`: the variables to *display*
  as mean +/- SD while keeping the nonparametric test (Wilcoxon
  rank-sum, or Kruskal-Wallis for 3+ groups). Use it for variables that
  are roughly symmetric in a table whose every continuous test should
  stay nonparametric. The display is the same as for `normal`, cell mark
  included when the table mixes statistics; only `normal` changes the
  test. A variable may appear in both, and is then tested with ANOVA.
  Default none. Last in the signature so positional calls keep working.

- show_variable:

  Single `TRUE`/`FALSE`. When `TRUE` (default), adds a "Variable" column
  beside the label holding each variable's column name in `data`, on its
  first row, as `%summarytable`'s report did. It belongs to the report
  view:
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
  show it, while
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  always drop it and
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  never shows it, so a saved or JTCVS table is a manuscript table
  whatever this says. Set `FALSE` to leave it out of the report view
  too.

- cutexact:

  When a binary or categorical variable is tested with Fisher's exact
  test rather than Pearson's chi-square (no continuity correction). The
  default, `"any"`, uses Fisher whenever any one group-by-level cell has
  an expected count below 5 (gtsummary's rule, and what the CORR team
  asked for). A number opts in to `%summarytable`'s `CUTEXACT=` rule, to
  reproduce a SAS table: Fisher when at least that percentage of cells
  expect fewer than 5. The macro's default was `50`; `0` makes every
  categorical test exact and a value above 100 makes none exact. In the
  CORR table each Fisher p-value is marked with a superscript double
  dagger, footnoted "Fisher exact test."; the JTCVS route letters it
  through
  [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md).
  Used only when `compare` produces p-values. The other tests that ran
  are named in the dagger note instead, as "P values from the Wilcoxon
  rank sum test and Pearson's chi-square test.", and the CORR table puts
  the dagger on the p-value header too. `compare = "smd"` or `"both"`
  names the difference column "Std. Diff." and the same note says what
  it is.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

A `gtsummary` object, ready for
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
or
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).
See Details for the `hv_stat_label`, `hv_trailing`, and `hv_footnotes`
renderer attributes. A table whose rows mix mean and median also carries
`hv_cell_marks`, a list with `symbol` (`"§"` or `"¶"`) and `variables`
(the names whose cells carry it); the attribute is `NULL` otherwise. The
manuscript style also reads `hv_by_label`, the grouping's name (the
variable's label when the data carry one), and the hidden `hv_n` column
of `table_body`, each variable's overall non-missing count.

## Details

Continuous variables are summarized as `median [P<low>, P<high>]` by
default, or as mean +/- SD, or both (`continuous_stat`), and tested
non-parametrically (Wilcoxon rank-sum for 2 groups, Kruskal-Wallis for
3+), the macro's `CON3=`. A variable you also list in `normal` is the
macro's `CON1=` instead: mean +/- SD, tested with one-way ANOVA.
`percentiles` defaults to the house convention documented in
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
(15th/85th), overridable per study (`%summarytable` equivalent: `PP=`).

The house notation: each median and percentile is shown to 2 significant
digits, and a value of 10 or more to the units place (`102 [63, 170]`,
`0.31 [0.21, 0.39]`), and a P value has no leading zero (`.013`,
`<.001`, `>.9`).

When rows of one table show different statistics, the header and dagger
name the statistic most rows use, and the cells of the other are marked
instead of the row labels (the macro's `DESCLABEL=1` suffixes, such as
`"Age, Mean±SD"`, are gone). When more rows show mean +/- SD than a
median, the mean is the default and a section sign (`§`) marks the
median cells; otherwise a pilcrow (`¶`) marks the mean cells. Each mark
has its own footnote. A tie leaves the median as the default.

Mean/SD output follows Eugene H. Blackstone's (EHB's) paired reporting
rule: the mean is rounded to the first-significant-digit place of the
SD, and the SD is rounded one place finer. When the SD begins with 1,
both retain one additional place. Exact ties round to even; values
beyond a tie round up. This applies to every group and Overall column
when `continuous_stat = "mean"`, and to the mean row under `"both"`.
Medians and percentiles follow the house notation above instead, and
their exact ties also round to even, as for mean +/- SD: 62.5 shows as
62, where gtsummary and SAS showed 63. When an SD is zero or
unavailable, no paired precision can be inferred, so gtsummary's
existing display is kept.

The returned object carries these renderer attributes: `hv_stat_label`,
the sub-header text naming the statistics shown
(`"No. (%) or Median [<low>, <high> percentiles]"` by default, with
ordinal suffixes; it follows `continuous_stat`); `hv_trailing`, a named
character vector ready to pass as
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)'s
`trailing` argument when `compare` produced a comparison column (`NULL`
when `compare = "none"`); and `hv_footnotes`, the CORR footnote block
that
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
carries into
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
so the default dagger follows `continuous_stat` and `percentiles`
automatically. A mixed table also carries `hv_cell_marks`, the symbol
and variables whose cells
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
marks, and a table built with `continuous_stat = "both"` carries
`hv_median_label`.

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

**The Overall column is missing from the JTCVS table.**
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
lays out only the columns its `groups` argument names, and
`overall = TRUE` is the default. Add `stat_0 = "Overall (n=<N>)"` to
`groups`.

**"`by` must not also be listed in `groups`."** `by` is the grouping
variable being compared across, not a row to summarize. Before this
check existed, the combination reached `gtsummary` and failed several
calls later with "`names` must be `NULL` or a character vector, not an
empty integer vector.", a message that never mentioned `by`. Remove the
variable from `groups`.

## See also

[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
or
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
