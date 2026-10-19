# Word measures column widths in dxa (twentieths of a point); 1440 dxa =
# 1 inch. A column is treated as hidden below 144 dxa (0.1"). That number
# is measured, not guessed: across the JTCVS reference templates and this
# package's own output, the narrowest column of any kind is 720 dxa, and
# the narrowest *all-empty* column is also 720 dxa (the 0.5" visual
# gutters the house template puts between group column-pairs, which are
# deliberate and must not be flagged). 144 sits 5x below that floor.
.hidden_col_dxa <- 144

.docx_body_xml <- function(path) {
  if (!file.exists(path))
    stop("File does not exist: ", path, call. = FALSE)
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  ok <- tryCatch({
    utils::unzip(path, files = "word/document.xml", exdir = xdir)
    file.exists(file.path(xdir, "word", "document.xml"))
  }, warning = function(w) FALSE, error = function(e) FALSE)
  if (!ok)
    stop("Not a valid .docx (no word/document.xml): ", path, call. = FALSE)
  xml2::read_xml(file.path(xdir, "word", "document.xml"))
}

.finding <- function(type, table, location, detail) {
  data.frame(
    type = type, table = table, location = location, detail = detail,
    stringsAsFactors = FALSE
  )
}

.empty_report <- function() {
  .finding(character(0), integer(0), character(0), character(0))
}

.detect_layers <- function(doc) {
  out <- list()
  frames <- xml2::xml_find_all(doc, "//w:framePr")
  if (length(frames) > 0)
    out[[length(out) + 1]] <- .finding(
      "layer", NA_integer_, NA_character_,
      sprintf(
        paste0("%d paragraph(s) positioned with w:framePr (legacy Word ",
               "frame). House rules require table content to live in the ",
               "table, not a floating frame."),
        length(frames)
      )
    )
  boxes <- xml2::xml_find_all(doc, "//*[local-name()='txbxContent']")
  if (length(boxes) > 0)
    out[[length(out) + 1]] <- .finding(
      "layer", NA_integer_, NA_character_,
      sprintf(
        paste0("%d floating text box (w:txbxContent). House rules require ",
               "table content to live in the table, not a text box."),
        length(boxes)
      )
    )
  if (length(out) == 0) return(.empty_report())
  do.call(rbind, out)
}

# A cell spanning n grid columns carries w:gridSpan; without it the cell
# occupies one column. Anything unparseable counts as one, which keeps the
# column bookkeeping conservative rather than dropping columns.
.grid_span <- function(tc) {
  span <- xml2::xml_find_first(tc, "./w:tcPr/w:gridSpan")
  if (inherits(span, "xml_missing")) return(1L)
  val <- suppressWarnings(as.integer(xml2::xml_attr(span, "val")))
  if (is.na(val) || val < 1L) 1L else val
}

# TRUE for each grid column of `tbl` that holds text anywhere. A spanning
# cell marks every column it covers, so a merged header never leaves the
# columns under it looking empty.
.col_has_text <- function(tbl, ncol) {
  filled <- rep(FALSE, ncol)
  for (row in xml2::xml_find_all(tbl, "./w:tr")) {
    pos <- 1L
    for (tc in xml2::xml_find_all(row, "./w:tc")) {
      if (pos > ncol) break
      span <- .grid_span(tc)
      if (nzchar(trimws(xml2::xml_text(tc))))
        filled[seq.int(pos, min(pos + span - 1L, ncol))] <- TRUE
      pos <- pos + span
    }
  }
  filled
}

.detect_hidden_col <- function(doc) {
  out <- list()
  tbls <- xml2::xml_find_all(doc, "//w:tbl")
  for (i in seq_along(tbls)) {
    grid <- xml2::xml_find_all(tbls[[i]], "./w:tblGrid/w:gridCol")
    if (length(grid) == 0) next
    widths <- suppressWarnings(as.integer(xml2::xml_attr(grid, "w")))
    empty <- !.col_has_text(tbls[[i]], length(grid))
    hidden <- which(!is.na(widths) & widths < .hidden_col_dxa & empty)
    for (j in hidden)
      out[[length(out) + 1]] <- .finding(
        "hidden_column", i, sprintf("column %d", j),
        sprintf(
          paste0("Column %d is entirely empty and %d dxa wide (%.3f in), ",
                 "below the %d dxa (0.1 in) floor: a hidden spacer column. ",
                 "House rules require spacing from cell margins, not from a ",
                 "column too narrow to see."),
          j, widths[j], widths[j] / 1440, .hidden_col_dxa
        )
      )
  }
  if (length(out) == 0) return(.empty_report())
  do.call(rbind, out)
}

