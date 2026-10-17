* `hv_man_table_save()` and `hv_man_table_save_jtcvs()` always drop the
  "Variable" column `hv_tbl_summary(show_variable = TRUE)` adds, before
  fitting the page, so a saved table is always a manuscript table and its
  width and orientation are the manuscript table's. `hv_man_table()` and
  `hv_man_table_display()` keep it for the report view; `show_variable`
  stays `TRUE` by default and no longer needs setting to `FALSE` for a
  manuscript. `hv_man_table_jtcvs()`, whose table is always a manuscript
  table, no longer shows it.
