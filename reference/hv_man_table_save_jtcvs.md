# Write an hv_man_table_jtcvs() table to a compliant .docx

JTCVS counterpart to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md):
it adds a bold `Table N. Caption` paragraph before the table, and
renders footnotes as lettered (`a.`, `b.`, ...) markers attached to
specific body cells rather than the fixed symbol set
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
uses on the header row, matching the JTCVS template convention.

## Usage

``` r
hv_man_table_save_jtcvs(
  ft,
  file,
  caption,
  footnotes = NULL,
  abbreviations = NULL
)
```

## Arguments

- ft:

  A `flextable`, from
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).

- file:

  Output `.docx` path.

- caption:

  Full caption text, e.g. `"Table 1. Baseline Characteristics"`,
  rendered bold above the table. This function does not auto-number
  tables for you; include the number yourself.

- footnotes:

  Optional list of `list(row =, col =, text =)`, one per footnote, in
  the order letters should be assigned (`a`, `b`, ...). `row`/`col`
  address a body cell in `ft` (`col` is a `col_keys` name). `row`
  indexes `ft`'s body rows as shown: for a sectioned table (built with
  `groupname_col`), that includes the section-header rows
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  interleaves into the body, so you need to count those rows too when
  computing the target row index, not just the data rows.

- abbreviations:

  Optional named character vector, same as
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
  rendered via the shared `Key:` helper.

## Value

Invisibly, the `file` path.

## See also

[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
to build a compliant `flextable` first.

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
out <- tempfile(fileext = ".docx")
hv_man_table_save_jtcvs(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  footnotes = list(list(
    row = 1, col = "n_stat_1", text = "Patients with data available."
  ))
)
```
