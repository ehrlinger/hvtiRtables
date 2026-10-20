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
#' Every style is written on a US Letter page. A report table with three
#' or more statistic columns, such as an Overall column and two groups, is
#' written on a landscape page: with a `No.` column beside each, it does
#' not fit a portrait one. A manuscript table turns only on width, since
#' it has one overall `n` column: Overall, two groups and a P value come
#' to 6.5 inches and stay portrait. Any table wider than a portrait page's
#' text block (6.53 inches on US Letter) is written landscape. A table
#' wider than landscape's (9.0 inches), as a `continuous_stat = "both"`
#' table with an Overall column can be, has its columns narrowed in
#' proportion to fit; the font size is not changed.
#'
#' In every style the saver drops the "Variable" column
#' [hv_tbl_summary()]'s `show_variable` adds for the report view before
#' the page is fitted, so it never reaches Word and never widens the page.
#' [hv_man_table_display()] keeps it, for the report.
#'
#' @section Common mistakes:
#' **"A manuscript table needs `caption` ..."** The table is in the
#' manuscript style, which requires a caption so the title is written with
#' the table. Pass
#' `caption = "Table 1. ..."`; a report table takes one optionally.
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
#'   count column only when the table has no such column. On a table
#'   that compares its groups, `†` also marks the p-value and
#'   standardized-difference headers, because the note names the tests
#'   behind the p-values and says what the difference is. Every other
#'   symbol goes on the table's count-column header cell (a column named
#'   `n`, else the first `n_stat_<k>` column [hv_man_table()] creates when
#'   it splits an [hv_tbl_summary()] table, else the first column). In a
#'   manuscript table the dagger goes on the grouping's spanning cell and
#'   `*` on its `n` column. Each text is rendered as its own paragraph
#'   below the table, in the order given.
#'   Every element must be named (unnamed or blank-named
#'   entries raise an error) and every text must be a single non-empty
#'   string (`NULL`, `NA`, a number, or a multi-element vector raise an
#'   error, since each writes a dangling marker); an empty list is a
#'   no-op, same as `NULL`. (`%summarytable` `ADDFN=` equivalent;
#'   `PRINTFN=1`'s house block is [hv_man_footnotes()]).
#' @param abbreviations Optional named character vector, `c(ABBR =
#'   "expansion", ...)`. A table with a confidence-interval column
#'   (`compare = "both"`) adds `CI` unless you define it yourself.
#'   Rendered as one `Key:` paragraph below any
#'   footnotes, sorted alphabetically by abbreviation, abbreviation
#'   italicized, pairs separated by `"; "` (house rule 14). Every element
#'   must be named (unnamed or blank-named entries raise an error); an
#'   empty or `NULL` vector is a no-op.
#' @param caption The table's caption, written in bold on its own line
#'   above the table. A manuscript table requires one, so it is written
#'   with the table and not typed in later; a report table takes one when
#'   given and writes none otherwise.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
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
                              abbreviations = NULL, caption = NULL, ...) {
  use_default_footnotes <- missing(footnotes)
  .check_sas_args(list(...), "hv_man_table_save")
  .check_flextable(ft)
  .check_not_display(ft)
  .check_file(file)
  style <- .table_style(ft)
  .check_caption(caption, style)
  ft <- .drop_variable_column(ft)
  if (use_default_footnotes) footnotes <- .default_footnotes(ft)
  # Hoisted out of .add_abbreviations_key() so it fires at entry
  # rather than mid-render: no partial .docx on a bad argument.
  .check_abbreviations(abbreviations)
  abbreviations <- .with_table_abbreviations(ft, abbreviations)

  footnotes <- .resolve_footnotes(ft, footnotes)
  ft <- .mark_header(ft, footnotes)

  fit <- .fit_page(ft, landscape = .is_wide(ft))
  ft <- fit$ft

  doc <- officer::read_docx()
  font <- .table_font(ft)
  if (!is.null(caption))
    doc <- officer::body_add_fpar(doc, officer::fpar(officer::ftext(
      caption, prop = .note_prop(font, bold = TRUE)
    )), style = "Normal")
  doc <- flextable::body_add_flextable(doc, ft)

  leading <- identical(style$marker, "leading")
  for (sym in names(footnotes)) {
    doc <- officer::body_add_fpar(
      doc, .runs_fpar(.note_runs(sym, footnotes[[sym]], leading), font),
      style = "Normal"
    )
  }

  doc <- .add_abbreviations_key(doc, abbreviations, font)
  doc <- .page_section(doc, fit$landscape)

  print(doc, target = file)
  invisible(file)
}

