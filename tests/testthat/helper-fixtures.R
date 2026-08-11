# Shared fixtures. Named fx_* rather than mk_* so they cannot collide
# with the per-file mk_tbl() helpers already defined in
# test-hv-man-table.R and its siblings.

# A gtsummary table built WITH the "{N_obs} ||| {stat}" convention.
# Both all_continuous() and all_categorical() must carry the
# convention -- age/grade otherwise mixes convention and
# non-convention stat cells (a bare missing-count, bare "n (%)"),
# which is a different table than the one this fixture's name
# promises. missing = "no" avoids a stray non-convention "missing"
# row_type row for the same reason.
fx_jtcvs_tbl <- function() {
  gtsummary::tbl_summary(
    gtsummary::trial,
    by = "trt",
    statistic = list(
      gtsummary::all_continuous() ~ "{N_obs} ||| {mean} ({sd})",
      gtsummary::all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
    ),
    missing = "no",
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

# Collect every stop() call in an expression tree. A regex over
# deparsed source cannot be trusted here: nested parentheses inside a
# message string would end the match early and let an offender pass.
# Blank arguments (e.g. the column index in `df[i, ]`) extract as R's
# missing-argument sentinel: assigning it succeeds, but merely
# *referencing* it afterwards raises "argument is missing, with no
# default". The tryCatch has to cover that reference too, not just
# the extraction, or a real construct like that crashes the walker.
.fx_stop_calls <- function(expr, out = list()) {
  if (!is.call(expr)) return(out)
  if (identical(expr[[1]], quote(stop))) out <- c(out, list(expr))
  for (i in seq_along(expr)) {
    out <- tryCatch({
      part <- expr[[i]]
      .fx_stop_calls(part, out)
    }, error = function(e) out)
  }
  out
}
