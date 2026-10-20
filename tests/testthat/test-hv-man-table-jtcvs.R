library(dplyr)
library(gtsummary)

dep_tbl <- function() {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", overall = TRUE,
    compare = "pvalue", show_variable = FALSE
  )
  hv_tbl_compare(tbl, c(age = "0.1", grade = "0.2"), "Std. Diff.")
}

test_that("each JTCVS function warns, naming the call that replaces it", {
  skip_if_not_installed("broom")
  tbl <- dep_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  new <- "hv_man_table(tbl, style = \"manuscript\", layout = \"describe\")"
  expect_warning(ft <- hv_man_table_jtcvs(tbl, g),
                 new, fixed = TRUE, class = "deprecatedWarning")
  expect_warning(hv_test_footnotes_jtcvs(tbl),
                 new, fixed = TRUE, class = "deprecatedWarning")
  expect_warning(
    hv_man_table_save_jtcvs(ft, tempfile(fileext = ".docx"),
                            caption = "Table 1. X"),
    new, fixed = TRUE, class = "deprecatedWarning"
  )
})

test_that("the wrappers keep the Overall, P and Std. Diff. columns", {
  # Design D3: groups and trailing choose the same columns as before.
  skip_if_not_installed("broom")
  tbl <- dep_tbl()
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_0 = "Overall", stat_1 = "A", stat_2 = "B"),
    trailing = attr(tbl, "hv_trailing")
  ))
  expect_true(all(c("disp_stat_0", "hv_compare_col", "hv_join_1") %in%
                    ft$col_keys))
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
  expect_gt(length(notes), 0L)
  expect_true(all(vapply(notes, `[[`, "", "col") == "hv_compare_col"))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. X",
    footnotes = notes
  ))
  x <- officer::read_docx(f)$doc_obj$get()
  head <- vapply(
    xml2::xml_find_all(x, "//w:tbl/w:tr[position() <= 2]/w:tc"),
    xml2::xml_text, character(1)
  )
  expect_true("Overall" %in% head)
  # The P column's label, then the dagger its note (the tests) puts on it.
  expect_true("P\u2020" %in% head)
  expect_true("Std. Diff." %in% head)
})

mk_jtcvs_tbl <- function() {
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10)),
    nyha = factor(sample(c("I", "II", "III"), n, replace = TRUE))
  )
  dta$age[sample(n, 5)] <- NA

  dta |>
    tbl_summary(
      by = group, # nolint: object_usage_linter.
      statistic = list(
        all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}",
        all_categorical() ~ "{N_nonmiss} ||| {n} ({p}%)"
      ),
      missing = "no"
    ) |>
    modify_table_body(
      mutate,
      groupname_col = case_when(
        variable == "age" ~ "Demographics", TRUE ~ "Cardiac"
      )
    )
}

test_that(".reshape_jtcvs_body splits N and stat into paired columns", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  age_row <- reshaped[reshaped$label == "age", ]
  # Non-missing counts: the fixture's 27/33 group rows less its 5 NA ages.
  expect_identical(age_row$n_stat_1, "24")
  expect_true(grepl("±", age_row$disp_stat_1))
  expect_identical(age_row$n_stat_2, "31")
})

test_that(".reshape_jtcvs_body marks section-header rows, blanks stats", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  sec <- reshaped[reshaped$is_section, ]
  expect_identical(sec$label, c("Demographics", "Cardiac"))
  expect_true(all(is.na(sec$n_stat_1)))
  expect_true(all(is.na(sec$disp_stat_1)))
})

test_that(".reshape_jtcvs_body leaves categorical rows blank, not erroring", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  nyha_row <- reshaped[reshaped$label == "nyha", ]
  expect_true(is.na(nyha_row$n_stat_1))
})

test_that(".reshape_jtcvs_body works with no groupname_col (no sections)", {
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10))
  )
  dta$age[sample(n, 5)] <- NA
  tbl <- dta |> tbl_summary(
    by = group,
    statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"),
    missing = "no"
  )
  expect_false("groupname_col" %in% names(tbl$table_body))
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  expect_false(any(reshaped$is_section))
  expect_identical(nrow(reshaped), nrow(tbl$table_body))
})

