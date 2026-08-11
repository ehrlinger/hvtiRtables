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
    grepl("^[0-9]+ \\|\\|\\| [0-9]+ \\([0-9.]+%\\)$", tbl$table_body$stat_0)
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
    expect_identical(tbl$table_body$stat_1[1], "20 ||| 15 (75%)",
                     info = nm)
  }
})
