library(dplyr)
library(gtsummary)

mk_tbl <- function() {
  set.seed(42)
  n <- 200
  grp <- factor(
    sample(c("B", "F", "Z"), n, replace = TRUE, prob = c(94, 114, 369)),
    levels = c("B", "F", "Z")
  )
  dta <- data.frame(
    group = grp,
    age = round(rnorm(n, 62, 12)),
    nyha = factor(sample(c("I", "II", "III"), n, replace = TRUE),
                  levels = c("I", "II", "III"))
  )
  dta$age[sample(n, 8)] <- NA

  dta |>
    tbl_summary(
      by = group, # nolint: object_usage_linter.
      statistic = list(
        all_continuous() ~ "{mean}±{sd}",
        all_categorical() ~ "{n} ({p})"
      ),
      missing = "no"
    ) |>
    modify_table_body(
      mutate,
      groupname_col = case_when(
        variable == "age" ~ "Demographics", TRUE ~ "Cardiac"
      )
    ) |>
    add_n()
}

docx_xml <- function(ft) {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  flextable::save_as_docx(ft, path = out)
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(out, exdir = xdir)
  paste(
    readLines(file.path(xdir, "word", "document.xml"), warn = FALSE),
    collapse = ""
  )
}

test_that("hv_man_table returns a flextable with a single header row", {
  ft <- hv_man_table(mk_tbl())
  expect_s3_class(ft, "flextable")
  expect_identical(flextable::nrow_part(ft, "header"), 1L)
})

test_that("hv_man_table output has no merged cells (gridSpan/vMerge)", {
  ft <- hv_man_table(mk_tbl())
  xml <- docx_xml(ft)
  expect_equal(lengths(regmatches(xml, gregexpr("gridSpan", xml))), 0L)
  expect_equal(lengths(regmatches(xml, gregexpr("vMerge", xml))), 0L)
})

test_that("hv_man_table applies the house font and size", {
  ft <- hv_man_table(mk_tbl())
  xml <- docx_xml(ft)
  expect_true(grepl("Times New Roman", xml, fixed = TRUE))
  # 12pt = half-points * 2 = 24
  expect_true(grepl('w:sz w:val="24"', xml, fixed = TRUE))
})

test_that("hv_man_table honours a smaller font_size for wide tables", {
  ft <- hv_man_table(mk_tbl(), font_size = 11)
  xml <- docx_xml(ft)
  # 11pt = 22 half-points
  expect_true(grepl('w:sz w:val="22"', xml, fixed = TRUE))
})

test_that("hv_man_table validates its inputs", {
  expect_error(hv_man_table("not a gtsummary object"), "gtsummary")
  expect_error(hv_man_table(mk_tbl(), font_size = 10), "font_size")
})

test_that("hv_man_table validates font", {
  expect_error(hv_man_table(mk_tbl(), font = 12), "`font`")
  expect_error(hv_man_table(mk_tbl(), font = c("a", "b")), "`font`")
  expect_error(hv_man_table(mk_tbl(), font = ""), "`font`")
})

test_that("hv_man_table splits the ||| sentinel into flat N and stat columns", {
  # hv_tbl_summary() applies the "{N_obs} ||| {stat}" convention for the
  # JTCVS renderer. hv_man_table() used to hand it straight to
  # as_flex_table(), so a CORR table rendered the sentinel literally as
  # "98 ||| 46 (32, 63)". House rule 8 wants the non-missing count as its
  # own column, so the fix splits rather than strips.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "none"
  )
  ft <- hv_man_table(tbl)
  expect_true(all(c("n_stat_1", "stat_1", "n_stat_2", "stat_2")
                  %in% ft$col_keys))
  d <- ft$body$dataset
  expect_false(any(grepl("|||", unlist(d), fixed = TRUE)))
  expect_identical(d$n_stat_1[1], "98")
  expect_identical(d$stat_1[1], "46 (32, 63)")
  # The N column sits immediately before the statistic it counts.
  expect_identical(
    which(ft$col_keys == "n_stat_1") + 1L,
    which(ft$col_keys == "stat_1")
  )
})

