#' Write an hv_man_table_jtcvs() table to a compliant .docx
#'
#' JTCVS counterpart to [hv_man_table_save()]: it adds a bold `Table N.
#' Caption` paragraph before the table, and renders footnotes as lettered
#' (`a.`, `b.`, ...) markers attached to specific body cells rather than
#' the fixed symbol set [hv_man_table_save()] uses on the header row,
#' matching the JTCVS template convention.
#'
#' @section Common mistakes:
#' **"`footnotes[[k]]$text` must be a single non-empty string."** Every
#' footnote needs all three of `row`, `col`, and `text`. Before this
#' check existed, an entry missing `text` wrote a document with a
#' dangling superscript marker and an empty footnote line.
#'
#' **"`footnotes[[k]]$row` must be whole numbers ..."** Row indices
#' count the section-header rows [hv_man_table_jtcvs()] interleaves
#' into the body. [hv_test_footnotes_jtcvs()] computes them for you.
#'
#' **"`file` must be a single non-empty file path."** Check the
#' argument order: it is `(ft, file, caption)`.
#'
#' @param ft A `flextable`, from [hv_man_table_jtcvs()].
#' @param file Output `.docx` path.
#' @param caption Full caption text, e.g. `"Table 1. Baseline
#'   Characteristics"`, rendered bold above the table. This function does
#'   not auto-number tables for you; include the number yourself.
#' @param footnotes Optional list of `list(row =, col =, text =)`, one per
#'   footnote, in the order letters should be assigned (`a`, `b`, ...).
#'   `col` is a single `col_keys` name. `row` may be a vector, in which
#'   case the one letter marks every row named, which is how several rows
#'   share a footnote. `row` indexes `ft`'s body rows as shown: for a
#'   sectioned table (built with `groupname_col`), that includes the
#'   section-header rows [hv_man_table_jtcvs()] interleaves into the body,
#'   so count those too. [hv_test_footnotes_jtcvs()] computes these
#'   indices for you when the footnotes mark statistical tests.
#' @param abbreviations Optional named character vector, same as
#'   [hv_man_table_save()], rendered via the shared `Key:` helper.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [hv_man_table_jtcvs()] to build a compliant `flextable` first.
#'
#' @examples
#' library(gtsummary)
#' tbl <- trial |>
#'   tbl_summary(
#'     by = trt,
#'     statistic = list(
#'       all_continuous() ~ "{N_obs} ||| {mean} ± {sd}",
#'       all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
#'     ),
#'     include = c(age, grade),
#'     missing = "no"
#'   )
#' ft <- hv_man_table_jtcvs(
#'   tbl,
#'   groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
#' )
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save_jtcvs(
#'   ft, out,
#'   caption = "Table 1. Baseline Characteristics",
#'   footnotes = list(list(
#'     row = 1, col = "n_stat_1", text = "Patients with data available."
#'   ))
#' )
#'
#' @export
hv_man_table_save_jtcvs <- function(ft, file, caption, footnotes = NULL,
                                    abbreviations = NULL) {
  .check_flextable(ft)
  .check_file(file)
  .check_string(caption, "caption")
  .check_abbreviations(abbreviations)

  letters_seq <- letters
  if (!is.null(footnotes) && length(footnotes) > length(letters_seq))
    stop("Too many footnotes (max ", length(letters_seq),
         " letters).", call. = FALSE)

  .assert_footnote_entries(footnotes, ft)

  if (!is.null(footnotes)) {
    for (k in seq_along(footnotes)) {
      fn <- footnotes[[k]]
      ft <- flextable::append_chunks(
        ft, i = fn$row, j = fn$col, part = "body",
        flextable::as_sup(letters_seq[k])
      )
    }
  }

  doc <- officer::read_docx()
  cap_par <- officer::fpar(
    officer::ftext(caption, prop = officer::fp_text(bold = TRUE))
  )
  doc <- officer::body_add_fpar(doc, cap_par, style = "Normal")
  doc <- flextable::body_add_flextable(doc, ft)

  if (!is.null(footnotes)) {
    for (k in seq_along(footnotes)) {
      sup_prop <- officer::fp_text(vertical.align = "superscript")
      note_par <- officer::fpar(
        officer::ftext(letters_seq[k], prop = sup_prop),
        officer::ftext(paste0(". ", footnotes[[k]]$text))
      )
      doc <- officer::body_add_fpar(doc, note_par, style = "Normal")
    }
  }

  doc <- .add_abbreviations_key(doc, abbreviations)

  print(doc, target = file)
  invisible(file)
}
