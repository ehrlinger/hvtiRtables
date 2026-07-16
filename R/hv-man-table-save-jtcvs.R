#' Write an hv_man_table_jtcvs() table to a compliant .docx
#'
#' JTCVS counterpart to [hv_man_table_save()]: adds a bold `Table N.
#' Caption` paragraph before the table, and renders footnotes as lettered
#' (`a.`, `b.`, ...) markers attached to specific body cells rather than
#' the fixed symbol set [hv_man_table_save()] uses on the header row —
#' matching Tess's JTCVS template convention.
#'
#' @param ft A `flextable`, from [hv_man_table_jtcvs()].
#' @param file Output `.docx` path.
#' @param caption Full caption text, e.g. `"Table 1. Baseline
#'   Characteristics"` — rendered bold above the table. This function does
#'   not auto-number tables; include the number yourself.
#' @param footnotes Optional list of `list(row =, col =, text =)`, one per
#'   footnote, in the order letters should be assigned (`a`, `b`, ...).
#'   `row`/`col` address a body cell in `ft` (`col` is a `col_keys` name).
#'   `row` indexes `ft`'s body rows as shown — for a sectioned table (built
#'   with `groupname_col`), that includes the section-header rows
#'   [hv_man_table_jtcvs()] interleaves into the body, so a caller must
#'   count those rows when computing the target row index rather than
#'   indexing only the data rows.
#' @param abbreviations Optional named character vector, same as
#'   [hv_man_table_save()] — rendered via the shared `Key:` helper.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [hv_man_table_jtcvs()] to build a compliant `flextable` first.
#'
#' @export
hv_man_table_save_jtcvs <- function(ft, file, caption, footnotes = NULL,
                                    abbreviations = NULL) {
  if (!inherits(ft, "flextable"))
    stop("`ft` must be a flextable object.", call. = FALSE)
  if (!is.character(caption) || length(caption) != 1L || is.na(caption) || !nzchar(caption))
    stop("`caption` must be a single non-empty string.", call. = FALSE)
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  letters_seq <- letters
  if (!is.null(footnotes) && length(footnotes) > length(letters_seq))
    stop("Too many footnotes (max ", length(letters_seq), " letters).", call. = FALSE)

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
  cap_par <- officer::fpar(officer::ftext(caption, prop = officer::fp_text(bold = TRUE)))
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
