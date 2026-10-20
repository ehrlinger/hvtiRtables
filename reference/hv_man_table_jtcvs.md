# Deprecated: Build a JTCVS-Format Manuscript Table with Merged Headers

**Deprecated.** Use
`hv_man_table(tbl, style = "manuscript", layout = "describe")`, the
manuscript style's describe layout, which this layout became. This
function warns on every call and goes in the next release.

## Usage

``` r
hv_man_table_jtcvs(
  tbl,
  groups,
  trailing = NULL,
  stat_label = NULL,
  font = "Times New Roman",
  font_size = 12,
  ...
)
```

## Arguments

- tbl:

  A `gtsummary` table object whose `statistic` argument used
  `"{N_nonmiss} ||| {<stat>}"` for every group column.
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  applies this convention for you. A table without it is rejected, since
  its cells cannot be split into their N and statistic parts.

- groups:

  Named character vector, `stat_<k>` column name in `tbl$table_body` -\>
  spanning header label (include the group's N in the label text
  yourself, e.g. `c(stat_1 = "Group A (n=60)")`). Every name must be a
  column of `tbl$table_body`, and each may appear at most once; unknown
  names are rejected with the available ones listed, and a repeated name
  is rejected too.

- trailing:

  Optional named character vector, existing `tbl$table_body` column name
  -\> header label, one entry per trailing comparison column, laid out
  in the order given (e.g. `c(std_diff = "Std. Diff.")` or
  `c(p_value = "P")`). Each must already exist in `tbl$table_body`. A
  table from
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
  with any columns
  [`hv_tbl_compare()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_compare.md)
  added, records the right value as its `hv_trailing` attribute.

- stat_label:

  Sub-header text under each group's statistic column. Default `NULL`
  takes it from the table:
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  records the statistic it used (e.g.
  `"No. (%) or Median [15th, 85th percentiles]"`), so the header cannot
  disagree with the cells. A table without that record falls back to
  `"No. (%) or Mean±SD"`; pass the right text yourself for any other
  statistic.

- font:

  Font family. Checked as a single non-empty string, as before, and
  ignored: the manuscript style sets no font, so the table takes the
  font of the document it is saved into.

- font_size:

  Font size in points. Checked as before (`11` or `12`, the rule
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  enforces) and ignored, for the same reason as `font`.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

A `flextable` in the manuscript style's describe layout, ready for
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).

## Details

Stage 2 of the `%summarytable` split: shapes the table. The macro
controlled this with `STYLE=` and `PAGE=`. This renderer is the
journal's one layout and takes neither; the CORR styles are chosen by
`style =` in
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md).
Pages are US Letter.

Until it goes, it passes its arguments through to that layout: `groups`
and `trailing` choose the same group, Overall and comparison columns,
and `stat_label` names the statistic under each group. The table is
drawn in the manuscript style, not the JTCVS look it drew before: a full
grid, shaded section rows spanning the table, `*` and `†` notes, and no
font of its own. `font` and `font_size` are checked and set nothing.

## Common mistakes

**"`tbl` was not built with the `{N_nonmiss} ||| {stat}` convention."**
The table came from a plain
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
call. Build it with
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
which applies the convention automatically, or pass
`statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ({sd})")`.
Before this check existed, such a table rendered every cell blank.

**"`groups` names must be columns in `tbl$table_body`."** Group names
are the `stat_<k>` columns `gtsummary` creates, one per level of the
`by` variable – not the group labels. Two groups give `stat_1` and
`stat_2`.

**"`font_size` must be 11 or 12."** House rule 5. The value is checked
as before and then ignored: the manuscript style sets no font size, so
the table takes the size of the document it is saved into.

## See also

`hv_man_table(style = "manuscript", layout = "describe")`, the layout
that replaces it, and
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md).
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
to write the result to a compliant `.docx`.

## Examples

``` r
# Instead of hv_man_table_jtcvs() and hv_man_table_save_jtcvs():
tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "grade")),
  continuous = "age", categorical = "grade", compare = "none"
)
ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
out <- tempfile(fileext = ".docx")
hv_man_table_save(ft, out, caption = "Table 2. Baseline Characteristics")
```
