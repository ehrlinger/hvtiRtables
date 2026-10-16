* `hv_tbl_summary()` gains `mean_sd`, the continuous variables to *show*
  as mean±SD while keeping the Wilcoxon or Kruskal-Wallis test. `normal`
  still couples mean±SD to one-way ANOVA and is unchanged.
* `hv_tbl_summary()` gains `show_variable`, on by default: a "Variable"
  column beside the label holds each variable's column name, as
  `%summarytable`'s report did. `hv_man_table()` and
  `hv_man_table_jtcvs()` both show it. **Existing tables gain this column**;
  pass `show_variable = FALSE` for a manuscript.
* New `hv_tbl_compare()` adds a comparison column you computed yourself,
  one value on each variable's first row, rightmost in the table. It is
  how `hvtiRpropensity::ps_stddiff()`'s `%stddiff` standardized difference
  reaches a table, beside `compare = "pvalue"`, without hvtiRtables
  depending on hvtiRpropensity. `compare = "smd"` is unchanged; its help
  now says it is gtsummary's generic SMD, not `%stddiff`'s.
* `hv_man_table_jtcvs()`'s `trailing` now takes several columns, laid out
  in order. Its error for a malformed `trailing` no longer says "of
  length 1".
