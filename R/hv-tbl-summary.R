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
#' @section Common mistakes:
#' **"`<var>` appears in more than one of `continuous`, `binary`, and
#' `categorical`."** Each variable is classified exactly once. A 0/1
#' variable is `binary`; a multi-level factor is `categorical`.
#'
#' **"Variable(s) in `groups` not classified ..."** Every variable
#' listed in `groups` also needs a type bucket, and every classified
#' variable needs to appear in `groups`. The two lists must match.
#'
#' **"`compare = "smd"` requires exactly two groups."** A standardized
#' mean difference is defined between two groups. Use
#' `compare = "pvalue"` for three or more. If `by` is a factor with an
#' unused level, `droplevels()` is usually what you want.
#'
#' **"`by` must not also be listed in `groups`."** `by` is the
#' grouping variable being compared across, not a row to summarize.
#' Before this check existed, the combination reached `gtsummary` and
#' failed several calls later with "`names` must be `NULL` or a
#' character vector, not an empty integer vector.", a message that
#' never mentioned `by`. Remove the variable from `groups`.
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
#'   there is nothing to compare. `"smd"` and `"both"` require `by` to
#'   have exactly two groups, because a standardized mean difference is
#'   defined between two of them; they error otherwise. `"pvalue"` and
#'   `"none"` work at any number of groups. `%summarytable`
#'   `PVALUES=`/`ASD=` equivalent.
#' @param percentiles Numeric vector of length 2, the low/high percentile
#'   pair for continuous summaries, as increasing whole numbers between 0
#'   and 100. Default `c(15, 85)`, the [hv_man_footnotes()] house
#'   convention (`%summarytable` `PP=` equivalent).
#'
#' @return A `gtsummary` object, ready for [hv_man_table_jtcvs()]. See
#'   Details for the `hv_stat_label`/`hv_trailing` attributes.
#'
#' @seealso [hv_man_table_jtcvs()] to render the result.
#'   [hv_man_footnotes()] for the percentile-footnote house convention.
#'
#' @examples
#' # A baseline-characteristics table of the kind a study manuscript
#' # actually carries: demography and disease sections, compared
#' # across treatment arms.
#' hv_tbl_summary(
#'   gtsummary::trial,
#'   by = "trt",
#'   groups = list(
#'     Demography = c("age", "marker"),
#'     Disease = c("stage", "grade")
#'   ),
#'   continuous = c("age", "marker"),
#'   categorical = c("stage", "grade")
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
  .assert_type_buckets(continuous, binary, categorical)
  # `by` fails the same way `groups` variables do, in this function's
  # own words. gtsummary's own error here is unusually good, but having
  # `by` fail differently from `groups` inside one function is exactly
  # the inconsistency this contract removes.
  if (!is.null(by)) {
    .check_string(by, "by")
    if (!by %in% names(data))
      stop("Variable(s) not found in `data`: ", by, call. = FALSE)
    # `by` is compared across, not summarized as a row -- the same
    # mistake as putting a SAS %summarytable CLASS= variable into
    # LIST=. Left to gtsummary this dies several calls later with
    # "`names` must be `NULL` or a character vector, not an empty
    # integer vector.", which never mentions `by` or `groups`.
    if (by %in% unlist(groups, use.names = FALSE))
      stop("`by` must not also be listed in `groups`: `", by,
           "` is the grouping variable, not a row to summarize. ",
           "Remove it from `groups`.", call. = FALSE)
  }
  if (!is.list(groups) || is.null(names(groups)) ||
        any(!nzchar(names(groups))))
    stop("`groups` must be a named list, e.g. ",
         "list(Demography = c(\"age\")).", call. = FALSE)
  if (!is.numeric(percentiles) || length(percentiles) != 2L)
    stop("`percentiles` must be a numeric vector of length 2, ",
         "e.g. c(15, 85).", call. = FALSE)
  # gtsummary's glue tokens are `{pNN}`, so a non-integer or out-of-range
  # value silently becomes an invalid token (`{p10.5}`) and a header that
  # states percentiles the table does not actually show. Reject here
  # rather than letting it surface as an opaque gtsummary error.
  if (anyNA(percentiles) || any(percentiles != as.integer(percentiles)) ||
        any(percentiles < 0 | percentiles > 100))
    stop("`percentiles` must be whole numbers between 0 and 100, ",
         "e.g. c(15, 85).", call. = FALSE)
  if (percentiles[1] >= percentiles[2])
    stop("`percentiles` must be increasing: the low percentile must be ",
         "less than the high one, e.g. c(15, 85).", call. = FALSE)

  vars <- unlist(groups, use.names = FALSE)
  if (!is.character(vars) || anyNA(vars) || any(!nzchar(vars)))
    stop("`groups` must contain variable names as non-empty strings, ",
         "e.g. list(Demography = c(\"age\")).", call. = FALSE)
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
  # Used inside the `digits =` formula below; lintr's static analysis
  # cannot see through the formula, hence the nolint.
  # nolint start: object_usage_linter.
  no_comma <- gtsummary::label_style_number(big.mark = "")
  # nolint end
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
    function(tb) {
      tb$groupname_col <- unname(section_map[tb$variable])
      tb
    }
  )

  attr(tbl, "hv_stat_label") <- sprintf(
    "No. (%%) or Median (%sth, %sth percentile)", p_lo, p_hi
  )

  effective_compare <- if (is.null(by)) "none" else compare
  if (effective_compare == "none") {
    return(tbl)
  }

  # gtsummary::add_difference() needs exactly two groups. Left to itself
  # it fails three different ways: it throws an internal message naming
  # `add_difference()`/`tbl_summary(by)` when `by` genuinely has 3+
  # levels, throws the same for a single level, and, when `by` is a
  # factor carrying an unused level, does not throw at all but returns
  # `estimate` as NA, silently rendering an empty comparison column.
  # Count the stat_ columns gtsummary actually built rather than the
  # distinct values present, because that is what add_difference() sees:
  # an unused factor level still gets its own column.
  if (effective_compare %in% c("smd", "both")) {
    n_groups <- sum(grepl("^stat_[0-9]+$", names(tbl$table_body)))
    if (n_groups != 2L) {
      hint <- ""
      if (is.factor(data[[by]])) {
        observed <- length(unique(stats::na.omit(data[[by]])))
        if (observed < nlevels(data[[by]]))
          hint <- sprintf(
            paste0(" `%s` is a factor with %d levels but only %d appear ",
                   "in the data; droplevels() may be what you want."),
            by, nlevels(data[[by]]), observed
          )
      }
      stop(sprintf(
        paste0("`compare = \"%s\"` requires exactly two groups; ",
               "`by = \"%s\"` produced %d.%s Use `compare = \"pvalue\"` ",
               "instead."),
        effective_compare, by, n_groups, hint
      ), call. = FALSE)
    }
  }

  # Order matters for compare = "both": add_difference() must run first.
  # Called second, it overwrites `estimate` with a raw mean difference
  # instead of the standardized one, and clobbers add_p()'s `test_name`
  # to "smd". Neither path runs both calls for any other `compare` value,
  # so the order is only observable here.
  if (effective_compare %in% c("smd", "both")) {
    tbl <- gtsummary::add_difference(tbl, gtsummary::everything() ~ "smd")
  }
  if (effective_compare %in% c("pvalue", "both")) {
    tbl <- gtsummary::add_p(tbl)
  }

  tb <- tbl$table_body
  compare_col <- switch(
    effective_compare,
    pvalue = gtsummary::style_pvalue(tb$p.value, digits = 1),
    smd    = gtsummary::style_sigfig(tb$estimate),
    both   = ifelse(
      is.na(tb$p.value), NA_character_,
      ifelse(
        is.na(tb$estimate),
        gtsummary::style_pvalue(tb$p.value, digits = 1),
        sprintf(
          "%s (SMD %s)",
          gtsummary::style_pvalue(tb$p.value, digits = 1),
          gtsummary::style_sigfig(tb$estimate)
        )
      )
    )
  )
  compare_label <- switch(
    effective_compare, pvalue = "P", smd = "Std. Diff.", both = "P (SMD)"
  )

  tbl <- gtsummary::modify_table_body(
    tbl,
    function(tb) {
      tb$hv_compare_col <- compare_col
      tb
    }
  )
  attr(tbl, "hv_trailing") <- stats::setNames(compare_label, "hv_compare_col")

  tbl
}
