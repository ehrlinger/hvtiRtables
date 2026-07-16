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
      by = group,
      statistic = list(
        all_continuous() ~ "{mean}±{sd}",
        all_categorical() ~ "{n} ({p})"
      ),
      missing = "no"
    ) |>
    modify_table_body(
      mutate,
      groupname_col = case_when(variable == "age" ~ "Demographics", TRUE ~ "Cardiac")
    ) |>
    add_n()
}

docx_xml <- function(ft) {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  flextable::save_as_docx(ft, path = out)
  xdir <- tempfile()
  utils::unzip(out, exdir = xdir)
  paste(readLines(file.path(xdir, "word", "document.xml"), warn = FALSE), collapse = "")
}

test_that("manuscript_flextable returns a flextable with a single header row", {
  ft <- manuscript_flextable(mk_tbl())
  expect_s3_class(ft, "flextable")
  expect_identical(flextable::nrow_part(ft, "header"), 1L)
})

test_that("manuscript_flextable output has no merged cells (gridSpan/vMerge)", {
  ft <- manuscript_flextable(mk_tbl())
  xml <- docx_xml(ft)
  expect_equal(lengths(regmatches(xml, gregexpr("gridSpan", xml))), 0L)
  expect_equal(lengths(regmatches(xml, gregexpr("vMerge", xml))), 0L)
})

test_that("manuscript_flextable applies the house font and size", {
  ft <- manuscript_flextable(mk_tbl())
  xml <- docx_xml(ft)
  expect_true(grepl("Times New Roman", xml, fixed = TRUE))
  expect_true(grepl('w:sz w:val="24"', xml, fixed = TRUE)) # 12pt = half-points * 2 = 24
})

test_that("manuscript_flextable honours a smaller font_size for wide tables", {
  ft <- manuscript_flextable(mk_tbl(), font_size = 11)
  xml <- docx_xml(ft)
  expect_true(grepl('w:sz w:val="22"', xml, fixed = TRUE)) # 11pt = 22 half-points
})

test_that("manuscript_flextable validates its inputs", {
  expect_error(manuscript_flextable("not a gtsummary object"), "gtsummary")
  expect_error(manuscript_flextable(mk_tbl(), font_size = 10), "font_size")
})
