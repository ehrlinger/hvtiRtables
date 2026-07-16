#' Write a hv_man_table() table to a compliant .docx
#'
#' Writes a `flextable` (typically from [hv_man_table()]) to a Word
#' document, with footnotes and an abbreviation key rendered as text below
#' the table rather than embedded within it — house rules 13-14. Note that
#' [flextable::footnote()] cannot be used for this: it renders footnote text
#' as an extra row inside the table's own `<w:tbl>` block (a "footer" table
#' part), which is exactly the compliance violation this function exists to
#' avoid. Instead, a superscript reference symbol is appended to the target
#' header cell (a normal, compliant reference mark), and the footnote text
#' itself is written as a genuine document paragraph after the table via
#' [officer::body_add_fpar()]. The table itself is inserted directly (no
#' leading blank paragraph), which is what keeps vertical cell alignment
#' controllable if the surrounding document is later reformatted to 1.5- or
#' double-spacing (house rule 2 concerns the *insertion point* in the
#' destination document, not this function's output — see the package
#' README for the paste-in workflow).
#'
#' @param ft A `flextable` object, typically from [hv_man_table()].
#' @param file Output `.docx` path.
#' @param footnotes Optional named list, symbol -> footnote text. Defaults to
#'   [hv_man_footnotes()] (the house-universal N and median/percentile
#'   footnotes). Pass `NULL` to suppress both, or compose with
#'   [hv_man_footnotes()] to override or extend — see its documentation.
#'   Symbols must be drawn from `c("*", "†", "‡", "§", "¶", "||")`. Each
#'   symbol is appended as a superscript reference mark to the table's `N`
#'   column header cell (or the first column if no `N` column is present),
#'   and its text is rendered as its own paragraph below the table, in the
#'   order given. Every element must be named (unnamed or blank-named
#'   entries raise an error); an empty list is a no-op, same as `NULL`.
#' @param abbreviations Optional named character vector, `c(ABBR =
#'   "expansion", ...)`. Rendered as one `Key:` paragraph below any
#'   footnotes, sorted alphabetically by abbreviation, abbreviation
#'   italicized, pairs separated by `"; "` — house rule 14. Every element
#'   must be named (unnamed or blank-named entries raise an error); an
#'   empty or `NULL` vector is a no-op.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [hv_man_table()] to build a compliant `flextable` first.
#'   [hv_man_footnotes()] for details on the default footnotes.
#'
#' @export
hv_man_table_save <- function(ft, file, footnotes = hv_man_footnotes(),
                              abbreviations = NULL) {
  if (!inherits(ft, "flextable"))
    stop("`ft` must be a flextable object.", call. = FALSE)
  if (!is.character(file) || length(file) != 1L || is.na(file) || !nzchar(file))
    stop("`file` must be a single non-empty file path.", call. = FALSE)
  out_dir <- dirname(file)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)

  valid_symbols <- c("*", "\u2020", "\u2021", "\u00A7", "\u00B6", "||")
  if (!is.null(footnotes) && length(footnotes) > 0) {
    fn_names <- names(footnotes)
    if (is.null(fn_names) || anyNA(fn_names) || any(!nzchar(fn_names)))
      stop("`footnotes` must be a named list (symbol -> footnote text); ",
           "every element must have a non-empty name. Valid symbols: ",
           paste(valid_symbols, collapse = " "), call. = FALSE)
    bad <- setdiff(fn_names, valid_symbols)
    if (length(bad) > 0)
      stop("Invalid footnote symbol(s): ", paste(bad, collapse = ", "),
           ". Must be one of: ", paste(valid_symbols, collapse = " "),
           call. = FALSE)
    n_col <- if ("n" %in% ft$col_keys) "n" else ft$col_keys[1]
    j <- which(ft$col_keys == n_col)
    for (sym in fn_names) {
      ft <- flextable::append_chunks(ft, i = 1, j = j, part = "header",
                                     flextable::as_sup(sym))
    }
  }

  doc <- officer::read_docx()
  doc <- flextable::body_add_flextable(doc, ft)

  if (!is.null(footnotes)) {
    for (sym in names(footnotes)) {
      sup_prop <- officer::fp_text(vertical.align = "superscript")
      note_par <- officer::fpar(
        officer::ftext(sym, prop = sup_prop),
        officer::ftext(paste0(" ", footnotes[[sym]]))
      )
      doc <- officer::body_add_fpar(doc, note_par, style = "Normal")
    }
  }

  doc <- .add_abbreviations_key(doc, abbreviations)

  print(doc, target = file)
  invisible(file)
}

.add_abbreviations_key <- function(doc, abbreviations) {
  if (is.null(abbreviations) || length(abbreviations) == 0) return(doc)
  abbr_names <- names(abbreviations)
  if (is.null(abbr_names) || anyNA(abbr_names) || any(!nzchar(abbr_names)))
    stop("`abbreviations` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)); every element must have a ",
         "non-empty name.", call. = FALSE)
  ordered <- abbreviations[order(names(abbreviations))]
  runs <- list(officer::ftext("Key: "))
  italic_prop <- officer::fp_text(italic = TRUE)
  for (i in seq_along(ordered)) {
    runs <- c(runs, list(officer::ftext(names(ordered)[i], prop = italic_prop)))
    suffix <- if (i < length(ordered)) {
      paste0(", ", ordered[i], "; ")
    } else {
      paste0(", ", ordered[i])
    }
    runs <- c(runs, list(officer::ftext(suffix)))
  }
  key_par <- do.call(officer::fpar, runs)
  officer::body_add_fpar(doc, key_par, style = "Normal")
}
