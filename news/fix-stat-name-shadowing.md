* `hv_tbl_summary()` no longer fails when the calling session defines an
  object named `sd` or `median`. gtsummary turns each statistic in
  `{mean}±{sd}` or `{median} [{p15}, {p85}]` into a function by looking its
  name up from where `tbl_summary()` was called, and from inside a package
  that lookup reaches the global environment before `package:stats`, so a
  study whose `R/` folder defined `sd` (as hvtiRtemplates jobs source it into
  the global environment) got "Value must be a named list of functions"
  whenever a row showed mean±SD or a median. The call now runs from an
  environment holding `stats::sd` and `stats::median` and then only base, so
  nothing a user defines can shadow a statistic. Present in 1.0.7 and 1.0.8.
