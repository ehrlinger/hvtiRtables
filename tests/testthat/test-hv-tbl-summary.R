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
  expected <- "No. (%) or Median [15th, 85th percentiles]"
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
    "No. (%) or Median [1st, 2nd percentiles]"
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
    "^[0-9]+ \\|\\|\\| [0-9.]+ \\[[0-9.]+, [0-9.]+\\]$"
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
  expect_gt(length(jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))), 0)
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
  # The header names the SMD, as it names percent, so the cell does not.
  cell <- tbl$table_body$hv_compare_col[tbl$table_body$row_type == "label"]
  expect_match(cell, "^(<)?[0-9.]+ \\(-?[0-9.]+\\)$")
  expect_false(grepl("SMD", cell))
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
    expect_match(val, "^(<)?[0-9.]+ \\(-?[0-9.]+\\)$", info = v)
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

  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl,
    groups = c(
      stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"
    ),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  ))
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

test_that("overall = FALSE matches gtsummary's layout, in house notation", {
  # A real comparison against a table built directly from gtsummary
  # primitives with the same statistic/type/digits arguments
  # hv_tbl_summary() itself uses -- not just the absence of stat_0, which
  # would also pass for a table with the wrong stat_1/stat_2 values.
  #
  # The reference's own median text is gtsummary's old rounding, so its
  # numbers are taken from its cards and shown in the house notation here:
  # brackets, and whole numbers because every value is 10 or more. R's
  # round() sends a tie to the even digit (62.5 to 62, not gtsummary's 63),
  # as the EHB paired rule for mean and SD does.
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
  cards <- reference$cards$tbl_summary
  want <- function(column) {
    s <- cards[cards$gts_column == column, ]
    get <- function(name) as.numeric(unlist(s$stat[s$stat_name == name]))
    sprintf("%d ||| %d [%d, %d]", as.integer(get("N_nonmiss")),
            as.integer(round(get("median"))), as.integer(round(get("p15"))),
            as.integer(round(get("p85"))))
  }

  expect_false("stat_0" %in% names(actual$table_body))
  expect_identical(actual$table_body$variable, reference$table_body$variable)
  expect_identical(actual$table_body$stat_1, want("stat_1"))
  expect_identical(actual$table_body$stat_2, want("stat_2"))
  # The counts and everything else about the layout are gtsummary's own.
  expect_identical(
    sub(" .*$", "", actual$table_body$stat_1),
    sub(" .*$", "", reference$table_body$stat_1)
  )
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

test_that("paired rounding changes only the mean column under both", {
  dta <- data.frame(value = c(100, 110, 130, 150))
  tbl <- hv_tbl_summary(
    dta, groups = list(D = "value"), continuous = "value",
    continuous_stat = "both"
  )

  expect_identical(tbl$table_body$stat_0, "4 ||| 120±22")
  expect_identical(tbl$table_body$hv_median_stat_0, "120 [100, 150]")
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

test_that("continuous_stat = \"both\" puts mean and median side by side", {
  dta <- data.frame(age = c(10, 20, 30, NA, 40, 50), g = c(0, 0, 0, 1, 1, 1))
  tbl <- hv_tbl_summary(
    dta, by = "g", groups = list(D = "age"), continuous = "age",
    continuous_stat = "both"
  )
  tb <- tbl$table_body
  # One row per variable: no sub-rows to stack.
  expect_identical(tb$row_type, "label")
  expect_match(tb$stat_1, "^3 \\|\\|\\| 20±[0-9.]+$")
  expect_identical(tb$hv_median_stat_1, "20 [10, 30]")
  expect_identical(tb$hv_median_stat_0, "30 [10, 50]")
  expect_false(is.na(tb$hv_compare_col))
  # The statistic columns hold mean±SD; the median columns name
  # themselves in their own header.
  expect_identical(attr(tbl, "hv_stat_label"), "No. (%) or Mean±SD")
  expect_identical(attr(tbl, "hv_median_label"),
                   "Median [15th, 85th percentiles]")
  st <- tbl$table_styling$header
  expect_false(st$hide[st$column == "hv_median_stat_1"])
  expect_match(st$label[st$column == "hv_median_stat_1"],
               "Median \\[15th, 85th percentiles\\]")
})

test_that("under 'both' the median column is blank on other rows", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(D = c("age", "marker", "grade", "response")),
    continuous = c("age", "marker"), categorical = "grade",
    binary = "response", continuous_stat = "both", mean_sd = "marker"
  )
  tb <- tbl$table_body
  has_med <- !is.na(tb$hv_median_stat_1)
  expect_identical(tb$variable[has_med], "age")
  expect_identical(tb$label[tb$variable == "marker"],
                   "Marker Level (ng/mL)")
})

test_that("continuous_stat = \"both\" renders through both renderers", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both"
  )
  corr <- hv_man_table(tbl)
  d <- corr$body$dataset
  expect_false(any(grepl("|||", unlist(d), fixed = TRUE)))
  expect_identical(
    corr$col_keys[match("stat_1", corr$col_keys) + c(-1L, 1L)],
    c("n_stat_1", "hv_median_stat_1")
  )
  expect_match(d$hv_median_stat_1[d$label == "Age"], "^[0-9]+ \\[")
  jt <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_0 = "Overall", stat_1 = "A", stat_2 = "B"),
    trailing = attr(tbl, "hv_trailing")
  ))
  expect_identical(
    jt$col_keys[match("disp_stat_1", jt$col_keys) + c(-1L, 1L)],
    c("n_stat_1", "med_stat_1")
  )
  jd <- jt$body$dataset
  expect_identical(jd$med_stat_1[jd$label == "Age"],
                   d$hv_median_stat_1[d$label == "Age"])
  chunks <- flextable::information_data_chunk(jt)
  h <- chunks[chunks$.part == "header" & chunks$.col_id == "med_stat_1", ]
  expect_true(any(h$txt == "Median [15th, 85th percentiles]"))
  expect_true(any(h$txt == "A"))
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(corr, path)
  expect_identical(nrow(hv_check_docx(path)), 0L)
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
  # hv_n is hidden bookkeeping, not a column the reader sees.
  shown <- setdiff(names(tbl$table_body), "hv_n")
  expect_identical(utils::tail(shown, 1), "hv_compare_col")
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
  expect_match(marker, "^[0-9]+ \\|\\|\\| [0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
})

