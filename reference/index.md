# Package index

## 

Compute the table — `%summarytable`

Where the macro’s `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=` and
`TOTALCOL=` land. Takes a grouped, ordered variable list and returns a
`gtsummary` object for the stages below.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  : Build a gtsummary table from a SAS %summarytable-style grouped
  variable list
- [`hv_tbl_compare()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_compare.md)
  : Join a comparison column computed elsewhere onto a summary table

## 

Shape the table: a style by role

A style is named by its role, report or manuscript; hv_table_style()
holds its properties.

- [`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
  : A table style, named by its role
- [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  : Convert a gtsummary table into a flextable matching HVTI CORR's
  table rules

## 

Write the document — `RTFFILE=` / `PDFFILE=`

The macro’s output block: `TBLTITLE=` becomes `caption`, `ADDFN=` and
`PRINTFN=` become `footnotes`. Output is always `.docx`.

- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  : Write an hv_man_table() table to a compliant .docx
- [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
  : Show a CORR table with its Word notes, for HTML
- [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  : The house-standard manuscript table footnotes

## 

Verify the written file

No macro analogue. Inspects a written `.docx` for structural layers the
manuscript rules prohibit, reading the file rather than the object that
produced it — so it catches anything introduced later, including by a
hand edit.

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  : Check a .docx for structural patterns the house rules forbid

## Correlations: `proc corr ... fisher`

Pairwise Spearman and Pearson coefficients with Fisher confidence
intervals, overall or within strata. The scatter-plot matrix is
`hvtiPlotR::hv_correlation_matrix()`.

- [`hv_correlation_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_correlation_table.md)
  : Pairwise correlations with Fisher confidence intervals

## Deprecated

The JTCVS functions, whose layout is now the manuscript style’s describe
layout. They warn on every call and go in the next release.

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  : Deprecated: Build a JTCVS-Format Manuscript Table with Merged
  Headers
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  : Deprecated: Write an hv_man_table_jtcvs() table to a compliant .docx
- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  : Deprecated: Build lettered test footnotes from a gtsummary table

## Package overview

Which rendering mode to use, and both pipelines end to end.

- [`hvtiRtables`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  [`hvtiRtables-package`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  : hvtiRtables: Manuscript-Compliant Table Construction
