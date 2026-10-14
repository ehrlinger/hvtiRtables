#' Write an hv_man_table() table to a compliant .docx
#'
#' Stage 3 of the `%summarytable` split: writes the document. Replaces
#' the macro's `RTFFILE=`/`PDFFILE=` output block.
#'
#' You hand this a `flextable` (typically from [hv_man_table()]), and it
#' writes a Word document with footnotes and an abbreviation key rendered
#' as text below the table rather than embedded within it (house rules
#' 13-14). [flextable::footnote()] cannot do this for you: it renders
#' footnote text as an extra row inside the table's own `<w:tbl>` block (a
#' "footer" table part), which is exactly the compliance violation this
#' function exists to avoid. Instead, a superscript reference symbol is
#' appended to the target header cell (a normal, compliant reference
#' mark), and the footnote text itself is written as a genuine document
#' paragraph after the table via [officer::body_add_fpar()]. The table
#' itself is inserted directly (no leading blank paragraph), which keeps
#' vertical cell alignment controllable if you later reformat the
#' surrounding document to 1.5- or double-spacing. House rule 2 concerns
#' the *insertion point* in the destination document, not this function's
#' output; see the package README for the paste-in workflow.
#'
#' @section Common mistakes:
#' **"unused argument (caption)"** The CORR saver writes no caption.
#' Only [hv_man_table_save_jtcvs()] takes one; here the table title goes
#' in the manuscript, above the pasted table.
#'
#' **"`footnotes` must be a named list (symbol -> footnote text) ..."**
#' You passed the JTCVS shape. The two savers' `footnotes` arguments are
#' unrelated types: this one is keyed by symbol,
#' `` list(`*` = "text") ``, and [hv_man_table_save_jtcvs()]'s is keyed
#' by position, `list(list(row =, col =, text =))`. So
#' [hv_test_footnotes_jtcvs()]'s output does not belong here;
#' [hv_man_footnotes()]'s does.
#'
#' **"Invalid footnote symbol(s): ..."** Symbols are drawn from the
#' house set `* † ‡ § ¶ ||`. A letter or a digit is not
#' one of them; lettered markers are the JTCVS renderer's convention.
#'
#' **"Output directory does not exist: ..."** The `dirname()` of `file`
#' is not created for you. Run
#' `dir.create(dirname(file), recursive = TRUE)` first.
#'
#' **A hand-built footnote that misstates the table.** The automatic
#' [hv_tbl_summary()] -> [hv_man_table()] path keeps the default dagger in
#' sync. When supplying `footnotes` yourself, make its wording match the
#' statistic and percentile pair used to build the table.
#'
#' @param ft A `flextable` object, typically from [hv_man_table()].
#' @param file Output `.docx` path. The output directory (`dirname(file)`)
#'   must already exist; this function does not create it. (`%summarytable`
#'   `RTFFILE=`/`PDFFILE=` equivalent; output here is always `.docx`).
#' @param footnotes Optional named list, symbol -> footnote text. When omitted,
#'   uses the `hv_footnotes` attribute carried from [hv_tbl_summary()] through
#'   [hv_man_table()], so the dagger follows that table's `continuous_stat`
#'   and `percentiles`. Other flextables fall back to [hv_man_footnotes()]'s
#'   median/15th-85th house defaults. Pass `NULL` to suppress both, or
#'   compose with [hv_man_footnotes()] to override or extend.
#'   Symbols must be drawn from `c("*", "†", "‡", "§", "¶", "||")`. `†`
#'   describes the statistic, so it is appended as a superscript reference
#'   mark to every statistic-column header (`stat_<k>`), and to the
#'   count column only when the table has no such column. Every other
#'   symbol goes on the table's count-column header cell (a column named
#'   `n`, else the first `n_stat_<k>` column [hv_man_table()] creates when
#'   it splits an [hv_tbl_summary()] table, else the first column). Each
#'   text is rendered as its own paragraph below the table, in the order
#'   given.
#'   Every element must be named (unnamed or blank-named
#'   entries raise an error) and every text must be a single non-empty
#'   string (`NULL`, `NA`, a number, or a multi-element vector raise an
#'   error, since each writes a dangling marker); an empty list is a
#'   no-op, same as `NULL`. (`%summarytable` `ADDFN=` equivalent;
#'   `PRINTFN=1`'s house block is [hv_man_footnotes()]).
#' @param abbreviations Optional named character vector, `c(ABBR =
#'   "expansion", ...)`. Rendered as one `Key:` paragraph below any
#'   footnotes, sorted alphabetically by abbreviation, abbreviation
#'   italicized, pairs separated by `"; "` (house rule 14). Every element
#'   must be named (unnamed or blank-named entries raise an error); an
#'   empty or `NULL` vector is a no-op.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' A table with three or more statistic columns, such as an Overall
#' column and two groups, is written on a landscape page: with a `No.`
#' column beside each, it does not fit a portrait one.
#'
#' @return Invisibly, the `file` path.
#'
#' @seealso [hv_man_table()] to build a compliant `flextable` first.
#'   [hv_man_footnotes()] for details on the default footnotes.
#'
#' @examples
#' library(gtsummary)
#' tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
#' ft <- hv_man_table(tbl)
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save(ft, out, abbreviations = c(N = "sample size"))
#'
#' @export
hv_man_table_save <- function(ft, file, footnotes = NULL,
                              abbreviations = NULL, ...) {
  use_default_footnotes <- missing(footnotes)
  .check_sas_args(list(...), "hv_man_table_save")
  .check_flextable(ft)
  .check_file(file)
  if (use_default_footnotes) footnotes <- .default_footnotes(ft)
  # Hoisted out of .add_abbreviations_key() so it fires at entry
  # rather than mid-render: no partial .docx on a bad argument.
  .check_abbreviations(abbreviations)

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
    # Validated at entry, alongside the symbol check, so a footnote
    # with no usable text never reaches print(doc): the defect this
    # prevents is a written .docx, not a bad object.
    for (k in seq_along(footnotes))
      .check_footnote_text(
        footnotes[[k]], sprintf('footnotes[["%s"]]', fn_names[k]),
        paste0("A marker whose text is missing renders as a ",
               "dangling reference with nothing after it. Give the ",
               "entry text, e.g. \"Values are median (P15, P85).\"")
      )
    for (sym in fn_names) {
      j <- which(ft$col_keys %in% .footnote_cols(ft, sym))
      ft <- flextable::append_chunks(ft, i = 1, j = j, part = "header",
                                     flextable::as_sup(sym))
    }
  }

  doc <- officer::read_docx()
  doc <- flextable::body_add_flextable(doc, ft)

  font <- .table_font(ft)
  if (!is.null(footnotes)) {
    for (sym in names(footnotes)) {
      note_par <- officer::fpar(
        officer::ftext(sym, prop = .note_prop(font, "superscript")),
        officer::ftext(paste0(" ", footnotes[[sym]]), prop = .note_prop(font))
      )
      doc <- officer::body_add_fpar(doc, note_par, style = "Normal")
    }
  }

  doc <- .add_abbreviations_key(doc, abbreviations, font)
  if (.is_wide(ft)) doc <- .landscape(doc)

  print(doc, target = file)
  invisible(file)
}

