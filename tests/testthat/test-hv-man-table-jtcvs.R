library(dplyr)
library(gtsummary)

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
        all_continuous() ~ "{N_obs} ||| {mean} ± {sd}",
        all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
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

test_that(".reshape_jtcvs_body splits N_obs and stat into paired columns", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  age_row <- reshaped[reshaped$label == "age", ]
  expect_identical(age_row$n_stat_1, "27")
  expect_true(grepl("±", age_row$disp_stat_1))
  expect_identical(age_row$n_stat_2, "33")
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
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
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
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  expect_s3_class(ft, "flextable")
  expect_identical(flextable::nrow_part(ft, "header"), 2L)

  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Group A (n=27)", xml, fixed = TRUE))
  expect_true(grepl("Group B (n=33)", xml, fixed = TRUE))
  expect_true(grepl(">na<", xml, fixed = TRUE))
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))
  # sub-header row ("na") comes after the spanning group-label row in
  # document order
  expect_true(
    regexpr("Group A", xml, fixed = TRUE) < regexpr(">na<", xml, fixed = TRUE)
  )
})

test_that("hv_man_table_jtcvs bolds, shades, and merges section-header rows", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  body <- ft$body$dataset
  sec_i <- which(body$label %in% c("Demographics", "Cardiac"))
  expect_length(sec_i, 2L)
  bold_map <- ft$body$styles$text$bold$data
  expect_true(all(bold_map[sec_i, 1]))
  # bold only, not italic, matching the canonical "Table Construction for
  # Manuscripts" house example (not bold-italic, as an earlier JTCVS
  # worked-example table happened to use)
  italic_map <- ft$body$styles$text$italic$data
  expect_false(any(italic_map[sec_i, 1]))
  # #CAEDFB matches the canonical house document's section-header shading
  bg_map <- ft$body$styles$cells$background.color$data
  expect_true(all(bg_map[sec_i, 1] == "#CAEDFB"))
})

test_that("hv_man_table_jtcvs sets column widths to avoid wrapping", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  widths <- dim(ft)$widths
  expect_equal(unname(widths["label"]), 2.5)
  expect_equal(unname(widths["n_stat_1"]), 0.6)
  expect_equal(unname(widths["disp_stat_1"]), 0.9)
})

test_that("hv_man_table_jtcvs rejects a trailing name not in table_body", {
  expect_error(
    hv_man_table_jtcvs(
      mk_jtcvs_tbl(),
      groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = c(nonexistent = "Label")
    ),
    "not a column"
  )
})

test_that("hv_man_table_jtcvs rejects an unnamed trailing", {
  expect_error(
    hv_man_table_jtcvs(
      mk_jtcvs_tbl(),
      groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = "std_diff"
    ),
    "named character vector of length 1"
  )
})

test_that("hv_man_table_jtcvs rejects a length-2 trailing", {
  tbl <- mk_jtcvs_tbl()
  tbl$table_body$a <- "x"
  tbl$table_body$b <- "y"
  expect_error(
    hv_man_table_jtcvs(
      tbl,
      groups = c(stat_1 = "Group A", stat_2 = "Group B"),
      trailing = c(a = "A", b = "B")
    ),
    "named character vector of length 1"
  )
})

test_that("hv_man_table_jtcvs adds an optional trailing column", {
  tbl <- mk_jtcvs_tbl()
  tbl$table_body$std_diff <- "12"
  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)"),
    trailing = c(std_diff = "Std. Diff.")
  )
  expect_true("std_diff" %in% ft$col_keys)
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Std. Diff.", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs applies the house font", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("Times New Roman", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs accepts a custom stat_label", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)"),
    stat_label = "No. (%) or Median (15th, 85th percentile)"
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(
    grepl("No. (%) or Median (15th, 85th percentile)", xml, fixed = TRUE)
  )
  expect_false(grepl("Mean", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs defaults stat_label to the mean/SD text", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))
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
    statistic = list(gtsummary::all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    missing = "no"
  ) |>
    gtsummary::modify_table_body(dplyr::mutate, groupname_col = "Demographics")

  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(
      stat_1 = "Non-Isolated Re-Replacement (n=392)",
      stat_2 = "Isolated Re-Replacement (n=133)"
    )
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl(">na<", xml, fixed = TRUE))
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))

  body <- ft$body$dataset
  expect_identical(body$label[1], "Demographics")
  expect_identical(body$n_stat_1[2], "392")
  expect_identical(body$n_stat_2[2], "133")
})

test_that("hv_man_table_jtcvs enforces the house font_size rule", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_s3_class(hv_man_table_jtcvs(tbl, g, font_size = 11),
                  "flextable")
  for (bad in list(10, c(11, 12), "12", NA_real_, numeric(0))) {
    expect_error(hv_man_table_jtcvs(tbl, g, font_size = bad),
                 "must be 11 or 12")
  }
})

test_that("hv_man_table_jtcvs validates font and stat_label", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_error(hv_man_table_jtcvs(tbl, g, font = 12), "`font`")
  expect_error(hv_man_table_jtcvs(tbl, g, stat_label = ""),
               "`stat_label`")
})

test_that("hv_man_table_jtcvs rejects unknown groups names", {
  tbl <- fx_jtcvs_tbl()
  expect_identical(
    tryCatch(hv_man_table_jtcvs(tbl, c(stat_3 = "C")),
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
    hv_man_table_jtcvs(tbl, c(stat_1 = "A", stat_2 = "B")),
    "was not built with the"
  )
})

test_that("hv_man_table_jtcvs accepts an hv_tbl_summary table", {
  # Guards the non-NA qualifier: this table has NA stat cells and must
  # still render.
  ft <- hv_man_table_jtcvs(fx_hv_tbl(),
                           c(stat_1 = "A", stat_2 = "B"))
  expect_s3_class(ft, "flextable")
})

test_that("hv_man_table_jtcvs rejects a duplicated groups name", {
  # Left to flextable this leaked "duplicated col_keys: n_stat_1,
  # disp_stat_1" -- internal column names the user never wrote and
  # cannot find in any help page.
  msg <- tryCatch(
    hv_man_table_jtcvs(fx_jtcvs_tbl(), c(stat_1 = "A", stat_1 = "B")),
    error = conditionMessage
  )
  expect_false(grepl("col_keys", msg, fixed = TRUE))
  expect_match(msg, "must name each column at most once", fixed = TRUE)
})
