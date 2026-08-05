# Package index

## Building Tables from Data

Build a grouped baseline-characteristics table straight from a data
frame, using an interface modeled on the SAS `%summarytable` macro.
Returns a `gtsummary` object for the renderers below.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  : Build a gtsummary table from a SAS %summarytable-style grouped
  variable list

## Flat-Header Tables

Standard HVTI CORR manuscript tables: flat (non-merged) headers, no
hidden spacer columns, footnotes as text below the table.

- [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  : Convert a gtsummary table into a flextable matching HVTI CORR's
  table rules
- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  : Write an hv_man_table() table to a compliant .docx

## JTCVS Merged-Header Tables

JTCVS submission mode, with merged spanning group headers and lettered
cell-targeted footnotes matching that journal’s template.

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  : Build a JTCVS-format manuscript table with merged spanning headers
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  : Write an hv_man_table_jtcvs() table to a compliant .docx

## Footnotes

- [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  : The house-standard manuscript table footnotes
