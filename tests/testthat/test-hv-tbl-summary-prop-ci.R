# Confidence intervals for the percentages of binary and categorical
# cells (#106). The reference cells are the ones a reviewer flagged,
# 3/28 and 1/27, and a zero count, 0/27.

# Group A: 28 patients, 3 events. Group B: 27 patients, 1 event. `grp`
# has a level no one in B is in, so B carries two 0/27 cells.
prop_ci_data <- function() {
  data.frame(
    arm = rep(c("A", "B"), c(28, 27)),
    event = c(rep(1, 3), rep(0, 25), 1, rep(0, 26)),
    grp = factor(c(rep(c("x", "y", "z"), length.out = 28), rep("x", 27)),
                 levels = c("x", "y", "z")),
    age = seq(40, 94)
  )
}

prop_ci_tbl <- function(...) {
  hv_tbl_summary(
    prop_ci_data(), by = "arm",
    groups = list(S = c("age", "event", "grp")),
    continuous = "age", binary = "event", categorical = "grp",
    compare = "none", ...
  )
}

test_that(".prop_ci() reproduces hand-computed Wilson intervals", {
  # z = qnorm(0.975) = 1.959964, z^2 = 3.841459. The Wilson centre is
  # x + z^2/2 over n + z^2, and the half-width is z times the square root
  # of x (n - x) / n + z^2/4, over n + z^2.
  # 3/28: centre 4.920729 / 31.841459 = 0.154539,
  #       half 1.959964 * sqrt(2.678571 + 0.960365) / 31.841459 = 0.117420
  # 1/27: centre 2.920729 / 30.841459 = 0.094701,
  #       half 1.959964 * sqrt(0.962963 + 0.960365) / 30.841459 = 0.088133
  ci <- .prop_ci(c(3, 1), c(28, 27), "wilson", 0.95)
  expect_equal(unname(ci[1, ]), c(0.037119, 0.271959), tolerance = 1e-5)
  expect_equal(unname(ci[2, ]), c(0.006568, 0.182834), tolerance = 1e-5)
  # The same as prop.test() without continuity correction, which inverts
  # the same score test.
  for (k in 1:2) {
    ref <- stats::prop.test(c(3, 1)[k], c(28, 27)[k], correct = FALSE)
    expect_equal(unname(ci[k, ]), as.numeric(ref$conf.int),
                 tolerance = 1e-10)
  }
})

test_that("a zero count gets the exact upper bound, not a point", {
  # Clopper-Pearson at x = 0: [0, 1 - (alpha / 2)^(1 / n)].
  # 1 - 0.025^(1/27) = 1 - exp(-3.688879 / 27) = 1 - 0.872297 = 0.127703.
  # Wilson alone would give 3.841459 / 30.841459 = 0.124554.
  for (method in c("wilson", "exact")) {
    ci <- .prop_ci(0, 27, method, 0.95)
    expect_identical(ci[1, "lower"], c(lower = 0))
    expect_equal(unname(ci[1, "upper"]), 0.127703, tolerance = 1e-5)
    expect_equal(unname(ci[1, "upper"]), 1 - 0.025^(1 / 27))
  }
  # And at x = n the mirror image: [(alpha / 2)^(1 / n), 1].
  ci <- .prop_ci(27, 27, "wilson", 0.95)
  expect_equal(unname(ci[1, ]), c(0.025^(1 / 27), 1))
})

test_that("method = \"exact\" is Clopper-Pearson in every cell", {
  ci <- .prop_ci(c(3, 1, 0), c(28, 27, 27), "exact", 0.95)
  for (k in 1:3) {
    ref <- stats::binom.test(c(3, 1, 0)[k], c(28, 27, 27)[k])$conf.int
    expect_equal(unname(ci[k, ]), as.numeric(ref), tolerance = 1e-10)
  }
  # Differs from Wilson away from the edges, so the method choice shows.
  expect_false(isTRUE(all.equal(ci[1, ], .prop_ci(3, 28, "wilson", 0.95)[1, ])))
})

test_that("an empty denominator has no interval", {
  ci <- .prop_ci(c(0, NA), c(0, 10), "wilson", 0.95)
  expect_true(all(is.na(ci)))
})

test_that("the interval column is absent by default", {
  tbl <- prop_ci_tbl()
  expect_length(grep("^hv_ci_", names(tbl$table_body)), 0L)
  expect_null(attr(tbl, "hv_prop_ci", exact = TRUE))
  expect_false(grepl("CI", attr(tbl, "hv_footnotes")[["†"]]))
})

