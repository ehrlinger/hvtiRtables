# The style matrix of the table-styles design (section 5), written from
# the style objects rather than by hand, so the "Table styles" article
# and the package cannot disagree (design D6). One row per property.
# Each row names the style properties it is written from (`reads`), and
# a test holds every property of hv_table_style() to some row, so a new
# property cannot go undocumented. The layout is an argument of
# hv_man_table(), not a property, so the manuscript style is two
# columns, one per layout (design section 5.1).
.style_matrix <- function(report = hv_table_style("report"),
                          manuscript = hv_table_style("manuscript")) {
  cols <- list(
    report = list(style = report, layout = NA_character_),
    compare = list(style = manuscript, layout = "compare"),
    describe = list(style = manuscript, layout = "describe")
  )
  rows <- .matrix_rows()
  cells <- lapply(cols, function(k) {
    vapply(rows, function(r) r$cell(k$style, k$layout), character(1))
  })
  out <- data.frame(
    property = vapply(rows, function(r) r$property, character(1)),
    cells, stringsAsFactors = FALSE
  )
  out$shared <- out$report == out$compare & out$compare == out$describe
  out
}

# The style properties the matrix reads: every row's, and the style's
# name, which heads its column.
.matrix_reads <- function() {
  unique(c("name", unlist(lapply(.matrix_rows(), function(r) r$reads))))
}

.mrow <- function(property, reads, cell) {
  list(property = property, reads = reads, cell = cell)
}

# One function per row, from (style, layout) to the cell's words. A
# property value with no words errors in vapply(), so a new value cannot
# reach the article blank.
.matrix_rows <- function() {
  dag <- "\u2020"
  list(
    .mrow("Section row", "section", function(s, layout) {
      switch(s$section,
             label = paste0("label in the first cell, bold, left; fill on ",
                            "every cell of the row, unmerged"),
             spanned = "spans the full width, bold; filled")
    }),
    .mrow("Fill color", "fill", function(s, layout) {
      sprintf("`%s`; `hv_table_style(fill =)` sets it", s$fill)
    }),
    .mrow("Borders", "borders", function(s, layout) {
      switch(s$borders,
             rules = "horizontal rules only",
             grid = paste0("full grid: box plus all inner lines, single ",
                           "0.5 pt"))
    }),
    .mrow("Header", "header", function(s, layout) {
      if (identical(s$header, "flat"))
        return(paste0("one row: a `No.` column before each group's ",
                      "`<group> N = n`; `*` on the first `No.`, `", dag,
                      "` on each group"))
      switch(layout,
             compare = paste0("two rows: `Characteristic` and `n*` merged ",
                              "down, the grouping's name with `", dag,
                              "` spanning its levels; row 2 ",
                              "`<level> (N = n)`"),
             describe = paste0("two rows: each group, `<level> (N = n)`, ",
                               "spans its own (n, statistic) pair; row 2 ",
                               "names them, `n*` and the statistic with `",
                               dag, "`"))
    }),
    .mrow("Non-missing count", "count", function(s, layout) {
      if (identical(s$count, "per_group")) return("one column per group")
      switch(layout,
             compare = "one overall `n*` column",
             describe = "one `n*` column per group, Overall's included")
    }),
    .mrow("Overall and comparison columns", character(0),
          function(s, layout) "shown when the table carries them"),
    .mrow("Continuous values", character(0), function(s, layout) {
      "`9.9 [8.5, 11]`, `63\u00B113`: the house standard"
    }),
    .mrow("Categorical values", character(0), function(s, layout) {
      "`30 (42)`: the house standard"
    }),
    .mrow("Note markers", "marker", function(s, layout) {
      switch(s$marker,
             superscript = paste0("the house symbols by meaning, ",
                                  "superscript, then a space"),
             leading = paste0("the house symbols by meaning, at the start ",
                              "of the note, not superscript"))
    }),
    .mrow("Count note", "count_note", function(s, layout) {
      sprintf("`%s`", s$count_note)
    }),
    .mrow("Statistic note", "stat_lead", function(s, layout) {
      sprintf("`%s`", .stat_note(.stat_label("median", c(15, 85)), s))
    }),
    .mrow("Abbreviations", character(0), function(s, layout) {
      key <- .key_runs(c(A = "\u2026", B = "\u2026"))
      sprintf("`%s`", paste(key$text, collapse = ""))
    }),
    .mrow("Font", c("font", "font_size"), function(s, layout) {
      if (is.na(s$font)) return("none set: the document's body font")
      sprintf("%s %g pt", s$font, s$font_size)
    }),
    .mrow("Caption", "caption", function(s, layout) {
      switch(s$caption,
             optional = "optional: bold, above the table, when given",
             required = "required: bold, above the table")
    }),
    .mrow("Alignment and weight", "header_bold", function(s, layout) {
      paste0(if (s$header_bold) "header bold" else "header plain",
             "; first column left, others centered")
    }),
    .mrow("Row height", c("row_height", "keep_rows"), function(s, layout) {
      h <- if (is.null(s$row_height)) "auto" else
        sprintf("at least %g twips", s$row_height)
      paste0(h, if (s$keep_rows) ", rows kept on one page")
    }),
    .mrow("Header repeated on a new page", "repeat_header",
          function(s, layout) if (s$repeat_header) "yes" else "no"),
    .mrow("Page", "page", function(s, layout) {
      switch(s$page,
             letter = "US Letter, landscape when wide, else portrait")
    }),
    .mrow("Variable column", "variable", function(s, layout) {
      if (s$variable) "on screen only; every saved `.docx` drops it" else
        "never"
    }),
    .mrow("Merged cells", "merged", function(s, layout) s$merged)
  )
}
