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

test_that("hv_tbl_summary rejects non-integer or out-of-range percentiles", {
  # gtsummary's glue token is `{pNN}`; a fractional or out-of-range value
  # becomes an invalid token and a header stating percentiles the table
  # does not show.
  dta <- mk_tbl_summary_data()
  bad <- list(c(10.5, 85), c(-5, 85), c(15, 150), c(NA_real_, 85))
  for (p in bad) {
    expect_error(
      hv_tbl_summary(
        dta, groups = list(Vitals = "age"), continuous = "age",
        percentiles = p
      ),
      "whole numbers between 0 and 100"
    )
  }
})

test_that("hv_tbl_summary rejects non-increasing percentiles", {
  dta <- mk_tbl_summary_data()
  for (p in list(c(85, 15), c(50, 50))) {
    expect_error(
      hv_tbl_summary(
        dta, groups = list(Vitals = "age"), continuous = "age",
        percentiles = p
      ),
      "must be increasing"
    )
  }
})

test_that("hv_tbl_summary rejects non-string variable names in groups", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(dta, groups = list(Vitals = 1), continuous = "age"),
    "non-empty strings"
  )
  expect_error(
    hv_tbl_summary(dta, groups = list(Vitals = ""), continuous = "age"),
    "non-empty strings"
  )
})

test_that("hv_tbl_summary sets hv_stat_label on every compare path", {
  # The attribute is assigned once, before the compare handling, and must
  # survive the add_p()/add_difference()/modify_table_body() chain rather
  # than being re-set afterwards.
  dta <- mk_tbl_summary_data()
  expected <- "No. (%) or Median (15th, 85th percentile)"
  for (cmp in c("none", "pvalue", "smd", "both")) {
    tbl <- hv_tbl_summary(
      dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
      compare = cmp
    )
    expect_identical(attr(tbl, "hv_stat_label"), expected)
  }
})

test_that("hv_tbl_summary formats custom percentile labels as ordinals", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age",
    percentiles = c(1, 2)
  )
  expect_identical(
    attr(tbl, "hv_stat_label"),
    "No. (%) or Median (1st, 2nd percentile)"
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
      dta,
      groups = list(Vitals = c("age", "nope")),
      continuous = c("age", "nope")
    ),
    "not found in `data`"
  )
})

test_that("hv_tbl_summary rejects an unclassified groups variable", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta,
      groups = list(Vitals = c("age", "bsa")),
      continuous = "age"
    ),
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

test_that("hv_tbl_summary does not comma-format large N", {
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

test_that("hv_tbl_summary's N column counts non-missing values only", {
  # The N column is footnoted "Number of non-missing values." and the
  # SAS tables count that way (bsa: 7947 of 7948). gtsummary's {N_obs}
  # counts every row, so a variable with missing data used to report the
  # full row count. Every fixture before this one had no NAs, which is
  # why the two tokens were indistinguishable in tests.
  dta <- data.frame(
    age = c(50, 60, NA, NA, 70, 80),
    flag = c(1, NA, 0, 1, 0, NA),
    race = factor(c("W", "B", NA, "W", "W", "B")),
    grp = c(0, 0, 0, 1, 1, 1)
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(X = c("age", "flag", "race")),
    continuous = "age", binary = "flag", categorical = "race"
  )
  n_of <- function(col, var) {
    tb <- tbl$table_body
    cell <- tb[[col]][tb$variable == var & tb$row_type == "label"]
    # Exactly one label row per variable. Anything else is a fixture or
    # gtsummary change, and should say so here rather than fail in if()
    # with "argument is of length zero".
    if (length(cell) != 1L)
      stop("expected one label row for `", var, "`, found ",
           length(cell), call. = FALSE)
    if (is.na(cell))
      cell <- tb[[col]][tb$variable == var & tb$row_type == "level"][1]
    sub(" \\|\\|\\| .*$", "", cell)
  }
  expect_identical(n_of("stat_1", "age"), "2")
  expect_identical(n_of("stat_2", "age"), "2")
  expect_identical(n_of("stat_1", "flag"), "2")
  expect_identical(n_of("stat_2", "flag"), "2")
  expect_identical(n_of("stat_1", "race"), "2")
  expect_identical(n_of("stat_2", "race"), "3")
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
    custom_tbl$table_body$stat_0,
    "^[0-9]+ \\|\\|\\| [0-9.]+ \\([0-9.]+, [0-9.]+\\)$"
  )
  expect_false(
    identical(default_tbl$table_body$stat_0, custom_tbl$table_body$stat_0)
  )
})

test_that("hv_tbl_summary summarizes a binary variable as a single n (%) row", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "flag"), binary = "flag"
  )
  expect_identical(tbl$table_body$variable, "flag")
  expect_identical(tbl$table_body$row_type, "label")
  expect_true(
    grepl("^[0-9]+ \\|\\|\\| [0-9]+ \\([0-9.]+\\)$", tbl$table_body$stat_0)
  )
})

test_that("hv_tbl_summary shows one row per categorical level", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "race"), categorical = "race"
  )
  levels_shown <- tbl$table_body$label[tbl$table_body$row_type == "level"]
  expect_setequal(levels_shown, c("White", "Black", "Other"))
})

test_that("hv_tbl_summary mixes all three variable types in one call", {
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

test_that("hv_tbl_summary compare 'pvalue'/'both' fail loudly without broom", {
  # Without broom, gtsummary's add_p() only warns and leaves every p-value
  # blank. The book shipped a week of blank p-values that way.
  local_mocked_bindings(.has_broom = function() FALSE)
  dta <- mk_tbl_summary_data()
  for (cmp in c("pvalue", "both")) {
    expect_error(
      hv_tbl_summary(
        dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
        compare = cmp
      ),
      "needs the 'broom' package"
    )
  }
  # SMD and none never call add_p(), so they still work without broom.
  expect_no_error(hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "smd"
  ))
})

test_that("hv_tbl_summary p-values and test_name are filled, not blank", {
  # The silent failure this guards: a p-value column of NA and no
  # test_name, so hv_test_footnotes_jtcvs() returns list().
  skip_if_not_installed("broom")
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Demographics = c("age", "flag", "race")),
    continuous = "age", binary = "flag", categorical = "race",
    compare = "pvalue"
  )
  tb <- tbl$table_body
  labels <- tb$row_type == "label"
  expect_false(anyNA(tb$p.value[labels]))
  expect_false(anyNA(tb$test_name[labels]))
  expect_gt(length(hv_test_footnotes_jtcvs(tbl)), 0)
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

test_that("hv_tbl_summary compare 'both' puts p and SMD in one column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "both"
  )
  expect_true(grepl("SMD", tbl$table_body$hv_compare_col))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "P (SMD)"))
})

