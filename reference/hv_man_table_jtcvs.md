# Build a JTCVS-format manuscript table with merged spanning headers

Stage 2 of the `%summarytable` split: shapes the table. The macro
controlled this with `STYLE=` and `PAGE=`, which have no equivalent here
– house style is fixed, and the only choice is flat header versus JTCVS
spanning header.

## Usage

``` r
hv_man_table_jtcvs(
  tbl,
  groups,
  trailing = NULL,
  stat_label = "No. (%) or Mean ± SD",
  font = "Times New Roman",
  font_size = 12,
  ...
)
```

## Arguments

- tbl:

  A `gtsummary` table object whose `statistic` argument used
  `"{N_obs} ||| {<stat>}"` for every group column.
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

  Optional named character vector of length 1, an existing
  `tbl$table_body` column name -\> header label, for a trailing
  comparison column (e.g. `c(std_diff = "Std. Diff.")` or
  `c(p_value = "P")`). Must already exist in `tbl$table_body`.

- stat_label:

  Sub-header text under each group's statistic column. Default
  `"No. (%) or Mean ± SD"` (house default for mean/SD tables). Pass e.g.
  `"No. (%) or Median (15th, 85th percentile)"` when the table's
  continuous statistic is a median, not a mean.

- font:

  Font family. Default `"Times New Roman"` (house rule). Any single
  non-empty string is accepted: `flextable` silently substitutes an
  unknown font name, so a typo would otherwise pass unnoticed, while a
  deliberate override is legitimate.

- font_size:

  Font size in points. Default `12` (house rule 5); pass `11` for wide
  tables. No other values are permitted – the same rule
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  enforces.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

A `flextable` with a 2-row header and merged section rows, ready for
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md).

## Details

Use this instead of
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
when you're building the shape editorial actually needs at JTCVS
submission: a 2-row header (group name spanning `na`/stat sub-columns)
and bold, light-blue-shaded, row-spanning section headers in the body,
matching the canonical "Table Construction for Manuscripts" house
example (section-header fill `#CAEDFB`). This is a separate mode, not a
replacement for
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)'s
flat-header CORR house style; the two exist because CORR reports and
JTCVS submissions want different things from the same header row.

## Common mistakes

**"`tbl` was not built with the `{N_obs} ||| {stat}` convention."** The
table came from a plain
[`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
call. Build it with
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
which applies the convention automatically, or pass
`statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ({sd})")`.
Before this check existed, such a table rendered every cell blank.

**"`groups` names must be columns in `tbl$table_body`."** Group names
are the `stat_<k>` columns `gtsummary` creates, one per level of the
`by` variable – not the group labels. Two groups give `stat_1` and
`stat_2`.

**"`font_size` must be 11 or 12."** House rule 5. Use `11` only for wide
tables.

## See also

[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
for the flat-header CORR house-style mode.
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
to write the result to a compliant `.docx`.

## Examples

``` r
library(gtsummary)
tbl <- trial |>
  tbl_summary(
    by = trt,
    statistic = list(
      all_continuous() ~ "{N_obs} ||| {mean} ± {sd}",
      all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
    ),
    include = c(age, grade),
    missing = "no"
  )
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
)
```
