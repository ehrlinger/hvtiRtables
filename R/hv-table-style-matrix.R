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
# "name" is exempt from a row: it selects the style and is not drawn.
.matrix_reads <- function() {
  unique(c("name", unlist(lapply(.matrix_rows(), function(r) r$reads))))
}

.mrow <- function(property, reads, cell) {
  list(property = property, reads = reads, cell = cell)
}

# The words for a property value. A value with none (unknown, NA, empty)
# errors naming the row and the value, so it cannot reach the article
# blank or as "NA".
.say <- function(row, value, ...) {
  words <- list(...)
  ok <- is.character(value) && length(value) == 1L && !is.na(value) &&
    nzchar(value)
  if (ok && !length(words)) return(value)
  if (ok && value %in% names(words)) return(words[[value]])
  shown <- if (is.character(value) && length(value) == 1L)
    value else deparse(value)
  stop(sprintf("No words for %s = %s in the style matrix.", row, shown),
       call. = FALSE)
}

# One function per row, from (style, layout) to the cell's words.
.matrix_rows <- function() {
  dag <- "\u2020"
  list(
    .mrow("Section row", "section", function(s, layout) {
      .say("section", s$section,
           label = paste0("label in the first cell, bold, left; fill on ",
                          "every cell of the row, unmerged"),
           spanned = "spans the full width, bold; filled")
    }),
    .mrow("Fill color", "fill", function(s, layout) {
      sprintf("`%s`; `hv_table_style(fill =)` sets it", .say("fill", s$fill))
    }),
    .mrow("Borders", "borders", function(s, layout) {
      .say("borders", s$borders,
           rules = "horizontal rules only",
           grid = paste0("full grid: box plus all inner lines, single ",
                         "0.5 pt"))
    }),
    .mrow("Header", "header", function(s, layout) {
      .say("header", s$header, flat = "", spanned = "")
      if (identical(s$header, "flat"))
        return(paste0("one row: a `No.` column before each group's ",
                      "`<group> N = n`; `*` on the first `No.`, `", dag,
                      "` on each group"))
      .say("layout", layout,
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
      .say("count", s$count, per_group = "", overall = "")
      if (identical(s$count, "per_group")) return("one column per group")
      .say("layout", layout,
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
      .say("marker", s$marker,
           superscript = paste0("the house symbols by meaning, ",
                                "superscript, then a space"),
           leading = paste0("the house symbols by meaning, at the start ",
                            "of the note, not superscript"))
    }),
    .mrow("Count note", "count_note", function(s, layout) {
      sprintf("`%s`", .say("count_note", s$count_note))
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
      .say("caption", s$caption,
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
      .say("page", s$page,
           letter = "US Letter, landscape when wide, else portrait")
    }),
    .mrow("Variable column", "variable", function(s, layout) {
      if (s$variable) "on screen only; every saved `.docx` drops it" else
        "never"
    }),
    .mrow("Merged cells", "merged", function(s, layout) {
      .say("merged", s$merged)
    })
  )
}