test_that("a mixed table marks the minority statistic, not the row labels", {
  # One mean row against one median row is a tie, so the median is the
  # default: the dagger names it, and the mean cells carry a pilcrow.
  tbl <- nm_tbl()
  expect_identical(nm_label(tbl, "age"), "Age")
  expect_identical(nm_label(tbl, "marker"), "Marker Level (ng/mL)")
  expect_identical(nm_label(tbl, "grade"), "Grade")
  expect_identical(attr(tbl, "hv_stat_label"),
                   "No. (%) or Median [15th, 85th percentiles]")
  expect_identical(attr(tbl, "hv_cell_marks"),
                   list(symbol = "\u00B6", variables = "age"))
  fn <- attr(tbl, "hv_footnotes")
  expect_identical(fn[["\u2020"]],
                   "No. (%) or Median [15th, 85th percentiles].")
  expect_identical(fn[["\u00B6"]], "Mean\u00B1SD.")
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

test_that("under 'both' a normal variable has a blank median", {
  tbl <- nm_tbl(continuous_stat = "both")
  tb <- tbl$table_body
  expect_identical(nm_label(tbl, "age"), "Age")
  expect_identical(sum(tb$variable == "age"), 1L)
  expect_true(is.na(tb$hv_median_stat_1[tb$variable == "age"]))
  expect_false(is.na(tb$hv_median_stat_1[tb$variable == "marker"]))
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
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
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

test_that("a mean_sd variable shows mean±SD and marks it, like normal", {
  tbl <- ms_tbl()
  tb <- tbl$table_body
  expect_match(tb$stat_1[tb$variable == "age"],
               "^[0-9]+ \\|\\|\\| [0-9.]+±[0-9.]+$")
  expect_match(tb$stat_1[tb$variable == "marker" & tb$row_type == "label"],
               "^[0-9]+ \\|\\|\\| [0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
  expect_identical(nm_label(tbl, "age"), "Age")
  expect_identical(attr(tbl, "hv_stat_label"),
                   "No. (%) or Median [15th, 85th percentiles]")
  expect_identical(attr(tbl, "hv_cell_marks")$variables, "age")
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

test_that("the report view shows the variable column beside the label", {
  tbl <- sv_tbl()
  ft <- hv_man_table(tbl)
  expect_identical(ft$col_keys[2], "hv_variable")
  d <- ft$body$dataset
  expect_identical(d$hv_variable[d$label == "Age"], "age")
  # The section row, which hv_man_table() inserts, carries no name.
  expect_true(is.na(d$hv_variable[d$label == "D"]) ||
                d$hv_variable[d$label == "D"] == "")
  shown <- hv_man_table_display(ft)
  expect_identical(shown$col_keys[2], "hv_variable")
  chunks <- flextable::information_data_chunk(shown)
  hdr <- chunks[chunks$.part == "header" & chunks$.col_id == "hv_variable", ]
  expect_identical(paste(hdr$txt, collapse = ""), "Variable")
})

test_that("a JTCVS table, always a manuscript, never shows the column", {
  tbl <- sv_tbl()
  jt <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B")
  ))
  expect_false("hv_variable" %in% jt$col_keys)
  chunks <- flextable::information_data_chunk(jt)
  expect_false(any(chunks$txt == "Variable"))
  expect_false(any(chunks$.part == "body" & chunks$txt == "age"))
})

# Every table cell of a saved .docx, header and body.
sv_cells <- function(path) {
  s <- officer::docx_summary(officer::read_docx(path))
  s[s$content_type == "table cell", ]
}

test_that("a saved CORR table never has the variable column", {
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(sv_tbl()), path)
  cells <- sv_cells(path)
  expect_false(any(cells$text == "Variable"))
  # The raw names "age" and "grade" appear nowhere; the labels do.
  expect_false(any(cells$text %in% c("age", "grade")))
  expect_true(all(c("Age", "Grade") %in% cells$text))
  expect_identical(nrow(hv_check_docx(path)), 0L)
})

test_that("a saved JTCVS table never has the variable column", {
  skip_if_not_installed("broom")
  tbl <- sv_tbl(compare = "pvalue")
  path <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       trailing = attr(tbl, "hv_trailing")),
    path, caption = "T1."
  ))
  cells <- sv_cells(path)
  expect_false(any(cells$text == "Variable"))
  expect_false(any(cells$text %in% c("age", "grade")))
})

test_that("the JTCVS saver drops the column from any flextable", {
  # hv_man_table_jtcvs() no longer builds it, so the saver's drop is the
  # guard for a flextable that carries it some other way.
  path <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    hv_man_table(sv_tbl()), path, caption = "T1."
  ))
  cells <- sv_cells(path)
  expect_false(any(cells$text == "Variable"))
  expect_false(any(cells$text %in% c("age", "grade")))
})