test_that(".jtcvs_body_row_index agrees with .reshape_jtcvs_body's row order", {
  # Anti-drift guard. hv_test_footnotes_jtcvs() computes rendered row
  # indices from .jtcvs_body_row_index(); the renderer lays rows out via
  # .reshape_jtcvs_body(). If either is edited without the other, this
  # fails rather than silently marking the wrong cells.
  tbl <- mk_jtcvs_tbl()
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  expect_identical(
    hvtiRtables:::.jtcvs_body_row_index(tbl$table_body),
    which(!reshaped$is_section)
  )
})

test_that(".jtcvs_body_row_index offsets every row past its section header", {
  # mk_jtcvs_tbl() has 5 body rows in 2 sections (age under Demographics;
  # nyha plus its 3 levels under Cardiac), rendering as:
  #   1 Demographics  2 age  3 Cardiac  4 nyha  5 I  6 II  7 III
  # Note row 1 maps to 2, not 1: the header inserted before a section's
  # first row pushes that row down too. That is why the rule uses `<=`.
  expect_identical(
    hvtiRtables:::.jtcvs_body_row_index(mk_jtcvs_tbl()$table_body),
    c(2L, 4L, 5L, 6L, 7L)
  )
})

test_that(".jtcvs_section_starts returns integer(0) without groupname_col", {
  tb <- data.frame(label = c("a", "b"), stringsAsFactors = FALSE)
  expect_identical(hvtiRtables:::.jtcvs_section_starts(tb), integer(0))
})

# Helper for rendering and checking DOCX XML
docx_xml_jtcvs <- function(ft) {
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

test_that("hv_man_table_jtcvs builds a 2-row header with merged group spans", {
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  ))
  expect_s3_class(ft, "flextable")
  expect_identical(flextable::nrow_part(ft, "header"), 2L)

  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Group A (n=27)", xml, fixed = TRUE))
  expect_true(grepl("Group B (n=33)", xml, fixed = TRUE))
  expect_true(grepl(">n<", xml, fixed = TRUE))
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))
  # sub-header row ("n") comes after the spanning group-label row in
  # document order
  expect_true(
    regexpr("Group A", xml, fixed = TRUE) < regexpr(">n<", xml, fixed = TRUE)
  )
})

test_that("hv_man_table_jtcvs rejects a trailing name not in table_body", {
  expect_error(
    jtcvs_quiet(hv_man_table_jtcvs(
      mk_jtcvs_tbl(),
      groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = c(nonexistent = "Label")
    )),
    "not a column"
  )
})

test_that("hv_man_table_jtcvs rejects an unnamed trailing", {
  expect_error(
    jtcvs_quiet(hv_man_table_jtcvs(
      mk_jtcvs_tbl(),
      groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = "std_diff"
    )),
    "`trailing` must be a named character vector",
    fixed = TRUE
  )
})

test_that("hv_man_table_jtcvs rejects a repeated trailing name", {
  tbl <- mk_jtcvs_tbl()
  tbl$table_body$a <- "x"
  expect_error(
    jtcvs_quiet(hv_man_table_jtcvs(
      tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = c(a = "P", a = "Q")
    )),
    "`trailing` names a column more than once: a.",
    fixed = TRUE
  )
})

