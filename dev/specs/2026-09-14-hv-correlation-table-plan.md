# hv_correlation_table() Implementation Plan (hvtiRtables)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hvtiRtables::hv_correlation_table()`, the tabular half of the SAS
`proc corr ... spearman pearson fisher(biasadj=no alpha=.32)` job, so the
`dc-tables` template can replace `dc.tables.ods_preoplabs_a1c.sas`.

**Architecture:** One exported function in its own file, returning a tidy data
frame (one row per stratum, pair and method), with a formatted `display` column
matching the SAS `put(corr,6.2) (lcl, ucl)` cell. No `gtsummary` object: Word
rendering of correlation tables is out of scope (a follow-up, not this plan).

**Tech Stack:** base R `stats` and `utils` only, testthat 3e.

## Global Constraints

- Source of truth: hvtiRtemplates `dev/specs/2026-09-09-eda-templates-design.md` sections 3.1 and 6.
- Name is `hv_correlation_*` in full. `corr` in this package means CORR the group (spec 3.2).
- Default `conf_level = 0.68`: the exemplar's `alpha=.32`, the house one-SD convention.
- Fisher z **without** bias adjustment (`biasadj=no`): `z = atanh(r)`, `se = 1/sqrt(n - 3)`.
- Missing data: pairwise deletion, per pair, per stratum (SAS `proc corr` default).
- Must support stratification (`by`), overall and within levels (exemplar: `a1c_grp`).
- No new Imports.
- Branch `feat/hv-correlation-table`; never push to `main`. No `Version:` bump in the PR;
  NEWS entry under the existing `# hvtiRtables (unreleased)` heading.
- Roxygen markdown is enabled here (`Roxygen: list(markdown = TRUE)`).

---

### Task 0: Branch and commit this plan

- [ ] `cd ~/Documents/GitHub/hvtiRtables && git fetch origin && git switch -c feat/hv-correlation-table origin/main`
- [ ] Copy this file to `dev/specs/2026-09-14-hv-correlation-table-plan.md`; `git add dev/specs && git commit -m "docs: plan hv_correlation_table()"`

### Task 1: Core computation, overall (no strata)

**Files:**
- Create: `R/hv-correlation-table.R`
- Test: `tests/testthat/test-hv-correlation-table.R`

**Interfaces:**
- Produces: `hv_correlation_table(data, vars, with = NULL, by = NULL, method = c("spearman", "pearson"), conf_level = 0.68, digits = 2)` returning a `data.frame` with columns
  `[<by>,] variable, label, with, method, n, estimate, conf.low, conf.high, p.value, display`
  and attribute `conf_level`. Consumed by hvtiRtemplates `dc-tables.qmd` (Plan C).

- [ ] **Step 1: Write the failing tests**

```r
mk_corr_data <- function() {
  set.seed(3)
  n <- 80
  a1c <- rnorm(n, 6.5, 1)
  data.frame(
    a1c = a1c,
    glu = 20 * a1c + rnorm(n, 0, 20),
    alb = 4 - 0.1 * a1c + rnorm(n, 0, 0.4),
    grp = factor(rep(c("low", "high"), each = n / 2))
  )
}

test_that("Pearson CI matches cor.test at the default 68% level", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  ref <- stats::cor.test(d$glu, d$a1c, conf.level = 0.68)
  row <- out[out$variable == "glu", ]
  expect_equal(row$estimate, unname(ref$estimate))
  expect_equal(c(row$conf.low, row$conf.high), as.numeric(ref$conf.int))
  expect_equal(attr(out, "conf_level"), 0.68)
})

test_that("Spearman estimate and Fisher p-value are computed by hand", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = "alb", with = "a1c",
                              method = "spearman")
  r <- stats::cor(d$alb, d$a1c, method = "spearman")
  expect_equal(out$estimate, r)
  expect_equal(out$p.value, 2 * stats::pnorm(-abs(atanh(r)) * sqrt(80 - 3)))
})

test_that("both methods by default, spearman first", {
  out <- hv_correlation_table(mk_corr_data(), vars = "glu", with = "a1c")
  expect_equal(out$method, c("spearman", "pearson"))
})

test_that("with = NULL gives every unordered pair of vars", {
  out <- hv_correlation_table(mk_corr_data(), vars = c("a1c", "glu", "alb"),
                              method = "pearson")
  expect_equal(nrow(out), 3L)
  expect_equal(paste(out$variable, out$with),
               c("a1c glu", "a1c alb", "glu alb"))
})

test_that("missing values are deleted pairwise", {
  d <- mk_corr_data()
  d$glu[1:5] <- NA
  d$alb[6:8] <- NA
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  expect_equal(out$n, c(75L, 77L))
})

test_that("display is 'r (lcl, ucl)' at `digits` places", {
  out <- hv_correlation_table(mk_corr_data(), vars = "glu", with = "a1c",
                              method = "pearson")
  expect_match(
    out$display,
    "^-?[0-9]\\.[0-9]{2} \\(-?[0-9]\\.[0-9]{2}, -?[0-9]\\.[0-9]{2}\\)$"
  )
})

test_that("labels come from a haven-style label attribute, else the name", {
  d <- mk_corr_data()
  attr(d$glu, "label") <- "Preop: Glucose"
  out <- hv_correlation_table(d, vars = c("glu", "alb"), with = "a1c",
                              method = "pearson")
  expect_equal(out$label, c("Preop: Glucose", "alb"))
})

test_that("n <= 3 gives an NA interval, not an error", {
  d <- mk_corr_data()[1:3, ]
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", method = "pearson")
  expect_true(is.na(out$conf.low))
  expect_true(is.na(out$display))
})
```

