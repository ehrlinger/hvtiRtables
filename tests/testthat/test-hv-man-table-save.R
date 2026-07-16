library(dplyr)
library(gtsummary)

mk_ft <- function() {
  set.seed(1)
  dta <- data.frame(age = round(rnorm(50, 60, 10)),
                    grp = factor(sample(c("A", "B"), 50, replace = TRUE)))
  tbl <- tbl_summary(dta, by = grp, # nolint: object_usage_linter.
                     missing = "no")
  hv_man_table(tbl)
}

read_docx_text <- function(path) {
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = xdir)
  lines <- readLines(file.path(xdir, "word", "document.xml"), warn = FALSE)
  paste(lines, collapse = "")
}

test_that("hv_man_table_save writes a file, returns the path invisibly", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  vis <- withVisible(hv_man_table_save(ft, f))
  expect_false(vis$visible)
  expect_identical(vis$value, f)
  expect_true(file.exists(f))
})

test_that("hv_man_table_save renders footnotes below the table, not a cell", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(
    ft, f,
    footnotes = list(`*` = "Number of non-missing values.")
  )
  xml <- read_docx_text(f)
  expect_true(grepl("Number of non-missing values", xml, fixed = TRUE))
  # Regression guard: the footnote text must NOT be embedded inside the
  # table's own <w:tbl> block (that's the flextable::footnote() bug this
  # function exists to avoid) — it must appear only after the table closes.
  tbl_start <- regexpr("<w:tbl[ >]", xml)
  tbl_end <- regexpr("</w:tbl>", xml, fixed = TRUE)
  expect_true(tbl_start > 0 && tbl_end > 0)
  tbl_region <- substr(
    xml, tbl_start, tbl_end + attr(tbl_end, "match.length") - 1
  )
  expect_false(grepl("Number of non-missing values", tbl_region, fixed = TRUE))
})

test_that("hv_man_table_save renders an alphabetical Key: block", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(
    ft, f,
    abbreviations = c(
      SMD = "standardized mean difference",
      NYHA = "New York Heart Association"
    )
  )
  xml <- read_docx_text(f)
  expect_true(grepl("Key:", xml, fixed = TRUE))
  nyha_pos <- regexpr("NYHA", xml, fixed = TRUE)
  smd_pos <- regexpr("SMD", xml, fixed = TRUE)
  expect_true(nyha_pos < smd_pos) # alphabetical: NYHA before SMD
})

test_that("hv_man_table_save validates footnote symbols", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    hv_man_table_save(ft, f, footnotes = list(`#` = "bad symbol")),
    "footnote symbol"
  )
})

test_that("hv_man_table_save validates inputs", {
  f <- tempfile(fileext = ".docx")
  expect_error(hv_man_table_save("not a flextable", f), "flextable")
  bad_path <- file.path(tempdir(), "no_such_dir_xyz", "t.docx")
  expect_error(
    hv_man_table_save(mk_ft(), bad_path),
    "directory does not exist"
  )
})

test_that("hv_man_table_save applies hv_man_footnotes() by default", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f)
  xml <- read_docx_text(f)
  expect_true(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_true(grepl("Median (15th, 85th percentile)", xml, fixed = TRUE))
})

test_that("footnotes = NULL suppresses both standard footnotes", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f, footnotes = NULL)
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_false(grepl("Median (15th, 85th percentile)", xml, fixed = TRUE))
})

test_that("hv_man_table_save rejects fully unnamed footnotes", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    hv_man_table_save(ft, f, footnotes = list("unnamed text")),
    "footnotes.*named"
  )
})

test_that("rejects footnotes with any unnamed entry", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    hv_man_table_save(ft, f, footnotes = list(`*` = "ok", "unnamed")),
    "footnotes.*named"
  )
})

test_that("rejects footnotes with an NA name (Copilot C1)", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  footnotes <- list(`*` = "ok")
  names(footnotes)[1] <- NA
  expect_error(
    hv_man_table_save(ft, f, footnotes = footnotes),
    "footnotes.*named"
  )
})

test_that("footnotes = list() is a no-op, same as NULL", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_no_error(hv_man_table_save(ft, f, footnotes = list()))
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
})

test_that("hv_man_table_save rejects fully unnamed abbreviations", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    hv_man_table_save(
      ft, f,
      abbreviations = c("expansion1", "expansion2")
    ),
    "abbreviations.*named"
  )
})

test_that("rejects abbreviations with any unnamed entry", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    hv_man_table_save(
      ft, f,
      abbreviations = c(ABBR = "expansion", "unnamed expansion")
    ),
    "abbreviations.*named"
  )
})

test_that("rejects abbreviations with an NA name (Copilot C2)", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  abbreviations <- c(ABBR = "expansion")
  names(abbreviations)[1] <- NA
  expect_error(
    hv_man_table_save(ft, f, abbreviations = abbreviations),
    "abbreviations.*named"
  )
})

test_that("abbreviations = character(0) is a no-op, same as NULL", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_no_error(hv_man_table_save(ft, f, abbreviations = character(0)))
  xml <- read_docx_text(f)
  expect_false(grepl("Key:", xml, fixed = TRUE))
})

test_that("hv_man_table_save still renders the Key: block after refactor", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(
    ft, f, abbreviations = c(NYHA = "New York Heart Association")
  )
  xml <- read_docx_text(f)
  expect_true(grepl("Key:", xml, fixed = TRUE))
  expect_true(grepl("NYHA", xml, fixed = TRUE))
})