test_that("the saved width leaves the variable column out", {
  # Every width set by hand, in whole half-inches (exact twips), so the
  # result does not depend on a platform's font metrics: 10.0 in with the
  # Variable column, past landscape's 9.03 in text block, and 9.0 in
  # without it, inside. Dropped first, the table fits unnarrowed and is
  # written at exactly 9.0 in. Fitted first, it would be narrowed to
  # 9.02 in and then lose its 1.0 in column: an 8.118 in grid.
  ft <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both",
    overall = FALSE, compare = "none"
  ))
  others <- setdiff(ft$col_keys, c("label", "hv_variable"))
  ft <- flextable::width(ft, j = others, width = 0.5)
  ft <- flextable::width(ft, j = "hv_variable", width = 1.0)
  ft <- flextable::width(ft, j = "label", width = 9.0 - 0.5 * length(others))
  expect_equal(sum(ft$body$colwidths), 10.0)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  g <- fit_geometry(path)
  expect_identical(g$table, 9.0 * 1440)
  expect_true(g$landscape)
})

test_that("a table that fits portrait without its variable column stays so", {
  skip_if_not_installed("broom")
  ft <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", overall = FALSE,
    compare = "pvalue"
  ))
  # Widen the label so the table is 6.8 in with the column (past a
  # portrait page's 6.53) and 5.9 in without it.
  extra <- 6.8 - sum(ft$body$colwidths)
  ft <- flextable::width(ft, j = "label",
                         width = ft$body$colwidths[["label"]] + extra)
  expect_gt(sum(ft$body$colwidths), 6.53)
  expect_lt(sum(ft$body$colwidths) - ft$body$colwidths[["hv_variable"]], 6.53)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  expect_false(fit_geometry(path)$landscape)
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
  # The fixture is sparse on purpose, so the reference test warns that
  # its approximation may be poor; the p-value is what is compared.
  want <- suppressWarnings(
    stats::chisq.test(table(d$grp, d$tri), correct = FALSE)$p.value
  )
  tb <- tbl$table_body
  expect_equal(unname(tb$p.value[tb$variable == "tri"][1]), want)
  expect_identical(ce_test(ce_tbl(cutexact = 0), "common"), "fisher.test")
  expect_identical(ce_test(ce_tbl(cutexact = 101), "rare"),
                   "chisq.test.no.correct")
})

