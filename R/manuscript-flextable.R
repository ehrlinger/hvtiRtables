#' Convert a gtsummary table into a Blackstone-compliant flextable
#'
#' Transforms a [gtsummary::tbl_summary()] (or any gtsummary table object
#' supporting [gtsummary::as_flex_table()]) into a `flextable` that complies
#' with the HVTI CORR "Table Construction for Manuscripts" rules: a single,
#' non-merged header row (no spanning parent cells over grouped columns), no
#' merged row-group section-header cells, and Times New Roman at the house
#' font size.
#'
#' `gtsummary::as_flex_table()` already emits one header row per group with
#' self-contained labels (e.g. `"B\nN = 45"`) rather than a merged spanning
#' header. The one remaining merge — a full-width `gridSpan` on the
#' `modify_table_body(groupname_col = ...)` section-header row — is removed
#' with [flextable::merge_none()], which un-merges every merged region back
#' into individual cells (content stays in the top-left cell of the former
#' merge, the rest become empty). This satisfies the "format the table as
#' flat as possible ... simple non-merged column titles" rule.
#'
#' Rounding, `%`-free percentage cells, and `±`-without-spaces formatting
#' are the caller's responsibility via the `statistic`/`digits` arguments to
#' [gtsummary::tbl_summary()] — see the package README for a worked example
#' using [gtsummary::style_sigfig()] for 2-significant-figure rounding.
#'
#' @param tbl A `gtsummary` table object (must support `as_flex_table()`).
#' @param font Font family. Default `"Times New Roman"` (house rule).
#' @param font_size Font size in points. Default `12`; pass `11` for wide
#'   tables, per house rule 5. No other values are permitted.
#' @param digits Kept for interface symmetry with future callers; currently
#'   unused (rounding is controlled upstream via `tbl_summary(digits = ...)`).
#'   Reserved so a future version can enforce sig-fig rounding centrally
#'   without a breaking signature change.
#'
#' @return A `flextable` object with a single header row and no merged
#'   cells, ready for [save_manuscript_table()].
#'
#' @seealso [save_manuscript_table()] to write the result to a compliant
#'   `.docx` with footnotes and an abbreviation key.
#'
#' @export
manuscript_flextable <- function(tbl, font = "Times New Roman", font_size = 12,
                                 digits = 2) {
  if (!inherits(tbl, "gtsummary"))
    stop("`tbl` must be a gtsummary table object.", call. = FALSE)
  if (!is.numeric(font_size) || length(font_size) != 1L || !(font_size %in% c(11, 12)))
    stop("`font_size` must be 11 or 12 (house rule: 12pt, 11pt permitted for wide tables).",
         call. = FALSE)

  ft <- gtsummary::as_flex_table(tbl)
  ft <- flextable::merge_none(ft)
  ft <- flextable::font(ft, fontname = font, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")

  ft
}
