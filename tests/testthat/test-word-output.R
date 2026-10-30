# The written .docx, read back as Word XML. Each test pins one point
# from the 2026-10-14 review of two commented example tables: what the
# reader sees in Word, not what the flextable object holds.

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

wx_save_describe <- function(tbl = wx_tbl(), ...) {
  ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 1. Test", ...)
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
    "† No. (%) or Median [15th, 85th percentiles]." %in% notes
  )
})

test_that("CORR: no % sign in any body cell", {
  f <- wx_save_corr()
  on.exit(unlink(f), add = TRUE)
  body <- unlist(lapply(wx_rows(wx_doc(f))[-1], cell_text))
  expect_true(any(grepl("^[0-9]+\\([0-9.]+\\)$", body)))
  expect_false(any(grepl("%", body, fixed = TRUE)))
})

test_that("CORR: gtsummary's own footnotes never reach the table", {
  # add_p() footnotes the test names on the p-value header, and
  # add_difference() footnotes the SMD and defines CI; as_flex_table()
  # writes all of them as rows and superscripts inside the w:tbl. House
  # rule 13 puts notes below the table, as paragraphs.
  for (cmp in c("pvalue", "smd", "both")) {
    tbl <- hv_tbl_summary(
      gtsummary::trial, by = "trt",
      groups = list(Demography = c("age", "marker"),
                    Disease = c("stage", "response")),
      continuous = c("age", "marker"), binary = "response",
      categorical = "stage", compare = cmp
    )
    f <- wx_save_corr(tbl)
    doc <- wx_doc(f)
    rows <- wx_rows(doc)
    last <- cell_text(rows[[length(rows)]])
    expect_identical(last[1], "Tumor Response", info = cmp)
    expect_true(any(nzchar(last[-1])), info = cmp)
    sup <- unlist(lapply(rows, function(r) vapply(r, `[[`, "", "sup")))
    expect_false(any(grepl("[0-9]", sup)), info = cmp)
    expect_false(
      grepl("Wilcoxon|Abbreviation", wx_text(xml2::xml_find_first(
        doc, "//w:tbl", wx_ns
      ))),
      info = cmp
    )
    expect_identical(nrow(hv_check_docx(f)), 0L, info = cmp)

    # What gtsummary said inside the table is said below it instead: the
    # tests in the dagger note, with the dagger on the p-value header; CI
    # in the key.
    header <- rows[[1]]
    head_text <- cell_text(header)
    head_sup <- vapply(header, `[[`, "", "sup")
    notes <- wx_paragraphs_after_table(doc)
    dagger <- grep("^†", notes, value = TRUE)
    stat_note <- "† No. (%) or Median [15th, 85th percentiles]"
    tests <- paste0("P values from the Wilcoxon rank sum test and ",
                    "Pearson's chi-square test")
    smd <- paste0("Std. Diff. is the standardized mean difference, ",
                  "with its 95% CI.")
    expected <- switch(
      cmp,
      pvalue = paste0(stat_note, "; ", tests, "."),
      smd = paste0(stat_note, "; ", smd),
      both = paste0(stat_note, "; ", tests, "; ", smd)
    )
    expect_identical(dagger, expected, info = cmp)
    # The dagger sits on each header the note explains. gtsummary's
    # "Difference" is replaced by the name the other renderers use.
    expect_false("Difference" %in% sub("[†*]+$", "", head_text), info = cmp)
    marked <- function(prefix) {
      head_sup[startsWith(head_text, prefix)]
    }
    if (cmp == "pvalue") {
      expect_identical(marked("p-value"), "†", info = cmp)
    } else {
      expect_identical(marked("Std. Diff."), "†", info = cmp)
      expect_identical(marked("95% CI"), "", info = cmp)
      expect_identical(marked("p-value"),
                       if (cmp == "both") "†" else character(0), info = cmp)
    }
    key <- grep("^Key:", notes, value = TRUE)
    if (cmp == "pvalue") {
      expect_length(key, 0L)
    } else {
      expect_identical(key, "Key: CI, confidence interval", info = cmp)
    }
    unlink(f)
  }
})

# -- The manuscript's describe layout (the JTCVS renderer's, renamed) ---

test_that("describe: Characteristic appears once, spanning both header rows", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  all_cells <- unlist(lapply(wx_rows(doc), cell_text))
  expect_identical(sum(all_cells == "Characteristic"), 1L)
  vmerge <- xml2::xml_find_all(
    doc, "//w:tbl//w:tr[position() <= 2]/w:tc[1]//w:vMerge", wx_ns
  )
  expect_length(vmerge, 2L)
})

