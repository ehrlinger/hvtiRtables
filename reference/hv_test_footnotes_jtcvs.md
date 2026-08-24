# Build lettered test footnotes from a gtsummary table

Reproduces the macro's lettered test footnotes. The letters differ by
design: `%summarytable` emitted `a=ANOVA` for `CON1=` variables, and
this package tests every continuous variable non-parametrically, so
ANOVA never appears.

## Usage

``` r
hv_test_footnotes_jtcvs(tbl)
```

## Arguments

- tbl:

  A `gtsummary` object, normally from
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md).
  Must be the same object passed to
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
  since the row indices are computed from its `table_body`.

## Value

A list of `list(row =, col =, text =)` entries, one per distinct test,
ready to pass as
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)'s
`footnotes` argument. [`list()`](https://rdrr.io/r/base/list.html) when
there is nothing to mark.

## Details

The SAS `%summarytable` macro marks every p-value with a superscript
letter naming the test behind it. This builds those footnotes from the
`test_name` column
[`gtsummary::add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)
records, in the format
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)'s
`footnotes` argument expects, so you do not have to map test identifiers
or count body rows by hand.

Takes the `gtsummary` object rather than the `flextable`, because
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
discards `test_name` when it reshapes the body. The returned `row`
indices are rendered body rows, counting the section-header rows
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
interleaves, and are therefore valid only against that renderer's
output.

Letters follow a fixed order (Wilcoxon, Kruskal-Wallis, chi-square,
Fisher), filtered to the tests actually used, so two tables in the same
manuscript that use the same tests get the same letters regardless of
variable order. Every row sharing a test collapses onto one letter.

Returns an empty list when there is nothing to mark: `by = NULL`,
`compare = "none"`, or `compare = "smd"`, since a standardized
difference is not a test. An empty list concatenates and renders
harmlessly, so no conditional is needed at the call site.

With `compare = "both"` the cell reads e.g. `0.7 (SMD -0.03)` and the
letter marks the p-value portion of it. Note also that
[`gtsummary::add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
requires exactly two groups, so `compare = "smd"` and `compare = "both"`
are unavailable for a 3-group table; `compare = "pvalue"` is.

An unrecognized `test_name` (only reachable from a hand-built object
that passed `add_p(test = ...)`, since
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
never sets `test`) is kept, using the raw identifier as its footnote
text, and warned about. A marked cell whose letter has no definition
would be worse than an unpolished label.

## Common mistakes

**"`tbl` must be a gtsummary table object."** You passed the
`flextable`. This needs the `gtsummary` object, because
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
drops the `test_name` column when it reshapes the body – by render time
the test identities are gone. Pass the same object you passed to the
renderer.

**An empty list back, and no footnotes in the document.** Expected, not
a failure: nothing is marked when `by = NULL`, `compare = "none"`, or
`compare = "smd"`, since a standardized difference names no test. An
empty list concatenates and renders harmlessly, so the call site needs
no conditional.

**Row indices that land on the wrong rows.** They are computed from
`tbl$table_body` at the moment you call this, and they count the
section-header rows
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
interleaves, so they are valid against that renderer's output and
nothing else. Finish the table first and call this last.

**Passing the result to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).**
This is the JTCVS shape. The CORR saver takes a symbol-keyed list and
rejects it; its equivalent is
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md).

## See also

[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md),
which renders the result.
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
which produces a suitable `tbl`.
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
for the house-universal footnotes, which are CORR-shaped and belong to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
not to this function's JTCVS output.

## Examples

``` r
set.seed(5)
dta <- data.frame(
  grp = factor(rep(c("A", "B"), each = 50)),
  age = rnorm(100, 60, 12),
  sex = factor(sample(c("F", "M"), 100, replace = TRUE))
)
tbl <- hv_tbl_summary(
  dta, by = "grp",
  groups = list(Demography = c("age", "sex")),
  continuous = "age", categorical = "sex"
)
hv_test_footnotes_jtcvs(tbl)
#> [[1]]
#> [[1]]$row
#> [1] 2
#> 
#> [[1]]$col
#> [1] "hv_compare_col"
#> 
#> [[1]]$text
#> [1] "Wilcoxon rank-sum test."
#> 
#> 
#> [[2]]
#> [[2]]$row
#> [1] 3
#> 
#> [[2]]$col
#> [1] "hv_compare_col"
#> 
#> [[2]]$text
#> [1] "Pearson chi-square test."
#> 
#> 
```