test_that("cutexact must be \"any\" or a single number from 0 up", {
  for (bad in list(-1, NA_real_, c(10, 20), "50", "all", NA_character_)) {
    expect_error(ce_tbl(cutexact = bad),
                 "`cutexact` must be \"any\" or a single number from 0 up",
                 fixed = TRUE)
  }
})

test_that("cutexact defaults to \"any\", Fisher when any cell expects < 5", {
  expect_identical(formals(hv_tbl_summary)$cutexact, "any")
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(
    ce_data(), by = "grp",
    groups = list(D = c("rare", "common", "tri")),
    binary = c("rare", "common"), categorical = "tri",
    compare = "pvalue", show_variable = FALSE
  )
  # tri has 2 of 6 sparse cells: Fisher under "any", chi-square under
  # the macro's 50%.
  expect_identical(ce_test(tbl, "tri"), "fisher.test")
  expect_identical(ce_test(tbl, "rare"), "fisher.test")
  expect_identical(ce_test(tbl, "common"), "chisq.test.no.correct")
  expect_identical(ce_test(ce_tbl(cutexact = 50), "tri"),
                   "chisq.test.no.correct")
})

test_that("the \"any\" default leaves categorical tests as gtsummary chose", {
  skip_if_not_installed("broom")
  # The previous release called add_p() with no categorical tests, so
  # gtsummary picked them. The default must reproduce that exactly,
  # unused factor levels and all.
  d <- ce_data()
  d$tri <- factor(d$tri, levels = c("x", "y", "z", "never"))
  ours <- hv_tbl_summary(
    d, by = "grp", groups = list(D = c("rare", "common", "tri")),
    binary = c("rare", "common"), categorical = "tri",
    compare = "pvalue", show_variable = FALSE, overall = FALSE
  )$table_body
  theirs <- gtsummary::tbl_summary(
    d, by = "grp", include = c("rare", "common", "tri"),
    type = list(rare ~ "dichotomous", common ~ "dichotomous"),
    value = list(rare ~ 1, common ~ 1), missing = "no"
  ) |> gtsummary::add_p()
  theirs <- theirs$table_body
  first <- function(tb) tb[tb$row_type == "label", ]
  expect_identical(first(ours)$test_name, first(theirs)$test_name)
  expect_equal(first(ours)$p.value, first(theirs)$p.value)
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
  body <- saved$text[saved$content_type == "table cell" & !saved$is_header]
  expect_true(any(grepl("\u2021", body)))
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
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(ce_tbl()))
  expect_true("Fisher exact test." %in% vapply(notes, `[[`, "", "text"))
})

test_that("saving a ‡-marked table with footnotes lacking ‡ fails loud", {
  skip_if_not_installed("broom")
  ft <- hv_man_table(ce_tbl())
  expect_error(
    hv_man_table_save(ft, tempfile(fileext = ".docx"),
                      footnotes = hv_man_footnotes()),
    "The table marks cells with \u2021 for \"Fisher exact test.\", so",
    fixed = TRUE
  )
})

test_that("a two-group 'both' table counts its median columns as wide", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", continuous_stat = "both", overall = FALSE
  )
  expect_true(.is_wide(hv_man_table(tbl)))
  narrow <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", overall = FALSE
  )
  expect_false(.is_wide(hv_man_table(narrow)))
})

test_that("an ungrouped 'both' table heads its median column plainly", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, groups = list(D = "age"), continuous = "age",
    continuous_stat = "both"
  )
  st <- tbl$table_styling$header
  expect_identical(st$label[st$column == "hv_median_stat_0"],
                   "**Median [15th, 85th percentiles]**")
})

test_that("a study footnote may not reuse the Fisher mark's symbol", {
  skip_if_not_installed("broom")
  ft <- hv_man_table(ce_tbl())
  expect_error(
    hv_man_table_save(
      ft, tempfile(fileext = ".docx"),
      footnotes = c(hv_man_footnotes(),
                    stats::setNames(list("Adjusted."), "\u2021"))
    ),
    "The table marks cells with \u2021 for \"Fisher exact test.\", so",
    fixed = TRUE
  )
})

