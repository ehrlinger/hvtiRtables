#' The house-standard manuscript table footnotes
#'
#' The house footnote block the macro emitted under `PRINTFN=1`.
#'
#' Two footnotes are universal to the HVTI CORR "Table Construction for
#' Manuscripts" rules, not specific to any one study, so you don't have to
#' re-type them at every [hv_man_table_save()] call site: a `*` for the
#' non-missing-value count (house rule 8, exact wording required) and a
#' `†` explaining the statistic in each group column, e.g.
#' `"No. (%) or Median [15th, 85th percentiles]."` The categorical half is
#' part of it because the cells print `12 (39)` with no `%` sign (house
#' rules 10/12), and the flat CORR header names only the group.
#'
#' [hv_man_table_save()]'s `footnotes` parameter defaults to calling
#' this function, so every table gets both automatically. A table built by
#' [hv_tbl_summary()] and [hv_man_table()] carries its `continuous_stat` and
#' `percentiles` choices through to the saver, so its default dagger follows
#' what the table shows. Call this function directly with the same arguments
#' when composing footnotes yourself. Override with ordinary list operations,
#' no special sentinel values needed:
#' - Suppress both: `footnotes = NULL`
#' - Change one: `modifyList(hv_man_footnotes(), list(...))` with
#'   `` `†` `` = "custom text"
#' - Add a study-specific one alongside: `c(hv_man_footnotes(), list(...))`
#'   with `` `||` `` = "extra note". Avoid `‡`, `§` and `¶` on a table from
#'   [hv_tbl_summary()]: `‡` marks Fisher exact p-values there, and `§`
#'   and `¶` mark the minority statistic when a table mixes mean and
#'   median.
#'
#' @section Common mistakes:
#' **Passing the result to the JTCVS saver.** These footnotes are
#' CORR-shaped, keyed by symbol, and belong to [hv_man_table_save()].
#' [hv_man_table_save_jtcvs()] takes an unrelated type keyed by row and
#' column, and rejects this one. Its equivalent is
#' [hv_test_footnotes_jtcvs()].
#'
#' **Calling this helper with settings different from the table.** The
#' automatic [hv_tbl_summary()] -> [hv_man_table()] ->
#' [hv_man_table_save()] path stays synchronized. If you call this helper
#' yourself, pass the same `continuous_stat` and `percentiles` used to build
#' the table, or override the dagger explicitly.
#'
#' @param continuous_stat One of `"median"` (default), `"mean"`, or
#'   `"both"`. Controls whether the dagger's continuous half reads as
#'   median and percentiles or mean +/- SD. Under `"both"` it reads as
#'   mean +/- SD, because [hv_tbl_summary()] puts the medians in columns
#'   of their own whose headers name them.
#' @param percentiles Numeric vector of length 2, the increasing whole-number
#'   percentile pair named by the dagger. Default `c(15, 85)`. Used for
#'   `continuous_stat = "median"` and `"both"`; validated but not printed for
#'   `"mean"`, so the arguments share [hv_tbl_summary()]'s contract.
#'
#' @return A named list with elements `` `*` `` and `` `†` ``, in the format
#'   [hv_man_table_save()]'s `footnotes` parameter expects.
#'
#' @seealso [hv_man_table_save()]
#'
#' @examples
#' hv_man_footnotes()
#' hv_man_footnotes(continuous_stat = "mean")
#' hv_man_footnotes(continuous_stat = "both", percentiles = c(16, 84))
#' modifyList(hv_man_footnotes(), list(`†` = "custom text"))
#'
#' @export
hv_man_footnotes <- function(
  continuous_stat = c("median", "mean", "both"),
  percentiles = c(15, 85)
) {
  continuous_stat <- match.arg(continuous_stat)
  .check_percentiles(percentiles)
  out <- list(`*` = "Number of non-missing values.")
  out[["\u2020"]] <- paste0(.stat_label(continuous_stat, percentiles), ".")
  out
}

# The statistic description shared by the JTCVS sub-header
# (hv_tbl_summary()'s `hv_stat_label` attribute) and the CORR dagger
# footnote, so the two renderers describe a table in the same words.
# It names "No. (%)" because the cells carry no "%" sign (house rules
# 10/12; the SAS macro prints "12 (39)" too), so the description is the
# only place the reader learns the parenthesized number is a percent.
.stat_label <- function(continuous_stat, percentiles) {
  ordinal <- .format_ordinal(percentiles)
  median_label <- sprintf(
    "Median [%s, %s percentiles]", ordinal[1], ordinal[2]
  )
  mean_label <- "Mean\u00B1SD"
  switch(
    continuous_stat,
    median = paste("No. (%) or", median_label),
    mean = paste("No. (%) or", mean_label),
    # Under "both" the statistic columns show mean±SD; the medians sit
    # in their own column, which names itself in its header.
    both = paste("No. (%) or", mean_label)
  )
}

# The dagger note in a style's words. The manuscript style leads with
# "Values are" and lowers the statistic's capital, as the submissions
# wrote it: "Values are No. (%) or median [15th, 85th percentiles]."
.stat_note <- function(stat_label, style) {
  if (!nzchar(style$stat_lead)) return(paste0(stat_label, "."))
  paste0(style$stat_lead,
         sub(" or ([A-Z])", " or \\L\\1", stat_label, perl = TRUE), ".")
}

.format_ordinal <- function(x) {
  suffix <- rep("th", length(x))
  is_exception <- x %% 100 %in% 11:13
  suffix[!is_exception & x %% 10 == 1] <- "st"
  suffix[!is_exception & x %% 10 == 2] <- "nd"
  suffix[!is_exception & x %% 10 == 3] <- "rd"
  paste0(x, suffix)
}
