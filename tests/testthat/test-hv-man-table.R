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
  # hv_tbl_summary() applies the "{N_nonmiss} ||| {stat}" convention for the
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
  # Row 1 is the section header "D"; age is row 2.
  # 91, not 98: Drug A has 98 rows, 7 of them with missing age.
  expect_identical(d$n_stat_1[2], "91")
  expect_identical(d$stat_1[2], "46 [32, 63]")
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
    statistic = list(gtsummary::all_continuous() ~ "{N_nonmiss} ||| {mean}")
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
    statistic = list(gtsummary::all_continuous() ~ "{N_nonmiss} ||| {mean}")
  )
  msg <- tryCatch(hv_man_table(tbl), error = conditionMessage)
  expect_match(msg, "hv_man_table() requires", fixed = TRUE)
  expect_false(grepl("hv_man_table_jtcvs()", msg, fixed = TRUE))
})

test_that("the house N footnote targets the N column when one exists", {
  # hv_man_footnotes()'s `*` is "Number of non-missing values." (house
  # rule 8). Splitting introduces the column it describes, so the marker
  # must move there. Without this the marker would land on col_keys[1],
  # the label column.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none"
  )
  ft <- hv_man_table(tbl)
  expect_identical(ft$col_keys[1], "label")
  # n_stat_0: hv_tbl_summary() adds the Overall column by default, and
  # its N column is the first one.
  expect_identical(.footnote_col(ft), "n_stat_0")
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

test_that("CORR's rendered P column has no leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), path)
  text <- officer::docx_summary(officer::read_docx(path))$text
  p <- text[grepl("^[<>]?0?\\.[0-9]+$", text)]
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})

test_that("hv_man_table() superscripts the minority mark on its cells", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = c("age", "ttdeath"), compare = "none",
                        show_variable = FALSE)
  ft <- hv_man_table(tbl)
  expect_identical(attr(ft, "hv_body_marks")[["§"]],
                   "Median [15th, 85th percentiles].")
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  text <- officer::docx_summary(officer::read_docx(path))$text
  expect_true(any(grepl("§", text, fixed = TRUE)))
  # The footnote line also holds the symbol, so assert on the cells.
  ch <- flextable::information_data_chunk(ft)
  body <- ch[ch$.part == "body" & ch$.col_id == "stat_1", ]
  lab <- ch[ch$.part == "body" & ch$.col_id == "label", ]
  sup <- function(pattern) {
    r <- lab$.row_id[grepl(pattern, lab$txt)]
    body[body$.row_id %in% r & body$txt == "\u00a7", ]
  }
  expect_equal(sum(grepl("^Age", lab$txt)), 1L)
  marked <- sup("^Marker")
  expect_equal(nrow(marked), 1L)
  expect_identical(marked$vertical.align, "superscript")
  expect_equal(nrow(sup("^Age")), 0L)
})

test_that("a cell mark and Fisher's dagger both survive in hv_body_marks", {
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
  # One mean row against one median row: a tie, so the mean row is marked.
  expect_identical(attr(tbl, "hv_cell_marks")$symbol, "¶")
  expect_true("‡" %in% names(attr(tbl, "hv_footnotes")))
  ft <- hv_man_table(tbl)
  expect_setequal(names(attr(ft, "hv_body_marks")), c("‡", "¶"))
  path <- tempfile(fileext = ".docx")
  expect_no_error(hv_man_table_save(ft, path))
})
