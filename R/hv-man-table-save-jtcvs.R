#' Deprecated: Write an hv_man_table_jtcvs() table to a compliant .docx
#'
#' **Deprecated.** Use
#' `hv_man_table_save(ft, file, caption = )` on a table from
#' `hv_man_table(tbl, style = "manuscript", layout = "describe")`. This
#' function warns on every call and goes in the next release.
#'
#' Stage 3 of the `%summarytable` split: writes the document. Replaces
#' the macro's `RTFFILE=`/`PDFFILE=` output block.
#'
#' JTCVS counterpart to [hv_man_table_save()]: it adds a bold `Table N.
#' Caption` paragraph before the table, and renders footnotes as lettered
#' (`a.`, `b.`, ...) markers attached to specific body cells rather than
#' the fixed symbol set [hv_man_table_save()] uses on the header row,
#' matching the JTCVS template convention. The header footnote
#' [hv_man_table_jtcvs()] marks on each `n` ("Patients with data
#' available.") is written first, as `a`.
#'
#' @section Common mistakes:
#' **"`footnotes\[\[k\]\]$text` must be a single non-empty string."**
#' Every footnote needs all three of `row`, `col`, and `text`, and
#' `text` must be one non-empty string. Before this check existed, an
#' entry missing `text` wrote a document with a dangling superscript
#' marker and an empty footnote line.
#'
#' **"`footnotes[[k]]` must be a list of the form list(row =, col =,
#' text =)."** `footnotes` is a list *of* footnotes, so a single one is
#' `list(list(row = 1, col = "n_stat_1", text = "..."))`. Dropping the
#' outer `list()` previously failed with `$ operator is invalid for
#' atomic vectors`.
#'
#' **"`footnotes[[k]]$row` must be whole numbers ..."** Row indices
#' count the section-header rows [hv_man_table_jtcvs()] interleaves
#' into the body. [hv_test_footnotes_jtcvs()] computes them for you.
#'
#' **"`file` must be a single non-empty file path."** Check the
#' argument order: it is `(ft, file, caption)`.
#'
#' **"Output directory does not exist: ..."** The directory part of
#' `file` (its `dirname()`) is not created for you; create it first
#' with `dir.create(dirname(file), recursive = TRUE)`.
#'
#' **A wide table on a landscape page.** Expected: a table wider than a
#' portrait page's text block (6.5 inches on US Letter), as a `"both"` table or
#' several trailing columns make it, is saved on a
#' landscape page. One wider than landscape's (9.0 inches) has its
#' columns narrowed in proportion to fit; the font size is not changed.
#'
#' @param ft A `flextable`, from [hv_man_table_jtcvs()].
#' @param file Output `.docx` path. The output directory (`dirname(file)`)
#'   must already exist; this function does not create it. (`%summarytable`
#'   `RTFFILE=`/`PDFFILE=` equivalent; output here is always `.docx`).
#' @param caption Full caption text, e.g. `"Table 1. Baseline
#'   Characteristics"`, rendered bold above the table. This function does
#'   not auto-number tables for you; include the number yourself.
#'   (`%summarytable` `TBLTITLE=` equivalent).
#' @param footnotes Optional list of `list(row =, col =, text =)`, one per
#'   footnote, in the order letters should be assigned. A table from
#'   [hv_man_table_jtcvs()] already uses `a` for its `n` header ("Patients
#'   with data available."), written first, so these start at `b`;
#'   other flextables start at `a`.
#'   `col` is a single `col_keys` name. `row` may be a vector, in which
#'   case the one letter marks every row named, which is how several rows
#'   share a footnote. `row` indexes `ft`'s body rows as shown: for a
#'   sectioned table (built with `groupname_col`), that includes the
#'   section-header rows [hv_man_table_jtcvs()] interleaves into the body,
#'   so count those too. [hv_test_footnotes_jtcvs()] computes these
#'   indices for you when the footnotes mark statistical tests.
#'   (`%summarytable` `ADDFN=` equivalent. `PRINTFN=1`'s house block is
#'   [hv_man_footnotes()], which is CORR-shaped and cannot be passed
#'   here: build the equivalent entries in this function's
#'   `list(row =, col =, text =)` shape instead.)
#' @param abbreviations Optional named character vector, same as
#'   [hv_man_table_save()], rendered via the shared `Key:` helper.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [hv_man_table_jtcvs()] to build a compliant `flextable` first.
#'
#' @examples
#' # Instead of hv_man_table_jtcvs() and hv_man_table_save_jtcvs():
#' tbl <- hv_tbl_summary(
#'   gtsummary::trial, by = "trt",
#'   groups = list(Demography = c("age", "grade")),
#'   continuous = "age", categorical = "grade", compare = "none"
#' )
#' ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save(ft, out, caption = "Table 2. Baseline Characteristics")
#'
#' @export
hv_man_table_save_jtcvs <- function(ft, file, caption, footnotes = NULL,
                                    abbreviations = NULL, ...) {
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_man_table_save_jtcvs",
    paste0("Use hv_man_table_save(ft, file, caption = ) on a table from ",
           "hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\").")
  ))
  .check_sas_args(list(...), "hv_man_table_save_jtcvs")
  .check_flextable(ft)
  .check_not_display(ft)
  .check_file(file)
  ft <- .drop_variable_column(ft)
  .check_string(caption, "caption")
  .check_abbreviations(abbreviations)

  # Footnotes the renderer already marked in the header (the "a" on
  # each `n`) keep their letters; footnotes given here take the rest.
  header_notes <- attr(ft, "hv_header_footnotes", exact = TRUE)
  letters_seq <- setdiff(letters, names(header_notes))
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

  fit <- .fit_page(ft)
  ft <- fit$ft

  doc <- officer::read_docx()
  doc <- .page_section(doc, fit$landscape)
  cap_par <- officer::fpar(
    officer::ftext(caption, prop = .note_prop(.table_font(ft), bold = TRUE))
  )
  doc <- officer::body_add_fpar(doc, cap_par, style = "Normal")
  doc <- flextable::body_add_flextable(doc, ft)

  font <- .table_font(ft)
  sup_prop <- .note_prop(font, "superscript")
  for (k in seq_along(header_notes)) {
    note_par <- officer::fpar(
      officer::ftext(names(header_notes)[k], prop = sup_prop),
      officer::ftext(paste0(". ", header_notes[[k]]), prop = .note_prop(font))
    )
    doc <- officer::body_add_fpar(doc, note_par, style = "Normal")
  }

  if (!is.null(footnotes)) {
    for (k in seq_along(footnotes)) {
      note_par <- officer::fpar(
        officer::ftext(letters_seq[k], prop = sup_prop),
        officer::ftext(paste0(". ", footnotes[[k]]$text),
                       prop = .note_prop(font))
      )
      doc <- officer::body_add_fpar(doc, note_par, style = "Normal")
    }
  }

  doc <- .add_abbreviations_key(doc, abbreviations, font)

  print(doc, target = file)
  invisible(file)
}