test_that("a malformed footnotes list is named as such on a marked table", {
  skip_if_not_installed("broom")
  ft <- hv_man_table(ce_tbl())
  expect_error(
    hv_man_table_save(ft, tempfile(fileext = ".docx"),
                      footnotes = list("text")),
    "`footnotes` must be a named list", fixed = TRUE
  )
})

test_that("under the \"any\" default a Fisher row is still marked ‡", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(
    ce_data(), by = "grp", groups = list(D = c("tri", "common")),
    binary = "common", categorical = "tri", compare = "pvalue",
    show_variable = FALSE
  )
  expect_identical(attr(tbl, "hv_footnotes")[["‡"]],
                   "Fisher exact test.")
  chunks <- flextable::information_data_chunk(hv_man_table(tbl))
  expect_true(any(chunks$.part == "body" & chunks$txt == "‡"))
})

test_that("a categorical missing in every grouped row is tested, not fatal", {
  skip_if_not_installed("broom")
  # Its only values sit in rows whose group is missing, so within the
  # groups there is nothing to tabulate. The CUTEXACT rule sees an empty
  # table; the variable is shown with zero counts and no p-value.
  d <- data.frame(
    grp = c(rep("A", 20), rep("B", 20), rep(NA, 4)),
    x = seq_len(44),
    cat = factor(c(rep(NA, 40), "u", "v", "u", "v"))
  )
  expect_identical(.cutexact_tests(d, "grp", "cat", 50),
                   c(cat = "chisq.test.no.correct"))
  tbl <- suppressMessages(hv_tbl_summary(
    d, by = "grp", groups = list(D = c("x", "cat")), continuous = "x",
    categorical = "cat", compare = "pvalue", cutexact = 50,
    show_variable = FALSE
  ))
  tb <- tbl$table_body
  levels_1 <- tb$stat_1[tb$variable == "cat" & tb$row_type == "level"]
  expect_identical(levels_1, c("0 ||| 0 (NA)", "0 ||| 0 (NA)"))
  expect_true(is.na(tb$p.value[tb$variable == "cat"][1]))
})

test_that("a ‡ footnote with no Fisher p-value marks no cell", {
  skip_if_not_installed("broom")
  # hv_tbl_summary() adds the footnote only when a Fisher test ran, so
  # this is a caller's hand-set footnote on a chi-square-only table.
  tbl <- ce_tbl(cutexact = 101)
  attr(tbl, "hv_footnotes")[["‡"]] <- "Fisher exact test."
  ft <- hv_man_table(tbl)
  chunks <- flextable::information_data_chunk(ft)
  expect_false(any(chunks$.part == "body" & chunks$txt == "‡"))
  expect_null(attr(ft, "hv_body_marks"))
})

test_that(".format_sig2() gives 2 significant digits, whole from 10 up", {
  x <- c(9.9, 0.31, 102.4, 0.8, 7, 9.96, 0, -0.0123, 18250.4, 2.067, 0.153,
         0.0049, NA, Inf)
  expect_identical(
    .format_sig2(x),
    c("9.9", "0.31", "102", "0.80", "7.0", "10", "0", "-0.012", "18250", "2.1",
      "0.15", "0.0049", NA, NA)
  )
})

test_that(".format_sig2() rounds exact ties to even, like the EHB mean rule", {
  expect_identical(.format_sig2(c(62.5, 63.5, 1.25)), c("62", "64", "1.2"))
})

test_that(".format_sig2() handles empty input and rounding boundaries", {
  expect_identical(.format_sig2(numeric(0)), character(0))
  expect_identical(.format_sig2(99.6), "100")
  expect_identical(.format_sig2(9.95), "10")
})

test_that("a mixed table with a Fisher test orders its notes canonically", {
  skip_if_not_installed("broom")
  d <- data.frame(
    grp = rep(c("A", "B"), each = 40),
    rare = c(rep(1, 3), rep(0, 37), rep(1, 1), rep(0, 39)),
    x = seq_len(80),
    y = rev(seq_len(80)) %% 7
  )
  tbl <- hv_tbl_summary(d, by = "grp", groups = list(D = c("rare", "x", "y")),
                        binary = "rare", continuous = c("x", "y"),
                        mean_sd = "x", compare = "pvalue", cutexact = 50,
                        show_variable = FALSE)
  expect_identical(names(attr(tbl, "hv_footnotes")),
                   c("*", "\u2020", "\u2021", "\u00B6"))
})

