#' Build a gtsummary table from a SAS %summarytable-style grouped variable list
#'
#' Thin wrapper over [gtsummary::tbl_summary()] modeled on the interface
#' biostats team members already know from the `%summarytable` SAS macro:
#' a grouped, ordered variable list (`groups`, the macro's `LIST=`
#' equivalent) and variable-type buckets (`continuous`/`binary`/
#' `categorical`, the `CON1=`/`CAT1=`/`CAT2=` equivalents), rather than
#' gtsummary's own tidyselect-based interface. Returns a plain `gtsummary`
#' object, ready for [hv_man_table_jtcvs()].
#'
#' Every continuous variable is summarized as
#' `median (P<low>, P<high>)` using a blanket non-parametric test
#' (Wilcoxon rank-sum for 2 groups, Kruskal-Wallis for 3+) — this
#' function does not classify variables as Gaussian/non-Gaussian the way
#' `%summarytable` does; that is `gtsummary::add_p()`'s own default
#' continuous test already. `percentiles` defaults to the house
#' convention documented in [hv_man_footnotes()] (15th/85th),
#' overridable per study (`%summarytable` equivalent: `PP=`).
#'
#' The returned object carries two attributes for [hv_man_table_jtcvs()]:
#' `hv_stat_label`, the percentile-aware sub-header text
#' (`"No. (%) or Median (<low>th, <high>th percentile)"`), and
#' `hv_trailing`, a named character vector ready to pass as
#' [hv_man_table_jtcvs()]'s `trailing` argument when `compare` produced a
#' comparison column (`NULL` when `compare = "none"`).
#'
#' @param data A data frame.
#' @param by Grouping variable name as a string (`%summarytable` `CLASS=`
#'   equivalent), or `NULL` for a single ungrouped "Overall" column.
#' @param groups Named list, section label -> variable names in display
#'   order (`%summarytable` `LIST=` equivalent), e.g.
#'   `list(Demography = c("age", "female"), Symptoms = c("nyha"))`. Every
#'   variable named here must appear in exactly one of `continuous`,
#'   `binary`, or `categorical`, and every classified variable must
#'   appear in `groups`.
#' @param continuous Character vector of continuous variable names
#'   (`%summarytable` `CON1=` equivalent), summarized as
#'   `median (P<low>, P<high>)`.
#' @param binary Character vector of 0/1 variable names (`%summarytable`
#'   `CAT1=` equivalent), summarized as `n (%)` on a single row.
#' @param categorical Character vector of multi-level variable names
#'   (`%summarytable` `CAT2=` equivalent), summarized as `n (%)` per
#'   level. Ordinal variables belong here too; this function does not
#'   run a trend test (`%summarytable`'s `ORD1=` distinction is not
#'   preserved).
#' @param compare One of `"pvalue"` (default), `"smd"`, `"both"`, or
#'   `"none"`. Ignored (treated as `"none"`) when `by` is `NULL`, since
#'   there is nothing to compare. `%summarytable` `PVALUES=`/`ASD=`
#'   equivalent.
#' @param percentiles Numeric vector of length 2, the low/high percentile
#'   pair for continuous summaries. Default `c(15, 85)`, the
#'   [hv_man_footnotes()] house convention (`%summarytable` `PP=`
#'   equivalent).
#'
#' @return A `gtsummary` object, ready for [hv_man_table_jtcvs()]. See
#'   Details for the `hv_stat_label`/`hv_trailing` attributes.
#'
#' @seealso [hv_man_table_jtcvs()] to render the result.
#'   [hv_man_footnotes()] for the percentile-footnote house convention.
#'
#' @examples
#' hv_tbl_summary(
#'   mtcars,
#'   groups = list(Engine = c("mpg", "cyl")),
#'   continuous = "mpg",
#'   categorical = "cyl"
#' )
#'
#' @export
hv_tbl_summary <- function(data, by = NULL, groups,
                           continuous = character(0),
                           binary = character(0),
                           categorical = character(0),
                           compare = c("pvalue", "smd", "both", "none"),
                           percentiles = c(15, 85)) {
  compare <- match.arg(compare)

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!is.list(groups) || is.null(names(groups)) ||
        any(!nzchar(names(groups))))
    stop("`groups` must be a named list, e.g. ",
         "list(Demography = c(\"age\")).", call. = FALSE)
  if (!is.numeric(percentiles) || length(percentiles) != 2L)
    stop("`percentiles` must be a numeric vector of length 2, ",
         "e.g. c(15, 85).", call. = FALSE)

  vars <- unlist(groups, use.names = FALSE)
  if (any(duplicated(vars)))
    stop("Variable(s) appear in more than one `groups` section: ",
         paste(unique(vars[duplicated(vars)]), collapse = ", "),
         call. = FALSE)

  missing_vars <- setdiff(vars, names(data))
  if (length(missing_vars) > 0)
    stop("Variable(s) not found in `data`: ",
         paste(missing_vars, collapse = ", "), call. = FALSE)

  classified <- c(continuous, binary, categorical)
  unclassified <- setdiff(vars, classified)
  if (length(unclassified) > 0)
    stop("Variable(s) in `groups` not classified into `continuous`, ",
         "`binary`, or `categorical`: ",
         paste(unclassified, collapse = ", "), call. = FALSE)
  extra <- setdiff(classified, vars)
  if (length(extra) > 0)
    stop("Variable(s) classified but not present in `groups`: ",
         paste(extra, collapse = ", "), call. = FALSE)

  p_lo <- percentiles[1]
  p_hi <- percentiles[2]
  cont_stat <- sprintf("{N_obs} ||| {median} ({p%s}, {p%s})", p_lo, p_hi)

  cat_stat <- "{N_obs} ||| {n} ({p}%)"

  statistic <- stats::setNames(
    as.list(c(
      rep(cont_stat, length(continuous)),
      rep(cat_stat, length(binary) + length(categorical))
    )),
    c(continuous, binary, categorical)
  )
  type <- stats::setNames(
    as.list(c(
      rep("continuous", length(continuous)),
      rep("dichotomous", length(binary)),
      rep("categorical", length(categorical))
    )),
    c(continuous, binary, categorical)
  )

  section_map <- stats::setNames(rep(names(groups), lengths(groups)), vars)

  # gtsummary's default N/n formatter inserts thousands separators
  # ("4,190"), but both real example tables examined during design
  # (summarytable_overall.docx, summarytable_stratified_grp_res.docx)
  # show plain digits ("7948", "4190", "3758") — verified empirically
  # during planning that tbl_summary()'s default digits= would otherwise
  # silently comma-format any N >= 1000, which both real example tables
  # actually reach. Force plain digits for N_obs and n explicitly.
  no_comma <- gtsummary::label_style_number(big.mark = "")
  tbl <- gtsummary::tbl_summary(
    data,
    by = if (is.null(by)) NULL else gtsummary::all_of(by),
    include = gtsummary::all_of(vars),
    statistic = statistic, type = type, missing = "no",
    digits = list(
      gtsummary::everything() ~ list(N_obs = no_comma, n = no_comma)
    )
  )
  tbl <- gtsummary::modify_table_body(
    tbl,
    function(tb) { tb$groupname_col <- unname(section_map[tb$variable]); tb }
  )

  attr(tbl, "hv_stat_label") <- sprintf(
    "No. (%%) or Median (%sth, %sth percentile)", p_lo, p_hi
  )
  tbl
}
