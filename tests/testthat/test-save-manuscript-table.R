library(dplyr)
library(gtsummary)

mk_ft <- function() {
  set.seed(1)
  dta <- data.frame(age = round(rnorm(50, 60, 10)),
                     grp = factor(sample(c("A", "B"), 50, replace = TRUE)))
  tbl <- tbl_summary(dta, by = grp, missing = "no")
  manuscript_flextable(tbl)
}

read_docx_text <- function(path) {
  xdir <- tempfile()
  utils::unzip(path, exdir = xdir)
  lines <- readLines(file.path(xdir, "word", "document.xml"), warn = FALSE)
  paste(lines, collapse = "")
}

test_that("save_manuscript_table writes a file, returns the path invisibly", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  vis <- withVisible(save_manuscript_table(ft, f))
  expect_false(vis$visible)
  expect_identical(vis$value, f)
  expect_true(file.exists(f))
})

test_that("save_manuscript_table renders footnotes below the table, not in a cell", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  save_manuscript_table(
    ft, f,
    footnotes = list(`*` = "Number of non-missing values.")
  )
  xml <- read_docx_text(f)
  expect_true(grepl("Number of non-missing values", xml, fixed = TRUE))
})

test_that("save_manuscript_table renders an alphabetical Key: block", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  save_manuscript_table(
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

test_that("save_manuscript_table validates footnote symbols", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    save_manuscript_table(ft, f, footnotes = list(`#` = "bad symbol")),
    "footnote symbol"
  )
})

test_that("save_manuscript_table validates inputs", {
  f <- tempfile(fileext = ".docx")
  expect_error(save_manuscript_table("not a flextable", f), "flextable")
  bad_path <- file.path(tempdir(), "no_such_dir_xyz", "t.docx")
  expect_error(
    save_manuscript_table(mk_ft(), bad_path),
    "directory does not exist"
  )
})

test_that("save_manuscript_table applies standard_footnotes() by default", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  save_manuscript_table(ft, f)
  xml <- read_docx_text(f)
  expect_true(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_true(grepl("Median (15th, 85th percentile)", xml, fixed = TRUE))
})

test_that("footnotes = NULL suppresses both standard footnotes", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  save_manuscript_table(ft, f, footnotes = NULL)
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_false(grepl("Median (15th, 85th percentile)", xml, fixed = TRUE))
})

test_that("save_manuscript_table rejects fully unnamed footnotes", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    save_manuscript_table(ft, f, footnotes = list("unnamed text")),
    "footnotes.*named"
  )
})

test_that("rejects footnotes with any unnamed entry", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    save_manuscript_table(ft, f, footnotes = list(`*` = "ok", "unnamed")),
    "footnotes.*named"
  )
})

test_that("footnotes = list() is a no-op, same as NULL", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_no_error(save_manuscript_table(ft, f, footnotes = list()))
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
})

test_that("save_manuscript_table rejects fully unnamed abbreviations", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_error(
    save_manuscript_table(
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
    save_manuscript_table(
      ft, f,
      abbreviations = c(ABBR = "expansion", "unnamed expansion")
    ),
    "abbreviations.*named"
  )
})

test_that("abbreviations = character(0) is a no-op, same as NULL", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  expect_no_error(save_manuscript_table(ft, f, abbreviations = character(0)))
  xml <- read_docx_text(f)
  expect_false(grepl("Key:", xml, fixed = TRUE))
})