test_that(".format_sig2() keeps whole numbers past the integer range", {
  # formatC(format = "d") coerces to R integers: 2.2e9 and 1e12 became "NA"
  # with a warning. Whole numbers stay doubles.
  expect_no_warning(out <- .format_sig2(c(2147483647, 2.2e9, 1e12, -3e10)))
  expect_identical(out, c("2147483647", "2200000000", "1000000000000",
                          "-30000000000"))
})

test_that("a median is shown in brackets, to 2 significant digits", {
  d <- data.frame(
    g = rep(c("a", "b"), each = 9),
    x = c(5, 20, 63, 80, 102.4, 110, 150, 170.3, 400,
          0.1, 0.153, 0.21, 0.31, 0.33, 0.39, 0.5, 0.6, 0.9)
  )
  tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                        continuous = "x", compare = "none", overall = FALSE,
                        show_variable = FALSE)
  row <- tbl$table_body[tbl$table_body$variable == "x", ]
  want <- function(v) {
    q <- stats::quantile(v, c(0.5, 0.15, 0.85), type = 2, names = FALSE)
    sprintf("9 ||| %s [%s, %s]", .format_sig2(q[1]), .format_sig2(q[2]),
            .format_sig2(q[3]))
  }
  expect_identical(row$stat_1, want(d$x[d$g == "a"]))
  expect_identical(row$stat_2, want(d$x[d$g == "b"]))
  expect_match(row$stat_1, "^9 \\|\\|\\| 102 \\[")
})

test_that("the statistic note names brackets and percentiles", {
  expect_identical(.stat_label("median", c(15, 85)),
                   "No. (%) or Median [15th, 85th percentiles]")
  expect_identical(hv_man_footnotes()[["†"]],
                   "No. (%) or Median [15th, 85th percentiles].")
})

test_that("under \"both\" the median column is bracketed to the standard", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = "marker"), continuous = "marker",
                        continuous_stat = "both", compare = "none",
                        overall = FALSE, show_variable = FALSE)
  want <- function(arm) {
    x <- gtsummary::trial$marker[gtsummary::trial$trt == arm]
    q <- stats::quantile(x, c(0.5, 0.15, 0.85), type = 2, na.rm = TRUE,
                         names = FALSE)
    sprintf("%s [%s, %s]", .format_sig2(q[1]), .format_sig2(q[2]),
            .format_sig2(q[3]))
  }
  is_marker <- tbl$table_body$variable == "marker"
  expect_identical(tbl$table_body$hv_median_stat_1[is_marker], want("Drug A"))
  expect_identical(tbl$table_body$hv_median_stat_2[is_marker], want("Drug B"))
})

test_that("a median cell the format cannot reach warns, and says where", {
  d <- data.frame(g = rep(c("a", "b"), each = 9), x = c(1:9, 11:19))
  tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                        continuous = "x", compare = "none", overall = FALSE,
                        show_variable = FALSE)
  tbl$table_body$stat_1[tbl$table_body$variable == "x"] <- "9 ||| 5"
  expect_warning(
    .format_standard_median(tbl, "x", c(15, 85)),
    "Could not apply the house median format to `x` in column `stat_1`"
  )
})

test_that("a group with no data is left as gtsummary shows it, silently", {
  d <- data.frame(g = factor(rep(c("a", "b"), each = 6)),
                  x = c(1:6, rep(NA_real_, 6)))
  expect_no_warning(
    tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                          continuous = "x", compare = "none", overall = FALSE,
                          show_variable = FALSE)
  )
  row <- tbl$table_body[tbl$table_body$variable == "x", ]
  # gtsummary's own NA text, untouched.
  expect_identical(row$stat_2, "0 ||| NA [NA, NA]")
  expect_identical(row$stat_1, "6 ||| 3.5 [1.0, 6.0]")
})

test_that("a non-finite median is left as gtsummary shows it", {
  d <- data.frame(g = factor(rep(c("a", "b"), each = 6)),
                  x = c(1:6, rep(Inf, 6)))
  expect_no_warning(
    tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                          continuous = "x", compare = "none", overall = FALSE,
                          show_variable = FALSE)
  )
  row <- tbl$table_body[tbl$table_body$variable == "x", ]
  expect_match(row$stat_2, "Inf", fixed = TRUE)
})

