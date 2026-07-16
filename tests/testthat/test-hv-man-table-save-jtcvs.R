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
