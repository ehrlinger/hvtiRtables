# The written .docx, read back as Word XML. Each test pins one point
# from the 2026-10-14 review of two commented example tables: what the
# reader sees in Word, not what the flextable object holds.

wx_ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")

wx_doc <- function(path) {
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = xdir)
  xml2::read_xml(file.path(xdir, "word", "document.xml"))
}

wx_text <- function(node) {
  paste(xml2::xml_text(xml2::xml_find_all(node, ".//w:t", wx_ns)),
        collapse = "")
}

# One list per table row, one element per cell: its text, its
# superscript text, its paragraph justification and its fill.
wx_rows <- function(doc) {
  trs <- xml2::xml_find_all(doc, "//w:tbl//w:tr", wx_ns)
  lapply(trs, function(tr) {
    lapply(xml2::xml_find_all(tr, "./w:tc", wx_ns), function(tc) {
      sup <- xml2::xml_find_all(
        tc, ".//w:r[w:rPr/w:vertAlign[@w:val='superscript']]/w:t", wx_ns
      )
      jc <- xml2::xml_attr(xml2::xml_find_first(tc, ".//w:jc", wx_ns), "val")
      fill <- xml2::xml_attr(xml2::xml_find_first(tc, ".//w:shd", wx_ns),
                             "fill")
      list(text = wx_text(tc), sup = paste(xml2::xml_text(sup), collapse = ""),
           jc = jc, fill = fill)
    })
  })
}

wx_paragraphs_after_table <- function(doc) {
  ps <- xml2::xml_find_all(doc, "//w:tbl/following-sibling::w:p", wx_ns)
  vapply(ps, wx_text, character(1))
}

wx_tbl <- function(continuous_stat = "median") {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "marker"),
                  Disease = c("stage", "response")),
    continuous = c("age", "marker"), binary = "response",
    categorical = "stage", compare = "none",
    continuous_stat = continuous_stat
  )
}

wx_save_corr <- function(tbl = wx_tbl()) {
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), f)
  f
}

wx_save_jtcvs <- function(tbl = wx_tbl(), footnotes = NULL) {
  ft <- hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "Drug A", stat_2 = "Drug B")
  )
  f <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(ft, f, caption = "Table 1. Test",
                          footnotes = footnotes)
  f
}

cell_text <- function(row) vapply(row, `[[`, "", "text")

# -- CORR house renderer -----------------------------------------------

test_that("CORR: no groupname_col column; sections are label-column rows", {
  f <- wx_save_corr()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  expect_false(grepl("groupname_col", wx_text(doc), fixed = TRUE))

  rows <- wx_rows(doc)
  expect_identical(cell_text(rows[[1]])[1], "Characteristic")
  for (sec in c("Demography", "Disease")) {
    hit <- Filter(function(r) cell_text(r)[1] == sec, rows)
    expect_length(hit, 1L)
    # The section name and nothing else on its row, in its own cells.
    expect_true(all(cell_text(hit[[1]])[-1] == ""), info = sec)
    expect_length(hit[[1]], length(rows[[1]]))
  }
  # Each section row sits immediately above its first variable.
  first <- vapply(rows, function(r) cell_text(r)[1], "")
  expect_identical(first[which(first == "Demography") + 1L], "Age")
  expect_identical(first[which(first == "Disease") + 1L], "T Stage")
})

test_that("CORR: the label column is left-justified in every row", {
  f <- wx_save_corr()
  on.exit(unlink(f), add = TRUE)
  jc <- vapply(wx_rows(wx_doc(f)), function(r) r[[1]]$jc, "")
  expect_true(all(jc %in% c("left", "start")))
})

test_that("CORR: the dagger marks the statistic columns, not the No. column", {
  f <- wx_save_corr()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  header <- wx_rows(doc)[[1]]
  is_no <- startsWith(cell_text(header), "No.")
  is_stat <- grepl("N = ", cell_text(header), fixed = TRUE)
  expect_true(any(is_stat))
  sup <- vapply(header, `[[`, "", "sup")
  expect_true(all(grepl("†", sup[is_stat], fixed = TRUE)))
  expect_false(any(grepl("†", sup[is_no], fixed = TRUE)))
  # `*` is the non-missing count, so it stays on the first No. column.
  expect_identical(sup[which(is_no)[1]], "*")

  notes <- wx_paragraphs_after_table(doc)
  expect_true(
    "† No. (%) or Median (15th, 85th percentile)." %in% notes
  )
})

