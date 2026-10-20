# hvtiRtables: Manuscript-Compliant Table Construction

Turns `gtsummary` table objects into MS Word tables that comply with
HVTI CORR's "Table Construction for Manuscripts" rules. A table is drawn
in a style named by its role, and a manuscript table in the layout its
content needs.

## Which style do I want?

**The report style** has a flat, non-merged header, a count beside each
group, and footnotes as text below the table. Use it for analysis
reports.

    tbl <- gtsummary::tbl_summary(dta, by = "trt")
    ft  <- hv_man_table(tbl)
    hv_man_table_save(ft, "table1.docx")

**The manuscript style** is the table a journal receives: a full grid, a
two-row header, shaded section rows, and the document's own font. Its
`"compare"` layout gives groups it compares one overall `n` column; its
`"describe"` layout gives cohorts it describes side by side a count
each. The JTCVS functions are deprecated: their layout is `"describe"`.

    tbl <- hv_tbl_summary(
      dta, by = "trt",
      groups = list(Demography = c("age", "sex")),
      continuous = "age", categorical = "sex"
    )
    ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
    hv_man_table_save(ft, "table2.docx", caption = "Table 2. Cohorts")

## Checking a finished document

[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
reads any `.docx` and reports the structural patterns the house rules
forbid. The saver does not run it on its own output, so call it on the
path afterwards.

## See also

Useful links:

- <https://github.com/ehrlinger/hvtiRtables>

- <https://ehrlinger.github.io/hvtiRtables/>

- Report bugs at <https://github.com/ehrlinger/hvtiRtables/issues>

## Author

**Maintainer**: John Ehrlinger <ehrlinj@ccf.org>

Authors:

- John Ehrlinger <ehrlinj@ccf.org>
