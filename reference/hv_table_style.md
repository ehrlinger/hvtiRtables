# A table style, named by its role

The properties a table is drawn with, from the style matrix of the
table-styles design: section rows, fill, borders, header, count column,
note markers and wording, font, caption, row height, page and merged
cells. A style is named for what the table is for, not for a journal.
`"report"` is the working table of an analysis report, as
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
has always drawn it. `"manuscript"` is the table a manuscript submits: a
full grid, a two-row header with the grouping spanning its levels, one
overall `n` column, shaded section rows spanning the table, a caption,
and no font of its own, so it takes the font of the document it is saved
into.

## Usage

``` r
hv_table_style(name = c("report", "manuscript"), fill = "#CAEDFB")
```

## Arguments

- name:

  `"report"` (default) or `"manuscript"`.

- fill:

  The section rows' shading, one color written `"#RRGGBB"`. Default
  `"#CAEDFB"`. Journals differ here (one submission used `"#A5C9EB"`),
  so the fill is the property a study changes.

## Value

A list of class `"hv_table_style"`, one element per property, for
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)'s
`style` argument.

## Details

Both styles follow the same house notation (medians, P values, marks),
which
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
writes, so a report reads like the manuscript and only the layout
differs.

## See also

[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md),
which draws a table in a style. The [Table
styles](https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
article prints every style's properties, read from this object.

## Examples

``` r
hv_table_style("manuscript", fill = "#A5C9EB")$fill
#> [1] "#A5C9EB"
```
