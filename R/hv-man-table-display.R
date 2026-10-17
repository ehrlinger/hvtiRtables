#' Show a CORR table with its Word notes, for HTML
#'
#' Adds to a flextable from [hv_man_table()] what [hv_man_table_save()]
#' writes around it in Word, so a report can show the same table in HTML:
#' the footnote marks in the header (an asterisk on each `No.` column, a dagger
#' on the statistic columns), the footnotes, and the abbreviation key. In Word
#' the notes are paragraphs below the table; here they are footer lines,
#' since HTML has no page to put them on.
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
#' **"`ft` is a JTCVS table ..."** The helper shows CORR tables. A JTCVS
#' table letters its notes, and [hv_man_table_save_jtcvs()] places them.
#'
#' **Different notes in the report and in Word.** Pass the same
#' `footnotes` and `abbreviations` to both calls.
#'
#' @param ft A `flextable`, from [hv_man_table()].
#' @param footnotes Optional named list, symbol -> footnote text, exactly
#'   as for [hv_man_table_save()]. Omit it for the table's own footnotes;
#'   `NULL` shows none.
#' @param abbreviations Optional named character vector, abbreviation ->
#'   definition, exactly as for [hv_man_table_save()]: shown as one
#'   "Key:" line, sorted by abbreviation.
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
  # A JTCVS table letters its notes and has no stat_ columns for the
  # dagger, which would land on the first n column instead.
  if (!is.null(attr(ft, "hv_header_footnotes", exact = TRUE)))
    stop("`ft` is a JTCVS table from hv_man_table_jtcvs(). ",
         "hv_man_table_display() shows CORR tables from hv_man_table(); ",
         "a JTCVS table's notes are lettered by hv_man_table_save_jtcvs().",
         call. = FALSE)
  if (use_default_footnotes) footnotes <- .default_footnotes(ft)
  .check_abbreviations(abbreviations)
  footnotes <- .resolve_footnotes(ft, footnotes)

  ft <- .mark_header(ft, footnotes)
  lines <- c(
    lapply(names(footnotes), function(sym) {
      .note_runs(sym, footnotes[[sym]])
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
  attr(ft, "hv_display") <- TRUE
  ft
}
