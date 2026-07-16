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
