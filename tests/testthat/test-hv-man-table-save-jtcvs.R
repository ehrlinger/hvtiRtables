library(dplyr)
library(gtsummary)

mk_jtcvs_ft <- function() {
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10))
  )
  dta$age[sample(n, 5)] <- NA
  tbl <- dta |> tbl_summary(
    by = group, # nolint: object_usage_linter.
    statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"),
    missing = "no"
  )
  jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  ))
}

read_docx_text <- function(path) {
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = xdir)
  paste(
    readLines(file.path(xdir, "word", "document.xml"), warn = FALSE),
    collapse = ""
  )
}

test_that("hv_man_table_save_jtcvs renders a bold caption before the table", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics"
  ))
  xml <- read_docx_text(f)
  expect_true(grepl("Table 1. Baseline Characteristics", xml, fixed = TRUE))
  # flextable/officer emit `<w:b w:val="true"/>`, not the bare `<w:b/>` form —
  # verified against actual rendered XML during planning. Check bold appears
  # in the run immediately preceding the caption text, not just anywhere in
  # the document (the table body also has bold section-header cells).
  cap_pos <- regexpr("Table 1. Baseline Characteristics", xml, fixed = TRUE)
  preceding_run <- substr(xml, max(1, cap_pos - 300), cap_pos)
  expect_true(grepl('w:b w:val="true"', preceding_run, fixed = TRUE))
})

test_that("the deprecated saver keeps a caller's notes, lettered from a", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics",
    footnotes = list(
      list(row = 1, col = "n_stat_1", text = "First footnote."),
      list(row = 1, col = "n_stat_2", text = "Second footnote.")
    )
  ))
  x <- wx_doc(f)
  notes <- vapply(
    xml2::xml_find_all(x, "//w:tbl/following-sibling::w:p", wx_ns),
    wx_text, character(1)
  )
  # The table's own notes first, in the manuscript's symbols, then the
  # caller's, lettered from a now that no n carries an "a".
  expect_identical(notes, c("*Patients with non-missing data.",
                            "\u2020Values are No. (%) or mean\u00B1SD.",
                            "a. First footnote.", "b. Second footnote."))
  age <- wx_rows(x)[[3]] # two header rows, then age
  expect_identical(vapply(age, `[[`, "", "sup"), c("", "a", "", "b", ""))
})

test_that(".drop_named_tests drops a test note only where the table names it", {
  entry <- function(text, col = "hv_compare_col") {
    list(row = 1, col = col, text = text)
  }
  wilcox <- entry(.hv_test_labels[["wilcox.test"]])
  fisher <- entry(.hv_test_labels[["fisher.test"]])
  own <- entry(.hv_test_labels[["wilcox.test"]], col = "disp_stat_1")
  notes <- list(wilcox, fisher, own)
  ft_with <- function(layout = "describe", test_note = NULL, marks = NULL) {
    ft <- flextable::flextable(data.frame(a = 1))
    attr(ft, "hv_layout") <- layout
    attr(ft, "hv_test_note") <- test_note
    attr(ft, "hv_body_marks") <- marks
    ft
  }
  # Neither named: both stay.
  expect_identical(.drop_named_tests(ft_with(), notes), notes)
  # The dagger note names the tests: Fisher's stays, as only a double
  # dagger on the P values names it.
  expect_identical(
    .drop_named_tests(ft_with(test_note = "x"), notes), list(fisher, own)
  )
  # The double dagger names Fisher's: the others stay.
  dd <- c("\u2021" = .hv_test_labels[["fisher.test"]])
  expect_identical(
    .drop_named_tests(ft_with(marks = dd), notes), list(wilcox, own)
  )
  # Both: only a caller's own note on another column stays.
  expect_identical(
    .drop_named_tests(ft_with(test_note = "x", marks = dd), notes),
    list(own)
  )
  # A table that is not a describe table names nothing.
  expect_identical(
    .drop_named_tests(ft_with(layout = "compare", test_note = "x",
                              marks = dd), notes),
    notes
  )
})

test_that("hv_man_table_save_jtcvs reuses the shared Key: helper", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics",
    abbreviations = c(SD = "standard deviation")
  ))
  xml <- read_docx_text(f)
  expect_true(grepl("Key:", xml, fixed = TRUE))
  expect_true(grepl("SD", xml, fixed = TRUE))
})

test_that("hv_man_table_save_jtcvs rejects an out-of-range footnote row", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 999, col = "n_stat_1", text = "note"))
    )),
    "whole numbers between"
  )
})

test_that("hv_man_table_save_jtcvs rejects a fractional footnote row", {
  # A fractional row previously passed validation, and flextable accepted
  # it silently rather than erroring, writing the marker onto whatever
  # cell it truncated to. That is precisely the silent-wrong-cell failure
  # this guard exists to prevent, so it has to be caught here.
  # Must be a two-row table with an in-range fractional index (1.5 lies
  # between rows 1 and 2). On mk_jtcvs_ft()'s single body row, 1.5 would
  # trip the range check instead and prove nothing about fractionality.
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10)),
    bsa = round(rnorm(n, 2, 0.2), 2)
  )
  tbl <- dta |> tbl_summary(
    by = group, # nolint: object_usage_linter.
    statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"),
    missing = "no"
  )
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  ))
  expect_identical(flextable::nrow_part(ft, "body"), 2L)

  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 1.5, col = "n_stat_1", text = "note"))
    )),
    "whole numbers"
  )
})