# Footnote markers: asterisk, dagger, double dagger, section, pilcrow, a
# lettered "a." / "b)" marker, or the literal "Key:" or "Abbreviation:"
# (gtsummary's definition of CI, written as a row). The four symbols are
# \u escapes so the source file stays ASCII; single-backslash, since R has
# to resolve them into characters before the regex engine sees them.
.footnote_marker <- paste0(
  "^(\\*|\u2020|\u2021|\u00a7|\u00b6|[a-z][.)](\\s|$)|Key:|Abbreviations?:)"
)

# TRUE when a cell opens with a superscript run of digits, the form
# gtsummary writes a footnote in ("1" raised, then the text). Read from
# the run's formatting rather than the text, so a body cell that starts
# with a plain digit ("30-day mortality") is not mistaken for one.
.opens_with_digit_marker <- function(tc) {
  run <- xml2::xml_find_first(tc, ".//w:r[w:t][1]")
  if (inherits(run, "xml_missing")) return(FALSE)
  raised <- xml2::xml_find_first(
    run, "./w:rPr/w:vertAlign[@w:val='superscript']"
  )
  !inherits(raised, "xml_missing") &&
    grepl("^[0-9]+$", trimws(xml2::xml_text(run)))
}

.detect_embedded_footnote <- function(doc) {
  out <- list()
  tbls <- xml2::xml_find_all(doc, "//w:tbl")
  for (i in seq_along(tbls)) {
    rows <- xml2::xml_find_all(tbls[[i]], "./w:tr")
    if (length(rows) == 0) next
    cells <- xml2::xml_find_all(rows[[length(rows)]], "./w:tc")
    for (k in seq_along(cells)) {
      txt <- trimws(xml2::xml_text(cells[[k]]))
      if (!grepl(.footnote_marker, txt) &&
            !.opens_with_digit_marker(cells[[k]]))
        next
      out[[length(out) + 1]] <- .finding(
        "embedded_footnote", i,
        sprintf("row %d (last row), cell %d", length(rows), k),
        sprintf(
          paste0("Last-row text starts with a footnote marker: \"%s\". ",
                 "House rules require footnotes as text below the table, ",
                 "not as a row inside it."),
          substr(txt, 1L, 60L)
        )
      )
    }
  }
  if (length(out) == 0) return(.empty_report())
  do.call(rbind, out)
}

# A table may overrun its text block by this much before it is flagged:
# 20 dxa is 1 pt, enough to absorb rounding when column widths are written
# out, far short of a clipped column.
.wide_tol_dxa <- 20

# A table wider than the text block of the section it sits in runs into
# the margin or off the page, and Word clips what does not fit. Each table
# belongs to the first section break after it: a paragraph's w:sectPr, or
# the body's own, which closes the last section.
.detect_wide_table <- function(doc) {
  out <- list()
  tbls <- xml2::xml_find_all(doc, "//w:tbl")
  for (i in seq_along(tbls)) {
    grid <- xml2::xml_find_all(tbls[[i]], "./w:tblGrid/w:gridCol")
    widths <- suppressWarnings(as.numeric(xml2::xml_attr(grid, "w")))
    if (length(widths) == 0L || anyNA(widths)) next
    # The body's own w:sectPr follows every table in the body, so this
    # also finds the last section. With no w:sectPr at all the widths
    # below are NA and the table is skipped.
    sect <- xml2::xml_find_first(tbls[[i]], "following::w:sectPr[1]")
    attr_num <- function(xp, at) {
      suppressWarnings(as.numeric(
        xml2::xml_attr(xml2::xml_find_first(sect, xp), at)
      ))
    }
    text <- attr_num("./w:pgSz", "w") - attr_num("./w:pgMar", "left") -
      attr_num("./w:pgMar", "right")
    if (is.na(text) || sum(widths) <= text + .wide_tol_dxa) next
    out[[length(out) + 1]] <- .finding(
      "wide_table", i, NA_character_,
      sprintf(
        paste0("Table is %.2f in wide; the page leaves %.2f in between the ",
               "margins, so Word clips the columns past them. Fit the ",
               "table or turn the page."),
        sum(widths) / 1440, text / 1440
      )
    )
  }
  if (length(out) == 0) return(.empty_report())
  do.call(rbind, out)
}