test_that("hv_tbl_summary compare 'both' reports a true SMD", {
  # Regression: add_difference() must run BEFORE add_p(). In the reverse
  # order gtsummary overwrites `estimate` with a raw mean difference, so
  # the table rendered a wildly wrong number under a header saying SMD
  # (e.g. "0.7 (SMD -1.0)" where the true SMD is -0.03). Pinned against
  # add_difference() computed independently rather than against a hard
  # coded literal, so the assertion tracks the statistic and not whatever
  # the current code happens to emit.
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "both"
  )
  tb <- tbl$table_body

  reference <- gtsummary::add_difference(
    gtsummary::tbl_summary(
      dta,
      by = gtsummary::all_of("grp"),
      include = gtsummary::all_of("age"), missing = "no"
    ),
    gtsummary::everything() ~ "smd"
  )
  ref_tb <- reference$table_body
  expected <- ref_tb$estimate[ref_tb$variable == "age"]

  is_age <- tb$variable == "age" & tb$row_type == "label"
  # unname(): add_p() leaves an empty names attribute on `estimate` that
  # the add_difference()-only reference does not carry. Irrelevant to the
  # statistic, so compare the values alone.
  expect_equal(unname(tb$estimate[is_age]), unname(expected))
})

test_that("hv_tbl_summary compare 'both' preserves add_p()'s test_name", {
  # Same root cause as the SMD regression above, different casualty:
  # add_difference() running second also overwrites `test_name` with
  # "smd", losing the record of which test produced the p-value.
  #
  # Pinned against add_p() computed independently, for the same reason the
  # SMD test above pins against add_difference(): the invariant is that
  # whatever add_p() selected survives, not that it selected any
  # particular test. A literal "wilcox.test" would fail if gtsummary
  # changed its default continuous test, or if this fixture's data
  # changed, even while hv_tbl_summary() was still preserving correctly.
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "both"
  )
  tb <- tbl$table_body

  reference <- gtsummary::add_p(
    gtsummary::tbl_summary(
      dta,
      by = gtsummary::all_of("grp"),
      include = gtsummary::all_of("age"), missing = "no"
    )
  )
  ref_tb <- reference$table_body
  expected <- ref_tb$test_name[ref_tb$variable == "age"]

  is_age <- tb$variable == "age" & tb$row_type == "label"
  expect_identical(tb$test_name[is_age], expected)
  # Backstop: if the reference itself were ever "smd", the comparison
  # above would pass while the bug was present. Assert the regression
  # value directly too.
  expect_false(identical(tb$test_name[is_age], "smd"))
})

test_that("hv_tbl_summary compare 'both' reports an SMD for every type", {
  # This test previously asserted the opposite, that nominal categoricals
  # get no SMD. That was not a gtsummary limitation but the
  # add_p()-before-add_difference() ordering bug showing through: called
  # second, add_difference() left `estimate` NA for binary and categorical
  # variables and a raw mean difference for continuous ones. Called first
  # it returns a valid SMD for all three. With the order corrected, every
  # variable's header row carries one, and only the categorical *level*
  # rows stay blank, which is where gtsummary genuinely reports nothing.
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp",
    groups = list(Vitals = c("age", "flag"), Demography = "race"),
    continuous = "age", binary = "flag", categorical = "race",
    compare = "both"
  )
  tb <- tbl$table_body

  # Continuous, binary, and nominal categorical alike. The old order gave
  # a mean difference for the first and NA for the other two.
  for (v in c("age", "flag", "race")) {
    val <- tb$hv_compare_col[tb$variable == v & tb$row_type == "label"]
    expect_false(is.na(val), info = v)
    expect_match(val, "^(<)?[0-9.]+ \\(SMD -?[0-9.]+\\)$", info = v)
  }

  race_level_vals <- tb$hv_compare_col[
    tb$variable == "race" & tb$row_type == "level"
  ]
  expect_true(all(is.na(race_level_vals)))
})

test_that("hv_tbl_summary + jtcvs reproduce the stratified example", {
  # Group and `female`/`race_gp` counts taken directly from
  # summarytable_stratified_grp_res.docx (PERIMOUNT n=4190, Resilia
  # n=3758; female: 964 of 4190 PERIMOUNT, 1363 of 3758 Resilia; race_gp
  # "White": 3833 of 4190 PERIMOUNT, 3320 of 3758 Resilia).
  set.seed(2026)
  n_perimount <- 4190
  n_resilia <- 3758
  dta <- data.frame(
    tissue = factor(
      rep(c("PERIMOUNT", "Resilia"), c(n_perimount, n_resilia)),
      levels = c("PERIMOUNT", "Resilia")
    ),
    female = c(
      sample(rep(0:1, c(n_perimount - 964, 964))),
      sample(rep(0:1, c(n_resilia - 1363, 1363)))
    ),
    race_gp = factor(c(
      sample(rep(c("White", "Other"), c(3833, n_perimount - 3833))),
      sample(rep(c("White", "Other"), c(3320, n_resilia - 3320)))
    ))
  )

  tbl <- hv_tbl_summary(
    dta, by = "tissue",
    groups = list(Demography = c("female", "race_gp")),
    binary = "female", categorical = "race_gp",
    compare = "pvalue"
  )

  expect_identical(as.integer(table(dta$tissue)), c(4190L, 3758L))
  female_row <- tbl$table_body[tbl$table_body$variable == "female", ]
  expect_true(grepl("^4190 \\|\\|\\| 964 ", female_row$stat_1))
  expect_true(grepl("^3758 \\|\\|\\| 1363 ", female_row$stat_2))

  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(
      stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"
    ),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  )
  expect_s3_class(ft, "flextable")

  body <- ft$body$dataset
  expect_identical(body$label[1], "Demography")
  expect_identical(body$n_stat_1[body$label == "female"], "4190")
  expect_identical(body$n_stat_2[body$label == "female"], "3758")
  expect_true("hv_compare_col" %in% ft$col_keys)
})

