#' Show a CORR table with its Word notes, for HTML
#'
#' Adds to a flextable from [hv_man_table()] what [hv_man_table_save()]
#' writes around it in Word, so a report can show the same table in HTML:
#' the footnote marks in the header (an asterisk on each `No.` column, a dagger
#' on the statistic columns), the footnotes, and the abbreviation key. In Word
#' the notes are paragraphs below the table; here they are footer lines,
#' since HTML has no page to put them on.
#'
#' The notes follow the table's style: a manuscript table's notes begin
#' with the plain symbol and use the submissions' wording, as they do in
#' the saved file. A manuscript table sets no font, so in HTML it takes
#' the font and size of the page around it, as in Word it takes the
#' document's.
#'
#' The one deliberate difference is the "Variable" column
#' [hv_tbl_summary()]'s `show_variable` adds: the display keeps it, as the
#' report view, while the saved table never has it.
#'
#' The marks, the note text and the key come from the same internal code
#' the saver uses, so the displayed table and the saved one cannot
#' disagree. `footnotes` resolves the same way too: left out, it is the
#' footnote block the table carries from [hv_tbl_summary()], or
#' [hv_man_footnotes()] for any other flextable. A double dagger
#' [hv_man_table()] put on a Fisher exact p-value is already on its cell
#' and is footnoted, not marked again in the header.
#'
#' The result is for display only. Save the flextable you passed in, not
#' the result: its notes are rows inside the table, which the Word layout
#' forbids, and [hv_man_table_save()] refuses it.
#'
#' @section Common mistakes:
#' **"`ft` is a display copy from hv_man_table_display() ..."** You passed
#' the result to [hv_man_table_save()]. Keep the flextable from
#' [hv_man_table()] for saving and display a copy:
#' `hv_man_table_save(ft, file)` and `hv_man_table_display(ft)`.
#'
#' **"The table marks cells with ..."** The table has a Fisher exact
#' p-value marked with a double dagger, and `footnotes` leaves it
#' unexplained or files another note under it. Omit `footnotes`, or add
#' the entry the error names.
#'
#' **Different notes in the report and in Word.** Pass the same
#' `footnotes` and `abbreviations` to both calls.
#'
#' @param ft A `flextable`, from [hv_man_table()].
#' @param footnotes Optional named list, symbol -> footnote text, exactly
#'   as for [hv_man_table_save()]. Omit it for the table's own footnotes;
#'   `NULL` shows none. A note's text may carry `^2^` or `~2~` markup, as
#'   a label does.
#' @param abbreviations Optional named character vector, abbreviation ->
#'   definition, exactly as for [hv_man_table_save()]: shown as one
#'   "Key:" line, sorted by abbreviation. A table showing a confidence
#'   interval adds `CI` unless you define it.
#'   A name or definition may carry `^2^` or `~2~` markup, as a label does.
#'
#' @return `ft` with the header marks and the footer lines added, for
#'   display.
#'
#' @seealso [hv_man_table_save()], which writes the same marks and notes
#'   to Word. [hv_man_footnotes()] for the default footnotes.
#'
#' @examples
#' ft <- hv_man_table(hv_tbl_summary(
#'   gtsummary::trial, by = "trt",
#'   groups = list(Demography = c("age", "grade")),
#'   continuous = "age", categorical = "grade", compare = "none"
#' ))
#' hv_man_table_display(ft, abbreviations = c(SD = "standard deviation"))
#'
#' @export
hv_man_table_display <- function(ft, footnotes = NULL,
                                 abbreviations = NULL) {
  use_default_footnotes <- missing(footnotes)
  .check_flextable(ft)
  .check_not_display(ft)
  style <- .table_style(ft)
  if (use_default_footnotes) footnotes <- .default_footnotes(ft)
  .check_abbreviations(abbreviations)
  abbreviations <- .with_table_abbreviations(ft, abbreviations)
  footnotes <- .resolve_footnotes(ft, footnotes)

  ft <- .mark_header(ft, footnotes)
  leading <- identical(style$marker, "leading")
  lines <- c(
    lapply(names(footnotes), function(sym) {
      .note_runs(sym, footnotes[[sym]], leading)
    }),
    list(.key_runs(abbreviations))
  )
  for (runs in Filter(Negate(is.null), lines))
    ft <- flextable::add_footer_lines(ft, values = .runs_paragraph(runs))

  if (flextable::nrow_part(ft, "footer") > 0L) {
    font <- .table_font(ft)
    if (!is.null(font))
      ft <- flextable::font(ft, fontname = font, part = "footer")
    size <- ft$body$styles$text$font.size$data
    if (length(size) > 0L && !is.na(size[1]))
      ft <- flextable::fontsize(ft, size = size[1], part = "footer")
    ft <- flextable::align(ft, align = "left", part = "footer")
  }
  if (is.na(style$font)) ft <- .document_font_html(ft)
  attr(ft, "hv_display") <- TRUE
  ft
}

# A style that sets no font takes the document's (design question 5).
# In Word that is a run with no font; in HTML flextable writes the
# missing name as font-family 'NA', which no browser has, so the browser
# fell back to its own default, a serif, and a manuscript table looked
# set in the report's Times New Roman. The class makes every run of the
# table, its footer lines included, take the page's font and size. It is
# added to the table's own HTML options, a scroll box, a class or CSS
# already set, and the table's other properties are passed back, since
# set_table_properties() resets any it is not given.
.document_font_html <- function(ft) {
  if (flextable::nrow_part(ft, "footer") > 0L) {
    ft <- flextable::font(ft, fontname = NA_character_, part = "footer")
    ft <- flextable::fontsize(ft, size = NA_real_, part = "footer")
  }
  p <- ft$properties
  html <- unclass(p$opts_html)
  html$extra_class <- c(html$extra_class, "hv-document-font")
  css <- c(html$extra_css,
           paste0(".hv-document-font span { font-family: inherit ",
                  "!important; font-size: inherit !important; }"))
  html$extra_css <- paste(css[nzchar(css)], collapse = "\n")
  flextable::set_table_properties(
    ft, layout = p$layout, width = p$width, align = p$align,
    opts_word = unclass(p$opts_word), opts_pdf = unclass(p$opts_pdf),
    opts_html = html, word_title = p$word_title,
    word_description = p$word_description
  )
}
