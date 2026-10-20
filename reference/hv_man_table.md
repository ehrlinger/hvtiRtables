# Convert a gtsummary table into a flextable matching HVTI CORR's table rules

Stage 2 of the `%summarytable` split: shapes the table. The macro
controlled this with `STYLE=` and `PAGE=`. `style =` is the equivalent
of `STYLE=`: tables are drawn in a style named by its role, `"report"`
(the default, described below) or `"manuscript"`. `PAGE=` has none;
pages are US Letter, turning landscape when the table is wide.

## Usage

``` r
hv_man_table(
  tbl,
  font = "Times New Roman",
  font_size = 12,
  digits = 2,
  style = "report",
  layout = "compare",
  ...
)
```

## Arguments

- tbl:

  A `gtsummary` table object (must support
  [`as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)).
  A table from
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  is split as described above; any other `gtsummary` object renders
  as-is.

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

- style:

  A style name, `"report"` (default) or `"manuscript"`, or a style from
  [`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md).
  `"manuscript"` needs an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  table, refuses `font` and `font_size`, and in the compare layout
  refuses `continuous_stat = "both"`.

- layout:

  The manuscript style's layout, chosen by what the table does:
  `"compare"` (default), one overall `n` column for groups it compares,
  or `"describe"`, a count beside each group, for cohorts or repeated
  measures it describes side by side. Either shows an Overall column and
  comparison columns when the table carries them. Only with
  `style = "manuscript"`.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

A `flextable` object, ready for
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).
In the report style it has a single header row and no merged cells; in
the manuscript style a two-row header. Its `hv_style` attribute holds
the style, which the saver and
[`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
read. Input from
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
retains its `hv_footnotes` attribute so the saver's default dagger
follows the table's continuous statistic.

## Details

The `"manuscript"` style lays out a comparison table as the journal
submissions did: a full grid, a two-row header with the grouping's name
spanning its levels, one overall `n` column, shaded section rows that
span the table, a bold header, and no font of its own, so the table
takes the body font of the document it is saved into. It needs a table
from
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
and
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
requires a `caption` for it. See
[`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
for the properties of each style, and the [Table
styles](https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
article, which draws one table in each style and layout beside the
matrix of their properties and says which house rules each style keeps.

The rest of this page describes the `"report"` style.

You give this a
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
(or any gtsummary table object supporting
[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)),
and you get back a `flextable` that already complies with HVTI CORR's
"Table Construction for Manuscripts" rules: a single, non-merged header
row (no spanning parent cells over grouped columns), no merged row-group
section-header cells, a left-justified label column, and Times New Roman
at the house font size. Section rows are shaded across every cell,
unmerged, in the style's fill (`#CAEDFB` by default), and the header is
bold.

[`gtsummary::as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)
already emits one header row per group with self-contained labels (e.g.
`"B\nN = 45"`), not a merged spanning header. Any merged region is
undone with
[`flextable::merge_none()`](https://davidgohel.github.io/flextable/reference/merge_none.html).
That satisfies the "format the table as flat as possible ... simple
non-merged column titles" rule.

The sections of an
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
table (its `groups` names, such as "Demography") become bold header rows
in the label column, each immediately above its first variable, rather
than a column of their own.

Rounding, `%`-free percentage cells, and `±`-without-spaces formatting
are yours to control, via the `statistic`/`digits` arguments to
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html);
see the package README for a worked example using
[`gtsummary::style_sigfig()`](https://www.danieldsjoberg.com/gtsummary/reference/style_sigfig.html)
for 2-significant-figure rounding.

A manuscript table that describes cohorts or repeated measures side by
side, rather than comparing groups, takes `layout = "describe"`: each
group spans its own count and statistic, so every group has its count.
Everything else is the comparison layout's. The JTCVS functions, whose
layout this is, are deprecated.

A table from
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
works in every style and layout. That function writes each cell as
`"{N_nonmiss} ||| {stat}"`, and this one splits the two apart into a
flat `No.` column immediately before the statistic it counts. Those are
the same two values the describe layout puts under each group's spanning
header, without the merge. House rule 8 wants that non-missing count,
and
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)'s
`*` footnote describes it, so it is kept rather than discarded. A plain
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
table carries no such convention and passes through unchanged.

None of `gtsummary`'s own footnotes reach the table:
[`as_flex_table()`](https://www.danieldsjoberg.com/gtsummary/reference/as_flex_table.html)
writes them as a footer row and a raised digit inside the table, and
house rule 13 puts notes below it.
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
says what they said in the notes
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
writes: the tests behind the p-values in the dagger note, and CI in the
key.

## Common mistakes

**Cells read `98 ||| 46 (32, 63)`.** You are on a version before the
split; upgrade. `|||` is the internal separator
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
writes between the count and the statistic, never intended to reach a
rendered table.

**"`tbl` was not built with the `{N_nonmiss} ||| {stat}` convention."**
Only some cells carry the separator, which means `statistic` was set for
part of the table. Splitting would leave the rest blank, so it is
rejected. Either apply the convention to every variable or to none;
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
does the former for you.

**"`font_size` must be 11 or 12."** House rule 5. Use `11` only for wide
tables.

**"`font` and `font_size` set the report style."** You passed one with
`style = "manuscript"`. That style sets no font, so the table takes the
font of the document it is saved into. Drop the argument, or use
`style = "report"`.

**The compare layout refuses a `continuous_stat = "both"` table.** That
table has a column for the median and another for the mean and SD, which
the compare layout's one statistic column per group cannot lay out.
Build the table with `"median"` or `"mean"`, or draw it with
`layout = "describe"` or the report style, which show both.

**The manuscript style refuses a table not built by
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md).**
The layout reads the overall count and the grouping's name that function
records. Build the table with it.

**"`layout` chooses between the manuscript style's layouts."** You named
a layout with the report style, which has one. Drop `layout`, or add
`style = "manuscript"`.

## See also

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
to write the result to a compliant `.docx` with footnotes and an
abbreviation key.
[`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
for each style's properties.

## Examples

``` r
library(gtsummary)
tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
ft <- hv_man_table(tbl)
ft2 <- hv_man_table(
  hv_tbl_summary(
    trial, by = "trt", groups = list(A = c("age", "grade")),
    continuous = "age", categorical = "grade"
  ),
  style = "manuscript", layout = "describe"
)
```
