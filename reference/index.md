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
- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  : Build lettered test footnotes from a gtsummary table

## Checking Written Files

Inspect a written `.docx` for structural layers the manuscript rules
prohibit. Reads the file rather than the object that produced it, so it
catches anything introduced later, including by a hand edit.

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  : Check a .docx for structural patterns the house rules forbid

## Package overview

Which rendering mode to use, and both pipelines end to end.

- [`hvtiRtables`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  [`hvtiRtables-package`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  : hvtiRtables: Manuscript-Compliant Table Construction
