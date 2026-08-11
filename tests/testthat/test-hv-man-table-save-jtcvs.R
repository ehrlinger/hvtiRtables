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
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    missing = "no"
  )
  hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
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
  hv_man_table_save_jtcvs(ft, f, caption = "Table 1. Baseline Characteristics")
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

test_that("hv_man_table_save_jtcvs attaches lettered footnotes to cells", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics",
    footnotes = list(
      list(row = 1, col = "n_stat_1", text = "Patients with data available."),
      list(row = 1, col = "n_stat_2", text = "Second footnote.")
    )
  )
  xml <- read_docx_text(f)
  # The superscript letter and its ". <text>" run are separate <w:r> runs
  # (different run formatting), so the raw XML never contains a contiguous
  # "a. Patients..." string — tags intervene between the two <w:t> elements.
  # Verified against actual rendered XML: use the same windowed-context
  # pattern as the caption/bold check above instead of a literal substring.
  a_pos <- regexpr("Patients with data available.", xml, fixed = TRUE)
  a_preceding <- substr(xml, max(1, a_pos - 250), a_pos)
  expect_true(grepl('vertAlign w:val="superscript"', a_preceding, fixed = TRUE))
  expect_true(grepl(">a<", a_preceding, fixed = TRUE))

  b_pos <- regexpr("Second footnote.", xml, fixed = TRUE)
  b_preceding <- substr(xml, max(1, b_pos - 250), b_pos)
  expect_true(grepl('vertAlign w:val="superscript"', b_preceding, fixed = TRUE))
  expect_true(grepl(">b<", b_preceding, fixed = TRUE))
})

test_that("hv_man_table_save_jtcvs reuses the shared Key: helper", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics",
    abbreviations = c(SD = "standard deviation")
  )
  xml <- read_docx_text(f)
  expect_true(grepl("Key:", xml, fixed = TRUE))
  expect_true(grepl("SD", xml, fixed = TRUE))
})

test_that("hv_man_table_save_jtcvs rejects an out-of-range footnote row", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 999, col = "n_stat_1", text = "note"))
    ),
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
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    missing = "no"
  )
  ft <- hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  expect_identical(flextable::nrow_part(ft, "body"), 2L)

  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 1.5, col = "n_stat_1", text = "note"))
    ),
    "whole numbers"
  )
})

test_that("hv_man_table_save_jtcvs rejects an unknown footnote column", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 1, col = "nope", text = "note"))
    ),
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
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    missing = "no"
  )
  ft <- hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  expect_identical(flextable::nrow_part(ft, "body"), 2L)

  out <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. X",
    footnotes = list(list(row = c(1, 2), col = "n_stat_1", text = "note"))
  )
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
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X", abbreviations = c("no name")
    ),
    "non-empty name"
  )
  expect_false(file.exists(out))

  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      abbreviations = list(SD = "standard deviation")
    ),
    "named character vector"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs validates file", {
  ft <- fx_jtcvs_ft()
  for (bad in list(1, NA_character_, "", character(0))) {
    expect_error(hv_man_table_save_jtcvs(ft, bad, caption = "T1."),
                 "must be a single non-empty file")
  }
})

test_that("hv_man_table_save_jtcvs rejects a footnote with no text", {
  # Regression for the silent defect: this previously wrote a .docx
  # with a dangling superscript marker and an empty footnote line.
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "T1.",
      footnotes = list(list(row = 1, col = "n_stat_1"))
    ),
    "must be a single non-empty string"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs writes nothing when it rejects", {
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(ft, out, caption = "T1.",
                            abbreviations = list(N = "x")),
    "named character vector"
  )
  expect_false(file.exists(out))
})
