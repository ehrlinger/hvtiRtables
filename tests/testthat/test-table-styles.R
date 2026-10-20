test_that("each style holds the matrix's properties", {
  r <- hv_table_style("report")
  m <- hv_table_style("manuscript")
  expect_s3_class(r, "hv_table_style")
  expect_identical(
    r[c("section", "borders", "header", "count", "marker", "count_note",
        "stat_lead", "font", "font_size", "caption", "header_bold",
        "keep_rows", "repeat_header", "page", "variable", "merged")],
    list(section = "label", borders = "rules", header = "flat",
         count = "per_group", marker = "superscript",
         count_note = "Number of non-missing values.", stat_lead = "",
         font = "Times New Roman", font_size = 12, caption = "optional",
         header_bold = TRUE, keep_rows = FALSE, repeat_header = TRUE,
         page = "letter", variable = TRUE, merged = "none")
  )
  expect_null(r$row_height)
  expect_identical(
    m[c("section", "borders", "header", "count", "marker", "count_note",
        "stat_lead", "font", "font_size", "caption", "header_bold",
        "row_height", "keep_rows", "repeat_header", "page", "variable",
        "merged")],
    list(section = "spanned", borders = "grid", header = "spanned",
         count = "overall", marker = "leading",
         count_note = "Patients with non-missing data.",
         stat_lead = "Values are ", font = NA_character_,
         font_size = NA_real_, caption = "required", header_bold = TRUE,
         row_height = 300, keep_rows = TRUE, repeat_header = TRUE,
         page = "letter", variable = FALSE,
         merged = "header and section rows")
  )
  expect_identical(c(r$fill, m$fill), c("#CAEDFB", "#CAEDFB"))
})

test_that("the fill is a property a journal can change", {
  expect_identical(hv_table_style("manuscript", fill = "#A5C9EB")$fill,
                   "#A5C9EB")
  expect_error(hv_table_style("manuscript", fill = "blue"), "#RRGGBB")
  expect_error(hv_table_style("manuscript", fill = c("#A5C9EB", "#CAEDFB")),
               "#RRGGBB")
  expect_error(hv_table_style("jtcvs"), "should be one of")
})

test_that("a style is given by name or as an object", {
  expect_identical(.as_style("manuscript"), hv_table_style("manuscript"))
  s <- hv_table_style("report", fill = "#A5C9EB")
  expect_identical(.as_style(s), s)
  expect_error(.as_style("corr"), "hv_table_style")
  expect_error(.as_style(NA_character_), "hv_table_style")
})

st_tbl <- function(by = "trt") {
  hv_tbl_summary(
    gtsummary::trial, by = by,
    groups = list(Demography = c("age", "marker"),
                  Disease = c("stage", "grade")),
    continuous = c("age", "marker"), categorical = c("stage", "grade")
  )
}
st_save <- function(name, fill = "#CAEDFB", tbl = st_tbl()) {
  ft <- hv_man_table(tbl, style = hv_table_style(name, fill = fill))
  f <- tempfile(fileext = ".docx")
  caption <- if (name == "manuscript") "Table 1. Baseline characteristics"
  hv_man_table_save(ft, f, caption = caption)
  f
}
xq <- function(x, path) xml2::xml_find_all(x, path, wx_ns)
ncols <- function(x) length(xq(x, "//w:tblGrid/w:gridCol"))
sec_row <- function(x) {
  xml2::xml_find_first(x, "//w:tr[normalize-space(.)='Demography']", wx_ns)
}

test_that("rows 1-2: shaded section rows, unmerged or spanned", {
  r <- wx_doc(st_save("report"))
  tcs <- xq(sec_row(r), "./w:tc")
  expect_length(tcs, ncols(r))
  fills <- xml2::xml_attr(xml2::xml_find_first(tcs, ".//w:shd", wx_ns), "fill")
  expect_true(all(fills == "CAEDFB"))
  m <- wx_doc(st_save("manuscript", fill = "#A5C9EB"))
  tc <- xq(sec_row(m), "./w:tc")
  expect_length(tc, 1L)
  expect_identical(xml2::xml_attr(xq(tc, ".//w:gridSpan"), "val"),
                   as.character(ncols(m)))
  expect_identical(xml2::xml_attr(xq(tc, ".//w:shd"), "fill"), "A5C9EB")
})

