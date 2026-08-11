#' Write an hv_man_table_jtcvs() table to a compliant .docx
#'
#' JTCVS counterpart to [hv_man_table_save()]: it adds a bold `Table N.
#' Caption` paragraph before the table, and renders footnotes as lettered
#' (`a.`, `b.`, ...) markers attached to specific body cells rather than
#' the fixed symbol set [hv_man_table_save()] uses on the header row,
#' matching the JTCVS template convention.
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
#'     statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
#'     include = c(age, grade)
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
  if (!inherits(ft, "flextable"))
    stop("`ft` must be a flextable object.", call. = FALSE)
  if (!is.character(caption) || length(caption) != 1L || is.na(caption) ||
        !nzchar(caption))
    stop("`caption` must be a single non-empty string.", call. = FALSE)
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  .check_abbreviations(abbreviations)

  letters_seq <- letters
  if (!is.null(footnotes) && length(footnotes) > length(letters_seq))
    stop("Too many footnotes (max ", length(letters_seq), " letters).",
         call. = FALSE)

  if (!is.null(footnotes)) {
    n_body <- flextable::nrow_part(ft, "body")
    for (k in seq_along(footnotes)) {
      fn <- footnotes[[k]]
      # Fractional rows are checked explicitly: flextable accepts them
      # silently rather than erroring, so without this they would mark
      # whatever cell they truncate to, which is the silent-wrong-cell
      # failure this validation exists to prevent.
      if (!is.numeric(fn$row) || length(fn$row) == 0L || anyNA(fn$row) ||
            any(!is.finite(fn$row)) || any(fn$row %% 1 != 0) ||
            any(fn$row < 1) || any(fn$row > n_body))
        stop("`footnotes[[", k, "]]$row` must be whole numbers between ",
             "1 and ", n_body, ", indexing `ft`'s body rows. Row indices ",
             "count the section-header rows hv_man_table_jtcvs() ",
             "interleaves; hv_test_footnotes_jtcvs() computes them for ",
             "you.", call. = FALSE)
      if (!is.character(fn$col) || length(fn$col) != 1L ||
            !fn$col %in% ft$col_keys)
        stop("`footnotes[[", k, "]]$col` is not a column in `ft`: ",
             paste(fn$col, collapse = ", "), call. = FALSE)
    }
  }

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