test_that("hv_man_table_jtcvs lays out two trailing columns in order", {
  tbl <- mk_jtcvs_tbl()
  tbl$table_body$a <- "x"
  tbl$table_body$b <- "y"
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "Group A", stat_2 = "Group B"),
    trailing = c(a = "P", b = "Std. Diff. (%)")
  ))
  expect_identical(utils::tail(ft$col_keys, 2), c("a", "b"))
  # Values, not just headers: flextable lays out a blank column for a
  # key its data lacks, so a dropped column would pass a header check.
  expect_true(all(ft$body$dataset$b[!is.na(ft$body$dataset$b)] == "y"))
  expect_true(any(!is.na(ft$body$dataset$b)))
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Std. Diff. (%)", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs adds an optional trailing column", {
  tbl <- mk_jtcvs_tbl()
  tbl$table_body$std_diff <- "12"
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)"),
    trailing = c(std_diff = "Std. Diff.")
  ))
  expect_true("std_diff" %in% ft$col_keys)
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Std. Diff.", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs accepts a custom stat_label", {
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)"),
    stat_label = "No. (%) or Median [15th, 85th percentiles]"
  ))
  xml <- docx_xml_jtcvs(ft)
  expect_true(
    grepl("No. (%) or Median [15th, 85th percentiles]", xml, fixed = TRUE)
  )
  expect_false(grepl("Mean", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs defaults stat_label to the mean/SD text", {
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  ))
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("No. (%) or Mean±SD", xml, fixed = TRUE))
  expect_false(grepl("Mean ± SD", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs reproduces template's header/section shape", {
  set.seed(1)
  n <- 525
  # `factor()` defaults to alphabetical level order ("Isolated" before
  # "Non-Isolated"), which would silently swap which group lands in stat_1
  # vs. stat_2 — verified by actually running this without explicit
  # `levels =` during planning and getting 133/392 reversed. Pin the levels
  # explicitly so stat_1 is deterministically "Non-Isolated".
  dta <- data.frame(
    group = factor(
      rep(c("Non-Isolated", "Isolated"), c(392, 133)),
      levels = c("Non-Isolated", "Isolated")
    ),
    age = round(rnorm(n, 66.6, 12))
  )
  tbl <- dta |> gtsummary::tbl_summary(
    by = group,
    statistic = list(
      gtsummary::all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"
    ),
    missing = "no"
  ) |>
    gtsummary::modify_table_body(dplyr::mutate, groupname_col = "Demographics")

  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl,
    groups = c(
      stat_1 = "Non-Isolated Re-Replacement (n=392)",
      stat_2 = "Isolated Re-Replacement (n=133)"
    )
  ))
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl(">n<", xml, fixed = TRUE))
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))

  body <- ft$body$dataset
  expect_identical(body$label[1], "Demographics")
  expect_identical(body$n_stat_1[2], "392")
  expect_identical(body$n_stat_2[2], "133")
})

test_that("hv_man_table_jtcvs enforces the house font_size rule", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_s3_class(jtcvs_quiet(hv_man_table_jtcvs(tbl, g, font_size = 11)),
                  "flextable")
  for (bad in list(10, c(11, 12), "12", NA_real_, numeric(0))) {
    expect_error(jtcvs_quiet(hv_man_table_jtcvs(tbl, g, font_size = bad)),
                 "must be 11 or 12")
  }
})

test_that("hv_man_table_jtcvs validates font and stat_label", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_error(jtcvs_quiet(hv_man_table_jtcvs(tbl, g, font = 12)), "`font`")
  expect_error(jtcvs_quiet(hv_man_table_jtcvs(tbl, g, stat_label = "")),
               "`stat_label`")
})

test_that("hv_man_table_jtcvs rejects unknown groups names", {
  tbl <- fx_jtcvs_tbl()
  expect_identical(
    tryCatch(jtcvs_quiet(hv_man_table_jtcvs(tbl, c(stat_3 = "C"))),
             error = conditionMessage),
    paste0("`groups` names must be columns in `tbl$table_body`. ",
           "Not found: stat_3. Available: stat_1, stat_2.")
  )
})

test_that("hv_man_table_jtcvs refuses a table lacking the convention", {
  # Regression for the silent defect: this previously returned a
  # complete, correctly styled, entirely empty flextable.
  tbl <- fx_plain_tbl()
  expect_error(
    jtcvs_quiet(hv_man_table_jtcvs(tbl, c(stat_1 = "A", stat_2 = "B"))),
    "was not built with the"
  )
})

test_that("hv_man_table_jtcvs's convention error still names itself", {
  # Regression for PR #23 review: .assert_stat_convention() gained a
  # `caller` argument so hv_man_table() could get its own name in this
  # message. The JTCVS caller passes nothing, relying on the default, so
  # its message must be byte-identical to before the change.
  tbl <- fx_plain_tbl()
  msg <- tryCatch(
    jtcvs_quiet(hv_man_table_jtcvs(tbl, c(stat_1 = "A", stat_2 = "B"))),
    error = conditionMessage
  )
  expect_match(msg, "hv_man_table_jtcvs() requires", fixed = TRUE)
  expect_false(grepl("hv_man_table()", msg, fixed = TRUE))
})

test_that("hv_man_table_jtcvs accepts an hv_tbl_summary table", {
  # Guards the non-NA qualifier: this table has NA stat cells and must
  # still render.
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    fx_hv_tbl(),
    c(stat_1 = "A", stat_2 = "B")
  ))
  expect_s3_class(ft, "flextable")
})

