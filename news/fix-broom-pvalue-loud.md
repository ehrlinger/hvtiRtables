- **`hv_tbl_summary(compare = "pvalue")` and `compare = "both"` now stop
  with an error when 'broom' is not installed**, instead of returning a table
  with every p-value blank. `gtsummary::add_p()` runs its Wilcoxon test
  through 'cardx', which needs 'broom'; without it gtsummary only warned,
  and `hv_test_footnotes_jtcvs()` then returned `list()` because no test was
  recorded. The HVTI Recipes book published blank p-values for a week this
  way. 'broom' stays in `Suggests`, so `compare = "smd"` and `"none"` still
  work without it.
