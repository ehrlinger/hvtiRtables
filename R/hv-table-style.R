#' A table style, named by its role
#'
#' The properties a table is drawn with, from the style matrix of the
#' table-styles design: section rows, fill, borders, header, count
#' column, note markers and wording, font, caption, row height, page and
#' merged cells. A style is named for what the table is for, not for a
#' journal. `"report"` is the working table of an analysis report, as
#' [hv_man_table()] has always drawn it. `"manuscript"` is the table a
#' manuscript submits: a full grid, a two-row header with the grouping
#' spanning its levels, one overall `n` column, shaded section rows
#' spanning the table, a caption, and no font of its own, so it takes the
#' font of the document it is saved into.
#'
#' Both styles follow the same house notation (medians, P values, marks),
#' which [hv_tbl_summary()] writes, so a report reads like the manuscript
#' and only the layout differs.
#'
#' @param name `"report"` (default) or `"manuscript"`.
#' @param fill The section rows' shading, one color written `"#RRGGBB"`.
#'   Default `"#CAEDFB"`. Journals differ here (one submission used
#'   `"#A5C9EB"`), so the fill is the property a study changes.
#'
#' @return A list of class `"hv_table_style"`, one element per property,
#'   for [hv_man_table()]'s `style` argument.
#'
#' @seealso [hv_man_table()], which draws a table in a style.
#'
#' @examples
#' hv_table_style("manuscript", fill = "#A5C9EB")$fill
#'
#' @export
hv_table_style <- function(name = c("report", "manuscript"),
                           fill = "#CAEDFB") {
  name <- match.arg(name)
  if (!is.character(fill) || length(fill) != 1L || is.na(fill) ||
        !grepl("^#[0-9A-Fa-f]{6}$", fill))
    stop("`fill` must be one color written \"#RRGGBB\", such as ",
         "\"#CAEDFB\".", call. = FALSE)
  props <- switch(
    name,
    report = list(
      section = "label", borders = "rules", header = "flat",
      count = "per_group", marker = "superscript",
      count_note = "Number of non-missing values.", stat_lead = "",
      font = "Times New Roman", font_size = 12, caption = "optional",
      header_bold = TRUE, row_height = NULL, keep_rows = FALSE,
      repeat_header = TRUE, page = "letter", variable = TRUE,
      merged = "none"
    ),
    manuscript = list(
      section = "spanned", borders = "grid", header = "spanned",
      count = "overall", marker = "leading",
      count_note = "Patients with non-missing data.",
      stat_lead = "Values are ", font = NA_character_,
      font_size = NA_real_, caption = "required", header_bold = TRUE,
      row_height = 300, keep_rows = TRUE, repeat_header = TRUE,
      page = "letter", variable = FALSE,
      merged = "header and section rows"
    )
  )
  structure(c(list(name = name, fill = fill), props),
            class = "hv_table_style")
}

# A style given by name or as an object.
.as_style <- function(style) {
  if (inherits(style, "hv_table_style")) return(style)
  if (is.character(style) && length(style) == 1L && !is.na(style) &&
        style %in% c("report", "manuscript"))
    return(hv_table_style(style))
  stop("`style` must be \"report\", \"manuscript\" or a style from ",
       "hv_table_style().", call. = FALSE)
}
