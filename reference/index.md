# Package index

## 

Compute the table — `%summarytable`

Where the macro’s `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=` and
`TOTALCOL=` land. Takes a grouped, ordered variable list and returns a
`gtsummary` object for the stages below.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  : Build a gtsummary table from a SAS %summarytable-style grouped
  variable list

## 

Shape the table - house style is fixed

House style is fixed, so the only choice here is the header shape. Flat
single-row headers for CORR reports and manuscripts; merged spanning
headers for a JTCVS submission.

- [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  : Convert a gtsummary table into a flextable matching HVTI CORR's
  table rules
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  : Build a JTCVS-format manuscript table with merged spanning headers

## 

Write the document — `RTFFILE=` / `PDFFILE=`

The macro’s output block: `TBLTITLE=` becomes `caption`, `ADDFN=` and
`PRINTFN=` become `footnotes`. Output is always `.docx`.

- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  : Write an hv_man_table() table to a compliant .docx
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  : Write an hv_man_table_jtcvs() table to a compliant .docx
- [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  : The house-standard manuscript table footnotes
- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  : Build lettered test footnotes from a gtsummary table

## 

Verify the written file

No macro analogue. Inspects a written `.docx` for structural layers the
manuscript rules prohibit, reading the file rather than the object that
produced it — so it catches anything introduced later, including by a
hand edit.

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  : Check a .docx for structural patterns the house rules forbid

## Package overview

Which rendering mode to use, and both pipelines end to end.

- [`hvtiRtables`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  [`hvtiRtables-package`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  : hvtiRtables: Manuscript-Compliant Table Construction