test_that("hv_tbl_summary rejects compare = 'smd' with other than two groups", {
  # gtsummary::add_difference() requires exactly two groups. Left to
  # itself it fails in three different ways depending on the shape of
  # `by`, none of them naming anything the caller wrote:
  #   3 observed / 3 levels -> throws "Cannot run add_difference() when
  #     tbl_summary(by) column does not have exactly two levels"
  #   2 observed / 3 levels -> does NOT throw, silently yields estimate
  #     NA and renders a blank SMD column
  #   1 group               -> throws the same internal message
  # The guard keys on the number of stat_ columns gtsummary actually
  # built, which is what add_difference() itself sees, so all three are
  # caught before gtsummary is reached.
  set.seed(1)
  n <- 90
  dta <- data.frame(
    grp3 = factor(rep(c("A", "B", "C"), each = n / 3)),
    age  = rnorm(n, 60, 10)
  )
  for (cmp in c("smd", "both")) {
    expect_error(
      hv_tbl_summary(
        dta, by = "grp3", groups = list(Vitals = "age"),
        continuous = "age", compare = cmp
      ),
      "requires exactly two groups"
    )
  }
})

test_that("hv_tbl_summary rejects an unused by level for compare = 'smd'", {
  # The silent case: 2 observed values but 3 factor levels. gtsummary
  # builds 3 stat columns, add_difference() returns without erroring, and
  # `estimate` is NA, so the SMD column renders blank with no signal.
  set.seed(1)
  n <- 40
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2), levels = c("A", "B", "C")),
    age = rnorm(n, 60, 10)
  )
  expect_error(
    hv_tbl_summary(
      dta, by = "grp", groups = list(Vitals = "age"),
      continuous = "age", compare = "smd"
    ),
    "requires exactly two groups"
  )
  # The hint is the actionable half: without it the message says "produced
  # 3" for data the caller sees as two groups, which reads like a bug.
  expect_error(
    hv_tbl_summary(
      dta, by = "grp", groups = list(Vitals = "age"),
      continuous = "age", compare = "smd"
    ),
    "droplevels"
  )
})

test_that("hv_tbl_summary still allows pvalue and none with 3+ groups", {
  # The guard must not touch the modes that work at 3+ groups.
  set.seed(1)
  n <- 90
  dta <- data.frame(
    grp3 = factor(rep(c("A", "B", "C"), each = n / 3)),
    age  = rnorm(n, 60, 10)
  )
  expect_no_error(
    hv_tbl_summary(
      dta, by = "grp3", groups = list(Vitals = "age"),
      continuous = "age", compare = "pvalue"
    )
  )
  expect_no_error(
    hv_tbl_summary(
      dta, by = "grp3", groups = list(Vitals = "age"),
      continuous = "age", compare = "none"
    )
  )
})

test_that("hv_tbl_summary rejects a variable in two type buckets", {
  expect_identical(
    tryCatch(
      hv_tbl_summary(mtcars, groups = list(Engine = "mpg"),
                     continuous = "mpg", binary = "mpg"),
      error = conditionMessage
    ),
    paste0("`mpg` appears in more than one of `continuous`, `binary`, ",
           "and `categorical`. Every variable must be classified ",
           "exactly once. Overlapping: mpg (continuous, binary).")
  )
})

test_that("hv_tbl_summary validates by in the package's own words", {
  expect_error(
    hv_tbl_summary(mtcars, by = "nope", groups = list(E = "mpg"),
                   continuous = "mpg"),
    "Variable(s) not found in `data`: nope", fixed = TRUE
  )
  expect_error(
    hv_tbl_summary(mtcars, by = c("am", "vs"),
                   groups = list(E = "mpg"), continuous = "mpg"),
    "`by`"
  )
  expect_error(
    hv_tbl_summary(mtcars, by = 1, groups = list(E = "mpg"),
                   continuous = "mpg"),
    "`by`"
  )
})

test_that("hv_tbl_summary rejects by also listed in groups", {
  # The SAS %summarytable equivalent of putting a CLASS= variable into
  # LIST= too. Left to gtsummary this dies with "`names` must be NULL
  # or a character vector, not an empty integer vector.", which never
  # mentions `by` or `groups` -- the package's stated standard is that
  # users never see upstream error vocabulary from a public API.
  expect_error(
    hv_tbl_summary(mtcars, by = "mpg", groups = list(E = "mpg"),
                   continuous = "mpg"),
    "`by`.*`groups`"
  )
})

test_that("hv_tbl_summary rejects non-character type buckets", {
  expect_error(
    hv_tbl_summary(mtcars, groups = list(E = "mpg"), continuous = 1),
    "`continuous` must be a character vector"
  )
})

test_that("hv_tbl_summary rejects a non-numeric variable in continuous", {
  # The flagship silent failure. gtsummary only *messages* here, so the
  # stat cells came back "98 ||| NA (NA, NA)" -- which SATISFIES
  # .assert_stat_convention(), because the convention genuinely is
  # applied and only the statistic is NA. The table then rendered and
  # saved as a complete, correctly styled, all-NA manuscript table.
  expect_identical(
    tryCatch(
      hv_tbl_summary(gtsummary::trial, by = "trt",
                     groups = list(D = "grade"), continuous = "grade",
                     compare = "none"),
      error = conditionMessage
    ),
    paste0("`continuous` lists `grade`, but `grade` is factor data ",
           "with 3 distinct non-missing values (I, II, III). ",
           "`continuous` summarizes numeric columns as a median and ",
           "percentiles, so non-numeric data gives a table of NA ",
           "statistics. Move `grade` to `categorical`.")
  )
})

test_that("hv_tbl_summary rejects a many-valued variable in binary", {
  # Left to gtsummary this leaked "Summary type is \"dichotomous\" but
  # no summary value has been assigned.". `dichotomous` is gtsummary's
  # vocabulary, not this package's.
  msg <- tryCatch(
    hv_tbl_summary(gtsummary::trial, by = "trt",
                   groups = list(D = "age"), binary = "age"),
    error = conditionMessage
  )
  expect_false(grepl("dichotomous", msg, fixed = TRUE))
  expect_match(msg, "`binary` lists `age`", fixed = TRUE)
  expect_match(msg, "Move `age` to `continuous`.", fixed = TRUE)
})

