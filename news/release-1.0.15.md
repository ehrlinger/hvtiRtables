* `hv_tbl_summary()`: `compare = "smd"` or `"both"` without the 'smd' package is now an
  error of class `hvtiRtables_missing_package`, as a p-value comparison without 'broom'
  already was. gtsummary only reported the failure and left every Std. Diff. cell blank.
* Examples, tests and vignettes that need 'broom' or 'smd', both suggested rather than
  imported, now run only when the package is installed.