test_that("row 3: rules in the report, a full grid in the manuscript", {
  r <- wx_doc(st_save("report"))
  expect_length(xq(r, "//w:tcBorders/w:left[@w:val='single']"), 0L)
  rules <- xq(r, paste0("//w:tcBorders/w:top[@w:val='single'] | ",
                        "//w:tcBorders/w:bottom[@w:val='single']"))
  expect_gt(length(rules), 0L) # the report carries its horizontal rules
  m <- wx_doc(st_save("manuscript"))
  n_tc <- length(xq(m, "//w:tc"))
  for (side in c("top", "bottom", "left", "right")) {
    path <- sprintf("//w:tcBorders/w:%s[@w:val='single' and @w:sz='4']", side)
    expect_length(xq(m, path), n_tc)
  }
})

test_that("rows 4-5: the header and the count column", {
  r <- wx_doc(st_save("report"))
  expect_length(xq(r, "//w:tr[w:trPr/w:tblHeader]"), 1L)
  r_head <- vapply(xq(r, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(sum(startsWith(r_head, "No.")), 3L) # Overall + 2 groups
  m <- wx_doc(st_save("manuscript"))
  expect_length(xq(m, "//w:tr[w:trPr/w:tblHeader]"), 2L)
  m_head <- vapply(xq(m, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(sum(m_head == "n*"), 1L)
  grouping <- xq(m, "//w:tr[1]/w:tc[.//w:gridSpan[@w:val='2']]")
  expect_identical(wx_text(grouping[[1]]), "Chemotherapy Treatment\u2020")
  expect_length(xq(m, "//w:tr[1]/w:tc[1]//w:vMerge[@w:val='restart']"), 1L)
})

test_that("rows 8-10: note markers and wording", {
  after <- function(x) {
    vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text, character(1))
  }
  r <- wx_doc(st_save("report"))
  expect_identical(after(r)[1], "* Number of non-missing values.")
  first <- xq(r, "//w:tbl/following-sibling::w:p[1]/w:r[1]")
  expect_length(xq(first[[1]], ".//w:vertAlign[@w:val='superscript']"), 1L)
  m <- wx_doc(st_save("manuscript"))
  expect_identical(after(m)[1:2], c(
    "*Patients with non-missing data.",
    paste0("\u2020Values are No. (%) or median [15th, 85th percentiles]; ",
           "P values from the Wilcoxon rank sum test and Pearson's ",
           "chi-square test.")
  ))
})

test_that("rows 12-13: the font and the caption", {
  r <- wx_doc(st_save("report"))
  expect_gt(length(xq(r, "//w:tbl//w:rFonts[@w:ascii='Times New Roman']")),
            0L)
  expect_identical(xml2::xml_name(xq(r, "//w:body/*[1]")[[1]]), "tbl")
  m <- wx_doc(st_save("manuscript"))
  expect_length(xq(m, "//w:tbl//w:rFonts[@w:ascii]"), 0L)
  expect_length(xq(m, "//w:tbl//w:sz"), 0L)
  cap <- xq(m, "//w:body/*[1]")[[1]]
  expect_identical(wx_text(cap), "Table 1. Baseline characteristics")
})

test_that("rows 14-16: weight, row height, rows kept whole, header repeated", {
  # Every header text run is bold in both styles, the "N = n" lines and
  # the marks the saver appends included (design row 14, "header bold").
  for (name in c("report", "manuscript")) {
    x <- wx_doc(st_save(name))
    head_runs <- xq(x, "//w:tr[w:trPr/w:tblHeader]//w:r[w:t]/w:rPr")
    bold <- xq(x, paste0("//w:tr[w:trPr/w:tblHeader]//w:r[w:t]/w:rPr/",
                         "w:b[not(@w:val='false')]"))
    expect_gt(length(head_runs), 0L)
    expect_length(bold, length(head_runs)) # every header run is bold
  }
  m <- wx_doc(st_save("manuscript"))
  n_tr <- length(xq(m, "//w:tr"))
  expect_length(xq(m, "//w:trHeight[@w:val='300' and @w:hRule='atLeast']"),
                n_tr)
  expect_length(xq(m, "//w:trPr/w:cantSplit"), n_tr)
  r <- wx_doc(st_save("report"))
  expect_length(xq(r, "//w:trPr/w:cantSplit"), 0L)
})

test_that("row 14: labels are left-justified and statistics centered", {
  for (name in c("report", "manuscript")) {
    rows <- wx_rows(wx_doc(st_save(name)))
    # Rows that carry a statistic, past the header: the section rows and
    # the footer line gtsummary adds to a report table hold none.
    body <- Filter(function(r) {
      any(nzchar(vapply(r[-1], function(cell) cell$text, character(1))))
    }, rows[-seq_len(if (name == "manuscript") 2L else 1L)])
    expect_gt(length(body), 0L)
    label <- vapply(body, function(r) r[[1]]$jc, character(1))
    expect_true(all(label == "left"), info = name)
    stats <- unlist(lapply(body, function(r) {
      vapply(r[-1], function(cell) cell$jc, character(1))
    }))
    expect_true(all(stats == "center"), info = name)
  }
})

test_that("the manuscript's default Table 1 is on a portrait Letter page", {
  # Overall, two groups and P: 2.0 + 0.6 + 1.1 * 3 + 0.6 = 6.5 inches,
  # inside Letter's 6.53-inch text block. At a 2.5-inch label it turned
  # landscape.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "marker"),
                  Disease = c("stage", "grade")),
    continuous = c("age", "marker"), categorical = c("stage", "grade"),
    overall = TRUE, compare = "pvalue"
  )
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(
    hv_man_table(tbl, style = "manuscript"), f,
    caption = "Table 1. Baseline characteristics"
  )
  expect_identical(pg_size(f), c(w = "12240", h = "15840"))
})

test_that("rows 17-19: Letter, no Variable column, merges where allowed", {
  for (name in c("report", "manuscript")) {
    x <- wx_doc(st_save(name))
    sz <- xq(x, "//w:sectPr/w:pgSz")[[1]]
    expect_setequal(
      c(xml2::xml_attr(sz, "w"), xml2::xml_attr(sz, "h")),
      c("12240", "15840")
    )
    cells <- vapply(xq(x, "//w:tc"), wx_text, character(1))
    expect_false("Variable" %in% cells, info = name)
  }
  r <- wx_doc(st_save("report"))
  expect_length(xq(r, "//w:gridSpan | //w:vMerge"), 0L)
  m <- wx_doc(st_save("manuscript"))
  merged_rows <- xq(m, "//w:tr[.//w:gridSpan or .//w:vMerge]")
  ok <- vapply(merged_rows, function(tr) {
    length(xq(tr, "./w:trPr/w:tblHeader")) > 0L ||
      trimws(wx_text(tr)) %in% c("Demography", "Disease")
  }, logical(1))
  expect_true(all(ok))
})

test_that("hv_check_docx() passes on every style, checked as that style", {
  for (name in c("report", "manuscript"))
    expect_identical(nrow(hv_check_docx(st_save(name), style = name)), 0L,
                     info = name)
})

test_that("replicas of the two submissions' Table 1 shapes", {
  # ms.1264: two groups, fill #CAEDFB. BVR rv3: three clusters, #A5C9EB.
  for (case in list(list(by = "trt", fill = "#CAEDFB", span = "2"),
                    list(by = "grade", fill = "#A5C9EB", span = "3"))) {
    tbl <- hv_tbl_summary(
      gtsummary::trial, by = case$by,
      groups = list(Demography = c("age", "marker"), Disease = "stage"),
      continuous = c("age", "marker"), categorical = "stage",
      overall = FALSE, show_variable = FALSE
    )
    x <- wx_doc(st_save("manuscript", fill = case$fill, tbl = tbl))
    expect_length(xq(x, sprintf("//w:tr[1]/w:tc[.//w:gridSpan[@w:val='%s']]",
                                case$span)), 1L)
    body_spans <- paste0("//w:tr[not(w:trPr/w:tblHeader)]",
                         "/w:tc[.//w:gridSpan]//w:shd")
    expect_identical(unique(xml2::xml_attr(xq(x, body_spans), "fill")),
                     sub("#", "", case$fill))
    cells <- vapply(xq(x, "//w:tr[not(w:trPr/w:tblHeader)]/w:tc"), wx_text,
                    character(1))
    expect_true(any(grepl("^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$", cells)))
    expect_true(any(grepl("^[0-9]+ \\([0-9.]+\\)$", cells)))
    expect_false(any(grepl("[0-9]\\[", cells))) # a space before brackets
    head <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
    expect_true(all(grepl("\\(N = [0-9]+\\)$", head[nzchar(head)])))
    notes <- vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text,
                    character(1))
    expect_true(any(grepl("15th, 85th percentiles", notes, fixed = TRUE)))
  }
})

