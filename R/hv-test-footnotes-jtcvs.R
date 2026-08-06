# gtsummary's internal test identifiers, in the order their letters are
# assigned. Canonical rather than first-appearance so two tables using the
# same set of tests get the same letters. "smd" is deliberately absent as
# a non-test: add_difference() writes it into test_name, and a
# standardized difference has no test to name.
.hv_test_labels <- c(
  wilcox.test           = "Wilcoxon rank-sum test.",
  kruskal.test          = "Kruskal-Wallis test.",
  chisq.test.no.correct = "Pearson chi-square test.",
  fisher.test           = "Fisher exact test."
)

#' Build lettered test footnotes from a gtsummary table
#'
#' The SAS `%summarytable` macro marks every p-value with a superscript
#' letter naming the test behind it. This builds those footnotes from the
#' `test_name` column [gtsummary::add_p()] records, in the format
#' [hv_man_table_save_jtcvs()]'s `footnotes` argument expects, so you do
#' not have to map test identifiers or count body rows by hand.
#'
#' Takes the `gtsummary` object rather than the `flextable`, because
#' [hv_man_table_jtcvs()] discards `test_name` when it reshapes the body.
#' The returned `row` indices are rendered body rows, counting the
#' section-header rows [hv_man_table_jtcvs()] interleaves, and are
#' therefore valid only against that renderer's output.
#'
#' Letters follow a fixed order (Wilcoxon, Kruskal-Wallis, chi-square,
#' Fisher), filtered to the tests actually used, so two tables in the same
#' manuscript that use the same tests get the same letters regardless of
#' variable order. Every row sharing a test collapses onto one letter.
#'
#' Returns an empty list when there is nothing to mark: `by = NULL`,
#' `compare = "none"`, or `compare = "smd"`, since a standardized
#' difference is not a test. An empty list concatenates and renders
#' harmlessly, so no conditional is needed at the call site.
#'
#' @details
#' With `compare = "both"` the cell reads e.g. `0.7 (SMD -0.03)` and the
#' letter marks the p-value portion of it. Note also that
#' [gtsummary::add_difference()] requires exactly two groups, so
#' `compare = "smd"` and `compare = "both"` are unavailable for a 3-group
#' table; `compare = "pvalue"` is.
#'
#' An unrecognized `test_name` (only reachable from a hand-built object
#' that passed `add_p(test = ...)`, since [hv_tbl_summary()] never sets
#' `test`) is kept, using the raw identifier as its footnote text, and
#' warned about. A marked cell whose letter has no definition would be
#' worse than an unpolished label.
#'
#' @param tbl A `gtsummary` object, normally from [hv_tbl_summary()]. Must
#'   be the same object passed to [hv_man_table_jtcvs()], since the row
#'   indices are computed from its `table_body`.
#'
#' @return A list of `list(row =, col =, text =)` entries, one per distinct
#'   test, ready to pass as [hv_man_table_save_jtcvs()]'s `footnotes`
#'   argument. `list()` when there is nothing to mark.
#'
#' @seealso [hv_man_table_save_jtcvs()], which renders the result.
#'   [hv_tbl_summary()], which produces a suitable `tbl`.
#'   [hv_man_footnotes()] for the house-universal footnotes.
#'
#' @examples
#' set.seed(5)
#' dta <- data.frame(
#'   grp = factor(rep(c("A", "B"), each = 50)),
#'   age = rnorm(100, 60, 12),
#'   sex = factor(sample(c("F", "M"), 100, replace = TRUE))
#' )
#' tbl <- hv_tbl_summary(
#'   dta, by = "grp",
#'   groups = list(Demography = c("age", "sex")),
#'   continuous = "age", categorical = "sex"
#' )
#' hv_test_footnotes_jtcvs(tbl)
#'
#' @export
hv_test_footnotes_jtcvs <- function(tbl) {
  if (!inherits(tbl, "gtsummary"))
    stop("`tbl` must be a gtsummary table object.", call. = FALSE)

  tb <- tbl$table_body
  trailing <- attr(tbl, "hv_trailing")
  col <- if (is.null(trailing)) "hv_compare_col" else names(trailing)

  if (!col %in% names(tb) || !"test_name" %in% names(tb)) return(list())

  shown <- !is.na(tb[[col]])
  if (!any(shown)) return(list())

  present <- unique(tb$test_name[shown])
  present <- present[!is.na(present) & present != "smd"]
  if (length(present) == 0) return(list())

  known <- intersect(names(.hv_test_labels), present)
  unknown <- sort(setdiff(present, names(.hv_test_labels)))
  if (length(unknown) > 0)
    warning("Unrecognized `test_name` value(s), using the raw name as the ",
            "footnote text: ", paste(unknown, collapse = ", "),
            call. = FALSE)

  tests <- c(known, unknown)
  texts <- c(unname(.hv_test_labels[known]), unknown)
  row_index <- .jtcvs_body_row_index(tb)

  lapply(seq_along(tests), function(k) {
    hit <- shown & !is.na(tb$test_name) & tb$test_name == tests[k]
    list(row = row_index[hit], col = col, text = texts[k])
  })
}
