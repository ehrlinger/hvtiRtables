#' Build a gtsummary table from a SAS %summarytable-style grouped variable list
#'
#' Thin wrapper over [gtsummary::tbl_summary()] modeled on the interface
#' biostats team members already know from the `%summarytable` SAS macro:
#' a grouped, ordered variable list (`groups`, the macro's `LIST=`
#' equivalent) and variable-type buckets (`continuous`/`binary`/
#' `categorical`, the `CON3=`/`CAT1=`/`CAT2=` equivalents), rather than
#' gtsummary's own tidyselect-based interface. Returns a plain `gtsummary`
#' object, ready for [hv_man_table()] or [hv_man_table_jtcvs()].
#'
#' Continuous variables are summarized as `median (P<low>, P<high>)` by
#' default, or as mean +/- SD, or both (`continuous_stat`). Whichever is
#' shown, the test is the same blanket non-parametric one (Wilcoxon
#' rank-sum for 2 groups, Kruskal-Wallis for 3+) — this function does
#' not classify variables as Gaussian/non-Gaussian the way
#' `%summarytable` does; that is `gtsummary::add_p()`'s own default
#' continuous test already. `percentiles` defaults to the house
#' convention documented in [hv_man_footnotes()] (15th/85th),
#' overridable per study (`%summarytable` equivalent: `PP=`).
#'
#' The returned object carries three renderer attributes:
#' `hv_stat_label`, the sub-header text naming the statistics shown
#' (`"No. (%) or Median (<low>th, <high>th percentile)"` by default; it
#' follows `continuous_stat`);
#' `hv_trailing`, a named character vector ready to pass as
#' [hv_man_table_jtcvs()]'s `trailing` argument when `compare` produced a
#' comparison column (`NULL` when `compare = "none"`); and `hv_footnotes`,
#' the CORR footnote block that [hv_man_table()] carries into
#' [hv_man_table_save()] so the default dagger follows `continuous_stat` and
#' `percentiles` automatically.
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
#' **The Overall column is missing from the JTCVS table.**
#' [hv_man_table_jtcvs()] lays out only the columns its `groups`
#' argument names, and `overall = TRUE` is the default. Add
#' `stat_0 = "Overall (n=<N>)"` to `groups`.
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
#'   belong here too. `continuous_stat = "mean"` reproduces `CON1=`'s
#'   statistic but not its test: every continuous variable is tested
#'   non-parametrically. Each named column must be numeric.
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
#'   `PVALUES=`/`ASD=` equivalent.
#' @param percentiles Numeric vector of length 2, the low/high percentile
#'   pair for continuous summaries, as increasing whole numbers between 0
#'   and 100. Default `c(15, 85)`, the [hv_man_footnotes()] house
#'   convention (`%summarytable` `PP=` equivalent).
#' @param overall Single `TRUE`/`FALSE`. When `TRUE` (default), prepends
#'   an Overall column across all groups (`%summarytable` `TOTALCOL=1`,
#'   the macro's default). Ignored when `by` is `NULL`, since the single
#'   column already is the overall one. [hv_man_table_jtcvs()] lays out
#'   only the columns its `groups` argument names, so name `stat_0`
#'   there to show it.
#' @param continuous_stat One of `"median"` (default), `"mean"`, or
#'   `"both"`: how continuous variables are summarized. `"median"` gives
#'   `median (P<low>, P<high>)`; `"mean"` gives mean +/- SD, with no
#'   spaces around the plus-minus sign, per the house table rules;
#'   `"both"` puts the two on sub-rows under the variable, mean +/- SD
#'   first, with the N shown once, on the first. Choosing one for the
#'   manuscript is then a matter of deleting a row. The test does not
#'   change with the statistic: it is always the non-parametric one
#'   described above. The CORR footnote carried through [hv_man_table()] to
#'   [hv_man_table_save()] follows this choice automatically. Placed after
#'   `overall` so calls passing `overall` by position keep working.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' @return A `gtsummary` object, ready for [hv_man_table()] or
#'   [hv_man_table_jtcvs()]. See Details for the `hv_stat_label`,
#'   `hv_trailing`, and `hv_footnotes` renderer attributes.
#'
#' @seealso [hv_man_table()] or [hv_man_table_jtcvs()] to render the
#'   result. [hv_man_footnotes()] for the percentile-footnote house
#'   convention.
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
                           ...) {
  .check_sas_args(list(...), "hv_tbl_summary")
  compare <- match.arg(compare)
  continuous_stat <- match.arg(continuous_stat)

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
  # {N_nonmiss}, not {N_obs}: the N column is footnoted "Number of
  # non-missing values." (house rule 8), and {N_obs} counts every row,
  # missing ones included. The SAS tables count non-missing (bsa shows
  # 7947 of 7948), so {N_obs} silently overstated n for any variable
  # with missing data.
  median_label <- sprintf("Median (%sth, %sth percentile)", p_lo, p_hi)
  mean_label <- "Mean\u00B1SD"
  median_stat <- sprintf("{median} ({p%s}, {p%s})", p_lo, p_hi)
  # No spaces around the plus-minus: journals count table entries toward
  # word limits, and "64 +/- 12" is three words (house table rules).
  mean_stat <- "{mean}\u00B1{sd}"
  cont_stat <- switch(
    continuous_stat,
    median = paste("{N_nonmiss} |||", median_stat),
    mean = paste("{N_nonmiss} |||", mean_stat),
    # Two sub-rows under one label row (gtsummary's "continuous2"). The
    # N sits on the first only: " ||| " with nothing before it splits
    # into a blank N cell, so each variable shows its n once.
    both = c(paste("{N_nonmiss} |||", mean_stat),
             paste(" |||", median_stat))
  )
  cont_type <- if (continuous_stat == "both") "continuous2" else "continuous"

  cat_stat <- "{N_nonmiss} ||| {n} ({p}%)"

  # A list rather than a character vector: under "both" each continuous
  # variable takes a length-2 statistic.
  statistic <- c(
    stats::setNames(rep(list(cont_stat), length(continuous)), continuous),
    stats::setNames(
      rep(list(cat_stat), length(binary) + length(categorical)),
      c(binary, categorical)
    )
  )
  type <- stats::setNames(
    as.list(c(
      rep(cont_type, length(continuous)),
      rep("dichotomous", length(binary)),
      rep("categorical", length(categorical))
    )),
    c(continuous, binary, categorical)
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
  # show plain digits ("7948", "4190", "3758") — verified empirically
  # during planning that tbl_summary()'s default digits= would otherwise
  # silently comma-format any N >= 1000, which both real example tables
  # actually reach. Force plain digits for N_nonmiss and n explicitly.
  # Used inside the `digits =` formula below; lintr's static analysis
  # cannot see through the formula, hence the nolint.
  # nolint start: object_usage_linter.
  no_comma <- gtsummary::label_style_number(big.mark = "")
  # nolint end
  tbl <- gtsummary::tbl_summary(
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
  # Applied at each return, not here: gtsummary labels continuous2
  # sub-rows from the glue string, separator and all ("N Non-missing |||
  # Mean ± SD"), and add_overall() matches rows on those labels, so
  # renaming them any earlier makes it fail.
  relabel <- function(tbl) {
    if (continuous_stat != "both") return(tbl)
    gtsummary::modify_table_body(tbl, function(tb) {
      i <- tb$row_type == "level" & tb$variable %in% continuous
      tb$label[i] <- rep_len(c(mean_label, median_label), sum(i))
      tb
    })
  }

  if (overall && !is.null(by))
    tbl <- gtsummary::add_overall(tbl, last = FALSE)

  attr(tbl, "hv_stat_label") <- switch(
    continuous_stat,
    median = paste("No. (%) or", median_label),
    mean = paste("No. (%) or", mean_label),
    both = paste0("No. (%), ", mean_label, ", or ", median_label)
  )
  attr(tbl, "hv_footnotes") <- hv_man_footnotes(
    continuous_stat = continuous_stat,
    percentiles = percentiles
  )

  effective_compare <- if (is.null(by)) "none" else compare
  if (effective_compare == "none") {
    return(relabel(tbl))
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

  relabel(tbl)
}