# The rows Word treats as the table's header: the leading run of rows
# whose w:tblHeader is on. The flag is on when present without a value
# or with "true", "on" or "1"; Word ignores a flag set off, and one on a
# row after a body row, so neither row is a header.
.header_rows <- function(rows) {
  flag <- vapply(rows, function(tr) {
    h <- xml2::xml_find_first(tr, "./w:trPr/w:tblHeader")
    if (inherits(h, "xml_missing")) return(FALSE)
    val <- xml2::xml_attr(h, "val")
    is.na(val) || !tolower(val) %in% c("false", "off", "0")
  }, logical(1))
  cumsum(!flag) == 0L
}

# Grid columns covered by each horizontal merge group in a row. A cell with
# w:hMerge of "continue", or with no value, joins the group before it; any
# other cell starts a group. A cell's own w:gridSpan counts toward its
# group, so the legacy hMerge and the modern gridSpan sum alike.
.hmerge_spans <- function(tcs) {
  spans <- integer(0)
  for (tc in tcs) {
    h <- xml2::xml_find_first(tc, "./w:tcPr/w:hMerge")
    cont <- !inherits(h, "xml_missing") &&
      (is.na(xml2::xml_attr(h, "val")) ||
         tolower(xml2::xml_attr(h, "val")) != "restart")
    if (cont && length(spans) > 0L) {
      spans[length(spans)] <- spans[length(spans)] + .grid_span(tc)
    } else {
      spans <- c(spans, .grid_span(tc))
    }
  }
  spans
}

# House rule 3 asks for no merged cells; a style may merge its header
# and its section rows, and a section row merged at all must span the
# table in one cell. A label beside one wide blank cell reads as a row
# that lost its contents. `strict` is the report style, which merges
# nothing.
.detect_merged_cell <- function(doc, strict = FALSE) {
  out <- list()
  tbls <- xml2::xml_find_all(doc, "//w:tbl")
  for (i in seq_along(tbls)) {
    ncol <- length(xml2::xml_find_all(tbls[[i]], "./w:tblGrid/w:gridCol"))
    rows <- xml2::xml_find_all(tbls[[i]], "./w:tr")
    header <- .header_rows(rows)
    for (r in seq_along(rows)) {
      tcs <- xml2::xml_find_all(rows[[r]], "./w:tc")
      spans <- vapply(tcs, .grid_span, integer(1))
      vmerge <- length(xml2::xml_find_all(
        rows[[r]], "./w:tc/w:tcPr/w:vMerge"
      )) > 0L
      hmerge <- length(xml2::xml_find_all(
        rows[[r]], "./w:tc/w:tcPr/w:hMerge"
      )) > 0L
      if (all(spans == 1L) && !vmerge && !hmerge) next
      groups <- .hmerge_spans(tcs)
      full <- length(groups) == 1L && groups[1] == ncol
      if (!strict && (header[r] || (full && !vmerge))) next
      detail <- if (strict) {
        paste0("Row ", r, " merges cells, and the report style merges ",
               "none (house rule 3).")
      } else {
        paste0("Row ", r, " merges cells outside the header without ",
               "spanning the table. A style merges only its header rows ",
               "and section rows that span the table in one cell.")
      }
      out[[length(out) + 1]] <- .finding("merged_cell", i,
                                         sprintf("row %d", r), detail)
    }
  }
  if (length(out) == 0) return(.empty_report())
  do.call(rbind, out)
}

