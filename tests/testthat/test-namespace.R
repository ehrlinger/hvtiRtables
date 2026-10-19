# The public surface, read from the NAMESPACE file rather than the loaded
# namespace: load_all() exports everything, so a lost export passes every
# other test. 9221ce0 did exactly that, exporting the internal
# .wide_tol_dxa in place of hv_check_docx(); only R CMD build noticed.
test_that("NAMESPACE exports exactly the public functions", {
  ns <- system.file("NAMESPACE", package = "hvtiRtables")
  skip_if(!nzchar(ns), "NAMESPACE file not found")
  lines <- readLines(ns)
  declared <- grep("^export\\(", lines, value = TRUE)
  exports <- sub("^export\\((.*)\\)$", "\\1", declared)
  expect_setequal(exports, c(
    "hv_check_docx", "hv_correlation_table", "hv_man_footnotes",
    "hv_man_table", "hv_man_table_display", "hv_man_table_jtcvs",
    "hv_man_table_save",
    "hv_man_table_save_jtcvs", "hv_table_style", "hv_tbl_compare",
    "hv_tbl_summary",
    "hv_test_footnotes_jtcvs"
  ))
})