test_that("hv_tbl_summary rejects a binary gtsummary cannot dichotomize", {
  # Two distinct values is necessary but not sufficient: gtsummary
  # assigns a dichotomous "event" value only for logical, 0/1, and
  # yes/no data, and leaks `dichotomous` for anything else.
  dta <- data.frame(grp = factor(rep(c("A", "B"), each = 10)),
                    sex = factor(rep(c("F", "M"), 10)))
  msg <- tryCatch(
    hv_tbl_summary(dta, by = "grp", groups = list(D = "sex"),
                   binary = "sex"),
    error = conditionMessage
  )
  expect_false(grepl("dichotomous", msg, fixed = TRUE))
  expect_identical(
    msg,
    paste0("`binary` lists `sex`, but `sex` has 2 distinct ",
           "non-missing values (F, M). `binary` renders one ",
           "\"n (%)\" row and so needs an unambiguous event value: it ",
           "accepts logical, 0/1, or Yes/No data. Recode `sex` to ",
           "0/1, or move it to `categorical`, which shows every level.")
  )
})

test_that("hv_tbl_summary sends a constant binary column to categorical", {
  # A zero-event indicator (e.g. no complications in a baseline table)
  # already IS 0/1 -- "Recode to 0/1" is impossible advice here, since
  # gtsummary cannot dichotomize a column with no variation at all.
  dta <- data.frame(grp = factor(rep(c("A", "B"), each = 10)),
                    complication = rep(0L, 20))
  msg <- tryCatch(
    hv_tbl_summary(dta, by = "grp", groups = list(D = "complication"),
                   binary = "complication"),
    error = conditionMessage
  )
  expect_identical(
    msg,
    paste0("`binary` lists `complication`, but `complication` has 1 ",
           "distinct non-missing value (0). `binary` renders one ",
           "\"n (%)\" row and so needs an unambiguous event value: it ",
           "accepts logical, 0/1, or Yes/No data. A column with no ",
           "variation has no event to count; move `complication` to ",
           "`categorical`, which shows every level.")
  )
})

test_that("hv_tbl_summary suggests droplevels for an orphaned level", {
  # `elig` carries an unused "Maybe" level (e.g. after subsetting), so
  # nlevels() is 3 even though only Yes/No values are present. "Recode
  # to 0/1" is impossible advice here -- droplevels() is the real fix.
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = 5)),
    elig = factor(c(rep("Yes", 5), rep("No", 5)),
                  levels = c("No", "Yes", "Maybe"))
  )
  msg <- tryCatch(
    hv_tbl_summary(dta, by = "grp", groups = list(D = "elig"),
                   binary = "elig"),
    error = conditionMessage
  )
  expect_identical(
    msg,
    paste0("`binary` lists `elig`, but `elig` has 2 distinct ",
           "non-missing values (No, Yes). `binary` renders one ",
           "\"n (%)\" row and so needs an unambiguous event value: it ",
           "accepts logical, 0/1, or Yes/No data. `elig` is a factor ",
           "with 3 levels but only 2 appear in the data; droplevels() ",
           "may be what you want.")
  )
})

test_that("hv_tbl_summary accepts every binary form gtsummary can use", {
  n <- 20
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    zero_one = rep(0:1, n / 2),
    lgl = rep(c(TRUE, FALSE), n / 2),
    yn = factor(rep(c("Yes", "No"), n / 2), levels = c("No", "Yes"))
  )
  for (v in c("zero_one", "lgl", "yn")) {
    tbl <- hv_tbl_summary(dta, by = "grp", groups = list(D = v),
                          binary = v, compare = "none")
    expect_false(anyNA(tbl$table_body$stat_1))
  }
})

test_that("hv_tbl_summary rejects a column with no non-missing values", {
  dta <- data.frame(grp = factor(rep(c("A", "B"), each = 5)),
                    empty = rep(NA_character_, 10))
  expect_identical(
    tryCatch(
      hv_tbl_summary(dta, by = "grp", groups = list(D = "empty"),
                     categorical = "empty", compare = "none"),
      error = conditionMessage
    ),
    paste0("`categorical` lists `empty`, but `empty` has no ",
           "non-missing values, so every statistic for it would be ",
           "NA. Drop `empty` from `groups` and `categorical`, or ",
           "check the data.")
  )
})

test_that("hv_tbl_summary imposes no type rule on categorical", {
  # Factors, characters, and small-integer codes are all legitimate
  # CAT2= data; only the all-missing rule applies here.
  dta <- data.frame(grp = factor(rep(c("A", "B"), each = 10)),
                    nyha = rep(1:4, 5))
  tbl <- hv_tbl_summary(dta, by = "grp", groups = list(D = "nyha"),
                        categorical = "nyha", compare = "none")
  expect_s3_class(tbl, "gtsummary")
})

test_that("hv_tbl_summary rejects a groups section with no variables", {
  # Plausible whenever `groups` is built programmatically from a filter
  # that returns nothing. list() was already caught; a named-but-empty
  # section was not, and leaked a base-R message byte-identical to the
  # one the `by`-in-`groups` check was added to prevent.
  msg <- tryCatch(
    hv_tbl_summary(gtsummary::trial, by = "trt",
                   groups = list(Demo = character(0)),
                   continuous = character(0)),
    error = conditionMessage
  )
  expect_false(grepl("empty integer vector", msg, fixed = TRUE))
  expect_identical(
    msg,
    paste0("`groups` section `Demo` lists no variables. Every section ",
           "must name at least one variable, e.g. ",
           "list(Demo = c(\"age\")). Drop the empty section.")
  )
})

test_that("binary passes an explicit event value to gtsummary", {
  # Without `value =`, gtsummary guesses the event level and fails on a
  # haven_labelled column over a DOUBLE base type -- which is exactly
  # what haven::read_sas() produces, since every SAS numeric is an
  # 8-byte float. The integer-backed form happens to work, so this
  # reproduces only with as.double().
  skip_if_not_installed("haven")
  d <- data.frame(
    grp = factor(rep(c("A", "B"), each = 20)),
    flag = haven::labelled(as.double(rep(0:1, 20)), c(No = 0, Yes = 1))
  )
  expect_s3_class(
    suppressWarnings(hv_tbl_summary(
      d, by = "grp", groups = list(G = "flag"),
      binary = "flag", compare = "none"
    )),
    "gtsummary"
  )
})

