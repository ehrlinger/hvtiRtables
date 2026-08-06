library(gtsummary)

# A minimal, clean .docx written by the package itself. Used as the
# negative case and as the base for the positive fixtures below.
mk_clean_docx <- function(path) {
  set.seed(1)
  n <- 40
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    age = rnorm(n, 60, 10)
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age"
  )
  ft <- hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B"),
    stat_label = attr(tbl, "hv_stat_label")
  )
  hv_man_table_save_jtcvs(ft, path, caption = "Table 1. X")
  path
}

# officer/flextable expose no API for building a floating text box, a
# hidden column, or an embedded footnote: the tools that enforce the house
# rules cannot produce documents that break them. Positive fixtures
# therefore rewrite word/document.xml directly, per the design spec.
splice_docx_xml <- function(src, dest, mutate) {
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(src, exdir = xdir)
  target <- file.path(xdir, "word", "document.xml")
  xml <- paste(readLines(target, warn = FALSE), collapse = "")
  writeLines(mutate(xml), target)
  old <- setwd(xdir)
  on.exit(setwd(old), add = TRUE)
  utils::zip(dest, list.files(".", recursive = TRUE), flags = "-qr9X")
  dest
}

test_that("hv_check_docx rejects a missing or non-docx path", {
  expect_error(hv_check_docx(tempfile(fileext = ".docx")), "does not exist")
  bad <- tempfile(fileext = ".docx")
  writeLines("not a zip archive", bad)
  expect_error(hv_check_docx(bad), "valid .docx")
})

test_that("hv_check_docx reports zero findings on the package's own output", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  report <- hv_check_docx(mk_clean_docx(out))
  expect_s3_class(report, "data.frame")
  expect_identical(
    names(report), c("type", "table", "location", "detail")
  )
  expect_identical(nrow(report), 0L)
})

test_that("hv_check_docx detects a w:framePr floating layer", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      paste0(
        "<w:body><w:p><w:pPr><w:framePr w:w=\"2000\" w:h=\"1000\"",
        " w:hRule=\"exact\" w:vAnchor=\"page\" w:hAnchor=\"page\"/>",
        "</w:pPr><w:r><w:t>floating</w:t></w:r></w:p>"
      ),
      xml, fixed = TRUE
    )
  })
  report <- hv_check_docx(dirty)
  expect_true("layer" %in% report$type)
  expect_match(report$detail[report$type == "layer"], "framePr")
})

test_that("hv_check_docx detects a floating text box", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      paste0(
        "<w:body><w:p><w:r><w:drawing>",
        "<wp:anchor xmlns:wp=\"http://schemas.openxmlformats.org/",
        "drawingml/2006/wordprocessingDrawing\">",
        "<w:txbxContent><w:p><w:r><w:t>boxed</w:t></w:r></w:p>",
        "</w:txbxContent></wp:anchor></w:drawing></w:r></w:p>"
      ),
      xml, fixed = TRUE
    )
  })
  report <- hv_check_docx(dirty)
  expect_true("layer" %in% report$type)
  expect_match(
    paste(report$detail[report$type == "layer"], collapse = " "),
    "text box"
  )
})
