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

test_that("hv_check_docx rejects an empty string or NA path", {
  # Tightened onto .check_string(), which rejects these shapes before
  # any filesystem check; never tested until now.
  expect_error(hv_check_docx(""), "non-empty string")
  expect_error(hv_check_docx(NA_character_), "non-empty string")
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

# gtsummary's footnote, as as_flex_table() writes it: a superscript digit
# opening a footer row, then the text. flextable::footnote() produces the
# same shape.
mk_digit_footnote_docx <- function(path, symbol = "1") {
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
    value = flextable::as_paragraph("Wilcoxon rank sum test"),
    ref_symbols = symbol, part = "header"
  )
  hv_man_table_save_jtcvs(ft, path, caption = "Table 1. X")
  path
}

test_that("hv_check_docx detects a gtsummary digit footnote row", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  report <- hv_check_docx(mk_digit_footnote_docx(out))
  hits <- report[report$type == "embedded_footnote", ]
  expect_identical(nrow(hits), 1L)
  expect_match(hits$location, "^row 5 \\(last row\\), cell 1$")
  expect_match(hits$detail, "Wilcoxon rank sum test")
})

test_that("hv_check_docx detects a multi-digit footnote marker", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  report <- hv_check_docx(mk_digit_footnote_docx(out, symbol = "12"))
  expect_identical(report$type, "embedded_footnote")
})

test_that("hv_check_docx detects gtsummary's abbreviation row", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      paste0("<w:body>", raw_table_xml(
        2880, last = "Abbreviation: CI = Confidence Interval"
      )),
      xml, fixed = TRUE
    )
  })
  report <- hv_check_docx(dirty)
  expect_identical(report$type, "embedded_footnote")
})

test_that("hv_check_docx spares a last row that starts with a plain digit", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  splice_docx_xml(clean, dirty, function(xml) {
    sub(
      "<w:body>",
      # Data, not a marker: the digit is body text, not a superscript.
      paste0("<w:body>", raw_table_xml(2880, last = "30-day mortality")),
      xml, fixed = TRUE
    )
  })
  expect_identical(nrow(hv_check_docx(dirty)), 0L)
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

# -- wide_table ------------------------------------------------------------

test_that("hv_check_docx flags a table wider than its page's text block", {
  ft <- flextable::flextable(data.frame(a = "x", b = "y", c = "z"))
  ft <- flextable::width(ft, width = 3)
  path <- tempfile(fileext = ".docx")
  print(flextable::body_add_flextable(officer::read_docx(), ft),
        target = path)
  res <- hv_check_docx(path)
  expect_identical(res$type, "wide_table")
  expect_identical(res$table, 1L)
  expect_match(res$detail, "9.00 in wide", fixed = TRUE)
  expect_match(res$detail, "6.30 in", fixed = TRUE)
})

test_that("hv_check_docx leaves a table that fits alone", {
  ft <- flextable::flextable(data.frame(a = "x", b = "y", c = "z"))
  ft <- flextable::width(ft, width = 2)
  path <- tempfile(fileext = ".docx")
  print(flextable::body_add_flextable(officer::read_docx(), ft),
        target = path)
  expect_identical(nrow(hv_check_docx(path)), 0L)
})

# Minimal WordprocessingML, enough for .detect_wide_table().
wt_doc <- function(body) {
  xml2::read_xml(paste0(
    "<w:document xmlns:w=\"http://schemas.openxmlformats.org/",
    "wordprocessingml/2006/main\"><w:body>", body, "</w:body></w:document>"
  ))
}
wt_tbl <- function(grid) {
  paste0("<w:tbl><w:tblGrid>", grid, "</w:tblGrid></w:tbl>")
}
wt_sect <- function(w) {
  paste0("<w:sectPr><w:pgSz w:w=\"", w, "\"/>",
         "<w:pgMar w:left=\"1417\" w:right=\"1417\"/></w:sectPr>")
}

test_that("wide_table skips a table whose grid widths are missing", {
  # Word fills in widths on open; with none written there is nothing to
  # measure, so the table is left alone rather than failing the check.
  for (grid in c("<w:gridCol/><w:gridCol w:w=\"9000\"/>",
                 "<w:gridCol w:w=\"auto\"/>", "")) {
    res <- .detect_wide_table(wt_doc(paste0(wt_tbl(grid), wt_sect(11900))))
    expect_identical(nrow(res), 0L)
  }
  # The same grid with every width written is measured, and flagged.
  res <- .detect_wide_table(wt_doc(paste0(
    wt_tbl("<w:gridCol w:w=\"9000\"/><w:gridCol w:w=\"9000\"/>"),
    wt_sect(11900)
  )))
  expect_identical(res$type, "wide_table")
})

test_that("wide_table measures each table against its own section", {
  # 8 in of table: past a portrait section's 6.3 in, inside a landscape
  # one's 9.7 in. The first table closes a portrait section with a
  # paragraph-level break; the second sits in the landscape body section.
  wide <- wt_tbl("<w:gridCol w:w=\"11520\"/>")
  doc <- wt_doc(paste0(
    wide, "<w:p><w:pPr>", wt_sect(11900), "</w:pPr></w:p>",
    wide, wt_sect(16840)
  ))
  res <- .detect_wide_table(doc)
  expect_identical(res$table, 1L)
})

test_that("wide_table leaves a document with no section properties alone", {
  doc <- wt_doc(wt_tbl("<w:gridCol w:w=\"20000\"/>"))
  expect_identical(nrow(.detect_wide_table(doc)), 0L)
})

# A saved flextable, for the merged-cell rule.
mc_save <- function(ft) {
  f <- tempfile(fileext = ".docx")
  print(flextable::body_add_flextable(officer::read_docx(), ft), target = f)
  f
}
mc_found <- function(f, style = NULL) {
  res <- hv_check_docx(f, style = style)
  res[res$type == "merged_cell", , drop = FALSE]
}

test_that("a body row merged short of the table's width is a finding", {
  ft <- flextable::flextable(data.frame(a = c("x", "y"), b = c("1", "2"),
                                        c = c("1", "3")))
  ft <- flextable::merge_at(ft, i = 1, j = c("b", "c"), part = "body")
  found <- mc_found(mc_save(ft))
  expect_identical(found$location, "row 2") # row 1 is the header
  expect_identical(found$table, 1L)
})

test_that("header merges and full-width section rows pass the shared rule", {
  ft <- flextable::flextable(data.frame(a = c("Demo", "Age"),
                                        b = c(NA, "1"), c = c(NA, "2")))
  ft <- flextable::add_header_row(ft, values = c("", "Group"),
                                  colwidths = c(1L, 2L))
  ft <- flextable::merge_at(ft, i = 1, j = c("a", "b", "c"), part = "body")
  f <- mc_save(ft)
  expect_identical(nrow(mc_found(f)), 0L)
  expect_identical(nrow(mc_found(f, style = "manuscript")), 0L)
  # The report style merges nothing, so both rows are findings.
  expect_identical(mc_found(f, style = "report")$location,
                   c("row 1", "row 3"))
})

test_that("the package's own tables pass the rule for their style", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade"), Disease = "stage"),
    continuous = "age", categorical = c("grade", "stage")
  )
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), f)
  expect_identical(nrow(mc_found(f, style = "report")), 0L)
  j <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       trailing = attr(tbl, "hv_trailing")),
    j, caption = "Table 1. Test"
  )
  expect_identical(nrow(mc_found(j)), 0L)
})

