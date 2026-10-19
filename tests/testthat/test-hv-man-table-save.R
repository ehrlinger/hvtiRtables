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
  expect_true(grepl("Median [15th, 85th percentiles]", xml, fixed = TRUE))
})

test_that("default footnotes follow a mean table", {
  dta <- data.frame(age = c(10, 20, 30, NA))
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "age"), continuous = "age",
    continuous_stat = "mean"
  )
  ft <- hv_man_table(tbl)
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f)
  xml <- read_docx_text(f)
  expect_true(grepl("Mean±SD.", xml, fixed = TRUE))
  expect_false(grepl("Median [15th, 85th percentiles]", xml, fixed = TRUE))
})

test_that("default footnotes follow a table with both statistics", {
  dta <- data.frame(age = c(10, 20, 30, NA))
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "age"), continuous = "age",
    continuous_stat = "both"
  )
  ft <- hv_man_table(tbl)
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f)
  xml <- read_docx_text(f)
  # The statistic columns hold mean±SD; the median sits in its own
  # column, which names itself in its header.
  expect_true(grepl("No. (%) or Mean±SD.", xml, fixed = TRUE))
  expect_true(grepl("Median [15th, 85th percentiles]", xml, fixed = TRUE))
})

test_that("default footnotes follow custom percentiles", {
  dta <- data.frame(age = c(10, 20, 30, NA))
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "age"), continuous = "age",
    percentiles = c(16, 84)
  )
  ft <- hv_man_table(tbl)
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f)
  xml <- read_docx_text(f)
  expect_true(grepl("Median [16th, 84th percentiles].", xml, fixed = TRUE))
  expect_false(grepl("Median [15th, 85th percentiles].", xml, fixed = TRUE))
})

test_that("default footnotes survive grouped p-value processing", {
  dta <- data.frame(
    age = c(10, 20, 30, 40, 50, 60),
    arm = factor(rep(c("A", "B"), each = 3))
  )
  tbl <- hv_tbl_summary(
    dta, by = "arm", groups = list(Demography = "age"),
    continuous = "age", continuous_stat = "mean"
  )
  ft <- hv_man_table(tbl)
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f)
  xml <- read_docx_text(f)
  # The table compares its groups, so the dagger note also names the test.
  expect_true(grepl(
    "Mean±SD; P values from the Wilcoxon rank sum test.", xml, fixed = TRUE
  ))
  expect_false(grepl("Median [15th, 85th percentiles]", xml, fixed = TRUE))
})

test_that("footnotes NULL suppresses metadata-bearing defaults", {
  dta <- data.frame(age = c(10, 20, 30, NA))
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "age"), continuous = "age",
    continuous_stat = "both"
  )
  ft <- hv_man_table(tbl)
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f, footnotes = NULL)
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_false(grepl("Mean±SD; Median", xml, fixed = TRUE))
})

test_that("footnotes = NULL suppresses both standard footnotes", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save(ft, f, footnotes = NULL)
  xml <- read_docx_text(f)
  expect_false(grepl("Number of non-missing values", xml, fixed = TRUE))
  expect_false(grepl("Median [15th, 85th percentiles]", xml, fixed = TRUE))
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

test_that("hv_man_table_save rejects footnote text that is not a string", {
  # Regression for the silent defect: each of these previously WROTE the
  # .docx, with a header marked `Characteristic*` and a footnote
  # paragraph of "* " (or "* NA", "* 1", "* a* b") -- a dangling marker.
  ft <- mk_ft()
  for (bad in list(NULL, NA, 1, c("a", "b"), "")) {
    f <- tempfile(fileext = ".docx")
    expect_error(
      hv_man_table_save(ft, f, footnotes = list(`*` = bad)),
      "must be a single non-empty string"
    )
    expect_false(file.exists(f))
  }
})

test_that("footnote text error names the offending symbol", {
  # `footnotes` is a named list keyed by symbol, not by position, so a
  # positional "entry 2" label would force a CORR caller to count list
  # entries to find the bad one. Put the bad entry second so a
  # positional label would visibly be wrong.
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  msg <- tryCatch(
    hv_man_table_save(
      ft, f, footnotes = list(`*` = "fine", `†` = NULL)
    ),
    error = conditionMessage
  )
  expect_identical(
    msg,
    paste0("`footnotes[[\"†\"]]` must be a single non-empty ",
           "string; it is missing. A marker whose text is missing ",
           "renders as a dangling reference with nothing after it. ",
           "Give the entry text, e.g. \"Values are median ",
           "[P15, P85].\"")
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

test_that("hv_man_table_save rejects a non-character abbreviations", {
  ft <- mk_ft()
  f <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save(ft, f, abbreviations = list(N = "x")),
    "named character vector"
  )
  expect_false(file.exists(f))
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

# -- the saved table fits the page ----------------------------------------

test_that("a two-group 'both' CORR table with Overall is fitted to landscape", {
  skip_if_not_installed("broom")
  # Measured 13.09 in before fitting: each median column autofits to its
  # header, and landscape alone (9.03 in of text) clipped the labels and
  # the p-value column.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = c("age", "grade")),
    continuous = "age", categorical = "grade", continuous_stat = "both",
    compare = "pvalue"
  )
  ft <- hv_man_table(tbl)
  expect_gt(sum(ft$body$colwidths), 9.03)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  g <- fit_geometry(path)
  expect_true(g$landscape)
  expect_lte(g$table, g$text)
  expect_identical(nrow(hv_check_docx(path)), 0L)
})

test_that("a CORR table wider than portrait but under 3 groups turns", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", continuous_stat = "both", overall = FALSE,
    compare = "none"
  )
  ft <- hv_man_table(tbl)
  ft <- flextable::width(ft, j = "label", width = 4)
  expect_gt(sum(ft$body$colwidths), 6.53)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  g <- fit_geometry(path)
  expect_true(g$landscape)
  expect_lte(g$table, g$text)
})

test_that("a table just inside the landscape text block is still narrowed", {
  # Between 0.01 in inside the margins and the margins themselves, the
  # per-column twip rounding could put the grid past the text block.
  ft <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none", show_variable = FALSE
  ))
  target <- .text_width(landscape = TRUE) - 0.005
  ft <- flextable::width(ft, j = "label",
                         width = ft$body$colwidths[["label"]] +
                           target - sum(ft$body$colwidths))
  fit <- .fit_page(ft)
  expect_lte(sum(fit$ft$body$colwidths), .text_width(landscape = TRUE) - 0.01)
  expect_true(fit$landscape)
})

