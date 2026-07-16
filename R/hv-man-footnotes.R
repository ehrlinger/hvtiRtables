#' The house-standard manuscript table footnotes
#'
#' Two footnotes are universal to the HVTI CORR "Table Construction for
#' Manuscripts" rules, not specific to any one study, so you don't have to
#' re-type them at every [hv_man_table_save()] call site: a `*` for the
#' non-missing-value count (house rule 8, exact wording required) and a
#' `†` explaining the `{median} ({p15}, {p85})` format used for continuous
#' variables throughout these tables. You don't need a footnote for the
#' categorical `n (%)` format; the column header text already covers it
#' (house rules 10/12).
#'
#' [hv_man_table_save()]'s `footnotes` parameter defaults to calling
#' this function, so every table gets both automatically. Override with
#' ordinary list operations, no special sentinel values needed:
#' - Suppress both: `footnotes = NULL`
#' - Change one: `modifyList(hv_man_footnotes(), list(...))` with
#'   `` `†` `` = "custom text"
#' - Add a study-specific one alongside: `c(hv_man_footnotes(), list(...))`
#'   with `` `‡` `` = "extra note"
#'
#' @return A named list with elements `` `*` `` and `` `†` ``, in the format
#'   [hv_man_table_save()]'s `footnotes` parameter expects.
#'
#' @seealso [hv_man_table_save()]
#'
#' @examples
#' hv_man_footnotes()
#' modifyList(hv_man_footnotes(), list(`†` = "custom text"))
#'
#' @export
hv_man_footnotes <- function() {
  out <- list(`*` = "Number of non-missing values.")
  out[["\u2020"]] <- "Median (15th, 85th percentile)."
  out
}