test_that("the manuscript names the tests in its dagger note and marks P", {
  skip_if_not_installed("broom")
  after <- function(x) {
    vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text, character(1))
  }
  for (cmp in c("pvalue", "both", "smd")) {
    f <- st_save("manuscript", tbl = hv_tbl_summary(
      gtsummary::trial, by = "trt",
      groups = list(Demography = c("age", "marker"),
                    Disease = c("stage", "grade")),
      continuous = c("age", "marker"), categorical = c("stage", "grade"),
      compare = cmp
    ))
    m <- wx_doc(f)
    rows <- wx_rows(m)
    p_head <- rows[[1]][[length(rows[[1]])]]
    note <- after(m)[2]
    if (cmp == "smd") {
      expect_identical(
        note,
        paste0("\u2020Values are No. (%) or median [15th, 85th ",
               "percentiles]; Std. Diff. is the standardized mean ",
               "difference."),
        info = cmp
      )
      expect_identical(p_head$sup, "\u2020", info = cmp)
    } else if (cmp == "both") {
      expect_identical(
        note,
        paste0("\u2020Values are No. (%) or median [15th, 85th ",
               "percentiles]; P values from the Wilcoxon rank sum test ",
               "and Pearson's chi-square test; SMD is the standardized ",
               "mean difference."),
        info = cmp
      )
      expect_identical(p_head$sup, "\u2020", info = cmp)
    } else {
      expect_identical(
        note,
        paste0("†Values are No. (%) or median [15th, 85th ",
               "percentiles]; P values from the Wilcoxon rank sum test and ",
               "Pearson's chi-square test."),
        info = cmp
      )
      expect_identical(p_head$sup, "†", info = cmp)
    }
    # gtsummary's own footnotes never reach the manuscript table either.
    expect_false(grepl("Wilcoxon", wx_text(xq(m, "//w:tbl")[[1]]),
                       fixed = TRUE), info = cmp)
    expect_identical(nrow(hv_check_docx(f, style = "manuscript")), 0L,
                     info = cmp)
  }
})