# Three statistic columns (an Overall column and two groups, say) each
# with its No. column overflow a portrait page; Word clips the right
# edge rather than wrapping.
.is_wide <- function(ft) {
  sum(grepl("^(hv_median_)?stat_[0-9]+$", ft$col_keys)) >= 3L
}

# US Letter for every style (design question 4), with the margins the
# A4 template had, 1417 twips (about 1 in) each side. The template's own
# page is A4, so the section is set whatever the orientation.
.letter <- c(width = 12240, height = 15840, margin = 1417)

# Inches between the margins.
.text_width <- function(landscape) {
  side <- if (landscape) .letter[["height"]] else .letter[["width"]]
  (side - 2 * .letter[["margin"]]) / 1440
}

# Fit a table to the page. Column widths add up past a portrait page once
# a table has a median column per group, a Variable column or several
# trailing columns, and gtsummary autofits each median column to its long
# header. Turn the page when the table does not fit portrait (or when the
# caller already wants landscape); narrow every column in proportion, not
# the house font, when it does not fit landscape either. Landscape alone
# used to clip the label and p-value columns of a 13-inch table.
.fit_page <- function(ft, landscape = FALSE) {
  wide <- sum(ft$body$colwidths)
  # Narrowed to 0.01 in inside the margins: Word stores each column in
  # whole twips, and rounding every column up could otherwise put the
  # grid a twip or two past the text block.
  room <- .text_width(landscape = TRUE) - 0.01
  if (wide > room)
    ft <- flextable::width(
      ft, j = ft$col_keys, width = ft$body$colwidths * room / wide
    )
  list(ft = ft, landscape = landscape || wide > .text_width(landscape = FALSE))
}

# officer swaps width and height itself for a landscape orientation.
.page_section <- function(doc, landscape) {
  twip <- 1 / 1440
  mar <- .letter[["margin"]] * twip
  officer::body_set_default_section(doc, officer::prop_section(
    page_size = officer::page_size(
      width = .letter[["width"]] * twip,
      height = .letter[["height"]] * twip,
      orient = if (landscape) "landscape" else "portrait"
    ),
    page_margins = officer::page_mar(
      bottom = mar, top = mar, right = mar, left = mar,
      header = 708 * twip, footer = 708 * twip, gutter = 0
    )
  ))
}

# The caller's key plus the table's own: CI, once a confidence-interval
# column is shown, because the table cannot be read without it. The
# caller's definition wins when they give one.
.with_table_abbreviations <- function(ft, abbreviations) {
  own <- attr(ft, "hv_abbreviations", exact = TRUE)
  c(abbreviations, own[setdiff(names(own), names(abbreviations))])
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
  runs <- .key_runs(abbreviations)
  if (is.null(runs)) return(doc)
  officer::body_add_fpar(doc, .runs_fpar(runs, font), style = "Normal")
}

# -- Shared with hv_man_table_display() -----------------------------------
#
# The saver writes the notes as paragraphs below the table (the CORR
# layout requires it); the display helper writes them as footer lines.
# Both build them from these functions, so the two cannot drift.

