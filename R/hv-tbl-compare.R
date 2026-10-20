#' Join a comparison column computed elsewhere onto a summary table
#'
#' Adds one column to a table from [hv_tbl_summary()], holding a value you
#' computed yourself for each variable: typically the standardized
#' difference `%summarytable` printed, which comes from the `%stddiff`
#' macro and is not the number [hv_tbl_summary()]'s `compare = "smd"`
#' gives. `hvtiRpropensity::ps_stddiff()` is the R port of `%stddiff`;
#' this function is how its output reaches the table, without hvtiRtables
#' depending on hvtiRpropensity.
#'
#' Each value goes on its variable's first row, as `%summarytable` laid it
#' out: beside the label of a categorical variable, not on every level.
#' The column is placed rightmost, after any `compare` column, so
#' `compare = "pvalue"` followed by this function puts the p-value and
#' the standardized difference side by side. Call it again for a further
#' column. [hv_man_table()] shows the column directly;
#' The manuscript style shows it too, from the table's `hv_trailing`
#' attribute, which this function extends.
#'
#' The values are shown exactly as given, so format them first, for
#' example `sprintf("%.1f", 100 * d)` for a difference as a percentage.
#' A variable missing from `values` is left blank.
#'
#' @section Common mistakes:
#' **"`values` must be a character vector named by variable ..."**
#' Numbers are not formatted for you. Convert them with [sprintf()] or
#' [format()], and name each element by the variable's column name, the
#' name in `groups`, not its label.
#'
#' **"`values` names variable(s) not in the table: ..."** A name that
#' matches no variable would silently show nothing. Usually a typo, or a
#' variable dropped from `groups`.
#'
#' @param tbl A `gtsummary` object, normally from [hv_tbl_summary()].
#' @param values Named character vector: variable name -> the text to
#'   show on that variable's first row.
#' @param label The column header, e.g. `"Std. Diff. (%)"`.
#'
#' @return `tbl` with the column added and its `hv_trailing` attribute
#'   extended by the new column.
#'
#' @seealso [hv_tbl_summary()], whose `compare` argument computes a
#'   p-value and gtsummary's generic standardized difference.
#'
#' @examples
#' tbl <- hv_tbl_summary(
#'   gtsummary::trial, by = "trt",
#'   groups = list(Demography = c("age", "grade")),
#'   continuous = "age", categorical = "grade",
#'   compare = "pvalue", show_variable = FALSE
#' )
#' # Standardized differences computed elsewhere, e.g. by
#' # hvtiRpropensity::ps_stddiff(), as proportions.
#' d <- c(age = 0.031, grade = 0.120)
#' tbl <- hv_tbl_compare(
#'   tbl, stats::setNames(sprintf("%.1f", 100 * d), names(d)),
#'   label = "Std. Diff. (%)"
#' )
#' hv_man_table(tbl)
#'
#' @export
hv_tbl_compare <- function(tbl, values, label) {
  .check_gtsummary(tbl)
  tb <- tbl$table_body
  if (!is.character(values) || length(values) == 0L ||
        is.null(names(values)) || anyNA(names(values)) ||
        any(!nzchar(names(values))))
    stop("`values` must be a character vector named by variable, ",
         "e.g. c(age = \"3.1\"). Received: ", .describe(values), ".",
         call. = FALSE)
  if (anyDuplicated(names(values)))
    stop("`values` names a variable more than once: ",
         paste(unique(names(values)[duplicated(names(values))]),
               collapse = ", "), ".", call. = FALSE)
  unknown <- setdiff(names(values), tb$variable)
  if (length(unknown) > 0L)
    stop("`values` names variable(s) not in the table: ",
         paste(unknown, collapse = ", "), ".", call. = FALSE)
  .check_string(label, "label")

  k <- 1L
  while (paste0("hv_join_", k) %in% names(tb)) k <- k + 1L
  col <- paste0("hv_join_", k)

  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    first <- tb$row_type == "label"
    tb[[col]] <- ifelse(first, unname(values[tb$variable]), NA_character_)
    tb
  })
  # do.call(): a computed column name, as in .split_stat_sentinel().
  tbl <- do.call(
    gtsummary::modify_header,
    c(list(tbl), stats::setNames(list(paste0("**", label, "**")), col))
  )
  attr(tbl, "hv_trailing") <- c(attr(tbl, "hv_trailing", exact = TRUE),
                                stats::setNames(label, col))
  tbl
}
