# Categorical variable deliberately placed FIRST so that canonical
# ordering and order-of-first-appearance give different answers. If the
# implementation ever regresses to first-appearance, the letters flip and
# these tests fail.
mk_footnote_tbl_2grp <- function() {
  set.seed(5)
  n <- 200
  dta <- data.frame(
    grp  = factor(rep(c("A", "B"), each = n / 2)),
    sex  = factor(sample(c("F", "M"), n, replace = TRUE)),
    age  = rnorm(n, 60, 12),
    rare = factor(
      sample(c("y", "n"), n, replace = TRUE, prob = c(0.985, 0.015))
    )
  )
  hv_tbl_summary(
    dta, by = "grp",
    groups = list(Demography = c("sex", "age"), Other = "rare"),
    continuous = "age", categorical = c("sex", "rare"),
    compare = "pvalue"
  )
}

mk_footnote_tbl_3grp <- function() {
  set.seed(9)
  n <- 300
  dta <- data.frame(
    grp  = factor(rep(c("A", "B", "C"), each = n / 3)),
    age  = rnorm(n, 60, 12),
    sex  = factor(sample(c("F", "M"), n, replace = TRUE)),
    rare = factor(
      sample(c("y", "n"), n, replace = TRUE, prob = c(0.99, 0.01))
    )
  )
  hv_tbl_summary(
    dta, by = "grp",
    groups = list(Demography = c("age", "sex"), Other = "rare"),
    continuous = "age", categorical = c("sex", "rare"),
    compare = "pvalue"
  )
}

test_that("hv_test_footnotes_jtcvs rejects a non-gtsummary object", {
  expect_error(
    hv_test_footnotes_jtcvs(data.frame(a = 1)),
    "must be a gtsummary"
  )
})

test_that("hv_test_footnotes_jtcvs orders tests canonically, not by row", {
  # sex (chi-square) is body row 1 and age (Wilcoxon) is body row 4, yet
  # Wilcoxon takes letter a. Order of first appearance would invert this.
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_length(fns, 3)
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Wilcoxon rank-sum test.", "Pearson chi-square test.",
      "Fisher exact test.")
  )
})

test_that("hv_test_footnotes_jtcvs targets the comparison column", {
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_true(all(vapply(fns, function(f) f$col, character(1)) ==
                    "hv_compare_col"))
})

test_that("hv_test_footnotes_jtcvs points at rendered rows, not body rows", {
  # Rendered layout, with section headers interleaved:
  #   1 Demography  2 sex  3 F  4 M  5 age  6 Other  7 rare  8 n  9 y
  # Rows are deliberately non-monotonic across footnotes (5, 2, 7),
  # because canonical test order is independent of row order.
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_identical(fns[[1]]$row, 5L)  # age, Wilcoxon
  expect_identical(fns[[2]]$row, 2L)  # sex, chi-square
  expect_identical(fns[[3]]$row, 7L)  # rare, Fisher
})

test_that("hv_test_footnotes_jtcvs uses Kruskal-Wallis for 3+ groups", {
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_3grp())
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Kruskal-Wallis test.", "Pearson chi-square test.",
      "Fisher exact test.")
  )
})

test_that("hv_test_footnotes_jtcvs collapses shared tests onto one letter", {
  # Two categorical variables both tested by chi-square must produce ONE
  # footnote with two row indices, not two footnotes.
  set.seed(21)
  n <- 200
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    sex = factor(sample(c("F", "M"), n, replace = TRUE)),
    hx  = factor(sample(c("yes", "no"), n, replace = TRUE))
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Demography = c("sex", "hx")),
    categorical = c("sex", "hx"), compare = "pvalue"
  )
  fns <- hv_test_footnotes_jtcvs(tbl)
  expect_length(fns, 1)
  expect_identical(fns[[1]]$text, "Pearson chi-square test.")
  expect_length(fns[[1]]$row, 2L)
})

test_that("hv_test_footnotes_jtcvs returns list() when there is no p-value", {
  set.seed(5)
  n <- 100
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    age = rnorm(n, 60, 12)
  )
  args <- list(
    dta, groups = list(Demography = "age"), continuous = "age"
  )

  no_by <- do.call(hv_tbl_summary, args)
  expect_identical(hv_test_footnotes_jtcvs(no_by), list())

  none <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "none")))
  expect_identical(hv_test_footnotes_jtcvs(none), list())

  smd <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "smd")))
  expect_identical(hv_test_footnotes_jtcvs(smd), list())
})

test_that("hv_test_footnotes_jtcvs still marks tests when compare = 'both'", {
  # "both" renders "0.7 (SMD -0.03)" in one cell; the letter marks the
  # p-value portion. This works only because hv_tbl_summary() calls
  # add_difference() before add_p(); the reverse order overwrites
  # test_name with "smd". See NEWS 0.9.2.
  set.seed(5)
  n <- 100
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    age = rnorm(n, 60, 12)
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Demography = "age"),
    continuous = "age", compare = "both"
  )
  fns <- hv_test_footnotes_jtcvs(tbl)
  expect_length(fns, 1)
  expect_identical(fns[[1]]$text, "Wilcoxon rank-sum test.")
})

test_that("hv_test_footnotes_jtcvs warns on an unmapped test_name", {
  tbl <- mk_footnote_tbl_2grp()
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$test_name[tb$variable == "age"] <- "mcnemar.test"
    tb
  })
  expect_warning(
    fns <- hv_test_footnotes_jtcvs(tbl),
    "mcnemar.test"
  )
  # Unmapped names sort after the canonical four, using the raw name.
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Pearson chi-square test.", "Fisher exact test.", "mcnemar.test")
  )
})

test_that("hv_test_footnotes_jtcvs round-trips through a saved .docx", {
  # Characterization against the SAS example's shape: a stratified table
  # whose letters are Kruskal-Wallis, chi-square, and Fisher. ANOVA is
  # absent by design, since this package tests continuous variables
  # non-parametrically throughout.
  tbl <- mk_footnote_tbl_3grp()
  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "A (n=100)", stat_2 = "B (n=100)",
               stat_3 = "C (n=100)"),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  )
  out <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. Baseline Characteristics",
    footnotes = hv_test_footnotes_jtcvs(tbl)
  )
  expect_true(file.exists(out))

  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(out, exdir = xdir)
  xml <- paste(
    readLines(file.path(xdir, "word", "document.xml"), warn = FALSE),
    collapse = ""
  )
  expect_true(grepl("Kruskal-Wallis test.", xml, fixed = TRUE))
  expect_true(grepl("Pearson chi-square test.", xml, fixed = TRUE))
  expect_true(grepl("Fisher exact test.", xml, fixed = TRUE))
  expect_false(grepl("ANOVA", xml, fixed = TRUE))
})
