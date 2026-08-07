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

#' Check a .docx for structural patterns the house rules forbid
#'
#' Read-only inspection of any Word document, whether written by this
#' package or received from elsewhere. Reports the three structural
#' failure patterns the canonical "Table Construction for Manuscripts"
#' memo names, and never modifies the file.
#'
#' @details
#' Three detectors run:
#'
#' * `"layer"` (structural, high confidence): paragraphs positioned with
#'   `w:framePr`, or floating text boxes (`w:txbxContent`). Table content
#'   belongs in the table, not in a floating layer over it.
#' * `"hidden_column"` (structural, high confidence): a table column that
#'   is both entirely empty **and** narrower than 0.1 inch. Both
#'   conditions are required. The house's own JTCVS templates contain
#'   all-empty 0.5-inch gutter columns between group pairs, which are
#'   deliberate; width alone or emptiness alone would flag them.
#' * `"embedded_footnote"` (heuristic, lower confidence): a table's last
#'   row containing text that starts with a footnote marker (`*`, a
#'   dagger, a lettered `a.`/`b.` marker, or `Key:`), the pattern
#'   `flextable::footnote()` produces when misused. This detector is
#'   pattern-based rather than a guaranteed structural signature, so
#'   treat its findings as prompts to look, not proof.
#'
#' @param path Path to a `.docx` file.
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
#' library(gtsummary)
#' tbl <- trial |>
#'   tbl_summary(
#'     by = trt,
#'     statistic = list(all_continuous() ~ "{N_obs} ||| {mean}"),
#'     include = age
#'   )
#' ft <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save_jtcvs(ft, out, caption = "Table 1. X")
#' hv_check_docx(out)
#'
#' @export
hv_check_docx <- function(path) {
  if (!is.character(path) || length(path) != 1L)
    stop("`path` must be a single file path.", call. = FALSE)
  doc <- .docx_body_xml(path)
  rbind(.detect_layers(doc))
}
