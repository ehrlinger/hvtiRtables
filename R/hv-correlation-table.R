#' Pairwise correlations with Fisher confidence intervals
#'
#' @description
#' The table half of the SAS correlation job
#' `proc corr nosimple spearman pearson fisher(biasadj=no alpha=.32)`, with
#' the `SpearmanCorr`, `FisherSpearmanCorr`, `PearsonCorr` and
#' `FisherPearsonCorr` ODS tables folded into one data frame. The scatter-plot
#' matrix (`plots=matrix`) is `hvtiPlotR::hv_correlation_matrix()`.
#'
#' @details
#' The interval is Fisher's z without bias adjustment, SAS's `biasadj=no`:
#' `z = atanh(r)`, `se = 1 / sqrt(n - 3)`, back-transformed with `tanh()`. The
#' same transform is applied to Spearman's coefficient, as SAS does. The
#' p-value tests rho = 0 on the same z scale, so it is the Fisher p-value SAS
#' reports alongside the interval, not the t-test p-value of
#' [stats::cor.test()]. The interval, by contrast, is identical to
#' `cor.test()`'s for Pearson.
#'
#' `conf_level` defaults to 0.68, the exemplar's `alpha=.32`: the house
#' one-standard-error convention, the same logic as the 15th and 85th
#' percentiles in [hv_tbl_summary()]. Pass `0.95` for a conventional interval.
#'
#' Missing values are deleted pairwise, per pair and per stratum, which is
#' `proc corr`'s default. Rows with a missing `by` value are dropped, where
#' SAS's `BY` would keep them as their own group.
#'
#' @param data A data frame.
#' @param vars Character vector of numeric columns (`VAR` statement).
#' @param with Character vector of numeric columns to correlate each of `vars`
#'   against (`WITH` statement). `NULL` (default) correlates every unordered
#'   pair within `vars`.
#' @param by Optional single column name to stratify on (`BY` statement). Each
#'   level gets its own rows; the column is carried first in the output.
#' @param method One or both of `"spearman"` and `"pearson"`.
#' @param conf_level Confidence level for the Fisher interval, strictly
#'   between 0 and 1. Default `0.68`.
#' @param digits Decimal places in `display`. Default `2`, the SAS `6.2` format.
#'
#' @return A data frame, one row per stratum, pair and method, with columns
#'   `by` (when given), `variable`, `label`, `with`, `method`, `n`,
#'   `estimate`, `conf.low`, `conf.high`, `p.value` and `display`
#'   (`"r (lcl, ucl)"`). `label` describes `variable` only, not the pair.
#'   `display` is `NA` whenever the interval is undefined: n <= 3, a
#'   zero-variance column, or an empty stratum. The level used is stored as
#'   `attr(x, "conf_level")`.
#'
#' @seealso `hvtiPlotR::hv_correlation_matrix()` for the plot.
#'
#' @examples
#' hv_correlation_table(
#'   datasets::mtcars, vars = c("hp", "wt", "qsec"), with = "mpg",
#'   by = "am"
#' )
#' @export
hv_correlation_table <- function(data, vars, with = NULL, by = NULL,
                                 method = c("spearman", "pearson"),
                                 conf_level = 0.68, digits = 2) {
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  method <- match.arg(method, several.ok = TRUE)
  if (!is.character(vars) || length(vars) == 0L || anyNA(vars))
    stop("`vars` must be a character vector of column names.", call. = FALSE)
  if (!is.null(with) && (!is.character(with) || anyNA(with)))
    stop("`with` must be NULL or a character vector naming at least one ",
         "column.", call. = FALSE)
  if (is.null(with) && length(vars) < 2L)
    stop("`vars` needs at least two columns when `with` is NULL.",
         call. = FALSE)
  if (!is.null(with) && length(with) == 0L)
    stop("`with` must be NULL or name at least one column.", call. = FALSE)
  if (!is.null(by)) .check_string(by, "by")
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
        is.na(conf_level) || conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits) ||
        digits < 0 || digits != round(digits))
    stop("`digits` must be a single non-negative whole number.",
         call. = FALSE)

  vars <- unique(vars)
  if (!is.null(with)) with <- unique(with)

  cols <- unique(c(vars, with))
  absent <- setdiff(c(cols, by), names(data))
  if (length(absent))
    stop("Variable(s) not found in `data`: ", paste(absent, collapse = ", "),
         call. = FALSE)
  not_num <- cols[!vapply(data[cols], is.numeric, logical(1))]
  if (length(not_num))
    stop("Correlation needs numeric columns; not numeric: ",
         paste(not_num, collapse = ", "), call. = FALSE)
  if (!is.null(by) && by %in% cols)
    stop("`by` must not also be a column in `vars` or `with`: ", by,
         call. = FALSE)

  pairs <- if (is.null(with)) {
    cmb <- utils::combn(vars, 2L)
    data.frame(variable = cmb[1L, ], with = cmb[2L, ],
               stringsAsFactors = FALSE)
  } else {
    g <- expand.grid(variable = vars, with = with, stringsAsFactors = FALSE)
    g <- g[g$variable != g$with, , drop = FALSE]
    if (nrow(g) == 0L)
      stop("No pairs to correlate: every column in `vars` is also in ",
           "`with`.", call. = FALSE)
    g[order(match(g$with, with), match(g$variable, vars)), , drop = FALSE]
  }

  strata <- if (is.null(by)) list(.all = data) else
    split(data, data[[by]], drop = TRUE)

  rows <- list()
  for (s in names(strata)) {
    d <- strata[[s]]
    stratum_value <- if (is.null(by)) s else d[[by]][1]
    for (i in seq_len(nrow(pairs))) {
      x <- d[[pairs$variable[i]]]
      y <- d[[pairs$with[i]]]
      ok <- stats::complete.cases(x, y)
      n <- sum(ok)
      for (m in method) {
        r <- if (n >= 2L) suppressWarnings(
          stats::cor(x[ok], y[ok], method = m)
        ) else NA_real_
        ci <- .fisher_interval(r, n, conf_level)
        rows[[length(rows) + 1L]] <- data.frame(
          stratum = stratum_value, variable = pairs$variable[i],
          label = .column_label(data[[pairs$variable[i]]], pairs$variable[i]),
          with = pairs$with[i], method = m, n = n, estimate = r,
          conf.low = ci[["low"]], conf.high = ci[["high"]],
          p.value = ci[["p"]], stringsAsFactors = FALSE
        )
      }
    }
  }
  out <- do.call(rbind, rows)
  out$display <- ifelse(
    is.na(out$conf.low), NA_character_,
    sprintf("%.*f (%.*f, %.*f)", digits, out$estimate, digits, out$conf.low,
            digits, out$conf.high)
  )
  if (is.null(by)) {
    out$stratum <- NULL
  } else {
    names(out)[names(out) == "stratum"] <- by
  }
  rownames(out) <- NULL
  attr(out, "conf_level") <- conf_level
  out
}

# Fisher z interval and p-value for rho = 0, without bias adjustment (SAS
# biasadj=no). Undefined below n = 4, where 1/sqrt(n - 3) is not finite.
.fisher_interval <- function(r, n, conf_level) {
  if (is.na(r) || n <= 3L)
    return(c(low = NA_real_, high = NA_real_, p = NA_real_))
  z <- atanh(r)
  se <- 1 / sqrt(n - 3)
  q <- stats::qnorm(1 - (1 - conf_level) / 2)
  c(low = tanh(z - q * se), high = tanh(z + q * se),
    p = 2 * stats::pnorm(-abs(z) / se))
}

# haven::read_sas() carries SAS labels as a "label" attribute; the exemplar
# printed them in place of the column name.
.column_label <- function(x, name) {
  lab <- attr(x, "label", exact = TRUE)
  if (is.character(lab) && length(lab) == 1L && nzchar(lab)) lab else name
}