test_that("every accepted binary shape counts the right event", {
  # The event is the "1"/TRUE/"Yes" side in each accepted encoding.
  # The split is deliberately uneven -- 15 events in each group of 20 --
  # because a 50/50 split renders identically whichever level is
  # counted, so it could not tell a correct event from an inverted one.
  # Correct is "15 (75%)"; counting the wrong side gives "5 (25%)".
  ev <- c(TRUE, TRUE, TRUE, FALSE)
  shapes <- list(
    integer = as.integer(rep(ev, 10)),
    double = as.double(rep(ev, 10)),
    logical = rep(ev, 10),
    factor_yn = factor(ifelse(rep(ev, 10), "Yes", "No")),
    char_lower = ifelse(rep(ev, 10), "yes", "no")
  )
  for (nm in names(shapes)) {
    d <- data.frame(grp = factor(rep(c("A", "B"), each = 20)),
                    flag = shapes[[nm]])
    tbl <- hv_tbl_summary(d, by = "grp", groups = list(G = "flag"),
                          binary = "flag", compare = "none")
    expect_identical(tbl$table_body$stat_1[1], "20 ||| 15 (75)",
                     info = nm)
  }
})

test_that("overall = TRUE adds exactly one column", {
  base <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = FALSE
  )
  with_total <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = TRUE
  )
  expect_equal(
    ncol(with_total$table_body) - ncol(base$table_body), 1L
  )
  expect_true("stat_0" %in% names(with_total$table_body))
})

test_that("overall = FALSE reproduces the previous output exactly", {
  # A real comparison against a table built directly from gtsummary
  # primitives with the same statistic/type/digits arguments
  # hv_tbl_summary() itself uses -- not just the absence of stat_0, which
  # would also pass for a table with the wrong stat_1/stat_2 values.
  dta <- mk_tbl_summary_data()
  actual <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    overall = FALSE
  )

  no_comma <- gtsummary::label_style_number(big.mark = "")
  reference <- gtsummary::tbl_summary(
    dta,
    by = gtsummary::all_of("grp"),
    include = gtsummary::all_of("age"),
    statistic = list(age = "{N_nonmiss} ||| {median} ({p15}, {p85})"),
    type = list(age = "continuous"),
    missing = "no",
    digits = list(
      gtsummary::everything() ~ list(N_nonmiss = no_comma, n = no_comma)
    )
  )

  expect_false("stat_0" %in% names(actual$table_body))
  expect_identical(actual$table_body$variable, reference$table_body$variable)
  expect_identical(actual$table_body$stat_1, reference$table_body$stat_1)
  expect_identical(actual$table_body$stat_2, reference$table_body$stat_2)
})

test_that("overall keeps its position for positional callers", {
  # The ninth positional argument has always been `overall`;
  # continuous_stat goes after it, so FALSE there still means "no
  # Overall column" rather than failing in match.arg() (Copilot, #49).
  tbl <- hv_tbl_summary(
    gtsummary::trial, "trt", list(Demography = "age"), "age",
    character(0), character(0), "pvalue", c(15, 85), FALSE
  )
  expect_false("stat_0" %in% names(tbl$table_body))
})

test_that("overall defaults to TRUE, the macro's TOTALCOL=1", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age"
  )
  expect_true("stat_0" %in% names(tbl$table_body))
})

test_that("overall is ignored when `by` is NULL", {
  # The single ungrouped column already is the overall one. This used to
  # error, but with TRUE the default an error would break every
  # ungrouped call.
  implicit <- hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                             continuous = "age")
  explicit <- hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                             continuous = "age", overall = TRUE)
  expect_identical(
    grep("^stat_", names(explicit$table_body), value = TRUE), "stat_0"
  )
  expect_identical(explicit$table_body$stat_0, implicit$table_body$stat_0)
})

test_that("continuous_stat = \"mean\" gives mean+/-SD without spaces", {
  dta <- data.frame(age = c(10, 20, 30, NA))
  tbl <- hv_tbl_summary(dta, groups = list(D = "age"), continuous = "age",
                        continuous_stat = "mean")
  expect_identical(tbl$table_body$stat_0, "3 ||| 20±10.0")
  expect_identical(attr(tbl, "hv_stat_label"), "No. (%) or Mean±SD")
})

test_that("mean/SD cells follow the paired EHB/Blackstone rule", {
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), c(4, 2))),
    value = c(100, 110, 130, 150, 113.5, 131.5)
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(D = "value"), continuous = "value",
    continuous_stat = "mean", overall = TRUE
  )

  # A: mean 122.5, SD 22.17 -> tens for mean, units for SD.
  expect_identical(tbl$table_body$stat_1, "4 ||| 120±22")
  # B: SD 12.73 begins with 1 -> units for mean, tenths for SD.
  # The exact 122.5 tie rounds to the even integer.
  expect_identical(tbl$table_body$stat_2, "2 ||| 122±12.7")
  # Overall: mean 122.5, SD 18.09 -> the same leading-1 exception.
  expect_identical(tbl$table_body$stat_0, "6 ||| 122±18.1")
})

test_that("EHB/Blackstone rounding treats only exact ties as ties", {
  dta <- data.frame(value = c(113.5001, 131.5001))
  tbl <- hv_tbl_summary(
    dta, groups = list(D = "value"), continuous = "value",
    continuous_stat = "mean"
  )

  expect_identical(tbl$table_body$stat_0, "2 ||| 123±12.7")
})

test_that("paired rounding changes only the mean row under both", {
  dta <- data.frame(value = c(100, 110, 130, 150))
  tbl <- hv_tbl_summary(
    dta, groups = list(D = "value"), continuous = "value",
    continuous_stat = "both"
  )

  expect_identical(tbl$table_body$stat_0[2], "4 ||| 120±22")
  expect_identical(
    tbl$table_body$stat_0[3], " ||| 120 (100, 150)"
  )
})

test_that("zero or unavailable SD keeps gtsummary's rendering", {
  zero_sd <- hv_tbl_summary(
    data.frame(value = rep(123.456, 4)),
    groups = list(D = "value"), continuous = "value",
    continuous_stat = "mean"
  )
  missing_sd <- suppressWarnings(hv_tbl_summary(
    data.frame(value = 123.456),
    groups = list(D = "value"), continuous = "value",
    continuous_stat = "mean"
  ))

  expect_identical(zero_sd$table_body$stat_0, "4 ||| 123.4560±0.0000")
  expect_identical(missing_sd$table_body$stat_0, "1 ||| 123.4560±NA")
})

