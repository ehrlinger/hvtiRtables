#' Build a gtsummary table from a SAS %summarytable-style grouped variable list
#'
#' Thin wrapper over [gtsummary::tbl_summary()] modeled on the interface
#' biostats team members already know from the `%summarytable` SAS macro:
#' a grouped, ordered variable list (`groups`, the macro's `LIST=`
#' equivalent) and variable-type buckets (`continuous`/`binary`/
#' `categorical`, the `CON3=`/`CAT1=`/`CAT2=` equivalents), rather than
#' gtsummary's own tidyselect-based interface. Returns a plain `gtsummary`
#' object, ready for [hv_man_table()].
#'
#' Continuous variables are summarized as `median [P<low>, P<high>]` by
#' default, or as mean +/- SD, or both (`continuous_stat`), and tested
#' non-parametrically (Wilcoxon rank-sum for 2 groups, Kruskal-Wallis for
#' 3+), the macro's `CON3=`. A variable you also list in `normal` is the
#' macro's `CON1=` instead: mean +/- SD, tested with one-way ANOVA.
#' `percentiles` defaults to the house convention documented in
#' [hv_man_footnotes()] (15th/85th), overridable per study
#' (`%summarytable` equivalent: `PP=`).
#'
#' The house notation: each median and percentile is shown to 2 significant
#' digits, and a value of 10 or more to the units place (`102 [63, 170]`,
#' `0.31 [0.21, 0.39]`), and a P value has no leading zero (`.013`,
#' `<.001`, `>.9`).
#'
#' When rows of one table show different statistics, the header and dagger
#' name the statistic most rows use, and the cells of the other are marked
#' instead of the row labels (the macro's `DESCLABEL=1` suffixes, such as
#' `"Age, Mean±SD"`, are gone). When more rows show mean +/- SD than a
#' median, the mean is the default and a section sign (`§`) marks the
#' median cells; otherwise a pilcrow (`¶`) marks the mean cells. Each mark
#' has its own footnote. A tie leaves the median as the default.
#'
#' Mean/SD output follows Eugene H. Blackstone's (EHB's) paired reporting
#' rule: the mean is rounded to the first-significant-digit place of the SD,
#' and the SD is rounded one place finer. When the SD begins with 1, both
#' retain one additional place. Exact ties round to even; values beyond a tie
#' round up. This applies to every group and Overall column when
#' `continuous_stat = "mean"`, and to the mean row under `"both"`. Medians and
#' percentiles follow the house notation above instead, and their exact ties
#' also round to even, as for mean +/- SD: 62.5 shows as 62, where gtsummary
#' and SAS showed 63. When an SD is zero or unavailable, no paired precision
#' can be inferred, so gtsummary's existing display is kept.
#'
#' The returned object carries these renderer attributes:
#' `hv_stat_label`, the sub-header text naming the statistics shown
#' (`"No. (%) or Median [<low>, <high> percentiles]"` by default, with
#' ordinal suffixes; it follows `continuous_stat`);
#' `hv_trailing`, a named character vector ready to pass as
#' naming the comparison columns the manuscript style shows, when `compare`
#' produced one (`NULL` when `compare = "none"`); and `hv_footnotes`,
#' the CORR footnote block that [hv_man_table()] carries into
#' [hv_man_table_save()] so the default dagger follows `continuous_stat` and
#' `percentiles` automatically. A mixed table also carries `hv_cell_marks`,
#' the symbol and variables whose cells [hv_man_table()] marks, and a table
#' built with `continuous_stat = "both"` carries `hv_median_label`.
#'
#' @section Common mistakes:
#' **"`<var>` appears in more than one of `continuous`, `binary`, and
#' `categorical`."** Each variable is classified exactly once. A 0/1
#' variable is `binary`; a multi-level factor is `categorical`.
#'
#' **"`continuous` lists `<var>`, but `<var>` is factor data ..."** The
#' bucket has to suit the data, not just be free of overlaps. A
#' non-numeric variable in `continuous` used to reach `gtsummary`,
#' which only *messages* about it, and produced a complete, correctly
#' styled table whose every statistic was `NA`.
#'
#' **"`binary` lists `<var>`, but `<var>` has ..."** `binary` renders
#' one `n (%)` row, so it takes at most two distinct values and needs
#' an unambiguous event value: logical, `0`/`1`, or `Yes`/`No`. A
#' three-level factor, or a two-level one like `F`/`M`, belongs in
#' `categorical`.
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
#'   `list(Demography = c("age", "female"), Symptoms = c("nyha"))`. Each
#'   section must name at least one variable; a section holding
#'   `character(0)` is an error, not an empty section. Every
#'   variable named here must appear in exactly one of `continuous`,
#'   `binary`, or `categorical`, and every classified variable must
#'   appear in `groups`.
#' @param continuous Character vector of continuous variable names
#'   (`%summarytable` `CON3=` equivalent), summarized as set by
#'   `continuous_stat`. Variables the macro classified as `CON1=`
#'   (mean +/- SD, one-way ANOVA) or `CON2=` (median with min and max)
#'   belong here too; list `CON1=` variables in `normal` as well to keep
#'   the macro's mean +/- SD and ANOVA. Each named column must be
#'   numeric.
#' @param binary Character vector of 0/1 variable names (`%summarytable`
#'   `CAT1=` equivalent), summarized as `n (%)` on a single row. Each
#'   named column must have at most 2 distinct non-`NA` values, and
#'   must be logical, `0`/`1`, or `Yes`/`No` data, so that the "event"
#'   the single row counts is unambiguous. Anything else belongs in
#'   `categorical`, which shows every level. The event is the `TRUE`,
#'   `1`, or `Yes` side, and is stated to `gtsummary` explicitly rather
#'   than inferred, so columns read from SAS with `haven::read_sas()`
#'   summarize the same as their plain-vector equivalents.
#' @param categorical Character vector of multi-level variable names
#'   (`%summarytable` `CAT2=` equivalent), summarized as `n (%)` per
#'   level. No type rule applies: factors, characters, and
#'   small-integer codes are all accepted. Ordinal variables belong
#'   here too; this function does not run a trend test
#'   (`%summarytable`'s `ORD1=` distinction is not preserved).
#' @param compare One of `"pvalue"` (default), `"smd"`, `"both"`, or
#'   `"none"`. Ignored (treated as `"none"`) when `by` is `NULL`, since
#'   there is nothing to compare. `"smd"` and `"both"` require `by` to
#'   have exactly two groups, because a standardized mean difference is
#'   defined between two of them; they error otherwise. `"pvalue"` and
#'   `"none"` work at any number of groups. `%summarytable`
#'   `PVALUES=` equivalent, and `ASD=` only in part: the `"smd"`
#'   number is gtsummary's generic standardized mean difference
#'   ([gtsummary::add_difference()]), a proportion computed alike for
#'   every continuous variable. `%summarytable`'s column came from the
#'   `%stddiff` macro, which treats non-Gaussian and ordinal variables
#'   differently and prints a percentage, so the two disagree for those
#'   variables (by 30% on one skewed test variable). To show `%stddiff`'s
#'   number, compute it with `hvtiRpropensity::ps_stddiff()` and add it
#'   with [hv_tbl_compare()], beside `compare = "pvalue"` if wanted.
#' @param percentiles Numeric vector of length 2, the low/high percentile
#'   pair for continuous summaries, as increasing whole numbers between 0
#'   and 100. Default `c(15, 85)`, the [hv_man_footnotes()] house
#'   convention (`%summarytable` `PP=` equivalent).
#' @param overall Single `TRUE`/`FALSE`. When `TRUE` (default), prepends
#'   an Overall column across all groups (`%summarytable` `TOTALCOL=1`,
#'   the macro's default). Ignored when `by` is `NULL`, since the single
#'   column already is the overall one.
#' @param continuous_stat One of `"median"` (default), `"mean"`, or
#'   `"both"`: how continuous variables not listed in `normal` are
#'   summarized. `"median"` gives
#'   `median [P<low>, P<high>]`; `"mean"` gives mean +/- SD, with no
#'   spaces around the plus-minus sign and EHB/Blackstone paired rounding;
#'   `"both"` puts the two side by side: each group's statistic column
#'   shows mean +/- SD (or `n (%)` for a categorical row), and a median
#'   column beside it shows `median [P<low>, P<high>]`, blank on rows
#'   with no median. Both renderers lay it out the same way. Choosing
#'   one for the manuscript is then a matter of dropping a column. The
#'   test does not
#'   change with the statistic: only `normal` selects ANOVA. The CORR
#'   footnote carried through [hv_man_table()] to [hv_man_table_save()]
#'   follows this choice automatically. Placed after
#'   `overall` so calls passing `overall` by position keep working.
#' @param normal Character vector, a subset of `continuous`: the
#'   variables to treat as normally distributed (`%summarytable` `CON1=`
#'   equivalent). Each is summarized as mean +/- SD whatever
#'   `continuous_stat` says, and, under `compare = "pvalue"` or
#'   `"both"`, tested with classical (pooled-variance) one-way ANOVA,
#'   the test the macro ran. Default none. Each name must also appear in
#'   `continuous`. Placed after `continuous_stat` so positional calls
#'   keep working. To show mean +/- SD without the ANOVA, use `mean_sd`.
#' @param mean_sd Character vector, a subset of `continuous`: the
#'   variables to *display* as mean +/- SD while keeping the
#'   nonparametric test (Wilcoxon rank-sum, or Kruskal-Wallis for 3+
#'   groups). Use it for variables that are roughly symmetric in a
#'   table whose every continuous test should stay nonparametric. The
#'   display is the same as for `normal`, cell mark included when the
#'   table mixes statistics; only `normal` changes the test. A
#'   variable may appear in both, and is then tested with ANOVA.
#'   Default none. Last in the signature so positional calls keep
#'   working.
#' @param show_variable Single `TRUE`/`FALSE`. When `TRUE` (default),
#'   adds a "Variable" column beside the label holding each variable's
#'   column name in `data`, on its first row, as `%summarytable`'s
#'   report did. It belongs to the report view: [hv_man_table()] and
#'   [hv_man_table_display()] show it, while [hv_man_table_save()]
#'   always drops it and the manuscript style never shows it, so a saved
#'   table is a manuscript table whatever this says. Set `FALSE` to leave
#'   it out of the report view too.
#' @param cutexact When a binary or categorical variable is tested with
#'   Fisher's exact test rather than Pearson's chi-square (no continuity
#'   correction). The default, `"any"`, uses Fisher whenever any one
#'   group-by-level cell has an expected count below 5 (gtsummary's
#'   rule, and what the CORR team asked for). A number opts in to
#'   `%summarytable`'s `CUTEXACT=` rule, to reproduce a SAS table:
#'   Fisher when at least that percentage of cells expect fewer than 5.
#'   The macro's default was `50`; `0` makes every categorical test
#'   exact and a value above 100 makes none exact. In the CORR table
#'   each Fisher p-value is marked with a superscript double dagger,
#'   footnoted "Fisher exact test.", in every style. Used only when
#'   `compare` produces p-values. The other tests that ran are named in
#'   the dagger note instead, as "P values from the Wilcoxon rank sum test
#'   and Pearson's chi-square test.", and the CORR table puts the dagger
#'   on the p-value header too. `compare = "smd"` or `"both"` names the
#'   difference column "Std. Diff." and the same note says what it is.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' @return A `gtsummary` object, ready for [hv_man_table()].
#'   See Details for the `hv_stat_label`,
#'   `hv_trailing`, and `hv_footnotes` renderer attributes. A table whose
#'   rows mix mean and median also carries `hv_cell_marks`, a list with
#'   `symbol` (`"§"` or `"¶"`) and `variables` (the names whose cells
#'   carry it); the attribute is `NULL` otherwise. The manuscript style
#'   also reads `hv_by_label`, the grouping's name (the variable's label
#'   when the data carry one), and the hidden `hv_n` column of
#'   `table_body`, each variable's overall non-missing count.
#'
#' @seealso [hv_man_table()] to render the result. [hv_man_footnotes()] for
#'   the percentile-footnote house convention.
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
                           percentiles = c(15, 85),
                           overall = TRUE,
                           continuous_stat = c("median", "mean", "both"),
                           normal = character(0),
                           mean_sd = character(0),
                           show_variable = TRUE,
                           cutexact = "any",
                           ...) {
  .check_sas_args(list(...), "hv_tbl_summary")
  compare <- match.arg(compare)
  continuous_stat <- match.arg(continuous_stat)

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  .assert_type_buckets(continuous, binary, categorical)
  .assert_normal(normal, continuous)
  .assert_normal(mean_sd, continuous, "mean_sd")
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
  # list() is caught above (it has no names); a named-but-empty section
  # is not, and left to gtsummary it fails with "`names` must be `NULL`
  # or a character vector, not an empty integer vector." -- byte
  # identical to the base-R message the `by`-in-`groups` check above
  # exists to prevent. Plausible whenever `groups` is built
  # programmatically from a filter that returns nothing.
  empty_sections <- names(groups)[lengths(groups) == 0L]
  if (length(empty_sections) > 0)
    stop("`groups` section `", empty_sections[1], "` lists no ",
         "variables. Every section must name at least one variable, ",
         "e.g. list(", empty_sections[1], " = c(\"age\")). Drop the ",
         "empty section.", call. = FALSE)
  # gtsummary's glue tokens are `{pNN}`, so a non-integer or out-of-range
  # value silently becomes an invalid token (`{p10.5}`) and a header that
  # states percentiles the table does not actually show. Reject here
  # rather than letting it surface as an opaque gtsummary error.
  .check_percentiles(percentiles)
  if (!is.logical(overall) || length(overall) != 1L || is.na(overall))
    stop("`overall` must be TRUE or FALSE.", call. = FALSE)
  if (!is.logical(show_variable) || length(show_variable) != 1L ||
        is.na(show_variable))
    stop("`show_variable` must be TRUE or FALSE.", call. = FALSE)
  if (!identical(cutexact, "any") &&
        (!is.numeric(cutexact) || length(cutexact) != 1L ||
           is.na(cutexact) || cutexact < 0))
    stop("`cutexact` must be \"any\" or a single number from 0 up, a ",
         "percentage of cells (e.g. 50, the macro's CUTEXACT=). Received: ",
         .describe(cutexact), ".", call. = FALSE)
  # With no `by` the single column already is the overall one, so
  # `overall` is ignored there, the way `compare` is. It errored while
  # the default was FALSE; with TRUE the default, an error would break
  # every ungrouped call.

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
  # Runs last of the entry checks, since it needs every variable to
  # exist in `data`. Buckets that don't overlap can still be wrong
  # about the data they name.
  .assert_bucket_data(data, continuous, binary, categorical)

  p_lo <- percentiles[1]
  p_hi <- percentiles[2]
  ordinal <- .format_ordinal(percentiles)
  # {N_nonmiss}, not {N_obs}: the N column is footnoted "Number of
  # non-missing values." (house rule 8), and {N_obs} counts every row,
  # missing ones included. The SAS tables count non-missing (bsa shows
  # 7947 of 7948), so {N_obs} silently overstated n for any variable
  # with missing data.
  median_label <- sprintf(
    "Median [%s, %s percentiles]", ordinal[1], ordinal[2]
  )
  mean_label <- "Mean\u00B1SD"
  # Brackets, the house standard: they keep the percentiles apart from
  # the n (%) parentheses in the same table. The numbers are re-formatted
  # from gtsummary's cards by .format_standard_median() below.
  median_stat <- sprintf("{median} [{p%s}, {p%s}]", p_lo, p_hi)
  # No spaces around the plus-minus: journals count table entries toward
  # word limits, and "64 +/- 12" is three words (house table rules).
  mean_stat <- "{mean}\u00B1{sd}"
  cont_stat <- switch(
    continuous_stat,
    median = paste("{N_nonmiss} |||", median_stat),
    mean = paste("{N_nonmiss} |||", mean_stat),
    # One row, both statistics: .split_median() below moves the part
    # after the separator into a median column beside each group's
    # statistic column, so the two read side by side rather than as
    # stacked sub-rows.
    both = paste("{N_nonmiss} |||", mean_stat, .median_sep, median_stat)
  )
  cont_type <- "continuous"

  # No "%" in the cell: the header or dagger says "No. (%)" once, as the
  # SAS macro does ("12 (39)"), and a repeated sign costs width and
  # counts toward journal word limits.
  cat_stat <- "{N_nonmiss} ||| {n} ({p})"

  # SAS CON1=: a `normal` variable is mean +/- SD whatever
  # continuous_stat says, on one row, tested with one-way ANOVA below.
  # A `mean_sd` variable is displayed the same way but keeps the
  # nonparametric test: the display and the test are separate choices.
  # `nonnormal` and `shown_mean` describe the display only; the test
  # reads `normal` alone.
  shown_mean <- union(normal, mean_sd)
  nonnormal <- setdiff(continuous, shown_mean)
  normal_stat <- paste("{N_nonmiss} |||", mean_stat)
  # Mixed: rows of one table show different continuous statistics. The
  # house standard names the statistic most rows use once, in the dagger
  # note, and marks the cells of the other: a section sign on medians, a
  # pilcrow on means. It replaces the macro's DESCLABEL=1 row suffixes.
  # Under "both" every statistic column shows mean±SD, and the median
  # columns name themselves, so nothing is mixed.
  mixed <- length(shown_mean) > 0L && length(nonnormal) > 0L &&
    continuous_stat == "median"
  mean_default <- mixed && length(shown_mean) > length(nonnormal)
  cell_marks <- if (!mixed) NULL else if (mean_default) {
    list(symbol = "\u00A7", variables = nonnormal)
  } else {
    list(symbol = "\u00B6", variables = shown_mean)
  }
  label_stat <- if (length(continuous) > 0L && length(nonnormal) == 0L) {
    "mean"
  } else if (mean_default) {
    "mean"
  } else if (continuous_stat == "both") {
    "mean"
  } else {
    continuous_stat
  }

  # A list rather than a character vector: under "both" each continuous
  # variable takes a length-2 statistic.
  statistic <- c(
    stats::setNames(rep(list(cont_stat), length(nonnormal)), nonnormal),
    stats::setNames(rep(list(normal_stat), length(shown_mean)), shown_mean),
    stats::setNames(
      rep(list(cat_stat), length(binary) + length(categorical)),
      c(binary, categorical)
    )
  )
  type <- stats::setNames(
    as.list(c(
      rep(cont_type, length(nonnormal)),
      rep("continuous", length(shown_mean)),
      rep("dichotomous", length(binary)),
      rep("categorical", length(categorical))
    )),
    c(nonnormal, shown_mean, binary, categorical)
  )

  # Tell gtsummary which level is the event rather than letting it
  # guess. Its guesser is type-sensitive in a way that bites the SAS
  # import path: a haven_labelled column over a DOUBLE base type (what
  # haven::read_sas() yields, since every SAS numeric is an 8-byte
  # float) failed with "Summary type is \"dichotomous\" but no summary
  # value has been assigned." while the integer-backed form worked.
  # .is_dichotomizable() has already accepted every column named here.
  value <- stats::setNames(
    lapply(binary, function(v) .event_value(data[[v]])), binary
  )

  section_map <- stats::setNames(rep(names(groups), lengths(groups)), vars)

  # gtsummary's default N/n formatter inserts thousands separators
  # ("4,190"), but both real example tables examined during design
  # (summarytable_overall.docx, summarytable_stratified_grp_res.docx)
  # show plain digits ("7948", "4190", "3758"). Verified empirically
  # during planning that tbl_summary()'s default digits= would otherwise
  # silently comma-format any N >= 1000, which both real example tables
  # actually reach. Force plain digits for N_nonmiss and n explicitly.
  # Used inside the `digits =` formula below; lintr's static analysis
  # cannot see through the formula, hence the nolint.
  # nolint start: object_usage_linter.
  no_comma <- gtsummary::label_style_number(big.mark = "")
  # nolint end
  tbl <- .tbl_summary_isolated(
    data,
    by = if (is.null(by)) NULL else gtsummary::all_of(by),
    include = gtsummary::all_of(vars),
    statistic = statistic, type = type, value = value, missing = "no",
    digits = list(
      gtsummary::everything() ~ list(N_nonmiss = no_comma, n = no_comma)
    )
  )
  tbl <- gtsummary::modify_table_body(
    tbl,
    function(tb) {
      tb$groupname_col <- unname(section_map[tb$variable])
      tb
    }
  )

  # add_overall() must run before add_p()/add_difference() below --
  # gtsummary requires it ahead of comparison columns so the comparison
  # column stays rightmost.
  # Every return goes through finish(): the variable column is added
  # last so add_overall() and the comparison calls never see a column
  # they do not know.
  # The grouping's name, for the manuscript header's spanning cell: the
  # variable's label when the data carry one, else its name.
  by_label <- if (!is.null(by)) attr(data[[by]], "label", exact = TRUE) %||% by
  finish <- function(tbl) {
    tbl <- .add_overall_n(tbl, data, by)
    if (show_variable) tbl <- .add_variable_column(tbl)
    attr(tbl, "hv_by_label") <- by_label
    tbl
  }

  if (overall && !is.null(by))
    tbl <- gtsummary::add_overall(tbl, last = FALSE)
  if (continuous_stat == "both" && length(nonnormal) > 0L) {
    tbl <- .split_median(tbl, median_label, grouped = !is.null(by))
    attr(tbl, "hv_median_label") <- median_label
  }

  attr(tbl, "hv_stat_label") <- .stat_label(label_stat, percentiles)
  attr(tbl, "hv_footnotes") <- stats::setNames(
    list("Number of non-missing values.",
         paste0(attr(tbl, "hv_stat_label"), ".")),
    c("*", "\u2020")
  )
  if (!is.null(cell_marks)) {
    attr(tbl, "hv_cell_marks") <- cell_marks
    attr(tbl, "hv_footnotes")[[cell_marks$symbol]] <-
      if (identical(cell_marks$symbol, "\u00A7")) paste0(median_label, ".")
      else paste0(mean_label, ".")
  }
  mean_vars <- if (continuous_stat %in% c("mean", "both"))
    continuous else shown_mean
  tbl <- .format_blackstone_mean_sd(tbl, mean_vars)
  median_vars <- if (continuous_stat %in% c("median", "both"))
    nonnormal else character(0)
  tbl <- .format_standard_median(tbl, median_vars, percentiles)

  effective_compare <- if (is.null(by)) "none" else compare
  if (effective_compare == "none") {
    return(finish(tbl))
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
    # `[1-9][0-9]*` excludes `stat_0`, the Overall column add_overall()
    # may have added above -- it is not one of the groups being compared.
    n_groups <- sum(grepl("^stat_[1-9][0-9]*$", names(tbl$table_body)))
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

  # add_p()'s Wilcoxon test goes through cardx, which needs broom. Without
  # it gtsummary only warns and leaves every p-value blank, and
  # hv_test_footnotes_jtcvs() then finds no test_name and returns list().
  # The book published blank p-values for a week that way (2026-10-05 to
  # 2026-10-12), so fail here instead.
  if (effective_compare %in% c("pvalue", "both") && !.has_broom()) {
    stop("`compare = \"", effective_compare, "\"` needs the 'broom' ",
         "package for its p-values, and it is not installed. ",
         "Install it with install.packages(\"broom\").", call. = FALSE)
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
    # CON1='s test: classical one-way ANOVA (pooled variance), which is
    # what SAS's npar1way anova runs. oneway.test() defaults to Welch.
    # Categorical tests: by default gtsummary's own rule, Fisher when any
    # one cell expects fewer than 5, which is what the team asked for
    # (SAS's 50% rule left chi-square rows they swapped by hand). A
    # number opts in to the macro's CUTEXACT= rule, to reproduce SAS.
    cat_tests <- if (is.numeric(cutexact))
      .cutexact_tests(data, by, c(binary, categorical), cutexact)
    fisher <- names(cat_tests)[cat_tests == "fisher.test"]
    chisq <- names(cat_tests)[cat_tests != "fisher.test"]
    test <- c(
      if (length(normal)) list(gtsummary::all_of(normal) ~ "oneway.test"),
      if (length(fisher)) list(gtsummary::all_of(fisher) ~ "fisher.test"),
      if (length(chisq))
        list(gtsummary::all_of(chisq) ~ "chisq.test.no.correct")
    )
    tbl <- gtsummary::add_p(
      tbl, test = test,
      test.args = if (length(normal)) list(
        gtsummary::all_of(normal) ~ list(var.equal = TRUE)
      )
    )
    # hv_man_table() shows gtsummary's own p.value column, not
    # hv_compare_col, so its format function has to follow the standard
    # as well.
    tbl <- gtsummary::modify_fmt_fun(tbl, p.value ~ .format_p)
    # The macro marked these p-values (ExactTest = "F"). hv_man_table()
    # puts the mark on each Fisher p-value; the JTCVS route letters them
    # through hv_test_footnotes_jtcvs().
    if (any(tbl$table_body$test_name %in% "fisher.test"))
      attr(tbl, "hv_footnotes") <- .order_notes(c(
        attr(tbl, "hv_footnotes"), list("\u2021" = "Fisher exact test.")
      ))
    # The other tests are named once, in the dagger note, and the
    # p-value header carries the dagger. gtsummary's own footnote said
    # the same, but inside the table.
    tests <- .test_sentence(tbl$table_body)
    if (nzchar(tests)) {
      attr(tbl, "hv_footnotes")[["\u2020"]] <- .append_note(
        attr(tbl, "hv_footnotes")[["\u2020"]], tests
      )
      attr(tbl, "hv_test_note") <- tests
    }
  }
  if (effective_compare %in% c("smd", "both")) {
    # gtsummary footnoted "Standardized Mean Difference" on these
    # columns, inside the table. hv_man_table() drops that, so the column
    # carries the name the other renderers use and the dagger note says
    # what it is.
    tbl <- gtsummary::modify_header(tbl, estimate = "**Std. Diff.**")
    attr(tbl, "hv_smd") <- effective_compare
    attr(tbl, "hv_footnotes")[["\u2020"]] <- .append_note(
      attr(tbl, "hv_footnotes")[["\u2020"]],
      .smd_sentence("Std. Diff.", ci = TRUE)
    )
  }

  tb <- tbl$table_body
  compare_col <- switch(
    effective_compare,
    pvalue = .format_p(tb$p.value),
    smd    = gtsummary::style_sigfig(tb$estimate),
    both   = ifelse(
      is.na(tb$p.value), NA_character_,
      ifelse(
        is.na(tb$estimate),
        .format_p(tb$p.value),
        sprintf(
          "%s (SMD %s)",
          .format_p(tb$p.value),
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

  finish(tbl)
}

# Separates mean±SD from the median inside one continuous_stat = "both"
# cell, until .split_median() takes them apart.
.median_sep <- "~~~"

# Move the median out of each "both" cell into a column of its own,
# `hv_median_<stat column>`, placed right after that statistic column
# and headed with the group's name and the median's description. Rows
# without a median (categorical, `normal`, `mean_sd`) are blank there.
# The renderers lay the column out beside its group: the report and the
# manuscript table show the same thing, side by side.
.split_median <- function(tbl, median_label, grouped) {
  stat_cols <- grep("^stat_[0-9]+$", names(tbl$table_body), value = TRUE)
  sep <- paste0(" ", .median_sep, " ")
  hdr <- tbl$table_styling$header
  for (col in stat_cols) {
    med <- paste0("hv_median_", col)
    tbl <- gtsummary::modify_table_body(tbl, function(tb) {
      parts <- strsplit(tb[[col]], sep, fixed = TRUE)
      tb[[col]] <- vapply(parts, `[`, character(1), 1L)
      tb[[med]] <- vapply(parts, function(p) {
        if (length(p) == 2L) p[2] else NA_character_
      }, character(1))
      keep <- setdiff(names(tb), med)
      tb[, append(keep, med, after = match(col, keep)), drop = FALSE]
    })
    # Ungrouped, the statistic header is only "N = <n>", which would
    # read as the median column's own count.
    label <- if (grouped) {
      paste0(sub("\\s*\\n.*$", "", hdr$label[hdr$column == col]), "  \n",
             median_label)
    } else {
      paste0("**", median_label, "**")
    }
    tbl <- do.call(
      gtsummary::modify_header,
      c(list(tbl), stats::setNames(list(label), med))
    )
  }
  tbl
}

# %summarytable's CUTEXACT= rule (summarytable.sas, lines 1265-1320):
# for each categorical variable, the percentage of cells in the group x
# level table whose expected count is below 5; at or above `cutexact`,
# Fisher's exact test, otherwise Pearson chi-square without continuity
# correction. Cells are every combination of the observed groups and
# levels among rows with both present, zero counts included (proc freq's
# SPARSE). An unused factor level is not a cell: SAS never knew it.
# cutexact = 0 makes every test exact; above 100, none.
.cutexact_tests <- function(data, by, vars, cutexact) {
  plain <- function(z) {
    if (is.factor(z)) as.character(z) else as.vector(unclass(z))
  }
  g <- plain(data[[by]])
  out <- vapply(vars, function(v) {
    x <- plain(data[[v]])
    ok <- !is.na(x) & !is.na(g)
    tab <- table(g[ok], x[ok])
    if (sum(tab) == 0) return("chisq.test.no.correct")
    expected <- outer(rowSums(tab), colSums(tab)) / sum(tab)
    if (100 * mean(expected < 5) >= cutexact) "fisher.test" else
      "chisq.test.no.correct"
  }, character(1))
  stats::setNames(out, vars)
}

# The raw column name beside its label, on the variable's first row, the
# column %summarytable printed as "Variable". A report shows it so the
# reader can find the column in the data. The savers drop it and the JTCVS
# renderer never shows it, so the report and the manuscript come from one
# regenerated table with no hand edit.
.add_variable_column <- function(tbl) {
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$hv_variable <- ifelse(tb$row_type == "label", tb$variable,
                             NA_character_)
    keep <- setdiff(names(tb), "hv_variable")
    tb[, append(keep, "hv_variable", after = match("label", keep)),
       drop = FALSE]
  })
  gtsummary::modify_header(tbl, hv_variable = "**Variable**")
}

# Round one reported number to a base-10 place using R's round-to-even rule,
# then retain the trailing zeros that communicate the chosen precision.
.format_to_place <- function(x, place) {
  rounded <- round(x, digits = -place)
  if (rounded == 0) rounded <- 0
  decimal_mark <- getOption("OutDec")
  formatC(
    rounded, format = "f", digits = max(0L, -place),
    big.mark = if (identical(decimal_mark, ",")) " " else ",",
    decimal.mark = decimal_mark
  )
}

# P values, the house standard: gtsummary's style_pvalue(digits = 1),
# which hv_tbl_summary() has always used, with the leading zero dropped,
# as AMA style and the typeset JTCVS tables print them (.013, <.001, >.9).
.format_p <- function(p) {
  sub("^([<>]?)0\\.", "\\1.", gtsummary::style_pvalue(p, digits = 1))
}

# The tests behind the p-values a table shows, in the house wording, as
# one sentence for the dagger note: "P values from the Wilcoxon rank sum
# test and Pearson's chi-square test." Fisher's exact test is left out,
# since it has a mark and a note of its own, and so is the standardized
# difference, which is no test. "" when no other test ran.
.test_sentence <- function(tb) {
  names_by_test <- c(
    oneway.test           = "one-way analysis of variance",
    wilcox.test           = "Wilcoxon rank sum test",
    kruskal.test          = "Kruskal-Wallis test",
    chisq.test.no.correct = "Pearson's chi-square test"
  )
  shown <- unique(tb$test_name[!is.na(tb$p.value)])
  used <- names_by_test[names(names_by_test) %in% shown]
  if (length(used) == 0L) return("")
  items <- unname(used)
  n <- length(items)
  joined <- if (n == 1L) items
  else if (n == 2L) paste(items, collapse = " and ")
  else paste0(paste(items[-n], collapse = ", "), ", and ", items[n])
  paste0("P values from the ", joined, ".")
}

# The dagger note with a sentence after the statistic, in either style's
# words: "<statistic>; P values from the ...". `x` is NULL when there is
# nothing to add.
.append_note <- function(note, x) {
  if (is.null(x)) return(note)
  paste0(sub("\\.$", "", note), "; ", x)
}

# What the standardized-difference column is, for the dagger note. The
# report shows its 95% CI beside it; the manuscript does not.
.smd_sentence <- function(label, ci) {
  paste0(label, " is the standardized mean difference",
         if (ci) ", with its 95% CI", ".")
}

# Notes print in the canonical symbol order, * dagger double-dagger section
# sign || pilcrow, whichever step added them.
.order_notes <- function(notes) {
  canon <- c("*", "\u2020", "\u2021", "\u00A7", "||", "\u00B6")
  notes[order(match(names(notes), canon))]
}

# The manuscript style's one n column (design section 7): each
# variable's non-missing count across every group, on its label row.
# A row whose `by` is missing is in no group and tbl_summary() drops it,
# so it is not counted here either. A column modify_table_body() adds is
# hidden from gtsummary's header, so the report never shows it.
.add_overall_n <- function(tbl, data, by) {
  if (!is.null(by)) data <- data[!is.na(data[[by]]), , drop = FALSE]
  n <- vapply(data, function(x) sum(!is.na(x)), integer(1))
  gtsummary::modify_table_body(tbl, function(tb) {
    tb$hv_n <- ifelse(tb$row_type == "label",
                      as.character(n[tb$variable]), NA_character_)
    tb
  })
}

# The house standard's precision for a median and its percentiles: 2
# significant digits, and a value of 10 or more to the units place, never
# coarser. Rounding 102 to 2 significant digits would print 100; a long
# right tail is exactly where a reader needs the digits. No thousands
# separator, as for the counts (house tables print plain digits).
.format_sig2 <- function(x) {
  out <- rep(NA_character_, length(x))
  ok <- is.finite(x)
  r <- signif(x[ok], 2)
  shown <- character(length(r))
  whole <- abs(r) >= 10
  # format = "f" with no decimals, not "d": "d" coerces to R integers, and
  # a finite value past 2^31 - 1 printed "NA".
  shown[whole] <- formatC(round(x[ok][whole]), format = "f", digits = 0,
                          big.mark = "")
  shown[!whole] <- sub(
    "\\.$", "", formatC(r[!whole], digits = 2, format = "fg", flag = "#")
  )
  shown[r == 0] <- "0"
  out[ok] <- shown
  out
}

# Apply EHB/Blackstone's paired reporting precision. The mean is rounded to
# the first-significant-digit place of the SD and the SD one place finer. An
# SD beginning with 1 shifts both one additional place finer.
.format_blackstone_pair <- function(mean, sd) {
  if (!is.finite(mean) || !is.finite(sd) || sd <= 0) return(NULL)
  mean_place <- floor(log10(abs(sd)))
  leading <- floor(abs(sd) / 10^mean_place)
  if (leading == 1L) mean_place <- mean_place - 1L
  paste0(
    .format_to_place(mean, mean_place), "\u00B1",
    .format_to_place(sd, mean_place - 1L)
  )
}

# gtsummary turns each "{name}" in a statistic string into a function by
# evaluating the name in the environment tbl_summary() was called from. A
# function defined in this package inherits namespace -> imports -> base ->
# the global environment -> package:stats, so an object a study defines as
# `sd` or `median` (hvtiRtemplates jobs source the study's R/ into the
# global environment) is found before stats::sd and stats::median and the
# call fails. Calling tbl_summary() from a function whose enclosure holds
# those two and then only base closes the lookup: nothing a user defines can
# shadow a statistic. `mean`, `min` and `max` are base; the percentiles
# gtsummary builds itself from "pNN".
.stat_lookup_env <- function() {
  list2env(list(sd = stats::sd, median = stats::median), parent = baseenv())
}

.tbl_summary_isolated <- function(...) {
  call_tbl_summary <- function(...) gtsummary::tbl_summary(...)
  environment(call_tbl_summary) <- .stat_lookup_env()
  call_tbl_summary(...)
}

# gtsummary retains unrounded statistics in ARD cards. Use those rather than
# parsing already rounded display strings, then replace only cells containing
# the mean/SD separator. Median rows under continuous_stat = "both" remain
# untouched.
.format_blackstone_mean_sd <- function(tbl, continuous) {
  if (!length(continuous)) return(tbl)

  card_names <- intersect(c("tbl_summary", "add_overall"), names(tbl$cards))
  raw <- lapply(card_names, function(card_name) {
    card <- tbl$cards[[card_name]]
    keep <- card$variable %in% continuous &
      card$stat_name %in% c("mean", "sd")
    data.frame(
      variable = card$variable[keep],
      gts_column = card$gts_column[keep],
      stat_name = card$stat_name[keep],
      stat = as.numeric(unlist(card$stat[keep])),
      stringsAsFactors = FALSE
    )
  })
  raw <- do.call(rbind, raw)
  keys <- unique(raw[c("variable", "gts_column")])

  for (i in seq_len(nrow(keys))) {
    variable <- keys$variable[i]
    column <- keys$gts_column[i]
    pair <- raw[raw$variable == variable & raw$gts_column == column, ]
    mean <- pair$stat[pair$stat_name == "mean"]
    sd <- pair$stat[pair$stat_name == "sd"]
    if (length(mean) != 1L || length(sd) != 1L) next
    formatted <- .format_blackstone_pair(mean, sd)
    if (is.null(formatted) || !column %in% names(tbl$table_body)) next

    cells <- tbl$table_body[[column]]
    target <- tbl$table_body$variable == variable & !is.na(cells) &
      grepl("\u00B1", cells, fixed = TRUE)
    if (sum(target) != 1L) next
    prefix <- strsplit(cells[target], " ||| ", fixed = TRUE)[[1]][1]
    tbl$table_body[[column]][target] <- paste(prefix, formatted, sep = " ||| ")
  }
  tbl
}

# The house standard's medians: each number from gtsummary's cards, to
# 2 significant digits (.format_sig2()), in brackets. Reads the raw
# statistics rather than parsing gtsummary's rounded text, as
# .format_blackstone_mean_sd() does. Under continuous_stat = "both" the
# median sits in hv_median_<col>, which .split_median() made.
.format_standard_median <- function(tbl, median_vars, percentiles) {
  if (!length(median_vars)) return(tbl)
  lo_name <- paste0("p", percentiles[1])
  hi_name <- paste0("p", percentiles[2])
  card_names <- intersect(c("tbl_summary", "add_overall"), names(tbl$cards))
  raw <- do.call(rbind, lapply(card_names, function(card_name) {
    card <- tbl$cards[[card_name]]
    keep <- card$variable %in% median_vars &
      card$stat_name %in% c("median", lo_name, hi_name)
    data.frame(
      variable = card$variable[keep], gts_column = card$gts_column[keep],
      stat_name = card$stat_name[keep],
      stat = as.numeric(unlist(card$stat[keep])), stringsAsFactors = FALSE
    )
  }))
  if (is.null(raw) || !nrow(raw)) return(tbl)
  keys <- unique(raw[c("variable", "gts_column")])
  for (i in seq_len(nrow(keys))) {
    v <- keys$variable[i]
    col <- keys$gts_column[i]
    s <- raw[raw$variable == v & raw$gts_column == col, ]
    get <- function(name) s$stat[s$stat_name == name]
    m <- get("median")
    lo <- get(lo_name)
    hi <- get(hi_name)
    if (length(m) != 1L || length(lo) != 1L || length(hi) != 1L) next
    # A group with no data: gtsummary already shows NA there, so no
    # unrounded number is hidden. Leave the cell as it is.
    if (!all(is.finite(c(m, lo, hi)))) next
    text <- sprintf("%s [%s, %s]", .format_sig2(m), .format_sig2(lo),
                    .format_sig2(hi))
    # The column that carries the median: hv_median_<col> under "both",
    # otherwise the statistic column itself.
    median_col <- paste0("hv_median_", col)
    target <- if (median_col %in% names(tbl$table_body)) median_col else col
    hit <- if (target %in% names(tbl$table_body)) {
      cells <- tbl$table_body[[target]]
      tbl$table_body$variable == v & !is.na(cells) &
        grepl("[", cells, fixed = TRUE)
    } else {
      FALSE
    }
    if (sum(hit) != 1L) {
      # Failing loud: a median left in gtsummary's own digits would pass
      # for the standard's.
      warning("Could not apply the house median format to `", v,
              "` in column `", target, "`; the cell keeps gtsummary's text.",
              call. = FALSE)
      next
    }
    parts <- strsplit(cells[hit], " ||| ", fixed = TRUE)[[1]]
    tbl$table_body[[target]][hit] <- if (length(parts) == 2L)
      paste(parts[1], text, sep = " ||| ") else text
  }
  tbl
}

# A function rather than an inline requireNamespace() call so the tests
# can mock broom's absence without uninstalling it.
.has_broom <- function() requireNamespace("broom", quietly = TRUE)
