# Build a JTCVS-format manuscript table with merged spanning headers

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

## Usage

``` r
hv_man_table_jtcvs(
  tbl,
  groups,
  trailing = NULL,
  font = "Times New Roman",
  font_size = 12
)
```

## Arguments

- tbl:

  A `gtsummary` table object whose `statistic` argument used
  `"{N_obs} ||| {<stat>}"` for every group column (see `groups`).

- groups:

  Named character vector, `stat_<k>` column name in `tbl$table_body` -\>
  spanning header label (include the group's N in the label text
  yourself, e.g. `c(stat_1 = "Group A (n=60)")`).

- trailing:

  Optional named character vector of length 1, an existing
  `tbl$table_body` column name -\> header label, for a trailing
  comparison column (e.g. `c(std_diff = "Std. Diff.")` or
  `c(p_value = "P")`). Must already exist in `tbl$table_body`.

- font:

  Font family. Default `"Times New Roman"` (house rule).

- font_size:

  Font size in points. Default `12`; pass `11` for wide tables.

## Value

A `flextable` with a 2-row header and merged section rows, ready for
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md).

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
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    include = c(age, grade)
  )
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
)
```