# Validate `footnotes` and check it against the marks hv_man_table() put
# on body cells. Returns it unchanged.
.resolve_footnotes <- function(ft, footnotes) {
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
               "entry text, e.g. \"Values are median [P15, P85].\"")
      )
  }
  # hv_man_table() put these symbols on body cells, each meaning one
  # thing (symbol -> text). A missing entry leaves the mark unexplained;
  # a different text under the same symbol would explain it wrongly.
  body_marks <- attr(ft, "hv_body_marks", exact = TRUE)
  for (sym in names(body_marks)) {
    if (!identical(footnotes[[sym]], body_marks[[sym]]))
      stop("The table marks cells with ", sym, " for \"",
           body_marks[[sym]], "\", so `footnotes` must carry ", sym,
           " with that text. Give any note of your own another symbol.",
           call. = FALSE)
  }
  footnotes
}

# Superscript each footnote symbol onto its header cells. A symbol
# already on body cells needs no header mark.
.mark_header <- function(ft, footnotes) {
  body_marks <- attr(ft, "hv_body_marks", exact = TRUE)
  for (sym in setdiff(names(footnotes), names(body_marks))) {
    cells <- .footnote_cells(ft, sym)
    for (i in unique(cells$i))
      ft <- flextable::append_chunks(ft, i = i, j = cells$j[cells$i == i],
                                     part = "header", flextable::as_sup(sym))
  }
  ft
}

# The header cells, as (row, column), one footnote symbol attaches to.
# Every mark goes on the first header row, which is the visible cell of
# any column merged down, except in the describe layout, where each
# group's name spans its pair in row 1 and row 2 names the count and
# the statistic: their marks go on row 2.
.footnote_cells <- function(ft, sym) {
  j <- which(ft$col_keys %in% .footnote_cols(ft, sym))
  i <- rep(1L, length(j))
  pairs <- attr(ft, "hv_pairs", exact = TRUE)
  i[ft$col_keys[j] %in% unlist(pairs)] <- 2L
  data.frame(i = i, j = j)
}

# The style a table was drawn in. A flextable that did not come from
# hv_man_table() carries none and is a report table.
.table_style <- function(ft) {
  attr(ft, "hv_style", exact = TRUE) %||% hv_table_style("report")
}

# The manuscript's caption is part of the table, so it is written with
# it rather than typed in later; a report's is optional.
.check_caption <- function(caption, style) {
  if (is.null(caption)) {
    if (identical(style$caption, "required"))
      stop("A manuscript table needs `caption`, such as \"Table 1. ",
           "Baseline characteristics\": it is written with the table, ",
           "not typed in later.", call. = FALSE)
    return(invisible(NULL))
  }
  .check_string(caption, "caption")
}

# One note line as runs. The report superscripts the symbol and spaces
# it from the text; the manuscript begins the line with the plain
# symbol, as the submissions did: "*Patients with non-missing data."
.note_runs <- function(sym, text, leading = FALSE) {
  if (leading)
    return(data.frame(text = paste0(sym, text), sup = FALSE, italic = FALSE,
                      stringsAsFactors = FALSE))
  data.frame(text = c(sym, paste0(" ", text)), sup = c(TRUE, FALSE),
             italic = FALSE, stringsAsFactors = FALSE)
}

# The abbreviation key as runs, sorted by abbreviation: "Key: ", then
# each abbreviation in italics followed by ", definition; ". NULL when
# there is nothing to key.
.key_runs <- function(abbreviations) {
  if (is.null(abbreviations) || length(abbreviations) == 0) return(NULL)
  ordered <- abbreviations[order(names(abbreviations))]
  n <- length(ordered)
  suffix <- paste0(", ", unname(ordered), c(rep("; ", n - 1L), ""))
  text <- c("Key: ", as.vector(rbind(names(ordered), suffix)))
  data.frame(text = text, sup = FALSE,
             italic = c(FALSE, rep(c(TRUE, FALSE), n)),
             stringsAsFactors = FALSE)
}

# Runs as a Word paragraph, in the table's font.
.runs_fpar <- function(runs, font) {
  do.call(officer::fpar, lapply(seq_len(nrow(runs)), function(k) {
    prop <- if (runs$sup[k]) {
      .note_prop(font, "superscript")
    } else if (runs$italic[k]) {
      .note_prop(font, italic = TRUE)
    } else {
      .note_prop(font)
    }
    officer::ftext(runs$text[k], prop = prop)
  }))
}