test_that("a saved table is on a US Letter page, portrait or landscape", {
  narrow <- hv_man_table(gtsummary::tbl_summary(gtsummary::trial,
                                                include = age))
  f1 <- tempfile(fileext = ".docx")
  hv_man_table_save(narrow, f1)
  expect_identical(pg_size(f1), c(w = "12240", h = "15840"))
  # Four statistic columns (Overall and three grades) turn the page.
  wide <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "grade", groups = list(A = "age"),
    continuous = "age", compare = "none", show_variable = FALSE
  ))
  f2 <- tempfile(fileext = ".docx")
  hv_man_table_save(wide, f2)
  expect_identical(pg_size(f2), c(w = "15840", h = "12240"))
})

# -- The manuscript style: caption, leading symbols, header marks ---------

ms_ft <- function() {
  hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", show_variable = FALSE
  ), style = "manuscript")
}
ms_doc <- function(ft = ms_ft(), ...) {
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, ...)
  officer::read_docx(f)$doc_obj$get()
}

test_that("a manuscript table is saved with its caption above it, in bold", {
  x <- ms_doc(caption = "Table 1. Baseline characteristics")
  first <- xml2::xml_find_first(x, "//w:body/*[1]")
  expect_identical(xml2::xml_name(first), "p")
  expect_identical(xml2::xml_text(first), "Table 1. Baseline characteristics")
  expect_length(xml2::xml_find_all(first, ".//w:rPr/w:b[not(@w:val='false')]"),
                1L)
})

test_that("a manuscript note begins with its plain symbol", {
  x <- ms_doc(caption = "Table 1. Test")
  ps <- xml2::xml_find_all(x, "//w:tbl/following-sibling::w:p")
  text <- vapply(ps, xml2::xml_text, character(1))
  expect_identical(text[1], "*Patients with non-missing data.")
  expect_identical(
    text[2], "†Values are No. (%) or median [15th, 85th percentiles]."
  )
  sup <- xml2::xml_find_all(ps[[1]], ".//w:vertAlign[@w:val='superscript']")
  expect_length(sup, 0L)
})

test_that("manuscript header marks: * on n, the dagger on the grouping", {
  x <- ms_doc(caption = "Table 1. Test")
  top <- xml2::xml_find_first(x, "//w:tbl/w:tr[1]")
  cells <- vapply(xml2::xml_find_all(top, "./w:tc"), xml2::xml_text,
                  character(1))
  expect_true("n*" %in% cells)
  expect_true("Chemotherapy Treatment†" %in% cells)
})

test_that("the manuscript requires a caption; the report takes one if given", {
  expect_error(ms_doc(), "caption")
  first <- function(f) {
    xml2::xml_find_first(officer::read_docx(f)$doc_obj$get(), "//w:body/*[1]")
  }
  with_cap <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(fx_hv_tbl()), with_cap,
                    caption = "Table 2. Report")
  expect_identical(xml2::xml_text(first(with_cap)), "Table 2. Report")
  expect_length(xml2::xml_find_all(first(with_cap),
                                   ".//w:rPr/w:b[not(@w:val='false')]"), 1L)
  without <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(fx_hv_tbl()), without)
  expect_identical(xml2::xml_name(first(without)), "tbl")
  expect_error(hv_man_table_save(hv_man_table(fx_hv_tbl()), without,
                                 caption = NA_character_), "caption")
})

test_that("an empty caption is refused before anything is written", {
  f <- tempfile(fileext = ".docx")
  expect_error(hv_man_table_save(hv_man_table(fx_hv_tbl()), f, caption = ""),
               "non-empty string")
  expect_false(file.exists(f))
  f <- tempfile(fileext = ".docx")
  expect_error(hv_man_table_save(ms_ft(), f, caption = ""),
               "non-empty string")
  expect_false(file.exists(f))
})

test_that("the caption takes the table's font", {
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(fx_hv_tbl()), f,
                    caption = "Table 2. Report")
  x <- officer::read_docx(f)$doc_obj$get()
  xp <- "(//w:body/*[1]//w:r)[1]/w:rPr/w:rFonts/@w:ascii"
  expect_identical(xml2::xml_text(xml2::xml_find_all(x, xp)),
                   "Times New Roman")
  x <- ms_doc(caption = "Table 1. Baseline characteristics")
  expect_length(xml2::xml_find_all(x, "//w:body/*[1]//w:rFonts[@w:ascii]"),
                0L)
})
