- `hv_tbl_summary()` takes `prop_ci = c("none", "wilson", "exact")` and
  `prop_ci_level = 0.95`. When it is not `"none"`, each group's binary and
  categorical cells get a confidence interval for the percentage, in a
  column of its own beside the group's statistic (`3(11)` beside
  `3.7, 27`). A zero count gets one too, `0` to the exact upper bound,
  where a Wald interval collapses to a point. `"wilson"` is the Wilson
  score interval with the exact (Clopper-Pearson) bound at 0% and 100%;
  `"exact"` is Clopper-Pearson throughout. The dagger note names the
  method and level. Every cell gets an interval: there is no
  small-proportion cut-off yet. The report style shows the column; the
  manuscript style and `hv_man_table_jtcvs()` refuse a table carrying it
  until it is decided where it belongs there (#106).
