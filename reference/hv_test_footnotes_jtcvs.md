# Deprecated: Build lettered test footnotes from a gtsummary table

**Deprecated.** A table from
`hv_man_table(tbl, style = "manuscript", layout = "describe")` names its
tests in its dagger note and marks Fisher's exact test on its P values,
so it needs no test footnotes. This function warns on every call and
goes in the next release.

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

Reproduces the macro's lettered test footnotes. The letters differ by
design: the macro lettered by test (`a=ANOVA`, `b=Kruskal-Wallis`, ...),
while here letters follow the order the tests appear. One-way ANOVA
appears only for variables listed in
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
`normal`.

The SAS `%summarytable` macro marks every p-value with a superscript
letter naming the test behind it. This builds those footnotes from the
`test_name` column
[`gtsummary::add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)
records, in the format
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)'s
`footnotes` argument expects, so you do not have to map test identifiers
or count body rows by hand.
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
drops the ones a describe table already names itself.

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

With `compare = "both"` the cell reads e.g. `0.7 (-0.03)` and the letter
is appended to the cell, after the SMD. Note also that
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
# Instead of hv_test_footnotes_jtcvs():
tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "grade")),
  continuous = "age", categorical = "grade", compare = "pvalue"
)
ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
attr(ft, "hv_footnotes")[["\u2020"]]
#> [1] "Values are No. (%) or median [15th, 85th percentiles]; P values from the Wilcoxon rank sum test and Pearson's chi-square test."
```