# Runs as a flextable paragraph, for a footer line.
.runs_paragraph <- function(runs) {
  do.call(flextable::as_paragraph, lapply(seq_len(nrow(runs)), function(k) {
    if (runs$sup[k]) {
      flextable::as_sup(runs$text[k])
    } else if (runs$italic[k]) {
      flextable::as_i(runs$text[k])
    } else {
      flextable::as_chunk(runs$text[k])
    }
  }))
}

# A saved table is a manuscript table: the Variable column
# hv_tbl_summary(show_variable = TRUE) adds is for the report view
# (hv_man_table(), hv_man_table_display()) and never reaches Word. Dropped
# before the page is fitted, so the width and the orientation are the
# manuscript table's.
.drop_variable_column <- function(ft) {
  if (!"hv_variable" %in% ft$col_keys) return(ft)
  flextable::delete_columns(ft, j = "hv_variable")
}

# A display copy carries its notes as footer rows inside the table, which
# the Word layout forbids; the saver writes them below the table itself.
.check_not_display <- function(ft) {
  if (isTRUE(attr(ft, "hv_display", exact = TRUE)))
    stop("`ft` is a display copy from hv_man_table_display(), with its ",
         "notes as rows inside the table. Pass the flextable it was made ",
         "from instead.", call. = FALSE)
  invisible(NULL)
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
  if ("hv_n" %in% ft$col_keys) return("hv_n")
  if ("n" %in% ft$col_keys) return("n")
  n_stat <- grep("^n_stat_[0-9]+$", ft$col_keys, value = TRUE)
  if (length(n_stat) > 0L) return(n_stat[1])
  ft$col_keys[1]
}

# TRUE when the dagger note also explains the comparison column: it names
# the tests behind the p-values, or defines the standardized difference.
.compare_noted <- function(ft) {
  !is.null(attr(ft, "hv_test_note", exact = TRUE)) ||
    !is.null(attr(ft, "hv_smd", exact = TRUE))
}

# Header cells one footnote symbol attaches to. The dagger describes the
# statistic, so it marks every column that holds one: on the count
# column it claimed the "No." header was a median.
.footnote_cols <- function(ft, sym) {
  # Each group in the describe layout has its own count, so every count
  # carries the count's mark and every statistic the dagger. The columns
  # are the groups the table was built with (hv_pairs), not a stat_<k>
  # pattern: the deprecated wrapper takes any column as a group.
  pairs <- attr(ft, "hv_pairs", exact = TRUE)
  if (!is.null(pairs)) {
    if (identical(sym, "*")) return(pairs$n)
    if (!identical(sym, "\u2020")) return(pairs$n[1])
    cols <- pairs$stat
    if (.compare_noted(ft))
      cols <- c(cols, intersect("hv_compare_col", ft$col_keys))
    return(cols)
  }
  if (identical(sym, "\u2020")) {
    # A spanned header names the grouping once, above its levels, and
    # the statistic note belongs on that name.
    if (identical(attr(ft, "hv_style", exact = TRUE)$header, "spanned")) {
      disp <- grep("^disp_stat_[0-9]+$", ft$col_keys, value = TRUE)
      group <- setdiff(disp, "disp_stat_0")
      cols <- if (length(group) > 0L) group[1] else disp[1]
      # The note also names the tests behind the p-values, so the
      # comparison header carries the dagger too.
      if (.compare_noted(ft))
        cols <- c(cols, intersect("hv_compare_col", ft$col_keys))
      return(cols)
    }
    stat <- grep("^stat_[0-9]+$", ft$col_keys, value = TRUE)
    # The dagger note also names the tests behind the p-values, so the
    # p-value header carries it too.
    if (!is.null(attr(ft, "hv_test_note", exact = TRUE)))
      stat <- c(stat, intersect("p.value", ft$col_keys))
    if (!is.null(attr(ft, "hv_smd", exact = TRUE)))
      stat <- c(stat, intersect("estimate", ft$col_keys))
    if (length(stat) > 0L) return(stat)
  }
  .footnote_col(ft)
}