# -- the manuscript's describe layout, saved ------------------------------

dsc_save <- function(tbl = st_tbl(), fill = "#CAEDFB") {
  ft <- hv_man_table(tbl, style = hv_table_style("manuscript", fill = fill),
                     layout = "describe")
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 2. Cohorts")
  f
}

test_that("describe, rows 1-3: spanning shaded sections and a full grid", {
  x <- wx_doc(dsc_save(fill = "#A5C9EB"))
  tc <- xq(sec_row(x), "./w:tc")
  expect_length(tc, 1L)
  expect_identical(xml2::xml_attr(xq(tc, ".//w:gridSpan"), "val"),
                   as.character(ncols(x)))
  expect_identical(xml2::xml_attr(xq(tc, ".//w:shd"), "fill"), "A5C9EB")
  n_tc <- length(xq(x, "//w:tc"))
  for (side in c("top", "bottom", "left", "right")) {
    path <- sprintf("//w:tcBorders/w:%s[@w:val='single' and @w:sz='4']", side)
    expect_length(xq(x, path), n_tc)
  }
})

test_that("describe, rows 4-5: each group spans its pair; n* on each", {
  x <- wx_doc(dsc_save())
  expect_length(xq(x, "//w:tr[w:trPr/w:tblHeader]"), 2L)
  top <- vapply(xq(x, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(top[1:4], c("Characteristic", "Overall (N = 200)",
                               "Drug A (N = 98)", "Drug B (N = 102)"))
  expect_identical(top[5], "P†")
  expect_length(xq(x, "//w:tr[1]/w:tc[.//w:gridSpan[@w:val='2']]"), 3L)
  sub <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
  stat <- "No. (%) or Median [15th, 85th percentiles]†"
  expect_identical(sub[2:7], rep(c("n*", stat), 3))
})

test_that("describe, rows 8-10: the notes, as compare writes them", {
  x <- wx_doc(dsc_save())
  notes <- vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text,
                  character(1))
  expect_identical(notes[1], "*Patients with non-missing data.")
  expect_match(notes[2], "^†Values are No\\. \\(%\\) or median")
  sup <- xq(x, paste0("//w:tbl/following-sibling::w:p//",
                      "w:vertAlign[@w:val='superscript']"))
  expect_length(sup, 0L)
})

test_that("describe: no font, a caption, Letter, and hv_check_docx() passes", {
  f <- dsc_save()
  x <- wx_doc(f)
  expect_length(xq(x, "//w:tbl//w:rFonts[@w:ascii]"), 0L)
  expect_identical(wx_text(xq(x, "//w:body/*[1]")[[1]]), "Table 2. Cohorts")
  expect_setequal(unname(pg_size(f)), c("12240", "15840"))
  expect_identical(nrow(hv_check_docx(f, style = "manuscript")), 0L)
})

test_that("a replica of a two-cohort describe table: no Overall, no P", {
  # ms.1333's shape: two separate cohorts side by side, a count each.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "marker"), Disease = "stage"),
    continuous = c("age", "marker"), categorical = "stage",
    overall = FALSE, compare = "none", show_variable = FALSE
  )
  f <- dsc_save(tbl)
  x <- wx_doc(f)
  top <- vapply(xq(x, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(top, c("Characteristic", "Drug A (N = 98)",
                          "Drug B (N = 102)"))
  sub <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(fit_geometry(f)$landscape, FALSE)
  expect_identical(nrow(hv_check_docx(f, style = "manuscript")), 0L)
})

test_that("a describe table displays with its marks where Word has them", {
  shown <- hv_man_table_display(hv_man_table(
    st_tbl(), style = "manuscript", layout = "describe"
  ))
  ch <- flextable::information_data_chunk(shown)
  marks <- ch[ch$.part == "header" & ch$vertical.align == "superscript", ]
  stars <- as.character(marks$.col_id[marks$txt == "*"])
  expect_identical(sort(unique(stars)), c("n_stat_0", "n_stat_1", "n_stat_2"))
  expect_true(all(marks$.row_id[marks$txt == "*"] == 2L))
  foot <- ch[ch$.part == "footer" & ch$.row_id == 1, ]
  expect_identical(paste(foot$txt, collapse = ""),
                   "*Patients with non-missing data.")
})

test_that("describe marks the groups it was built with, whatever their names", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$custom_a <- tbl$table_body$stat_1
  tbl$table_body$custom_b <- tbl$table_body$stat_2
  ft <- .man_table_describe(tbl, hv_table_style("manuscript"),
                            groups = c(custom_a = "A", custom_b = "B"),
                            trailing = NULL, stat_label = NULL)
  expect_identical(attr(ft, "hv_pairs"),
                   list(n = c("n_custom_a", "n_custom_b"),
                        stat = c("disp_custom_a", "disp_custom_b")))
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 2. Cohorts")
  sub <- vapply(xq(wx_doc(f), "//w:tr[2]/w:tc"), wx_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(sum(endsWith(sub, "†")), 2L)
})

# -- the matrix the "Table styles" article prints (design D6) -------------

# The design's section 5 matrix and its 5.1 describe column, as facts:
# the wording is the generated matrix's, the content the design's. A
# change to a style changes a cell here, and the design records it.
test_that("the style matrix states the design's matrix", {
  dag <- "\u2020"
  m <- .style_matrix()
  expect_identical(m$property, c(
    "Section row", "Fill color", "Borders", "Header", "Non-missing count",
    "Overall and comparison columns", "Continuous values",
    "Categorical values", "Note markers", "Count note", "Statistic note",
    "Abbreviations", "Font", "Caption", "Alignment and weight",
    "Row height", "Header repeated on a new page", "Page",
    "Variable column", "Merged cells"
  ))
  shared <- c(
    "`#CAEDFB`; `hv_table_style(fill =)` sets it",
    "shown when the table carries them",
    "`9.9 [8.5, 11]`, `63\u00B113`: the house standard",
    "`30 (42)`: the house standard",
    "`Key: A, \u2026; B, \u2026`",
    "header bold; first column left, others centered",
    "yes", "US Letter, landscape when wide, else portrait"
  )
  expect_identical(m$property[m$shared], c(
    "Fill color", "Overall and comparison columns", "Continuous values",
    "Categorical values", "Abbreviations", "Alignment and weight",
    "Header repeated on a new page", "Page"
  ))
  expect_identical(m$report[m$shared], shared)
  expect_identical(m$report[!m$shared], c(
    paste0("label in the first cell, bold, left; fill on every cell of ",
           "the row, unmerged"),
    "horizontal rules only",
    paste0("one row: a `No.` column before each group's `<group> N = n`; ",
           "`*` on the first `No.`, `", dag, "` on each group"),
    "one column per group",
    "the house symbols by meaning, superscript, then a space",
    "`Number of non-missing values.`",
    "`No. (%) or Median [15th, 85th percentiles].`",
    "Times New Roman 12 pt",
    "optional: bold, above the table, when given",
    "auto",
    "on screen only; every saved `.docx` drops it",
    "none"
  ))
  ms <- c(
    "spans the full width, bold; filled",
    "full grid: box plus all inner lines, single 0.5 pt",
    NA, NA,
    paste0("the house symbols by meaning, at the start of the note, not ",
           "superscript"),
    "`Patients with non-missing data.`",
    "`Values are No. (%) or median [15th, 85th percentiles].`",
    "none set: the document's body font",
    "required: bold, above the table",
    "at least 300 twips, rows kept on one page",
    "never",
    "header and section rows"
  )
  ms_cmp <- ms
  ms_cmp[3:4] <- c(
    paste0("two rows: `Characteristic` and `n*` merged down, the ",
           "grouping's name with `", dag, "` spanning its levels; row 2 ",
           "`<level> (N = n)`"),
    "one overall `n*` column"
  )
  ms_dsc <- ms
  ms_dsc[3:4] <- c(
    paste0("two rows: each group, `<level> (N = n)`, spans its own (n, ",
           "statistic) pair; row 2 names them, `n*` and the statistic ",
           "with `", dag, "`"),
    "one `n*` column per group, Overall's included"
  )
  expect_identical(m$compare[!m$shared], ms_cmp)
  expect_identical(m$describe[!m$shared], ms_dsc)
})

test_that("every style property is written into the matrix", {
  expect_setequal(.matrix_reads(), names(hv_table_style()))
})

test_that("the matrix is read from the style objects, not written", {
  fill <- .style_matrix(manuscript = hv_table_style("manuscript",
                                                    fill = "#A5C9EB"))
  i <- fill$property == "Fill color"
  expect_identical(fill$compare[i],
                   "`#A5C9EB`; `hv_table_style(fill =)` sets it")
  expect_false(fill$shared[i])
  s <- hv_table_style("report")
  s$borders <- "grid"
  b <- .style_matrix(report = s)
  expect_identical(b$report[b$property == "Borders"],
                   "full grid: box plus all inner lines, single 0.5 pt")
  s$borders <- "dotted"
  expect_error(.style_matrix(report = s),
               "No words for borders = dotted in the style matrix")
})

test_that("a property value with no words errors naming the row", {
  for (p in c("merged", "fill", "count_note")) {
    for (bad in list(NA_character_, "")) {
      s <- hv_table_style("report")
      s[[p]] <- bad
      expect_error(.style_matrix(report = s),
                   sprintf("No words for %s = ", p), fixed = TRUE)
    }
  }
})

test_that("the matrix's notes and key are the words the saver writes", {
  m <- .style_matrix()
  cell <- function(col, prop) gsub("`", "", m[[col]][m$property == prop])
  after <- function(f) {
    vapply(xq(wx_doc(f), "//w:tbl/following-sibling::w:p"), wx_text,
           character(1))
  }
  r <- after(st_save("report"))
  expect_identical(r[1], paste("*", cell("report", "Count note")))
  expect_identical(r[2], paste0("\u2020 ", sub("\\.$", "", cell(
    "report", "Statistic note"
  )), "; P values from the Wilcoxon rank sum test and Pearson's ",
  "chi-square test."))
  x <- after(st_save("manuscript"))
  expect_identical(x[1], paste0("*", cell("compare", "Count note")))
  # The manuscript's dagger note goes on to name the tests.
  stat <- sub("\\.$", ";", cell("compare", "Statistic note"))
  expect_identical(x[2], paste0(
    "\u2020", stat, " P values from the Wilcoxon rank sum test and ",
    "Pearson's chi-square test."
  ))
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(st_tbl()), f,
                    abbreviations = c(B = "\u2026", A = "\u2026"))
  expect_identical(utils::tail(after(f), 1),
                   cell("report", "Abbreviations"))
})
