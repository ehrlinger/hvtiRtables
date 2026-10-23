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
    jtcvs_quiet(hv_test_footnotes_jtcvs(data.frame(a = 1))),
    "must be a gtsummary"
  )
})

test_that("hv_test_footnotes_jtcvs orders tests canonically, not by row", {
  # sex (chi-square) is body row 1 and age (Wilcoxon) is body row 4, yet
  # Wilcoxon takes letter a. Order of first appearance would invert this.
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp()))
  expect_length(fns, 3)
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Wilcoxon rank-sum test.", "Pearson chi-square test.",
      "Fisher exact test.")
  )
})

test_that("hv_test_footnotes_jtcvs targets the comparison column", {
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp()))
  expect_true(all(vapply(fns, function(f) f$col, character(1)) ==
                    "hv_compare_col"))
})

test_that("hv_test_footnotes_jtcvs points at rendered rows, not body rows", {
  # Rendered layout, with section headers interleaved:
  #   1 Demography  2 sex  3 F  4 M  5 age  6 Other  7 rare  8 n  9 y
  # Rows are deliberately non-monotonic across footnotes (5, 2, 7),
  # because canonical test order is independent of row order.
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp()))
  expect_identical(fns[[1]]$row, 5L)  # age, Wilcoxon
  expect_identical(fns[[2]]$row, 2L)  # sex, chi-square
  expect_identical(fns[[3]]$row, 7L)  # rare, Fisher
})

test_that("hv_test_footnotes_jtcvs uses Kruskal-Wallis for 3+ groups", {
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(mk_footnote_tbl_3grp()))
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
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
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
  expect_identical(jtcvs_quiet(hv_test_footnotes_jtcvs(no_by)), list())

  none <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "none")))
  expect_identical(jtcvs_quiet(hv_test_footnotes_jtcvs(none)), list())

  smd <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "smd")))
  expect_identical(jtcvs_quiet(hv_test_footnotes_jtcvs(smd)), list())
})

test_that("hv_test_footnotes_jtcvs still marks tests when compare = 'both'", {
  # "both" renders "0.7 (-0.03)" in one cell; the letter marks the
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
  fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
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
    fns <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl)),
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
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "A (n=100)", stat_2 = "B (n=100)",
               stat_3 = "C (n=100)"),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  ))
  out <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. Baseline Characteristics",
    footnotes = hv_test_footnotes_jtcvs(tbl)
  ))
  expect_true(file.exists(out))

  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(out, exdir = xdir)
  xml <- paste(
    readLines(file.path(xdir, "word", "document.xml"), warn = FALSE),
    collapse = ""
  )
  # The describe table names its own tests, so the saver drops these
  # entries rather than say each twice.
  notes <- vapply(
    xml2::xml_find_all(wx_doc(out), "//w:tbl/following-sibling::w:p",
                       wx_ns),
    wx_text, character(1)
  )
  expect_identical(notes, c(
    "*Patients with non-missing data.",
    paste0("\u2020Values are No. (%) or median [15th, 85th percentiles]; ",
           "P values from the Kruskal-Wallis test and Pearson's ",
           "chi-square test."),
    "\u2021Fisher exact test."
  ))
  expect_false(grepl("ANOVA", xml, fixed = TRUE))
})

test_that("a joined column is never lettered with a test", {
  skip_if_not_installed("broom")
  # Reported on #77: compare = "none", then add_p(), then an SMD joined
  # with hv_tbl_compare(). The letters used to fall back to the first
  # trailing column and footnoted the SMD "Fisher exact test."
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "none",
    show_variable = FALSE
  ) |> gtsummary::add_p()
  tbl <- hv_tbl_compare(tbl, c(age = "10.1", grade = "3.0"),
                        "Standardized difference (%)")
  expect_identical(jtcvs_quiet(hv_test_footnotes_jtcvs(tbl)), list())
})

test_that("tests stay on the p-value column beside a joined column", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "pvalue",
    show_variable = FALSE
  )
  tbl <- hv_tbl_compare(tbl, c(age = "10.1", grade = "3.0"), "SD (%)")
  cols <- vapply(jtcvs_quiet(hv_test_footnotes_jtcvs(tbl)), `[[`, "", "col")
  expect_true(length(cols) > 0L && all(cols == "hv_compare_col"))
})
