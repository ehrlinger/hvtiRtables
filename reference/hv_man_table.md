# Convert a gtsummary table into a flextable matching HVTI CORR's table rules

You give this a
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
(or any gtsummary table object supporting
[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)),
and you get back a `flextable` that already complies with HVTI CORR's
"Table Construction for Manuscripts" rules: a single, non-merged header
row (no spanning parent cells over grouped columns), no merged row-group
section-header cells, and Times New Roman at the house font size.

## Usage

``` r
hv_man_table(tbl, font = "Times New Roman", font_size = 12, digits = 2)
```

## Arguments

- tbl:

  A `gtsummary` table object (must support
  [`as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)).

- font:

  Font family. Default `"Times New Roman"` (house rule). Any single
  non-empty string is accepted: `flextable` silently substitutes an
  unknown font name, so a typo would otherwise pass unnoticed, while a
  deliberate override is legitimate.

- font_size:

  Font size in points. Default `12`; pass `11` for wide tables, per
  house rule 5. No other values are permitted.

- digits:

  Kept for interface symmetry with future callers; currently unused
  (rounding is controlled upstream via `tbl_summary(digits = ...)`).
  Reserved so a future version can enforce sig-fig rounding centrally
  without a breaking signature change.

## Value

A `flextable` object with a single header row and no merged cells, ready
for
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).

## Details

[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)
already emits one header row per group with self-contained labels (e.g.
`"B\nN = 45"`), not a merged spanning header. The one remaining merge, a
full-width `gridSpan` on the `modify_table_body(groupname_col = ...)`
section-header row, gets removed with
[`flextable::merge_none()`](https://davidgohel.github.io/flextable/reference/merge_none.html),
which un-merges every merged region back into individual cells (content
stays in the top-left cell of the former merge; the rest become empty).
That satisfies the "format the table as flat as possible ... simple
non-merged column titles" rule.

Rounding, `%`-free percentage cells, and `±`-without-spaces formatting
are yours to control, via the `statistic`/`digits` arguments to
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html);
see the package README for a worked example using
[`gtsummary::style_sigfig()`](https://www.danieldsjoberg.com/gtsummary/reference/style_sigfig.html)
for 2-significant-figure rounding.

Submitting to JTCVS instead? Use
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
which builds the two-row merged spanning header that journal's template
expects: CORR house style and JTCVS submission format want different
things from the same header row.

## See also

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
to write the result to a compliant `.docx` with footnotes and an
abbreviation key.
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
for the JTCVS submission format instead.

## Examples

``` r
library(gtsummary)
tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
ft <- hv_man_table(tbl)
```
