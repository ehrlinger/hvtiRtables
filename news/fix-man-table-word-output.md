* The Word tables from `hv_man_table_save()` and `hv_man_table_save_jtcvs()`
  now match the SAS `%summarytable` layout, after a review of two commented
  example tables:
  - `hv_tbl_summary()` writes categorical cells as `12 (39)`, without the `%`
    sign. The `(%)` is stated once, in the JTCVS sub-header or the CORR
    dagger footnote.
  - `hv_man_table()` puts each section ("Demography") on its own bold row in
    the Characteristic column, above its first variable. Before, the sections
    filled an extra column headed `groupname_col`. The Characteristic column
    is now left-justified.
  - The CORR dagger now marks each statistic column instead of the first
    `No.` column. Its text now covers both kinds of row, for example
    "No. (%) or Median (15th, 85th percentile)."
    `hv_man_footnotes()` returns the same wording.
  - `hv_man_table_jtcvs()` takes its statistic sub-header from the table
    (`stat_label = NULL`). The fixed `"No. (%) or Mean±SD"` default labeled
    median tables as mean and SD.
  - In the JTCVS table, "Characteristic" spans both header rows instead of
    printing twice, and the section rows are no longer shaded blue. Each `n`
    sub-header carries a superscript `a`, which `hv_man_table_save_jtcvs()`
    explains first with "a. Patients with data available." The `a` used to
    print as plain text, `na`. Footnotes you pass now start at `b`.
