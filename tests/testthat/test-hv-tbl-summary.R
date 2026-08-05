mk_tbl_summary_data <- function() {
  set.seed(7)
  n <- 40
  data.frame(
    age = round(rnorm(n, 60, 10)),
    bsa = round(rnorm(n, 2, 0.2), 2),
    grp = factor(rep(c("A", "B"), each = n / 2))
  )
}

mk_tbl_summary_mixed_data <- function() {
  set.seed(11)
  n <- 60
  data.frame(
    age = round(rnorm(n, 60, 10)),
    flag = sample(0:1, n, replace = TRUE),
    race = factor(sample(c("White", "Black", "Other"), n, replace = TRUE)),
    grp = factor(rep(c("A", "B"), each = n / 2))
  )
}

test_that("hv_tbl_summary rejects a non-data-frame", {
  expect_error(
    hv_tbl_summary(list(a = 1), groups = list(X = "a"), continuous = "a"),
    "must be a data frame"
  )
})

test_that("hv_tbl_summary rejects an unnamed groups list", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(dta, groups = list("age"), continuous = "age"),
    "named list"
  )
})

test_that("hv_tbl_summary rejects a percentiles vector of the wrong length", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = "age"), continuous = "age",
      percentiles = c(10, 50, 90)
    ),
    "length 2"
  )
})

test_that("hv_tbl_summary rejects a variable listed in two groups sections", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta,
      groups = list(A = "age", B = "age"),
      continuous = "age"
    ),
    "more than one"
  )
})

test_that("hv_tbl_summary rejects a groups variable missing from data", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = c("age", "nope")), continuous = c("age", "nope")
    ),
    "not found in `data`"
  )
})

test_that("hv_tbl_summary rejects an unclassified groups variable", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(dta, groups = list(Vitals = c("age", "bsa")), continuous = "age"),
    "not classified"
  )
})

test_that("hv_tbl_summary rejects a classified variable absent from groups", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = "age"), continuous = c("age", "bsa")
    ),
    "not present in `groups`"
  )
})

test_that("hv_tbl_summary builds a continuous, ungrouped (by = NULL) table", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age"
  )
  expect_s3_class(tbl, "gtsummary")
  expect_identical(tbl$table_body$variable, "age")
  expect_identical(tbl$table_body$groupname_col, "Vitals")
  expect_true(grepl("^[0-9]+ \\|\\|\\|", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary builds a continuous, grouped (by given) table", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age"
  )
  expect_true(all(c("stat_1", "stat_2") %in% names(tbl$table_body)))
  expect_identical(tbl$table_body$groupname_col, "Vitals")
})

test_that("hv_tbl_summary does not comma-format large N (house style is plain digits)", {
  # Both real example tables examined during design (N=7948, 4190, 3758)
  # show plain digits, not "7,948" — gtsummary's default N_obs/n
  # formatter inserts thousands separators for any value >= 1000, which
  # this synthetic 1500-row dataset deliberately exceeds to catch a
  # regression.
  set.seed(3)
  n <- 1500
  dta <- data.frame(age = round(rnorm(n, 60, 10)))
  tbl <- hv_tbl_summary(dta, groups = list(Vitals = "age"), continuous = "age")
  expect_true(grepl("^1500 \\|\\|\\|", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary's percentiles argument changes the glue statistic", {
  # Pin structural shape ("N ||| median (lo, hi)") and prove the
  # percentiles argument actually flows into the glue string, without
  # pinning exact quantile values: gtsummary applies its own internal
  # digit-rounding to {pXX} tokens (verified empirically during planning
  # that it does not simply match stats::quantile(..., type = 2) rounded
  # with round() — e.g. a raw 80.5 rendered as "81", not R's round-half
  # -to-even "80") which is gtsummary's implementation detail, not
  # something hv_tbl_summary() controls or should assert on.
  dta <- mk_tbl_summary_data()
  default_tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age"
  )
  custom_tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age",
    percentiles = c(10, 90)
  )
  expect_match(
    custom_tbl$table_body$stat_0, "^[0-9]+ \\|\\|\\| [0-9.]+ \\([0-9.]+, [0-9.]+\\)$"
  )
  expect_false(identical(default_tbl$table_body$stat_0, custom_tbl$table_body$stat_0))
})

test_that("hv_tbl_summary summarizes a binary variable as a single n (%) row", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "flag"), binary = "flag"
  )
  expect_identical(tbl$table_body$variable, "flag")
  expect_identical(tbl$table_body$row_type, "label")
  expect_true(grepl("^[0-9]+ \\|\\|\\| [0-9]+ \\([0-9.]+%\\)$", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary summarizes a categorical variable with one row per level", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "race"), categorical = "race"
  )
  levels_shown <- tbl$table_body$label[tbl$table_body$row_type == "level"]
  expect_setequal(levels_shown, c("White", "Black", "Other"))
})

test_that("hv_tbl_summary mixes continuous, binary, and categorical in one call", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta,
    groups = list(Vitals = c("age", "flag"), Demography = "race"),
    continuous = "age", binary = "flag", categorical = "race"
  )
  expect_identical(
    tbl$table_body$variable[tbl$table_body$row_type != "level"],
    c("age", "flag", "race")
  )
  expect_identical(
    tbl$table_body$groupname_col[tbl$table_body$row_type != "level"],
    c("Vitals", "Vitals", "Demography")
  )
})

test_that("hv_tbl_summary compare is ignored (no-op) when by is NULL", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age", compare = "pvalue"
  )
  expect_false("hv_compare_col" %in% names(tbl$table_body))
  expect_null(attr(tbl, "hv_trailing"))
})

test_that("hv_tbl_summary compare = 'none' adds no comparison column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "none"
  )
  expect_false("hv_compare_col" %in% names(tbl$table_body))
  expect_null(attr(tbl, "hv_trailing"))
})

test_that("hv_tbl_summary compare = 'pvalue' adds a formatted p-value column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "pvalue"
  )
  expect_true("hv_compare_col" %in% names(tbl$table_body))
  expect_true(grepl("^(<)?[0-9.]+$", tbl$table_body$hv_compare_col))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "P"))
})

test_that("hv_tbl_summary compare = 'smd' adds a formatted std. diff. column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "smd"
  )
  expect_true("hv_compare_col" %in% names(tbl$table_body))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "Std. Diff."))
})

test_that("hv_tbl_summary compare = 'both' combines p-value and SMD in one column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "both"
  )
  expect_true(grepl("SMD", tbl$table_body$hv_compare_col))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "P (SMD)"))
})