test_that("describe: every n carries the count's mark, noted below", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  sub <- wx_rows(doc)[[2]]
  n_cells <- Filter(function(cell) cell$text == "n*", sub)
  # Overall and two groups, three n columns; the mark is a superscript.
  expect_length(n_cells, 3L)
  expect_true(all(vapply(n_cells, `[[`, "", "sup") == "*"))
  notes <- wx_paragraphs_after_table(doc)
  expect_identical(notes[1],
                   paste0("*", hv_table_style("manuscript")$count_note))
})

test_that("describe: the statistic label follows the table's statistic", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  sub <- cell_text(wx_rows(wx_doc(f))[[2]])
  expect_true(
    "No. (%) or Median [15th, 85th percentiles]\u2020" %in% sub
  )
  expect_false(any(grepl("Mean", sub, fixed = TRUE)))

  f2 <- wx_save_describe(wx_tbl("mean"))
  on.exit(unlink(f2), add = TRUE)
  sub2 <- cell_text(wx_rows(wx_doc(f2))[[2]])
  expect_true("No. (%) or Mean\u00B1SD\u2020" %in% sub2)
})

test_that("describe: under continuous_stat = 'both', stats sit side by side", {
  f <- wx_save_describe(wx_tbl("both"))
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  labels <- vapply(rows, function(r) r[[1]]$text, "")
  age <- which(labels == "Age")
  # No sub-rows under the variable.
  expect_false(labels[age + 1] %in% c("Mean\u00B1SD",
                                      "Median [15th, 85th percentiles]"))
  sub <- cell_text(rows[[2]])
  expect_true("No. (%) or Mean\u00B1SD\u2020" %in% sub)
  expect_true("Median [15th, 85th percentiles]" %in% sub)
})

test_that("describe: only the section rows are shaded", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  ms <- hv_table_style("manuscript")
  for (r in wx_rows(wx_doc(f))) {
    fills <- vapply(r, `[[`, "", "fill")
    fills <- toupper(fills[!is.na(fills)])
    if (cell_text(r)[1] %in% c("Demography", "Disease")) {
      expect_identical(fills, toupper(sub("^#", "", ms$fill)))
    } else {
      expect_true(all(fills %in% c("FFFFFF", "AUTO")))
    }
  }
})

test_that("describe: no % sign in any body cell, label column left", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  body <- unlist(lapply(rows[-(1:2)], cell_text))
  expect_true(any(grepl("^[0-9]+\\([0-9.]+\\)$", body)))
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

test_that("both renderers mark the minority statistic's cells in Word", {
  # Age is the one mean row against one median row, so the median is the
  # default and the mean cells carry the mark: a pilcrow in both the report
  # and the manuscript's describe layout.
  f <- wx_save_corr(wx_mixed())
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  rows <- wx_rows(doc)
  labels <- vapply(rows, function(r) r[[1]]$text, "")
  expect_true("Age" %in% labels)
  expect_true("Marker Level (ng/mL)" %in% labels)
  expect_false(any(grepl("Mean±SD$|Median \\[", labels)))
  age <- cell_text(rows[[which(labels == "Age")]])
  expect_true(all(grepl("¶$", age[c(3, 5, 7)])))
  marker <- cell_text(rows[[which(labels == "Marker Level (ng/mL)")]])
  expect_false(any(grepl("¶", marker, fixed = TRUE)))
  notes <- wx_paragraphs_after_table(doc)
  expect_true("† No. (%) or Median [15th, 85th percentiles]." %in% notes)
  expect_true("¶ Mean±SD." %in% notes)

  f2 <- wx_save_describe(wx_mixed())
  on.exit(unlink(f2), add = TRUE)
  doc2 <- wx_doc(f2)
  rows2 <- wx_rows(doc2)
  labels2 <- vapply(rows2, function(r) r[[1]]$text, "")
  expect_true("Age" %in% labels2)
  expect_true("No. (%) or Median [15th, 85th percentiles]\u2020" %in%
                cell_text(rows2[[2]]))
  age2 <- cell_text(rows2[[which(labels2 == "Age")]])
  expect_true(all(grepl("\u00B6$", age2[c(3, 5, 7)])))
  expect_true("\u00B6Mean\u00B1SD." %in% wx_paragraphs_after_table(doc2))
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
  # wide, past a portrait page's 6.53, so it now turns, as it should.
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

test_that("describe: caption, notes and Key set no font of their own", {
  # The manuscript style takes the document's font, below the table too.
  f <- wx_save_describe(abbreviations = c(SMD = "standardized difference"))
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  runs <- xml2::xml_find_all(doc, "//w:tbl/following-sibling::w:p/w:r", wx_ns)
  expect_gt(length(runs), 3L)
  expect_length(
    xml2::xml_find_all(doc, "//w:body/w:p//w:rFonts[@w:ascii]", wx_ns), 0L
  )
})