test_that("continuous_stat = \"both\" puts mean and median on sub-rows", {
  dta <- data.frame(age = c(10, 20, 30, NA, 40, 50), g = c(0, 0, 0, 1, 1, 1))
  tbl <- hv_tbl_summary(
    dta, by = "g", groups = list(D = "age"), continuous = "age",
    continuous_stat = "both"
  )
  tb <- tbl$table_body
  expect_identical(tb$row_type, c("label", "level", "level"))
  expect_identical(
    tb$label[2:3], c("Mean±SD", "Median (15th, 85th percentile)")
  )
  # N once per variable, on the first sub-row; the second carries a
  # blank N that the renderers split into an empty cell.
  expect_identical(sub(" \\|\\|\\| .*$", "", tb$stat_1[2]), "3")
  expect_true(startsWith(tb$stat_1[3], " ||| "))
  # The comparison sits on the variable's label row, not a sub-row.
  expect_false(is.na(tb$hv_compare_col[1]))
  expect_true(all(is.na(tb$hv_compare_col[2:3])))
  expect_identical(
    attr(tbl, "hv_stat_label"),
    "No. (%), Mean±SD, or Median (15th, 85th percentile)"
  )
})

test_that("continuous_stat = \"both\" renders through both renderers", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both"
  )
  d <- hv_man_table(tbl)$body$dataset
  expect_false(any(grepl("|||", unlist(d), fixed = TRUE)))
  expect_identical(d$n_stat_1[d$label == "Median (15th, 85th percentile)"],
                   "")
  ft <- hv_man_table_jtcvs(
    tbl, groups = c(stat_0 = "Overall", stat_1 = "A", stat_2 = "B"),
    stat_label = attr(tbl, "hv_stat_label"),
    trailing = attr(tbl, "hv_trailing")
  )
  expect_s3_class(ft, "flextable")
})

test_that("overall must be a single TRUE or FALSE", {
  expect_error(
    hv_tbl_summary(gtsummary::trial, by = "trt",
                   groups = list(D = "age"), continuous = "age",
                   overall = "yes"),
    "`overall` must be TRUE or FALSE", fixed = TRUE
  )
})

test_that("overall = TRUE does not break the two-group guard for smd", {
  # stat_0 (Overall) must not be counted as one of the compared groups --
  # `trial$trt` genuinely has two levels, so this must not error.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = TRUE, compare = "smd"
  )
  stat_cols <- grep("^stat_", names(tbl$table_body), value = TRUE)
  expect_identical(stat_cols[1], "stat_0")
  expect_setequal(stat_cols, c("stat_0", "stat_1", "stat_2"))
  # SMD is computed between the two real groups; the Overall column must
  # not shift the estimate.
  ref <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = FALSE, compare = "smd"
  )
  expect_equal(tbl$table_body$estimate, ref$table_body$estimate)
})

test_that("overall = TRUE does not break the two-group guard for both", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = TRUE, compare = "both"
  )
  stat_cols <- grep("^stat_", names(tbl$table_body), value = TRUE)
  expect_identical(stat_cols[1], "stat_0")
  expect_setequal(stat_cols, c("stat_0", "stat_1", "stat_2"))
  last_cols <- utils::tail(names(tbl$table_body), 1)
  expect_identical(last_cols, "hv_compare_col")
})

test_that("three-level `by` + overall = TRUE + compare = smd still errors", {
  expect_error(
    hv_tbl_summary(gtsummary::trial, by = "grade",
                   groups = list(D = "age"), continuous = "age",
                   overall = TRUE, compare = "smd"),
    "requires exactly two groups"
  )
})

test_that("SAS QNTLDEF=5 corresponds to quantile type 2, not R's default", {
  # Guards the equivalence vignettes/sas-migration.Rmd documents. If a
  # future change routes percentiles through stats::quantile() directly
  # rather than gtsummary's {pXX}, this is the value that must hold.
  expect_equal(stats::quantile(c(1, 2, 3, 4), 0.25, type = 2,
                               names = FALSE), 1.5)
  expect_equal(stats::quantile(c(1, 2, 3, 4), 0.25, type = 7,
                               names = FALSE), 1.75)
})

# -- normal = (the macro's CON1=) ----------------------------------------

nm_tbl <- function(normal = "age", continuous_stat = "median",
                   compare = "none") {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(D = c("age", "marker", "grade")),
    continuous = c("age", "marker"), categorical = "grade",
    compare = compare, continuous_stat = continuous_stat, normal = normal
  )
}

nm_label <- function(tbl, v) {
  tb <- tbl$table_body
  tb$label[tb$variable == v & tb$row_type == "label"]
}

test_that("normal rejects names outside `continuous`, repeats, non-strings", {
  expect_error(
    nm_tbl(normal = "grade"),
    "`normal` variable(s) must also be listed in `continuous`: grade.",
    fixed = TRUE
  )
  expect_error(nm_tbl(normal = c("age", "age")),
               "`normal` lists a variable more than once: age.", fixed = TRUE)
  expect_error(nm_tbl(normal = 1), "`normal` must be a character vector",
               fixed = TRUE)
})

test_that("a normal variable shows mean±SD while the rest show medians", {
  tbl <- nm_tbl()
  tb <- tbl$table_body
  age <- tb$stat_1[tb$variable == "age"]
  marker <- tb$stat_1[tb$variable == "marker" & tb$row_type == "label"]
  expect_match(age, "^[0-9]+ \\|\\|\\| [0-9.]+±[0-9.]+$")
  expect_match(marker, "^[0-9]+ \\|\\|\\| [0-9.]+ \\([0-9.]+, [0-9.]+\\)$")
})

test_that("a mixed table names each continuous row's statistic", {
  tbl <- nm_tbl()
  expect_identical(nm_label(tbl, "age"), "Age, Mean±SD")
  expect_identical(nm_label(tbl, "marker"),
                   "Marker Level (ng/mL), Median (15th, 85th percentile)")
  expect_identical(nm_label(tbl, "grade"), "Grade")
  expect_identical(attr(tbl, "hv_stat_label"),
                   "No. (%) or as labeled")
  expect_identical(attr(tbl, "hv_footnotes")[["†"]],
                   "No. (%) or as labeled.")
})

test_that("an unmixed table keeps plain labels and one stated statistic", {
  all_normal <- nm_tbl(normal = c("age", "marker"))
  expect_identical(nm_label(all_normal, "age"), "Age")
  expect_identical(attr(all_normal, "hv_stat_label"), "No. (%) or Mean±SD")
  # Every row shows mean±SD; only the test differs, which the
  # comparison footnotes carry.
  mean_tbl <- nm_tbl(continuous_stat = "mean")
  expect_identical(nm_label(mean_tbl, "age"), "Age")
  expect_identical(attr(mean_tbl, "hv_stat_label"), "No. (%) or Mean±SD")
})