#' Check a .docx for structural patterns the house rules forbid
#'
#' Read-only inspection of any Word document, whether written by this
#' package or received from elsewhere. Reports the three structural
#' failure patterns the canonical "Table Construction for Manuscripts"
#' memo names, and a table too wide for its page, and never modifies the
#' file.
#'
#' @details
#' Five detectors run:
#'
#' * `"layer"` (structural, high confidence): paragraphs positioned with
#'   `w:framePr`, or floating text boxes (`w:txbxContent`). Table content
#'   belongs in the table, not in a floating layer over it.
#' * `"hidden_column"` (structural, high confidence): a table column that
#'   is both entirely empty **and** strictly narrower than 0.1 inch (a
#'   `w:gridCol` width below 144 dxa; exactly 144 does not count). Both
#'   conditions are required. The house's own JTCVS templates contain
#'   all-empty 0.5-inch gutter columns between group pairs, which are
#'   deliberate; width alone or emptiness alone would flag them. A cell
#'   spanning several columns counts as filling every column it covers,
#'   so a merged header never makes the columns beneath it look empty.
#' * `"wide_table"` (structural, high confidence): a table whose grid is
#'   wider than the text block of the page section it sits in (page width
#'   less both margins), by more than 1 pt. Word clips what runs past the
#'   margin, so the rightmost columns are lost from the page.
#' * `"embedded_footnote"` (heuristic, lower confidence): a cell in a
#'   table's last row whose text starts with a footnote marker (`*`, a
#'   dagger or double dagger, a section or pilcrow sign, a lettered
#'   `a.`/`b.` marker, `Key:` or `Abbreviation:`) or whose first run is a
#'   superscript number, as `gtsummary` writes a footnote, the pattern
#'   `flextable::footnote()` produces when misused. This detector is
#'   pattern-based rather than a guaranteed structural signature, so treat
#'   its findings as prompts to look, not proof.
#' * `"merged_cell"` (structural, high confidence): a row whose cells are
#'   merged (`w:gridSpan` above 1, `w:vMerge`, or the legacy `w:hMerge`)
#'   outside the header rows, unless the row is one cell spanning the
#'   table. The header rows are the leading run of rows whose
#'   `w:tblHeader` flag is on, as Word
#'   reads it. With `style = "report"`, any merged cell is a finding.
#'
#' @section Common mistakes:
#' **"`path` must be a single non-empty string."** The argument is a
#' file path, not a `flextable` or an `officer` document. Neither saver
#' runs this on its own output, so call it on the written `.docx`
#' afterwards.
#'
#' **Reading a `hidden_column` finding as a gutter column.** It is not
#' one. The detector requires empty **and** narrower than 0.1 inch,
#' precisely so the deliberate half-inch gutter columns in the house
#' JTCVS templates do not trip it. A finding here is a real spacer.
#'
#' **Treating `embedded_footnote` as proof.** It is the one heuristic
#' detector of the five: it matches a marker character opening a cell
#' in a table's last row, and a legitimate last row that happens to
#' start that way matches it too. Read it as a prompt to look, not a
#' verdict.
#'
#' **Expecting a repair.** This is read-only and never modifies the
#' file. Fix what it reports in Word, or rebuild the table through
#' [hv_man_table_save()] or [hv_man_table_save_jtcvs()].
#'
#' @param path Path to a `.docx` file.
#' @param style `NULL`, the default, applies the rule every style shares.
#'   A style name or [hv_table_style()] applies that style's rule: the
#'   report style merges no cells at all.
#'
#' @return A `data.frame` with one row per finding and columns `type`,
#'   `table` (1-indexed table number, `NA` when document-level),
#'   `location` (row/column detail where applicable, `NA` otherwise), and
#'   `detail` (human-readable description). Zero rows means clean.
#'
#' @seealso [hv_man_table_save()] and [hv_man_table_save_jtcvs()], which
#'   write the files this checks. Neither runs the check on its own
#'   output, so call this on the path afterwards when you want it.
#'
#' @examples
#' # \donttest{}: the example writes a .docx and reads it back, which is
#' # I/O-bound enough to trip CRAN's 5s example budget (12.7s elapsed at
#' # 1.0.0). It runs, and is meant to -- it is not \dontrun{}.
#' \donttest{
#' library(gtsummary)
#' tbl <- trial |>
#'   tbl_summary(
#'     by = trt,
#'     statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ± {sd}"),
#'     include = age,
#'     missing = "no"
#'   )
#' ft <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save_jtcvs(ft, out, caption = "Table 1. X")
#' hv_check_docx(out)
#' }
#'
#' @export
hv_check_docx <- function(path, style = NULL) {
  .check_string(path, "path")
  strict <- !is.null(style) && identical(.as_style(style)$merged, "none")
  doc <- .docx_body_xml(path)
  rbind(
    .detect_layers(doc),
    .detect_hidden_col(doc),
    .detect_embedded_footnote(doc),
    .detect_wide_table(doc),
    .detect_merged_cell(doc, strict)
  )
}
