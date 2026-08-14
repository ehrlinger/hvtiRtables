#' Convert a gtsummary table into a flextable matching HVTI CORR's table rules
#'
#' Stage 2 of the `%summarytable` split: shapes the table. The macro
#' controlled this with `STYLE=` and `PAGE=`, which have no equivalent
#' here -- house style is fixed, and the only choice is flat header
#' versus JTCVS spanning header.
#'
#' You give this a [gtsummary::tbl_summary()] (or any gtsummary table object
#' supporting [gtsummary::as_flex_table()]), and you get back a `flextable`
#' that already complies with HVTI CORR's "Table Construction for
#' Manuscripts" rules: a single, non-merged header row (no spanning parent
#' cells over grouped columns), no merged row-group section-header cells,
#' and Times New Roman at the house font size.
#'
#' `gtsummary::as_flex_table()` already emits one header row per group with
#' self-contained labels (e.g. `"B\nN = 45"`), not a merged spanning header.
#' The one remaining merge, a full-width `gridSpan` on the
#' `modify_table_body(groupname_col = ...)` section-header row, gets removed
#' with [flextable::merge_none()], which un-merges every merged region back
#' into individual cells (content stays in the top-left cell of the former
#' merge; the rest become empty). That satisfies the "format the table as
#' flat as possible ... simple non-merged column titles" rule.
#'
#' Rounding, `%`-free percentage cells, and `±`-without-spaces formatting are
#' yours to control, via the `statistic`/`digits` arguments to
#' [gtsummary::tbl_summary()]; see the package README for a worked example
#' using [gtsummary::style_sigfig()] for 2-significant-figure rounding.
#'
#' Submitting to JTCVS instead? Use [hv_man_table_jtcvs()], which builds the
#' two-row merged spanning header that journal's template expects: CORR
#' house style and JTCVS submission format want different things from the
#' same header row.
#'
#' A table from [hv_tbl_summary()] works here as well as in the JTCVS
#' renderer. That function writes each cell as `"{N_obs} ||| {stat}"`, and
#' this one splits the two apart into a flat `No.` column immediately
#' before the statistic it counts — the same two values JTCVS mode puts
#' under a merged spanning header, without the merge. House rule 8 wants
#' that non-missing count, and [hv_man_footnotes()]'s `*` footnote
#' describes it, so it is kept rather than discarded. A plain
#' [gtsummary::tbl_summary()] table carries no such convention and passes
#' through unchanged.
#'
#' @section Common mistakes:
#' **Cells read `98 ||| 46 (32, 63)`.** You are on a version before the
#' split; upgrade. `|||` is the internal separator [hv_tbl_summary()]
#' writes between the count and the statistic, never intended to reach a
#' rendered table.
#'
#' **"`tbl` was not built with the `{N_obs} ||| {stat}` convention."**
#' Only some cells carry the separator, which means `statistic` was set
#' for part of the table. Splitting would leave the rest blank, so it is
#' rejected. Either apply the convention to every variable or to none;
#' [hv_tbl_summary()] does the former for you.
#'
#' **"`font_size` must be 11 or 12."** House rule 5. Use `11` only for
#' wide tables.
#'
#' @param tbl A `gtsummary` table object (must support `as_flex_table()`).
#'   A table from [hv_tbl_summary()] is split as described above; any
#'   other `gtsummary` object renders as-is.
#' @param font Font family. Default `"Times New Roman"` (house rule).
#'   Any single non-empty string is accepted: `flextable` silently
#'   substitutes an unknown font name, so a typo would otherwise pass
#'   unnoticed, while a deliberate override is legitimate.
#' @param font_size Font size in points. Default `12`; pass `11` for wide
#'   tables, per house rule 5. No other values are permitted.
#' @param digits Kept for interface symmetry with future callers; currently
#'   unused (rounding is controlled upstream via `tbl_summary(digits = ...)`).
#'   Reserved so a future version can enforce sig-fig rounding centrally
#'   without a breaking signature change.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' @return A `flextable` object with a single header row and no merged
#'   cells, ready for [hv_man_table_save()].
#'
#' @seealso [hv_man_table_save()] to write the result to a compliant
#'   `.docx` with footnotes and an abbreviation key. [hv_man_table_jtcvs()]
#'   for the JTCVS submission format instead.
#'
#' @examples
#' library(gtsummary)
#' tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
#' ft <- hv_man_table(tbl)
#'
#' @export
hv_man_table <- function(tbl, font = "Times New Roman", font_size = 12,
                         digits = 2, ...) {
  .check_sas_args(list(...), "hv_man_table")
  .check_gtsummary(tbl)
  .check_string(font, "font")
  .check_font_size(font_size)

  tbl <- .split_stat_sentinel(tbl)
  ft <- gtsummary::as_flex_table(tbl)
  ft <- flextable::merge_none(ft)
  ft <- flextable::font(ft, fontname = font, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")

  ft
}

# TRUE when any non-NA cell of a stat column carries the "{N_obs} |||
# {stat}" convention hv_tbl_summary() applies for the JTCVS renderer.
.has_stat_sentinel <- function(tb, stat_cols) {
  for (col in stat_cols) {
    vals <- tb[[col]]
    vals <- vals[!is.na(vals)]
    if (any(grepl(" ||| ", vals, fixed = TRUE))) return(TRUE)
  }
  FALSE
}

# Split each "{N_obs} ||| {stat}" column into a flat N column and the
# statistic it counts, N immediately before its statistic.
#
# hv_man_table() previously handed such a table straight to
# as_flex_table(), which rendered the sentinel literally
# ("98 ||| 46 (32, 63)"). Stripping the N instead would have been
# smaller, but house rule 8 requires the non-missing count and
# hv_man_footnotes() ships a `*` footnote describing it, so CORR wants
# the column, just without the merged spanning header JTCVS puts over
# it.
#
# A table without the convention passes through untouched: a plain
# gtsummary object is the documented CORR path and must not gain
# invented columns.
.split_stat_sentinel <- function(tbl) {
  tb <- tbl$table_body
  stat_cols <- grep("^stat_[0-9]+$", names(tb), value = TRUE)
  if (length(stat_cols) == 0L || !.has_stat_sentinel(tb, stat_cols))
    return(tbl)

  # Rejects a table where only some cells carry the convention. Splitting
  # that leaves the rest blank -- the silent-empty failure this package
  # exists to prevent -- so it fails the same way the JTCVS renderer
  # does, through the same assertion.
  .assert_stat_convention(
    tb, stats::setNames(as.list(stat_cols), stat_cols),
    caller = "hv_man_table"
  )

  # gtsummary writes a header footnote describing each stat column,
  # built from the glue string -- so it reads "No. obs. ||| Median (15%
  # Centile, 85% Centile)" and carries the separator into the rendered
  # .docx even after the cells themselves are split. Dropped rather than
  # rewritten: hv_man_footnotes() already ships both halves as house
  # footnotes ("Number of non-missing values." and "Median (15th, 85th
  # percentile)."), so a rewrite would duplicate them. Only columns
  # whose footnote actually carries the separator are touched, so a
  # caller's own header footnote survives.
  fh <- tbl$table_styling$footnote_header
  if (is.data.frame(fh) && nrow(fh) > 0L) {
    hit <- intersect(
      stat_cols,
      fh$column[grepl(" ||| ", fh$footnote, fixed = TRUE)]
    )
    # all_of(): `columns` is tidyselect, and a bare external vector is
    # deprecated there.
    if (length(hit) > 0L)
      tbl <- gtsummary::remove_footnote_header(
        tbl, columns = gtsummary::all_of(hit)
      )
  }

  # Reversed so each inserted N column lands immediately before its own
  # statistic regardless of how many have been inserted already.
  for (col in rev(stat_cols)) {
    n_col <- paste0("n_", col)
    tbl <- gtsummary::modify_table_body(tbl, function(tb) {
      parts <- strsplit(tb[[col]], " \\|\\|\\| ")
      tb[[n_col]] <- vapply(
        parts, function(p) if (length(p) == 2L) p[1] else NA_character_,
        character(1)
      )
      tb[[col]] <- vapply(
        parts, function(p) if (length(p) == 2L) p[2] else NA_character_,
        character(1)
      )
      # Base reordering rather than dplyr::relocate(): dplyr is a
      # Suggests, and this is a core rendering path.
      keep <- setdiff(names(tb), n_col)
      at <- match(col, keep)
      tb[, append(keep, n_col, after = at - 1L), drop = FALSE]
    })
    # do.call() rather than tidyeval: `!!n_col := ` needs rlang's `:=`,
    # which this package does not import and lint_package() flags as
    # undefined, while passing the list positionally hits
    # modify_header()'s deprecated `update` argument. Splicing the named
    # list through do.call() reaches the same dynamic dots with neither
    # problem.
    tbl <- do.call(
      gtsummary::modify_header,
      c(list(tbl), stats::setNames(list("**No.**"), n_col))
    )
  }
  tbl
}