test_that("CORR: no % sign in any body cell", {
  f <- wx_save_corr()
  on.exit(unlink(f), add = TRUE)
  body <- unlist(lapply(wx_rows(wx_doc(f))[-1], cell_text))
  expect_true(any(grepl("^[0-9]+ \\([0-9.]+\\)$", body)))
  expect_false(any(grepl("%", body, fixed = TRUE)))
})

# -- JTCVS renderer ----------------------------------------------------

test_that("JTCVS: Characteristic appears once, spanning both header rows", {
  f <- wx_save_jtcvs()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  all_cells <- unlist(lapply(wx_rows(doc), cell_text))
  expect_identical(sum(all_cells == "Characteristic"), 1L)
  vmerge <- xml2::xml_find_all(
    doc, "//w:tbl//w:tr[position() <= 2]/w:tc[1]//w:vMerge", wx_ns
  )
  expect_length(vmerge, 2L)
})

test_that("JTCVS: n carries a real superscript a, footnoted below", {
  f <- wx_save_jtcvs()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  sub <- wx_rows(doc)[[2]]
  n_cells <- Filter(function(cell) cell$text == "na", sub)
  # Two groups, two n columns; the "a" is a superscript run, not text.
  expect_length(n_cells, 2L)
  expect_true(all(vapply(n_cells, `[[`, "", "sup") == "a"))

  notes <- wx_paragraphs_after_table(doc)
  expect_identical(notes[1], "a. Patients with data available.")
})

test_that("JTCVS: caller footnotes letter from b after the n footnote", {
  f <- wx_save_jtcvs(footnotes = list(
    list(row = 2, col = "disp_stat_1", text = "Own note.")
  ))
  on.exit(unlink(f), add = TRUE)
  notes <- wx_paragraphs_after_table(wx_doc(f))
  expect_identical(notes[1:2],
                   c("a. Patients with data available.", "b. Own note."))
})

test_that("JTCVS: the statistic label follows the table's statistic", {
  f <- wx_save_jtcvs()
  on.exit(unlink(f), add = TRUE)
  sub <- cell_text(wx_rows(wx_doc(f))[[2]])
  expect_true(
    "No. (%) or Median (15th, 85th percentile)" %in% sub
  )
  expect_false(any(grepl("Mean", sub, fixed = TRUE)))

  f2 <- wx_save_jtcvs(wx_tbl("mean"))
  on.exit(unlink(f2), add = TRUE)
  sub2 <- cell_text(wx_rows(wx_doc(f2))[[2]])
  expect_true("No. (%) or Mean±SD" %in% sub2)
})

test_that("JTCVS: under continuous_stat = 'both', the stats sit side by side", {
  f <- wx_save_jtcvs(wx_tbl("both"))
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  labels <- vapply(rows, function(r) r[[1]]$text, "")
  age <- which(labels == "Age")
  # No sub-rows under the variable.
  expect_false(labels[age + 1] %in% c("Mean±SD",
                                      "Median (15th, 85th percentile)"))
  sub <- cell_text(rows[[2]])
  expect_true("No. (%) or Mean±SD" %in% sub)
  expect_true("Median (15th, 85th percentile)" %in% sub)
})

test_that("JTCVS: no fill colour anywhere in the table", {
  f <- wx_save_jtcvs()
  on.exit(unlink(f), add = TRUE)
  fills <- unlist(lapply(wx_rows(wx_doc(f)),
                         function(r) vapply(r, `[[`, "", "fill")))
  fills <- fills[!is.na(fills)]
  expect_true(all(toupper(fills) %in% c("FFFFFF", "AUTO")))
})

test_that("JTCVS: no % sign in any body cell, label column left", {
  f <- wx_save_jtcvs()
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  body <- unlist(lapply(rows[-(1:2)], cell_text))
  expect_true(any(grepl("^[0-9]+ \\([0-9.]+\\)$", body)))
  expect_false(any(grepl("%", body, fixed = TRUE)))
  jc <- vapply(rows, function(r) r[[1]]$jc, "")
  expect_true(all(jc %in% c("left", "start")))
})

