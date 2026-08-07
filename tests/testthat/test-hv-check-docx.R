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

# The one house rule flextable *can* break: footnote() writes its text as
# an extra row inside the table rather than as document text below it,
# which is exactly the misuse hv_man_table_save_jtcvs() warns about. This
# fixture needs no XML surgery.
mk_footnote_docx <- function(path) {
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
  ft <- flextable::footnote(
    ft, i = 1, j = 1,
    value = flextable::as_paragraph("Values are median (15th, 85th)."),
    ref_symbols = "*", part = "header"
  )
  hv_man_table_save_jtcvs(ft, path, caption = "Table 1. X")
  path
}

# A raw two-column table, spliced in as the document's first table. `width`
# is the second column's dxa width and `fill` its cell text, so one helper
# covers the hidden spacer and both near misses (wide-and-empty gutter,
# narrow-but-filled column).
raw_table_xml <- function(width, fill = "", last = "age") {
  cell <- function(txt) {
    if (nzchar(txt))
      sprintf("<w:tc><w:p><w:r><w:t>%s</w:t></w:r></w:p></w:tc>", txt)
    else "<w:tc><w:p/></w:tc>"
  }
  paste0(
    "<w:tbl><w:tblGrid><w:gridCol w:w=\"2880\"/>",
    sprintf("<w:gridCol w:w=\"%d\"/>", width),
    "</w:tblGrid>",
    "<w:tr>", cell("Characteristic"), cell(fill), "</w:tr>",
    "<w:tr>", cell(last), cell(fill), "</w:tr>",
    "</w:tbl>"
  )
}

# officer/flextable expose no API for building a floating text box or a
# hidden column: the tools that enforce the house rules cannot produce
# documents that break them. Those fixtures therefore rewrite
# word/document.xml directly, per the design spec.
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

test_that("hv_check_docx detects an empty near-zero-width column", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub("<w:body>", paste0("<w:body>", raw_table_xml(72)), xml, fixed = TRUE)
  })
  report <- hv_check_docx(dirty)
  hits <- report[report$type == "hidden_column", ]
  expect_identical(nrow(hits), 1L)
  expect_identical(hits$table, 1L)
  expect_identical(hits$location, "column 2")
  expect_match(hits$detail, "72 dxa")
})

test_that("hv_check_docx spares a wide gutter and a narrow filled column", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      paste0(
        "<w:body>",
        # the deliberate 0.5" all-empty spacer the house templates use
        raw_table_xml(720),
        # a legitimately narrow column carrying a two-digit N
        raw_table_xml(72, fill = "20")
      ),
      xml, fixed = TRUE
    )
  })
  expect_identical(nrow(hv_check_docx(dirty)), 0L)
})

test_that("hv_check_docx detects a footnote row inside the table", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  report <- hv_check_docx(mk_footnote_docx(out))
  hits <- report[report$type == "embedded_footnote", ]
  expect_identical(nrow(hits), 1L)
  expect_identical(hits$table, 1L)
  expect_match(hits$location, "^row 5 \\(last row\\), cell 1$")
  expect_match(hits$detail, "Values are median")
})

test_that("hv_check_docx detects a dagger-marked last row", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      # &#8224; is the dagger, written as an XML character reference so the
      # test source and the spliced file both stay ASCII.
      paste0("<w:body>", raw_table_xml(2880, last = "&#8224; n = 40")),
      xml, fixed = TRUE
    )
  })
  report <- hv_check_docx(dirty)
  expect_identical(report$type, "embedded_footnote")
  expect_identical(report$location, "row 2 (last row), cell 1")
})

test_that("hv_check_docx spares a last row that merely starts a word", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      # "a fib" starts with a letter, but a lettered footnote marker needs
      # the trailing "." or ")": a bare word is data, not a footnote.
      paste0("<w:body>", raw_table_xml(2880, last = "a fib")),
      xml, fixed = TRUE
    )
  })
  expect_identical(nrow(hv_check_docx(dirty)), 0L)
})

test_that("hv_check_docx reports every violation kind in one file", {
  fn <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(fn, dirty)), add = TRUE)
  mk_footnote_docx(fn)
  splice_docx_xml(fn, dirty, function(xml) {
    sub(
      "<w:body>",
      paste0(
        "<w:body><w:p><w:pPr><w:framePr w:w=\"2000\" w:h=\"1000\"",
        " w:hRule=\"exact\" w:vAnchor=\"page\" w:hAnchor=\"page\"/>",
        "</w:pPr><w:r><w:t>floating</w:t></w:r></w:p>",
        raw_table_xml(72)
      ),
      xml, fixed = TRUE
    )
  })
  report <- hv_check_docx(dirty)
  expect_setequal(
    report$type, c("layer", "hidden_column", "embedded_footnote")
  )
  expect_identical(nrow(report), 3L)
  # the spliced table is first, so the real one shifts to table 2
  expect_identical(report$table[report$type == "hidden_column"], 1L)
  expect_identical(report$table[report$type == "embedded_footnote"], 2L)
})