test_that("under 'both' a normal variable is one suffixed row", {
  tbl <- nm_tbl(continuous_stat = "both")
  tb <- tbl$table_body
  expect_identical(nm_label(tbl, "age"), "Age, Mean±SD")
  expect_identical(sum(tb$variable == "age"), 1L)
  expect_identical(
    tb$label[tb$variable == "marker" & tb$row_type == "level"],
    c("Mean±SD", "Median (15th, 85th percentile)")
  )
})

test_that("a normal variable is tested with pooled-variance one-way ANOVA", {
  skip_if_not_installed("broom")
  tbl <- nm_tbl(compare = "pvalue")
  tb <- tbl$table_body
  expect_identical(tb$test_name[tb$variable == "age"], "oneway.test")
  expect_identical(tb$test_name[tb$variable == "marker"][1], "wilcox.test")
  # The macro's npar1way anova; for two groups, a pooled t-test.
  want <- stats::t.test(age ~ trt, gtsummary::trial,
                        var.equal = TRUE)$p.value
  expect_equal(unname(tb$p.value[tb$variable == "age"]), want)
  notes <- hv_test_footnotes_jtcvs(tbl)
  expect_true("One-way analysis of variance." %in%
                vapply(notes, `[[`, "", "text"))
})

# -- mean_sd = (display mean±SD, keep the nonparametric test) ------------

ms_tbl <- function(mean_sd = "age", normal = character(0),
                   continuous_stat = "median", compare = "none") {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(D = c("age", "marker", "grade")),
    continuous = c("age", "marker"), categorical = "grade",
    compare = compare, continuous_stat = continuous_stat, normal = normal,
    mean_sd = mean_sd
  )
}

test_that("mean_sd rejects names outside `continuous`, repeats, non-strings", {
  expect_error(
    ms_tbl(mean_sd = "grade"),
    "`mean_sd` variable(s) must also be listed in `continuous`: grade.",
    fixed = TRUE
  )
  expect_error(ms_tbl(mean_sd = c("age", "age")),
               "`mean_sd` lists a variable more than once: age.",
               fixed = TRUE)
  expect_error(ms_tbl(mean_sd = 1), "`mean_sd` must be a character vector",
               fixed = TRUE)
})

test_that("a mean_sd variable shows mean±SD and names it, like normal", {
  tbl <- ms_tbl()
  tb <- tbl$table_body
  expect_match(tb$stat_1[tb$variable == "age"],
               "^[0-9]+ \\|\\|\\| [0-9.]+±[0-9.]+$")
  expect_match(tb$stat_1[tb$variable == "marker" & tb$row_type == "label"],
               "^[0-9]+ \\|\\|\\| [0-9.]+ \\([0-9.]+, [0-9.]+\\)$")
  expect_identical(nm_label(tbl, "age"), "Age, Mean±SD")
  expect_identical(attr(tbl, "hv_stat_label"), "No. (%) or as labeled")
  # The display matches normal = "age" exactly; only the test differs.
  expect_identical(tb$stat_1, nm_tbl()$table_body$stat_1)
})

test_that("a mean_sd variable keeps the Wilcoxon test, not ANOVA", {
  skip_if_not_installed("broom")
  tb <- ms_tbl(compare = "pvalue")$table_body
  expect_identical(tb$test_name[tb$variable == "age"], "wilcox.test")
  want <- suppressWarnings(
    stats::wilcox.test(age ~ trt, gtsummary::trial)$p.value
  )
  expect_equal(unname(tb$p.value[tb$variable == "age"]), want,
               tolerance = 1e-6)
})

test_that("mean_sd keeps its position after normal for positional callers", {
  f <- names(formals(hv_tbl_summary))
  expect_identical(f[match("normal", f) + 1L], "mean_sd")
})

test_that("normal and mean_sd may name the same variable; normal's test wins", {
  skip_if_not_installed("broom")
  tb <- ms_tbl(normal = "age", compare = "pvalue")$table_body
  expect_identical(tb$test_name[tb$variable == "age"], "oneway.test")
})

# -- show_variable = (the raw column name beside the label) --------------

sv_tbl <- function(...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", ...
  )
}

test_that("show_variable puts the column name on each variable's first row", {
  tb <- sv_tbl()$table_body
  expect_identical(names(tb)[match("label", names(tb)) + 1L], "hv_variable")
  expect_identical(tb$hv_variable[tb$row_type == "label"], c("age", "grade"))
  expect_true(all(is.na(tb$hv_variable[tb$row_type != "label"])))
})

test_that("show_variable's column is visible and headed Variable", {
  st <- sv_tbl()$table_styling$header
  row <- st[st$column == "hv_variable", ]
  expect_false(row$hide)
  expect_identical(row$label, "**Variable**")
})

test_that("show_variable = FALSE leaves the table as it was", {
  tbl <- sv_tbl(show_variable = FALSE)
  expect_false("hv_variable" %in% names(tbl$table_body))
})

test_that("show_variable must be a single TRUE or FALSE", {
  for (bad in list(NA, "yes", c(TRUE, FALSE), 1)) {
    expect_error(sv_tbl(show_variable = bad),
                 "`show_variable` must be TRUE or FALSE.", fixed = TRUE)
  }
})

test_that("show_variable follows mean_sd for positional callers", {
  f <- names(formals(hv_tbl_summary))
  expect_identical(f[match("mean_sd", f) + 1L], "show_variable")
})

test_that("the variable column renders beside the label in both renderers", {
  tbl <- sv_tbl()
  ft <- hv_man_table(tbl)
  expect_identical(ft$col_keys[2], "hv_variable")
  d <- ft$body$dataset
  expect_identical(d$hv_variable[d$label == "Age"], "age")
  # The section row, which hv_man_table() inserts, carries no name.
  expect_true(is.na(d$hv_variable[d$label == "D"]) ||
                d$hv_variable[d$label == "D"] == "")
  jt <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
  expect_identical(jt$col_keys[2], "hv_variable")
  expect_identical(jt$body$dataset$hv_variable[
    jt$body$dataset$label == "Age"], "age")
  chunks <- flextable::information_data_chunk(jt)
  hdr <- chunks[chunks$.part == "header" & chunks$.col_id == "hv_variable", ]
  expect_true(all(hdr$txt == "Variable"))
})

