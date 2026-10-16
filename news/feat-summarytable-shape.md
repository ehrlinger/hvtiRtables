* `hv_tbl_summary()` gains `mean_sd`, the continuous variables to *show*
  as mean±SD while keeping the Wilcoxon or Kruskal-Wallis test. `normal`
  still couples mean±SD to one-way ANOVA and is unchanged.
* `hv_tbl_summary()` gains `show_variable`, on by default: a "Variable"
  column beside the label holds each variable's column name, as
  `%summarytable`'s report did. `hv_man_table()` and
  `hv_man_table_jtcvs()` both show it. **Existing tables gain this column**;
  pass `show_variable = FALSE` for a manuscript.