test_that("hv_man_table_jtcvs rejects a duplicated groups name", {
  # Left to flextable this leaked "duplicated col_keys: n_stat_1,
  # disp_stat_1" -- internal column names the user never wrote and
  # cannot find in any help page.
  msg <- tryCatch(
    jtcvs_quiet(hv_man_table_jtcvs(
      fx_jtcvs_tbl(), c(stat_1 = "A", stat_1 = "B")
    )),
    error = conditionMessage
  )
  expect_false(grepl("col_keys", msg, fixed = TRUE))
  expect_match(msg, "must name each column at most once", fixed = TRUE)
})

test_that("the JTCVS comparison column has no leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B"),
    trailing = attr(tbl, "hv_trailing")
  ))
  p <- stats::na.omit(ft$body$dataset$hv_compare_col)
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})

test_that("a JTCVS section row spans the table in one cell", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(Demography = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "none")
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B")
  ))
  sec <- which(ft$body$dataset$is_section)
  n <- length(ft$col_keys)
  expect_equal(unname(ft$body$spans$rows[sec, ]), c(n, rep(0L, n - 1L)))
})

test_that("the wrapper passes groups, trailing and stat_label through", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$a <- "x"
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_2 = "Second", stat_1 = "First"),
    trailing = c(a = "Own"), stat_label = "Mean (SD)"
  ))
  expect_identical(attr(ft, "hv_layout"), "describe")
  expect_identical(ft$col_keys, c("label", "n_stat_2", "disp_stat_2",
                                  "n_stat_1", "disp_stat_1", "a"))
  head <- flextable::information_data_chunk(ft)
  head <- head[head$.part == "header", ]
  txt <- function(i, k) {
    paste(head$txt[head$.row_id == i & head$.col_id == k], collapse = "")
  }
  expect_identical(c(txt(1, "n_stat_2"), txt(1, "n_stat_1"), txt(1, "a"),
                     txt(2, "disp_stat_2")),
                   c("Second", "First", "Own", "Mean (SD)"))
})

test_that("the deprecated call marks the minority statistic with a pilcrow", {
  # One mean row against one median row: a tie, so the median stays the
  # default and the mean row carries the standard's mark.
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker")),
                        continuous = c("age", "marker"), mean_sd = "age",
                        compare = "none", show_variable = FALSE)
  ft <- jtcvs_quiet(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
  )
  expect_identical(attr(ft, "hv_body_marks"),
                   c("¶" = "Mean±SD."))
  ch <- flextable::information_data_chunk(ft)
  age <- which(ft$body$dataset$variable == "age")
  for (col in c("disp_stat_1", "disp_stat_2"))
    expect_true(any(ch$.part == "body" & ch$.row_id == age &
                      ch$.col_id == col & ch$txt == "¶" &
                      ch$vertical.align == "superscript"), info = col)
  path <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, path, caption = "Table 1. Test"))
  text <- officer::docx_summary(officer::read_docx(path))$text
  expect_true("¶Mean±SD." %in% text)
  expect_false(any(grepl("Age, Mean", text, fixed = TRUE)))
})

test_that("the wrapper's marks follow custom group columns", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$custom_a <- tbl$table_body$stat_1
  tbl$table_body$custom_b <- tbl$table_body$stat_2
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(custom_a = "A", custom_b = "B")
  ))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "Table 1. X"))
  x <- officer::read_docx(f)$doc_obj$get()
  sub <- vapply(xml2::xml_find_all(x, "//w:tbl/w:tr[2]/w:tc"),
                xml2::xml_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(sum(endsWith(sub, "†")), 2L)
})

test_that("a test note the table does not name itself is kept, lettered", {
  # A plain gtsummary table carries no test sentence in its dagger note,
  # so the note hv_test_footnotes_jtcvs() wrote is the only place the
  # test is named.
  skip_if_not_installed("broom")
  tbl <- gtsummary::add_p(fx_jtcvs_tbl())
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$hv_compare_col <- ifelse(is.na(tb$p.value), NA_character_,
                                sprintf("%.2f", tb$p.value))
    tb
  })
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B"),
    trailing = c(hv_compare_col = "P")
  ))
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
  expect_identical(vapply(notes, `[[`, "", "text"),
                   c("Wilcoxon rank-sum test.", "Pearson chi-square test."))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "Table 1. X",
                                      footnotes = notes))
  text <- officer::docx_summary(officer::read_docx(f))$text
  expect_true("a. Wilcoxon rank-sum test." %in% text)
  expect_true("b. Pearson chi-square test." %in% text)
})