test_that("prop_ci = \"wilson\" adds an interval beside every cell", {
  tbl <- prop_ci_tbl(prop_ci = "wilson")
  tb <- tbl$table_body
  # Each column sits right after its own statistic.
  expect_identical(
    grep("^(hv_ci_)?stat_", names(tb), value = TRUE),
    c("stat_0", "hv_ci_stat_0", "stat_1", "hv_ci_stat_1",
      "stat_2", "hv_ci_stat_2")
  )
  # Rows: age, event, grp (label), x, y, z. Percent, house precision.
  expect_identical(tb$hv_ci_stat_1,
                   c(NA, "3.7, 27", NA, "21, 54", "18, 51", "18, 51"))
  expect_identical(tb$hv_ci_stat_2,
                   c(NA, "0.66, 18", NA, "87, 100", "0, 13", "0, 13"))
  # The cells themselves are untouched.
  expect_identical(tb$stat_1[2], "28 ||| 3(11)")
  expect_identical(tb$stat_2[5], "27 ||| 0(0)")
  expect_identical(attr(tbl, "hv_prop_ci", exact = TRUE), "wilson")
  expect_identical(
    attr(tbl, "hv_footnotes")[["†"]],
    paste0("No. (%) or Median [15th, 85th percentiles]; 95% CIs for the ",
           "percentages are Wilson score intervals, with the exact ",
           "(Clopper-Pearson) bound at 0% and 100%.")
  )
})

test_that("prop_ci = \"exact\" and prop_ci_level change the cells and note", {
  tbl <- prop_ci_tbl(prop_ci = "exact", prop_ci_level = 0.9)
  tb <- tbl$table_body
  ref <- stats::binom.test(3, 28, conf.level = 0.9)$conf.int
  expect_identical(tb$hv_ci_stat_1[2],
                   paste(.format_sig2(100 * ref), collapse = ", "))
  expect_match(attr(tbl, "hv_footnotes")[["†"]],
               "90% CIs for the percentages are exact (Clopper-Pearson) ",
               fixed = TRUE)
  hdr <- tbl$table_styling$header
  expect_match(hdr$label[hdr$column == "hv_ci_stat_1"], "90% CI$")
})

test_that("an ungrouped table gets one interval column", {
  tbl <- hv_tbl_summary(
    prop_ci_data(), groups = list(S = "event"), binary = "event",
    prop_ci = "wilson"
  )
  expect_identical(grep("^hv_ci_", names(tbl$table_body), value = TRUE),
                   "hv_ci_stat_0")
  hdr <- tbl$table_styling$header
  expect_identical(hdr$label[hdr$column == "hv_ci_stat_0"], "**95% CI**")
})

test_that("prop_ci and prop_ci_level are validated", {
  expect_error(prop_ci_tbl(prop_ci = "wald"), "should be one of")
  for (bad in list(0, 1, 95, NA_real_, c(0.9, 0.95), "0.95")) {
    expect_error(prop_ci_tbl(prop_ci = "wilson", prop_ci_level = bad),
                 "`prop_ci_level` must be a single number strictly between")
  }
})

test_that("the report style shows the intervals and saves", {
  ft <- hv_man_table(prop_ci_tbl(prop_ci = "wilson"))
  expect_true(all(paste0("hv_ci_stat_", 0:2) %in% ft$col_keys))
  # The dagger note describes the intervals, so their headers carry it.
  expect_true(all(paste0("hv_ci_stat_", 0:2) %in%
                    .footnote_cols(ft, "†")))
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  expect_true(file.exists(path))
})

test_that("the manuscript tables refuse the intervals, in one sentence", {
  tbl <- prop_ci_tbl(prop_ci = "wilson")
  msg <- "The manuscript tables do not show the `prop_ci` intervals yet."
  m1 <- tryCatch(hv_man_table(tbl, style = "manuscript"),
                 error = conditionMessage)
  m2 <- tryCatch(
    hv_man_table(tbl, style = "manuscript", layout = "describe"),
    error = conditionMessage
  )
  g <- c(stat_1 = "A", stat_2 = "B")
  m3 <- tryCatch(jtcvs_quiet(hv_man_table_jtcvs(tbl, g)),
                 error = conditionMessage)
  expect_true(startsWith(m1, msg))
  expect_identical(m1, m2)
  expect_identical(m1, m3)
})