# -- Mixed statistics and page orientation ------------------------------

wx_mixed <- function(overall = TRUE) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "marker")),
    continuous = c("age", "marker"), normal = "age",
    compare = "none", overall = overall
  )
}

test_that("both renderers print each mixed row's statistic in Word", {
  f <- wx_save_corr(wx_mixed())
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  labels <- vapply(wx_rows(doc), function(r) r[[1]]$text, "")
  expect_true("Age, Mean±SD" %in% labels)
  expect_true(
    "Marker Level (ng/mL), Median (15th, 85th percentile)" %in% labels
  )
  expect_true("† No. (%) or as labeled." %in%
                wx_paragraphs_after_table(doc))

  f2 <- wx_save_jtcvs(wx_mixed())
  on.exit(unlink(f2), add = TRUE)
  rows <- wx_rows(wx_doc(f2))
  expect_true("No. (%) or as labeled" %in%
                cell_text(rows[[2]]))
  expect_true("Age, Mean±SD" %in%
                vapply(rows, function(r) r[[1]]$text, ""))
})

# One orient value per section; a single section is expected.
wx_orient <- function(f) {
  sz <- xml2::xml_find_all(wx_doc(f), "//w:sectPr/w:pgSz", wx_ns)
  xml2::xml_attr(sz, "orient")
}

test_that("CORR: Overall plus two groups goes on a landscape page", {
  f <- wx_save_corr(wx_mixed(overall = TRUE))
  on.exit(unlink(f), add = TRUE)
  expect_identical(wx_orient(f), "landscape")
})

test_that("CORR: a two-group table that fits stays on a portrait page", {
  # Not wx_mixed(overall = FALSE): its suffixed row labels make it 8.6 in
  # wide, past a portrait page's 6.3, so it now turns, as it should.
  narrow <- hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(Demography = "age"),
    continuous = "age", compare = "none", overall = FALSE,
    show_variable = FALSE
  )
  f <- wx_save_corr(narrow)
  on.exit(unlink(f), add = TRUE)
  orient <- wx_orient(f)
  expect_length(orient, 1L)
  expect_true(orient %in% c(NA, "portrait"))
})

# -- Text below the table ------------------------------------------------

# The font of every run with text in the paragraphs after the table (and,
# for JTCVS, the caption before it): all four slots must agree, since
# Word picks among them per character.
wx_note_fonts <- function(doc, xpath) {
  runs <- xml2::xml_find_all(doc, paste0(xpath, "/w:r"), wx_ns)
  rf <- xml2::xml_find_first(runs, "./w:rPr/w:rFonts", wx_ns)
  fonts <- vapply(c("ascii", "hAnsi", "cs", "eastAsia"),
                  function(a) xml2::xml_attr(rf, a), character(length(runs)))
  fonts <- matrix(fonts, nrow = length(runs))
  agree <- apply(fonts, 1, function(r) length(unique(r)) == 1L)
  ifelse(agree, fonts[, 1], "mismatch")[nzchar(vapply(runs, wx_text, ""))]
}

test_that("CORR: footnotes and Key use the table's font", {
  for (font in c("Times New Roman", "Arial")) {
    f <- tempfile(fileext = ".docx")
    hv_man_table_save(hv_man_table(wx_tbl(), font = font), f,
                      abbreviations = c(SMD = "standardized difference"))
    fonts <- wx_note_fonts(wx_doc(f), "//w:tbl/following-sibling::w:p")
    unlink(f)
    expect_gt(length(fonts), 3L)
    expect_true(all(fonts == font), info = font)
  }
})

test_that("JTCVS: caption, footnotes and Key use the table's font", {
  ft <- hv_man_table_jtcvs(wx_tbl(),
                           groups = c(stat_1 = "Drug A", stat_2 = "Drug B"))
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Test",
    footnotes = list(list(row = 2, col = "disp_stat_1", text = "Own note.")),
    abbreviations = c(SMD = "standardized difference")
  )
  doc <- wx_doc(f)
  after <- wx_note_fonts(doc, "//w:tbl/following-sibling::w:p")
  caption <- wx_note_fonts(doc, "//w:body/w:p[1]")
  expect_gt(length(after), 3L)
  expect_true(all(c(after, caption) == "Times New Roman"))
})
