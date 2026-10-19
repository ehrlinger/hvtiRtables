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