# A three-column table from rows of hand-written XML. `header` is NULL
# for no flag, "" for a bare flag, or an attribute such as
# ' w:val="false"'; `span` merges the first two cells.
mc_tr <- function(header = NULL, span = FALSE) {
  pr <- if (!is.null(header)) {
    paste0("<w:trPr><w:tblHeader", header, "/></w:trPr>")
  } else {
    ""
  }
  cells <- if (span) {
    paste0("<w:tc><w:tcPr><w:gridSpan w:val=\"2\"/></w:tcPr><w:p/></w:tc>",
           "<w:tc><w:p/></w:tc>")
  } else {
    strrep("<w:tc><w:p/></w:tc>", 3)
  }
  paste0("<w:tr>", pr, cells, "</w:tr>")
}
mc_doc <- function(...) {
  wt_doc(paste0("<w:tbl><w:tblGrid>", strrep("<w:gridCol/>", 3),
                "</w:tblGrid>", ..., "</w:tbl>"))
}

test_that("only Word's own header rows may merge", {
  # A leading run of flags that are on: exempt.
  ok <- mc_doc(mc_tr("", span = TRUE), mc_tr(" w:val=\"1\"", span = TRUE),
               mc_tr())
  expect_identical(nrow(.detect_merged_cell(ok)), 0L)
  # A flag switched off is no header.
  off <- mc_doc(mc_tr(" w:val=\"false\"", span = TRUE), mc_tr())
  expect_identical(.detect_merged_cell(off)$location, "row 1")
  # A flag after a body row is ignored by Word, so the row is a body row.
  late <- mc_doc(mc_tr(""), mc_tr(), mc_tr("", span = TRUE))
  expect_identical(.detect_merged_cell(late)$location, "row 3")
})

# A row of hand-written cells carrying the legacy w:hMerge. Each element
# of `h` is one cell: NA for no hMerge, "" for a valueless one, else its
# w:val.
mc_tr_h <- function(h, header = FALSE) {
  pr <- if (header) "<w:trPr><w:tblHeader/></w:trPr>" else ""
  cells <- vapply(h, function(v) {
    m <- if (is.na(v)) {
      ""
    } else if (nzchar(v)) {
      paste0("<w:hMerge w:val=\"", v, "\"/>")
    } else {
      "<w:hMerge/>"
    }
    paste0("<w:tc><w:tcPr>", m, "</w:tcPr><w:p/></w:tc>")
  }, character(1))
  paste0("<w:tr>", pr, paste(cells, collapse = ""), "</w:tr>")
}

test_that("legacy w:hMerge groups count as merged cells", {
  part <- mc_doc(mc_tr(), mc_tr_h(c("restart", "continue", NA)))
  expect_identical(.detect_merged_cell(part)$location, "row 2")
  # A valueless hMerge continues the group, too.
  expect_identical(
    .detect_merged_cell(mc_doc(mc_tr_h(c("restart", "", NA))))$location,
    "row 1"
  )
  full <- mc_doc(mc_tr(), mc_tr_h(c("restart", "continue", "")))
  expect_identical(nrow(.detect_merged_cell(full)), 0L)
  expect_identical(.detect_merged_cell(full, strict = TRUE)$location,
                   "row 2")
  hdr <- mc_doc(mc_tr_h(c("restart", "continue", NA), header = TRUE),
                mc_tr())
  expect_identical(nrow(.detect_merged_cell(hdr)), 0L)
})
