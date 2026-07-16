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