test_that("a median whose column is missing warns, and says where", {
  d <- data.frame(g = rep(c("a", "b"), each = 9), x = c(1:9, 11:19))
  tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                        continuous = "x", compare = "none", overall = FALSE,
                        show_variable = FALSE)
  names(tbl$table_body)[names(tbl$table_body) == "stat_1"] <- "renamed"
  expect_warning(
    .format_standard_median(tbl, "x", c(15, 85)),
    "Could not apply the house median format to `x` in column `stat_1`"
  )
})

test_that(".format_p() drops the leading zero and keeps today's digits", {
  expect_identical(
    .format_p(c(0.0004, 0.001, 0.0094, 0.013, 0.043, 0.12, 0.3, 0.7, 0.95, NA)),
    c("<.001", ".001", ".009", ".013", ".043", ".12", ".3", ".7", ">.9", NA)
  )
})

test_that("the comparison column prints P without a leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  p <- stats::na.omit(tbl$table_body$hv_compare_col)
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})

test_that("medians among means are marked with a section sign", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = c("age", "ttdeath"), compare = "none",
                        show_variable = FALSE)
  expect_identical(attr(tbl, "hv_cell_marks"),
                   list(symbol = "§", variables = "marker"))
  fn <- attr(tbl, "hv_footnotes")
  expect_identical(fn[["§"]], "Median [15th, 85th percentiles].")
  expect_identical(fn[["†"]], "No. (%) or Mean±SD.")
  labels <- tbl$table_body$label[tbl$table_body$row_type == "label"]
  expect_false(any(grepl(", (Mean|Median)", labels)))
})

test_that("means among medians are marked with a pilcrow", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = "age", compare = "none",
                        show_variable = FALSE)
  expect_identical(attr(tbl, "hv_cell_marks"),
                   list(symbol = "¶", variables = "age"))
  fn <- attr(tbl, "hv_footnotes")
  expect_identical(fn[["¶"]], "Mean±SD.")
  expect_identical(fn[["†"]],
                   "No. (%) or Median [15th, 85th percentiles].")
})

test_that("a table showing one statistic carries no cell marks", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker")),
                        continuous = c("age", "marker"), compare = "none",
                        show_variable = FALSE)
  expect_null(attr(tbl, "hv_cell_marks"))
})

# -- The tests behind the p-values are named in the dagger note ----------

tn_note <- function(...) {
  attr(hv_tbl_summary(...), "hv_footnotes")[["†"]]
}

test_that("the dagger note names the tests that ran, Fisher left to its mark", {
  skip_if_not_installed("broom")
  tbl <- ce_tbl()
  expect_true(any(tbl$table_body$test_name %in% "fisher.test"))
  note <- attr(tbl, "hv_footnotes")[["†"]]
  expect_match(note, "; P values from the ", fixed = TRUE)
  expect_false(grepl("Fisher", note, fixed = TRUE))
  expect_match(attr(tbl, "hv_test_note"), "^P values from the ")
  expect_identical(attr(tbl, "hv_footnotes")[["‡"]], "Fisher exact test.")
})

test_that("three groups name Kruskal-Wallis, and `normal` names ANOVA", {
  skip_if_not_installed("broom")
  trial3 <- gtsummary::trial
  trial3$grp <- factor(rep(c("a", "b", "c"), length.out = nrow(trial3)))
  note <- tn_note(trial3, by = "grp", groups = list(D = "age"),
                  continuous = "age")
  expect_match(note, "P values from the Kruskal-Wallis test.", fixed = TRUE)
  note <- tn_note(gtsummary::trial, by = "trt",
                  groups = list(D = c("age", "marker")),
                  continuous = c("age", "marker"), normal = "age")
  expect_match(
    note,
    paste0("P values from the one-way analysis of variance and Wilcoxon ",
           "rank sum test."),
    fixed = TRUE
  )
})

test_that("no comparison test, no test sentence and no p-value mark", {
  skip_if_not_installed("broom")
  for (cmp in c("none", "smd")) {
    tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                          groups = list(D = "age"), continuous = "age",
                          compare = cmp)
    expect_false(grepl("P values", attr(tbl, "hv_footnotes")[["†"]]),
                 info = cmp)
    expect_null(attr(tbl, "hv_test_note"), info = cmp)
  }
})

