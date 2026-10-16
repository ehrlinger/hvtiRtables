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
* `hv_tbl_summary()` gains `cutexact`. The default, `"any"`, keeps the
  rule used until now: Fisher's exact test when any cell expects fewer
  than 5, so categorical p-values are unchanged. A number opts in to
  `%summarytable`'s `CUTEXACT=` rule to reproduce a SAS table
  (`cutexact = 50` is the macro's default). In the CORR table each
  Fisher p-value now carries a superscript double dagger, footnoted
  "Fisher exact test."; `hv_man_table_save()` stops if given `footnotes`
  that leave that mark unexplained or file another note under it.
* `continuous_stat = "both"` now shows mean±SD and the median side by side,
  in a median column beside each group's statistic column, instead of
  stacked sub-rows. Both renderers lay it out the same way. **This changes
  existing "both" tables**: the statistic columns and their dagger now read
  "No. (%) or Mean±SD", the median column names itself in its header, and
  a two-group "both" table now saves in landscape.
* `hv_man_table_save_jtcvs()` saves a table wider than a portrait page on
  a landscape page, and narrows its columns in proportion when it is wider
  than landscape too, so the rightmost columns are never clipped.