test_that("hv_man_table leaves a plain tbl_summary table untouched", {
  # The documented CORR path takes a plain gtsummary table with no
  # sentinel; it must pass through with no columns invented.
  tbl <- gtsummary::tbl_summary(
    gtsummary::trial, by = "trt", include = c("age", "grade")
  )
  ft <- hv_man_table(tbl)
  expect_false(any(grepl("^n_stat_", ft$col_keys)))
  expect_true(all(c("label", "stat_1", "stat_2") %in% ft$col_keys))
})

test_that("hv_man_table rejects a partially-sentineled table", {
  # Some cells carrying the convention and some not means the caller set
  # `statistic` for only part of the table; splitting would leave the
  # rest blank, which is the silent-empty failure this package exists to
  # prevent.
  tbl <- gtsummary::tbl_summary(
    gtsummary::trial, by = "trt", include = c("age", "grade"),
    statistic = list(gtsummary::all_continuous() ~ "{N_obs} ||| {mean}")
  )
  expect_error(hv_man_table(tbl), "was not built with the")
})

test_that("hv_man_table's convention error names itself, not JTCVS", {
  # Regression for PR #23 Copilot review: .assert_stat_convention()
  # hardcoded "hv_man_table_jtcvs()" in its message, so a CORR user
  # hitting a partially-sentineled table was told the JTCVS renderer
  # required a convention they never asked for. A fixed = TRUE substring
  # check for "hv_man_table()" alone would pass even with the wrong name
  # still present (it's a substring of "hv_man_table_jtcvs()"), so the
  # negative assertion below is the one that actually catches the defect.
  tbl <- gtsummary::tbl_summary(
    gtsummary::trial, by = "trt", include = c("age", "grade"),
    statistic = list(gtsummary::all_continuous() ~ "{N_obs} ||| {mean}")
  )
  msg <- tryCatch(hv_man_table(tbl), error = conditionMessage)
  expect_match(msg, "hv_man_table() requires", fixed = TRUE)
  expect_false(grepl("hv_man_table_jtcvs()", msg, fixed = TRUE))
})

test_that("the house N footnote targets the N column when one exists", {
  # hv_man_footnotes()'s `*` is "Number of non-missing values." (house
  # rule 8). Splitting introduces the column it describes, so the marker
  # must move there. Without this the marker would land on col_keys[1],
  # which for a sectioned table is `groupname_col` -- a regression the
  # split itself would have introduced.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none"
  )
  ft <- hv_man_table(tbl)
  expect_identical(ft$col_keys[1], "groupname_col")
  expect_identical(.footnote_col(ft), "n_stat_1")
})

test_that(".footnote_col prefers n, then n_stat_*, then the first key", {
  expect_identical(.footnote_col(list(col_keys = c("label", "n", "x"))), "n")
  expect_identical(
    .footnote_col(list(col_keys = c("groupname_col", "label", "n_stat_2",
                                    "n_stat_1"))),
    "n_stat_2"
  )
  expect_identical(
    .footnote_col(list(col_keys = c("label", "stat_1"))), "label"
  )
})

test_that("no sentinel survives into the rendered .docx", {
  # Splitting the cells was not enough: gtsummary also writes a header
  # footnote built from the glue string, which read "No. obs. ||| Median
  # (15% Centile, 85% Centile)" and carried the separator into the
  # document even with every cell correct. Asserting on the flextable
  # alone missed it -- this checks the artifact the user actually opens.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age", Disease = "grade"),
    continuous = "age", categorical = "grade", compare = "none"
  )
  out <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), out)
  x <- tempfile()
  utils::unzip(out, files = "word/document.xml", exdir = x)
  txt <- xml2::xml_text(
    xml2::read_xml(file.path(x, "word", "document.xml"))
  )
  expect_false(grepl("|||", txt, fixed = TRUE))
  # The house footnotes still describe both halves.
  expect_true(grepl("Number of non-missing values", txt, fixed = TRUE))
  expect_true(grepl("No.", txt, fixed = TRUE))
})