# Three statistic columns (an Overall column and two groups, say) each
# with its No. column overflow a portrait page; Word clips the right
# edge rather than wrapping.
.is_wide <- function(ft) {
  sum(grepl("^stat_[0-9]+$", ft$col_keys)) >= 3L
}

# The template's own page (A4, 1417-twip margins) turned on its side,
# so only the orientation changes.
.landscape <- function(doc) {
  twip <- 1 / 1440
  officer::body_set_default_section(doc, officer::prop_section(
    page_size = officer::page_size(
      width = 11900 * twip, height = 16840 * twip, orient = "landscape"
    ),
    page_margins = officer::page_mar(
      bottom = 1417 * twip, top = 1417 * twip, right = 1417 * twip,
      left = 1417 * twip, header = 708 * twip, footer = 708 * twip,
      gutter = 0
    )
  ))
}

.default_footnotes <- function(ft) {
  footnotes <- attr(ft, "hv_footnotes", exact = TRUE)
  if (is.null(footnotes)) hv_man_footnotes() else footnotes
}

# The table's own font, read back from its first body cell, so the text
# under it matches. Without it the paragraphs fell back to the
# template's Normal style, a sans-serif under a Times New Roman table.
.table_font <- function(ft) {
  fam <- ft$body$styles$text$font.family$data
  if (length(fam) == 0L) fam <- ft$header$styles$text$font.family$data
  if (length(fam) == 0L || is.na(fam[1])) return(NULL)
  fam[1]
}

# fp_text_lite() rather than fp_text(): it sets only what is named, so
# size and colour still come from the paragraph style. fp_text() would
# also impose its own 10-point Arial defaults.
#
# Every font slot, as flextable sets them in the table: Word picks the
# slot per character, so a "±" in a footnote could otherwise fall back
# to the style's font.
.note_prop <- function(font, align = "baseline", ...) {
  font <- font %||% NA_character_
  officer::fp_text_lite(font.family = font, hansi.family = font,
                        cs.family = font, eastasia.family = font,
                        vertical.align = align, ...)
}

.add_abbreviations_key <- function(doc, abbreviations, font = NULL) {
  if (is.null(abbreviations) || length(abbreviations) == 0) return(doc)
  ordered <- abbreviations[order(names(abbreviations))]
  runs <- list(officer::ftext("Key: ", prop = .note_prop(font)))
  italic_prop <- .note_prop(font, italic = TRUE)
  for (i in seq_along(ordered)) {
    runs <- c(runs, list(officer::ftext(names(ordered)[i], prop = italic_prop)))
    suffix <- if (i < length(ordered)) {
      paste0(", ", ordered[i], "; ")
    } else {
      paste0(", ", ordered[i])
    }
    runs <- c(runs, list(officer::ftext(suffix, prop = .note_prop(font))))
  }
  key_par <- do.call(officer::fpar, runs)
  officer::body_add_fpar(doc, key_par, style = "Normal")
}

# Header cell the house footnote symbols attach to. `*` is "Number of
# non-missing values." (house rule 8), so it belongs on the N column
# when the table has one.
#
# hv_man_table() splits the "{N_nonmiss} ||| {stat}" convention into
# `n_stat_<k>` columns; without this the marker would land on the
# label column. The bare "n" case is kept for a hand-built
# flextable that names its count column that way.
.footnote_col <- function(ft) {
  if ("n" %in% ft$col_keys) return("n")
  n_stat <- grep("^n_stat_[0-9]+$", ft$col_keys, value = TRUE)
  if (length(n_stat) > 0L) return(n_stat[1])
  ft$col_keys[1]
}

# Header cells one footnote symbol attaches to. The dagger describes the
# statistic, so it marks every column that holds one: on the count
# column it claimed the "No." header was a median.
.footnote_cols <- function(ft, sym) {
  if (identical(sym, "\u2020")) {
    stat <- grep("^stat_[0-9]+$", ft$col_keys, value = TRUE)
    if (length(stat) > 0L) return(stat)
  }
  .footnote_col(ft)
}