test_that("hv_man_table_save_jtcvs rejects an unknown footnote column", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 1, col = "nope", text = "note"))
    )),
    "not a column"
  )
})

test_that("hv_man_table_save_jtcvs marks every row of a vector-valued row", {
  # mk_jtcvs_ft() renders a single body row, so it cannot exercise a
  # multi-row footnote. Build a two-variable table instead.
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10)),
    bsa = round(rnorm(n, 2, 0.2), 2)
  )
  tbl <- dta |> tbl_summary(
    by = group, # nolint: object_usage_linter.
    statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"),
    missing = "no"
  )
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  ))
  expect_identical(flextable::nrow_part(ft, "body"), 2L)

  out <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. X",
    footnotes = list(list(row = c(1, 2), col = "n_stat_1", text = "note"))
  ))
  xml <- read_docx_text(out)
  # One superscript "a" per marked cell, plus one in the footnote line.
  expect_gte(lengths(regmatches(xml, gregexpr("superscript", xml))), 3)
})

test_that("hv_man_table_save_jtcvs rejects a bad abbreviations arg", {
  # Regression: .add_abbreviations_key()'s own name-validation was moved
  # out to .check_abbreviations() at hv_man_table_save()'s entry, but
  # this function's entry was never updated to call it too. A bad
  # `abbreviations` used to either write a malformed .docx (unnamed
  # element) or crash with an opaque officer/flextable internal error
  # (a `list`), instead of the package's own clear validation message,
  # and always after writing no file.
  ft <- fx_jtcvs_ft()

  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X", abbreviations = c("no name")
    )),
    "non-empty name"
  )
  expect_false(file.exists(out))

  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      abbreviations = list(SD = "standard deviation")
    )),
    "named character vector"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs validates file", {
  ft <- fx_jtcvs_ft()
  for (bad in list(1, NA_character_, "", character(0))) {
    expect_error(jtcvs_quiet(hv_man_table_save_jtcvs(ft, bad, caption = "T1.")),
                 "must be a single non-empty file")
  }
})

test_that("hv_man_table_save_jtcvs rejects a footnote with no text", {
  # Regression for the silent defect: this previously wrote a .docx
  # with a dangling superscript marker and an empty footnote line.
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "T1.",
      footnotes = list(list(row = 1, col = "n_stat_1"))
    )),
    "must be a single non-empty string"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs rejects non-string footnote text", {
  ft <- fx_jtcvs_ft()
  for (bad in list(NULL, NA, 1, c("a", "b"), "")) {
    out <- tempfile(fileext = ".docx")
    expect_error(
      jtcvs_quiet(hv_man_table_save_jtcvs(
        ft, out, caption = "T1.",
        footnotes = list(list(row = 1, col = "n_stat_1", text = bad))
      )),
      "must be a single non-empty string"
    )
    expect_false(file.exists(out))
  }
})

test_that("hv_man_table_save_jtcvs writes nothing when it rejects", {
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "T1.",
      abbreviations = list(N = "x")
    )),
    "named character vector"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs rejects a flat footnotes list", {
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  msg <- tryCatch(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      ft, out, caption = "T",
      footnotes = list(row = 1, col = "label", text = "x")
    )),
    error = conditionMessage
  )
  expect_false(grepl("$ operator", msg, fixed = TRUE))
  expect_match(msg, "must be a list of the form", fixed = TRUE)
  expect_false(file.exists(out))
})

# -- the saved table fits the page ----------------------------------------

test_that("a two-group 'both' JTCVS table turns landscape and fits", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both",
    compare = "none", show_variable = FALSE, overall = FALSE
  )
  g <- save_fit(tbl, c(stat_1 = "A", stat_2 = "B"))
  expect_true(g$landscape)
  expect_lte(g$table, g$text)
})

test_that("a table too wide even for landscape is narrowed to fit", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both",
    compare = "pvalue"
  )
  tbl <- hv_tbl_compare(tbl, c(age = "1.0", grade = "2.0"), "Std. Diff.")
  g <- save_fit(tbl, c(stat_0 = "Overall", stat_1 = "A", stat_2 = "B"))
  expect_true(g$landscape)
  expect_lte(g$table, g$text)
})

test_that("a narrow JTCVS table stays portrait at its own widths", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "none",
    show_variable = FALSE, overall = FALSE
  )
  g <- save_fit(tbl, c(stat_1 = "A", stat_2 = "B"))
  expect_false(g$landscape)
  # 2.0 + 2 x (0.6 + 1.1) inches, the describe layout's, untouched.
  expect_equal(g$table, 5.4 * 1440, tolerance = 1e-3)
})

test_that("the JTCVS saver writes a US Letter page", {
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    fx_jtcvs_ft(), f, caption = "Table 1. Test"
  ))
  expect_setequal(unname(pg_size(f)), c("12240", "15840"))
})
