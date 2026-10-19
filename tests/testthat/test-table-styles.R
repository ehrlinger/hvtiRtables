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
    "\u2020Values are No. (%) or median [15th, 85th percentiles]."
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
  m <- wx_doc(st_save("manuscript"))
  head_runs <- xq(m, "//w:tr[w:trPr/w:tblHeader]//w:r[w:t]/w:rPr")
  bold <- xq(m, paste0("//w:tr[w:trPr/w:tblHeader]//w:r[w:t]/w:rPr/",
                       "w:b[not(@w:val='false')]"))
  expect_gt(length(head_runs), 0L)
  expect_length(bold, length(head_runs)) # every header run is bold
  n_tr <- length(xq(m, "//w:tr"))
  expect_length(xq(m, "//w:trHeight[@w:val='300' and @w:hRule='atLeast']"),
                n_tr)
  expect_length(xq(m, "//w:trPr/w:cantSplit"), n_tr)
  r <- wx_doc(st_save("report"))
  expect_length(xq(r, "//w:trPr/w:cantSplit"), 0L)
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