test_that("the variable column survives into a saved, valid .docx", {
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(sv_tbl()), path)
  expect_identical(nrow(hv_check_docx(path)), 0L)
  jpath <- tempfile(fileext = ".docx")
  tbl <- sv_tbl(compare = "pvalue")
  hv_man_table_save_jtcvs(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       trailing = attr(tbl, "hv_trailing")),
    jpath, caption = "T1."
  )
  expect_true(file.exists(jpath))
})

# -- cutexact = (%summarytable's CUTEXACT=: Fisher's exact when sparse) ---

# 2 groups x 2 levels. `rare` makes cells with expected count < 5:
# with 40 per group and 4 events in all, both "1" cells expect 2.
ce_data <- function() {
  data.frame(
    grp = rep(c("A", "B"), each = 40),
    # 2 of 4 cells expect < 5: 50% exactly.
    rare = c(rep(1, 3), rep(0, 37), rep(1, 1), rep(0, 39)),
    # No cell expects < 5.
    common = rep(c(0, 1), 40),
    # 3 levels x 2 groups, 2 of 6 cells (33%) expect < 5.
    tri = c(rep("x", 20), rep("y", 18), "z", "z",
            rep("x", 20), rep("y", 18), "z", "z")
  )
}

ce_tbl <- function(cutexact = 50, compare = "pvalue") {
  hv_tbl_summary(
    ce_data(), by = "grp",
    groups = list(D = c("rare", "common", "tri")),
    binary = c("rare", "common"), categorical = "tri",
    compare = compare, cutexact = cutexact, show_variable = FALSE
  )
}

ce_test <- function(tbl, v) {
  tb <- tbl$table_body
  tb$test_name[tb$variable == v & tb$row_type == "label"]
}

test_that(".cutexact_tests ports the macro's percentage-of-cells rule", {
  d <- ce_data()
  vars <- c("rare", "common", "tri")
  f <- "fisher.test"
  ch <- "chisq.test.no.correct"
  expect_identical(.cutexact_tests(d, "grp", vars, 50),
                   c(rare = f, common = ch, tri = ch))
  # The comparison is >=, as the macro's "ge": 33.3% meets 33.
  expect_identical(.cutexact_tests(d, "grp", vars, 33),
                   c(rare = f, common = ch, tri = f))
  expect_identical(.cutexact_tests(d, "grp", vars, 51)[["rare"]], ch)
  # 0 is the macro's "exact tests only"; above 100, never.
  expect_identical(unname(.cutexact_tests(d, "grp", vars, 0)), rep(f, 3))
  expect_identical(unname(.cutexact_tests(d, "grp", vars, 101)),
                   rep(ch, 3))
})

test_that(".cutexact_tests counts cells over observed levels only", {
  d <- ce_data()
  # An unused factor level is not a cell; SAS never knew it existed.
  d$tri <- factor(d$tri, levels = c("x", "y", "z", "never"))
  expect_identical(.cutexact_tests(d, "grp", "tri", 34)[["tri"]],
                   "chisq.test.no.correct")
})

test_that("hv_tbl_summary picks each categorical test by cutexact", {
  skip_if_not_installed("broom")
  tbl <- ce_tbl()
  expect_identical(ce_test(tbl, "rare"), "fisher.test")
  expect_identical(ce_test(tbl, "common"), "chisq.test.no.correct")
  # gtsummary's own default would give tri Fisher (any cell < 5); the
  # macro's 50% rule gives chi-square.
  expect_identical(ce_test(tbl, "tri"), "chisq.test.no.correct")
  d <- ce_data()
  want <- stats::chisq.test(table(d$grp, d$tri), correct = FALSE)$p.value
  tb <- tbl$table_body
  expect_equal(unname(tb$p.value[tb$variable == "tri"][1]), want)
  expect_identical(ce_test(ce_tbl(cutexact = 0), "common"), "fisher.test")
  expect_identical(ce_test(ce_tbl(cutexact = 101), "rare"),
                   "chisq.test.no.correct")
})

test_that("cutexact must be a single number from 0 up", {
  for (bad in list(-1, NA_real_, c(10, 20), "50")) {
    expect_error(ce_tbl(cutexact = bad),
                 "`cutexact` must be a single number from 0 up",
                 fixed = TRUE)
  }
})

test_that("cutexact is last in the signature", {
  f <- names(formals(hv_tbl_summary))
  expect_identical(f[length(f) - 1L], "cutexact")
})

test_that("a Fisher p-value is marked ‡ in the CORR table and footnoted", {
  skip_if_not_installed("broom")
  tbl <- ce_tbl()
  expect_identical(attr(tbl, "hv_footnotes")[["‡"]], "Fisher exact test.")
  ft <- hv_man_table(tbl)
  chunks <- flextable::information_data_chunk(ft)
  p <- chunks[chunks$.part == "body" & chunks$.col_id == "p.value", ]
  marked <- unique(p$.row_id[p$txt == "‡"])
  d <- ft$body$dataset
  expect_identical(d$label[marked], "rare")
  # The mark is on the cell, not the header: a header ‡ would claim
  # every p-value for Fisher.
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  saved <- officer::docx_summary(officer::read_docx(path))
  expect_true(any(grepl("Fisher exact test.", saved$text, fixed = TRUE)))
  hdr <- saved$text[saved$content_type == "table cell" & saved$is_header]
  expect_false(any(grepl("\u2021", hdr)))
  expect_true(any(grepl("\u2021", saved$text[
    saved$content_type == "table cell" & !saved$is_header])))
  expect_identical(nrow(hv_check_docx(path)), 0L)
})

test_that("no Fisher row, no ‡ footnote and no mark", {
  skip_if_not_installed("broom")
  tbl <- ce_tbl(cutexact = 101)
  expect_null(attr(tbl, "hv_footnotes")[["‡"]])
  chunks <- flextable::information_data_chunk(hv_man_table(tbl))
  expect_false(any(chunks$txt == "‡"))
})

test_that("the JTCVS test footnotes letter the Fisher row", {
  skip_if_not_installed("broom")
  notes <- hv_test_footnotes_jtcvs(ce_tbl())
  expect_true("Fisher exact test." %in% vapply(notes, `[[`, "", "text"))
})

test_that("saving a ‡-marked table with footnotes lacking ‡ fails loud", {
  skip_if_not_installed("broom")
  ft <- hv_man_table(ce_tbl())
  expect_error(
    hv_man_table_save(ft, tempfile(fileext = ".docx"),
                      footnotes = hv_man_footnotes()),
    "The table marks p-values with \u2021, but `footnotes` has no \u2021 entry",
    fixed = TRUE
  )
})
