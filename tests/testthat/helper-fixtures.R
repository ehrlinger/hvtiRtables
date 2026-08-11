# Shared fixtures. Named fx_* rather than mk_* so they cannot collide
# with the per-file mk_tbl() helpers already defined in
# test-hv-man-table.R and its siblings.

# A gtsummary table built WITH the "{N_obs} ||| {stat}" convention.
fx_jtcvs_tbl <- function() {
  gtsummary::tbl_summary(
    gtsummary::trial,
    by = "trt",
    statistic = list(
      gtsummary::all_continuous() ~ "{N_obs} ||| {mean} ({sd})"
    ),
    include = c("age", "grade")
  )
}

# A gtsummary table built WITHOUT the convention.
fx_plain_tbl <- function() {
  gtsummary::tbl_summary(
    gtsummary::trial, by = "trt", include = c("age", "grade")
  )
}

# An hv_tbl_summary() table, which carries NA stat cells on the parent
# label row of the multi-level categorical.
fx_hv_tbl <- function() {
  hv_tbl_summary(
    gtsummary::trial,
    by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade",
    compare = "none"
  )
}

# A rendered JTCVS flextable.
fx_jtcvs_ft <- function() {
  hv_man_table_jtcvs(
    fx_jtcvs_tbl(), groups = c(stat_1 = "A", stat_2 = "B")
  )
}