test_that("each variable's overall non-missing count rides on its label row", {
  d <- gtsummary::trial
  d$trt[1:3] <- NA # outside every group, so tbl_summary() drops them
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "none",
    show_variable = FALSE
  )
  tb <- tbl$table_body
  kept <- d[!is.na(d$trt), ]
  lab <- tb$row_type == "label"
  expect_identical(
    tb$hv_n[lab],
    as.character(c(sum(!is.na(kept$age)), sum(!is.na(kept$grade))))
  )
  expect_true(all(is.na(tb$hv_n[!lab])))
  # Independent of the data: the per-group counts gtsummary printed.
  age <- unlist(tb[tb$variable == "age" & lab, c("stat_1", "stat_2")])
  per_group <- as.integer(sub(" \\|\\|\\| .*", "", age))
  expect_identical(tb$hv_n[tb$variable == "age" & lab],
                   as.character(sum(per_group)))
})

test_that("the overall count is hidden from the report", {
  tbl <- fx_hv_tbl()
  hdr <- tbl$table_styling$header
  expect_true(hdr$hide[hdr$column == "hv_n"])
  expect_false("hv_n" %in% hv_man_table(tbl)$col_keys)
})

test_that("the grouping's name is its label, else its name, else NULL", {
  expect_identical(attr(fx_hv_tbl(), "hv_by_label"), "Chemotherapy Treatment")
  d <- gtsummary::trial
  attr(d$trt, "label") <- NULL
  tbl <- hv_tbl_summary(d, by = "trt", groups = list(A = "age"),
                        continuous = "age", compare = "none")
  expect_identical(attr(tbl, "hv_by_label"), "trt")
  none <- hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                         continuous = "age")
  expect_null(attr(none, "hv_by_label"))
  expect_identical(none$table_body$hv_n,
                   as.character(sum(!is.na(gtsummary::trial$age))))
})

test_that("a standardized difference is named and defined, not 'Difference'", {
  skip_if_not_installed("broom")
  for (cmp in c("smd", "both")) {
    tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                          groups = list(D = c("age", "stage")),
                          continuous = "age", categorical = "stage",
                          compare = cmp)
    hdr <- tbl$table_styling$header
    expect_identical(hdr$label[hdr$column == "estimate"], "**Std. Diff.**",
                     info = cmp)
    expect_identical(attr(tbl, "hv_smd"), cmp)
    expect_match(
      attr(tbl, "hv_footnotes")[["†"]],
      "Std. Diff. is the standardized mean difference, with its 95% CI.$",
      info = cmp
    )
  }
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(D = "age"), continuous = "age",
                        compare = "pvalue")
  expect_null(attr(tbl, "hv_smd"))
})

# gtsummary turns each "{name}" in a statistic string into a function by
# evaluating the name in its caller's environment. From inside a package
# that lookup reaches the global environment before package:stats, so a
# study that defines `sd` or `median` in its R/ folder, as hvtiRtemplates
# jobs source it, broke every table that showed mean +/- SD or a median.
# `mean` lives in base, which is searched first, and was never exposed.
with_global <- function(values, code) {
  for (nm in names(values)) assign(nm, values[[nm]], envir = globalenv())
  on.exit(rm(list = names(values), envir = globalenv()))
  force(code)
}

test_that("objects named like statistics never shadow them", {
  build <- function(continuous, ...) {
    hv_tbl_summary(gtsummary::trial, by = "trt",
                   groups = list(D = c(continuous, "stage")),
                   continuous = continuous, categorical = "stage", ...)
  }
  shadows <- list(
    sd = 1, median = 1, mean = 1, min = 1, max = 1, n = 1, p = 1,
    N_nonmiss = 1, p25 = 1, p75 = 1, p15 = 1, p85 = 1, quantile = 1,
    oneway.test = 1, fisher.test = 1, chisq.test = 1, t.test = 1,
    chisq.test.no.correct = 1, var = 1, smd = 1
  )
  for (stat in c("median", "mean", "both")) {
    for (cont in list(c("age", "marker"), "age")) {
      mean_sd <- if (length(cont) > 1L) "marker" else character(0)
      args <- list(continuous = cont, mean_sd = mean_sd,
                   continuous_stat = stat)
      clean <- do.call(build, args)$table_body
      shadowed <- with_global(shadows, do.call(build, args)$table_body)
      expect_identical(shadowed, clean, info = paste(stat, length(cont)))
    }
  }
  normal <- function() {
    build(c("age", "marker"), normal = "marker")$table_body
  }
  clean <- normal()
  shadowed <- with_global(list(sd = data.frame(x = 1), median = "a"), normal())
  expect_identical(shadowed, clean)
})