- [ ] **Step 2: Run to verify failure.**
  Run: `Rscript -e 'devtools::test(filter = "hv-correlation-table")'`
  Expected: FAIL, `could not find function "hv_correlation_table"`.

- [ ] **Step 3: Implement** `R/hv-correlation-table.R`:

```r
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
#'   (`"r (lcl, ucl)"`, `NA` when the interval is undefined at n <= 3). The
#'   level used is stored as `attr(x, "conf_level")`.
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
  if (is.null(with) && length(vars) < 2L)
    stop("`vars` needs at least two columns when `with` is NULL.",
         call. = FALSE)
  if (!is.null(by)) .check_string(by, "by")
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
        is.na(conf_level) || conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)

  cols <- unique(c(vars, with))
  absent <- setdiff(c(cols, by), names(data))
  if (length(absent))
    stop("Variable(s) not found in `data`: ", paste(absent, collapse = ", "),
         call. = FALSE)
  not_num <- cols[!vapply(data[cols], is.numeric, logical(1))]
  if (length(not_num))
    stop("Correlation needs numeric columns; not numeric: ",
         paste(not_num, collapse = ", "), call. = FALSE)

  pairs <- if (is.null(with)) {
    cmb <- utils::combn(vars, 2L)
    data.frame(variable = cmb[1L, ], with = cmb[2L, ],
               stringsAsFactors = FALSE)
  } else {
    g <- expand.grid(variable = setdiff(vars, with), with = with,
                     stringsAsFactors = FALSE)
    g[order(match(g$with, with), match(g$variable, vars)), , drop = FALSE]
  }

  strata <- if (is.null(by)) list(.all = data) else
    split(data, data[[by]], drop = TRUE)

  rows <- list()
  for (s in names(strata)) {
    d <- strata[[s]]
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
          stratum = s, variable = pairs$variable[i],
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
```

- [ ] **Step 4: Run to verify pass.** Same command; expected: all PASS.
- [ ] **Step 5: Commit.** `git add R/hv-correlation-table.R tests/testthat/test-hv-correlation-table.R && git commit -m "feat: hv_correlation_table() with Fisher intervals"`

### Task 2: Stratification and argument errors

**Files:** Modify `tests/testthat/test-hv-correlation-table.R`. Task 1's implementation already supports `by`; this task proves it.

- [ ] **Step 1: Add tests**

```r
test_that("by stratifies: one block per level, carried first", {
  d <- mk_corr_data()
  out <- hv_correlation_table(d, vars = "glu", with = "a1c", by = "grp",
                              method = "pearson")
  expect_equal(names(out)[1], "grp")
  expect_equal(nrow(out), 2L)
  hi <- d[d$grp == "high", ]
  expect_equal(out$estimate[out$grp == "high"], stats::cor(hi$glu, hi$a1c))
  expect_equal(out$n, c(40L, 40L))
})

test_that("errors name the problem", {
  d <- mk_corr_data()
  expect_error(hv_correlation_table(list(), vars = "a"), "data frame")
  expect_error(hv_correlation_table(d, vars = "nope", with = "a1c"), "not found")
  expect_error(hv_correlation_table(d, vars = "grp", with = "a1c"), "numeric")
  expect_error(hv_correlation_table(d, vars = "glu"), "at least two")
  expect_error(hv_correlation_table(d, vars = "glu", with = "a1c",
                                    conf_level = 95), "between 0 and 1")
})
```

- [ ] **Step 2: Run.** `Rscript -e 'devtools::test(filter = "hv-correlation-table")'`; expected PASS. If one fails, fix the implementation, not the test.
- [ ] **Step 3: Commit.** `git commit -am "test: stratified and error paths for hv_correlation_table()"`

### Task 3: Docs, pkgdown, NEWS, vignette pointer

**Files:** `man/`, `NAMESPACE` (via roxygen), `_pkgdown.yml`, `NEWS.md`, `vignettes/sas-migration.Rmd`

- [ ] `Rscript -e 'devtools::document()'`, then confirm `export(hv_correlation_table)` is in `NAMESPACE`.
- [ ] `_pkgdown.yml`: add after the "1. Compute the table" section:

```yaml
- title: "Correlations: `proc corr ... fisher`"
  desc: >
    Pairwise Spearman and Pearson coefficients with Fisher confidence
    intervals, overall or within strata. The scatter-plot matrix is
    `hvtiPlotR::hv_correlation_matrix()`.
  contents:
  - hv_correlation_table
```

- [ ] `NEWS.md`, first bullet under `# hvtiRtables (unreleased)`:

```markdown
- **New `hv_correlation_table()`** ports the SAS correlation job
  (`proc corr spearman pearson fisher(biasadj=no alpha=.32)`): pairwise
  coefficients with Fisher intervals, a 68% interval by default, pairwise
  deletion, and a `by` stratum. It backs the `dc-tables` job template.
```

- [ ] `vignettes/sas-migration.Rmd`: append a `## proc corr` section showing the exemplar SAS call and its port, `hv_correlation_table(built, vars = labs, with = "hbga1cpr", by = "a1c_grp")` (`eval = FALSE`), and state the 0.68 default.
- [ ] Definition of done: `Rscript -e 'devtools::test(); devtools::check()'` gives 0/0/0; `Rscript -e 'lintr::lint_package()'` gives no lints.
- [ ] Commit `docs: document hv_correlation_table()`; push; `gh pr create` with the body ending in the Claude Code attribution line. The maintainer merges.
- [ ] **After merge, in a separate commit (at most one version name per day):** rename the unreleased heading to `# hvtiRtables 1.0.1` and set `DESCRIPTION` `Version: 1.0.1` and `Date`. Plan C pins `hvtiRtables (>= 1.0.1)`.
