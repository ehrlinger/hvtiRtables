# hv_tbl_summary() Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hv_tbl_summary()`, a thin wrapper over `gtsummary::tbl_summary()`/`add_p()`/`add_difference()` that lets biostats team members build a grouped baseline-characteristics table using an interface modeled on the SAS `%summarytable` macro they already know, feeding straight into the existing `hv_man_table_jtcvs()` renderer.

**Architecture:** No new statistical logic — `gtsummary::add_p()`'s default test selection (Wilcoxon/Kruskal-Wallis for continuous, chi-square-with-Fisher's-fallback for categorical) and `add_difference(... ~ "smd")` already do everything `%summarytable` computes. `hv_tbl_summary()`'s only job is translating a grouped/typed variable list into the correct `tbl_summary()` call and attaching two rendering hints (`hv_stat_label`, `hv_trailing`) as object attributes so the caller can hand the result straight to `hv_man_table_jtcvs()`. One existing-function change is required: `hv_man_table_jtcvs()` currently hard-codes its stat sub-header text to `"No. (%) or Mean ± SD"`, which would be wrong for `hv_tbl_summary()`'s median-based output.

**Tech Stack:** R, gtsummary (>= 2.5.0, already an Import), flextable, officer, testthat edition 3.

## Global Constraints

- No new hard dependencies. Use `gtsummary::all_of()`/`gtsummary::everything()`/`gtsummary::style_pvalue()`/`gtsummary::style_sigfig()` (all confirmed present in the `gtsummary` namespace) instead of adding `dplyr` to Imports — `dplyr` stays a test-only Suggests dependency, matching the current DESCRIPTION.
- Percentile default is `c(15, 85)`, matching `hv_man_footnotes()`'s existing house convention text ("Median (15th, 85th percentile)."), not `%summarytable`'s own `PP=` default.
- Blanket non-parametric testing: never write custom test-selection code. Continuous comparisons rely entirely on `add_p()`'s own default.
- The `Variable` (internal SAS/R name) column is dropped from the final table; only the human-readable label is shown. `hv_tbl_summary()` never adds a `Variable`-equivalent column to `table_body` beyond what `tbl_summary()` already produces internally (which `hv_man_table_jtcvs()` already ignores).
- Ordinal variables fold into `categorical` — no trend test. This is a real, documented scope cut, not silent.
- Version stays under the current `0.9.x` minor. This plan's final task bumps `DESCRIPTION`/`NEWS.md` from `0.9.0` to `0.9.1` (patch only) — do not bump the minor digit.
- Every exported function/parameter needs a complete `@param`/`@return` roxygen block (house documentation rule, checked by `R CMD check --as-cran` with the manual build).

---

### Task 1: `stat_label` parameter on `hv_man_table_jtcvs()`

**Files:**
- Modify: `R/hv-man-table-jtcvs.R:108-171`
- Test: `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Consumes: nothing new.
- Produces: `hv_man_table_jtcvs(tbl, groups, trailing = NULL, stat_label = "No. (%) or Mean ± SD", font = "Times New Roman", font_size = 12)` — one new optional parameter, default matches current hard-coded text so every existing caller is unaffected.

- [ ] **Step 1: Write the failing test**

Add to `tests/testthat/test-hv-man-table-jtcvs.R` (after the existing `"hv_man_table_jtcvs applies the house font"` test block):

```r
test_that("hv_man_table_jtcvs accepts a custom stat_label", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)"),
    stat_label = "No. (%) or Median (15th, 85th percentile)"
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(
    grepl("No. (%) or Median (15th, 85th percentile)", xml, fixed = TRUE)
  )
  expect_false(grepl("Mean", xml, fixed = TRUE))
})

test_that("hv_man_table_jtcvs defaults stat_label to the mean/SD text", {
  ft <- hv_man_table_jtcvs(
    mk_jtcvs_tbl(),
    groups = c(stat_1 = "Group A (n=27)", stat_2 = "Group B (n=33)")
  )
  xml <- docx_xml_jtcvs(ft)
  expect_true(grepl("No. (%) or Mean", xml, fixed = TRUE))
})
```

- [ ] **Step 2: Run tests to verify the new one fails, existing ones still pass**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-man-table-jtcvs.R')"`
Expected: the two new tests FAIL (`stat_label` is an unused argument error on the first; the second passes already since it matches current behavior), all prior tests in the file PASS.

- [ ] **Step 3: Add the parameter**

In `R/hv-man-table-jtcvs.R`, change the function signature (line 108-109) from:

```r
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               font = "Times New Roman", font_size = 12) {
```

to:

```r
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               stat_label = "No. (%) or Mean ± SD",
                               font = "Times New Roman", font_size = 12) {
```

Then change line 136 from:

```r
    header_labels[[paste0("disp_", g)]] <- "No. (%) or Mean ± SD"
```

to:

```r
    header_labels[[paste0("disp_", g)]] <- stat_label
```

Add a new `@param` line to the roxygen block, right after the existing `@param trailing` block (before `@param font`):

```r
#' @param stat_label Sub-header text under each group's statistic column.
#'   Default `"No. (%) or Mean ± SD"` (house default for mean/SD
#'   tables). Pass e.g. `"No. (%) or Median (15th, 85th percentile)"` when
#'   the table's continuous statistic is a median, not a mean.
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-man-table-jtcvs.R')"`
Expected: PASS, all tests including the two new ones and the pre-existing `"hv_man_table_jtcvs reproduces template's header/section shape"` test (which asserts the literal `"No. (%) or Mean"` default text).

- [ ] **Step 5: Regenerate roxygen and commit**

```bash
Rscript -e "devtools::document()"
git add R/hv-man-table-jtcvs.R man/hv_man_table_jtcvs.Rd tests/testthat/test-hv-man-table-jtcvs.R
git commit -m "feat: add stat_label parameter to hv_man_table_jtcvs()"
```

---

### Task 2: `hv_tbl_summary()` skeleton — validation + continuous-only

**Files:**
- Create: `R/hv-tbl-summary.R`
- Create: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: `gtsummary::tbl_summary()`, `gtsummary::all_of()`, `gtsummary::modify_table_body()`.
- Produces: `hv_tbl_summary(data, by = NULL, groups, continuous = character(0), binary = character(0), categorical = character(0), percentiles = c(15, 85))` returning a `gtsummary` object with a `groupname_col` column set from `groups`. (`binary`/`categorical`/`compare` land in Tasks 3-4; this task wires the continuous-only, validation-complete skeleton.)

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-hv-tbl-summary.R`:

```r
mk_tbl_summary_data <- function() {
  set.seed(7)
  n <- 40
  data.frame(
    age = round(rnorm(n, 60, 10)),
    bsa = round(rnorm(n, 2, 0.2), 2),
    grp = factor(rep(c("A", "B"), each = n / 2))
  )
}

test_that("hv_tbl_summary rejects a non-data-frame", {
  expect_error(
    hv_tbl_summary(list(a = 1), groups = list(X = "a"), continuous = "a"),
    "must be a data frame"
  )
})

test_that("hv_tbl_summary rejects an unnamed groups list", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(dta, groups = list("age"), continuous = "age"),
    "named list"
  )
})

test_that("hv_tbl_summary rejects a percentiles vector of the wrong length", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = "age"), continuous = "age",
      percentiles = c(10, 50, 90)
    ),
    "length 2"
  )
})

test_that("hv_tbl_summary rejects a variable listed in two groups sections", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta,
      groups = list(A = "age", B = "age"),
      continuous = "age"
    ),
    "more than one"
  )
})

test_that("hv_tbl_summary rejects a groups variable missing from data", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = c("age", "nope")), continuous = c("age", "nope")
    ),
    "not found in `data`"
  )
})

test_that("hv_tbl_summary rejects an unclassified groups variable", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(dta, groups = list(Vitals = c("age", "bsa")), continuous = "age"),
    "not classified"
  )
})

test_that("hv_tbl_summary rejects a classified variable absent from groups", {
  dta <- mk_tbl_summary_data()
  expect_error(
    hv_tbl_summary(
      dta, groups = list(Vitals = "age"), continuous = c("age", "bsa")
    ),
    "not present in `groups`"
  )
})

test_that("hv_tbl_summary builds a continuous, ungrouped (by = NULL) table", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age"
  )
  expect_s3_class(tbl, "gtsummary")
  expect_identical(tbl$table_body$variable, "age")
  expect_identical(tbl$table_body$groupname_col, "Vitals")
  expect_true(grepl("^[0-9]+ \\|\\|\\|", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary builds a continuous, grouped (by given) table", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age"
  )
  expect_true(all(c("stat_1", "stat_2") %in% names(tbl$table_body)))
  expect_identical(tbl$table_body$groupname_col, "Vitals")
})

test_that("hv_tbl_summary does not comma-format large N (house style is plain digits)", {
  # Both real example tables examined during design (N=7948, 4190, 3758)
  # show plain digits, not "7,948" — gtsummary's default N_obs/n
  # formatter inserts thousands separators for any value >= 1000, which
  # this synthetic 1500-row dataset deliberately exceeds to catch a
  # regression.
  set.seed(3)
  n <- 1500
  dta <- data.frame(age = round(rnorm(n, 60, 10)))
  tbl <- hv_tbl_summary(dta, groups = list(Vitals = "age"), continuous = "age")
  expect_true(grepl("^1500 \\|\\|\\|", tbl$table_body$stat_0))
  expect_false(grepl(",", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary's percentiles argument changes the glue statistic", {
  # Pin structural shape ("N ||| median (lo, hi)") and prove the
  # percentiles argument actually flows into the glue string, without
  # pinning exact quantile values: gtsummary applies its own internal
  # digit-rounding to {pXX} tokens (verified empirically during planning
  # that it does not simply match stats::quantile(..., type = 2) rounded
  # with round() — e.g. a raw 80.5 rendered as "81", not R's round-half
  # -to-even "80") which is gtsummary's implementation detail, not
  # something hv_tbl_summary() controls or should assert on.
  dta <- mk_tbl_summary_data()
  default_tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age"
  )
  custom_tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age",
    percentiles = c(10, 90)
  )
  expect_match(
    custom_tbl$table_body$stat_0, "^[0-9]+ \\|\\|\\| [0-9.]+ \\([0-9.]+, [0-9.]+\\)$"
  )
  expect_false(identical(default_tbl$table_body$stat_0, custom_tbl$table_body$stat_0))
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: FAIL — `could not find function "hv_tbl_summary"`.

- [ ] **Step 3: Write the implementation**

Create `R/hv-tbl-summary.R`:

```r
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

  statistic <- stats::setNames(
    as.list(rep(cont_stat, length(continuous))), continuous
  )
  type <- stats::setNames(
    as.list(rep("continuous", length(continuous))), continuous
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: PASS, all 10 tests.

- [ ] **Step 5: Regenerate roxygen and commit**

```bash
Rscript -e "devtools::document()"
git add R/hv-tbl-summary.R man/hv_tbl_summary.Rd tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: add hv_tbl_summary() skeleton (validation + continuous)"
```

---

### Task 3: Add `binary` and `categorical` variable types

**Files:**
- Modify: `R/hv-tbl-summary.R`
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: same as Task 2.
- Produces: `hv_tbl_summary()` now honors `binary` (type `"dichotomous"`) and `categorical` (type `"categorical"`), both summarized with `"{N_obs} ||| {n} ({p}%)"`.

- [ ] **Step 1: Write the failing tests**

Add to `tests/testthat/test-hv-tbl-summary.R`:

```r
mk_tbl_summary_mixed_data <- function() {
  set.seed(11)
  n <- 60
  data.frame(
    age = round(rnorm(n, 60, 10)),
    flag = sample(0:1, n, replace = TRUE),
    race = factor(sample(c("White", "Black", "Other"), n, replace = TRUE)),
    grp = factor(rep(c("A", "B"), each = n / 2))
  )
}

test_that("hv_tbl_summary summarizes a binary variable as a single n (%) row", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "flag"), binary = "flag"
  )
  expect_identical(tbl$table_body$variable, "flag")
  expect_identical(tbl$table_body$row_type, "label")
  expect_true(grepl("^[0-9]+ \\|\\|\\| [0-9]+ \\([0-9.]+%\\)$", tbl$table_body$stat_0))
})

test_that("hv_tbl_summary summarizes a categorical variable with one row per level", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Demography = "race"), categorical = "race"
  )
  levels_shown <- tbl$table_body$label[tbl$table_body$row_type == "level"]
  expect_setequal(levels_shown, c("White", "Black", "Other"))
})

test_that("hv_tbl_summary mixes continuous, binary, and categorical in one call", {
  dta <- mk_tbl_summary_mixed_data()
  tbl <- hv_tbl_summary(
    dta,
    groups = list(Vitals = c("age", "flag"), Demography = "race"),
    continuous = "age", binary = "flag", categorical = "race"
  )
  expect_identical(
    tbl$table_body$variable[tbl$table_body$row_type != "level"],
    c("age", "flag", "race")
  )
  expect_identical(
    tbl$table_body$groupname_col[tbl$table_body$row_type != "level"],
    c("Vitals", "Vitals", "Demography")
  )
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: FAIL — binary/categorical variables are currently `setdiff`'d into the "not classified" error path... actually at this point they're accepted by validation (already in `classified`) but never added to `statistic`/`type`, so `tbl_summary()` receives them via `include` but with no matching `statistic`/`type` entries, falling back to gtsummary's own defaults (median/IQR for numeric, all-levels for factor) rather than the `{N_obs} ||| ...` glue pattern this package's renderer needs. Expected failure: `stat_0` regex assertions fail (no `|||` separator present).

- [ ] **Step 3: Extend the implementation**

In `R/hv-tbl-summary.R`, replace the `statistic`/`type` block from:

```r
  statistic <- stats::setNames(
    as.list(rep(cont_stat, length(continuous))), continuous
  )
  type <- stats::setNames(
    as.list(rep("continuous", length(continuous))), continuous
  )
```

with:

```r
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: PASS, all tests (Task 2's 10 plus these 3).

- [ ] **Step 5: Commit**

```bash
Rscript -e "devtools::document()"
git add R/hv-tbl-summary.R man/hv_tbl_summary.Rd tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: add binary and categorical variable types to hv_tbl_summary()"
```

---

### Task 4: `compare` — p-value, SMD, both, or none

**Files:**
- Modify: `R/hv-tbl-summary.R`
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: `gtsummary::add_p()`, `gtsummary::add_difference()`, `gtsummary::everything()`, `gtsummary::style_pvalue()`, `gtsummary::style_sigfig()`.
- Produces: when `by` is set and `compare != "none"`, `table_body` gains an `hv_compare_col` character column, and `attr(tbl, "hv_trailing")` is set to a length-1 named character vector (e.g. `c(hv_compare_col = "P")`) ready to pass as `hv_man_table_jtcvs()`'s `trailing` argument.

- [ ] **Step 1: Write the failing tests**

Add to `tests/testthat/test-hv-tbl-summary.R`:

```r
test_that("hv_tbl_summary compare is ignored (no-op) when by is NULL", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, groups = list(Vitals = "age"), continuous = "age", compare = "pvalue"
  )
  expect_false("hv_compare_col" %in% names(tbl$table_body))
  expect_null(attr(tbl, "hv_trailing"))
})

test_that("hv_tbl_summary compare = 'none' adds no comparison column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "none"
  )
  expect_false("hv_compare_col" %in% names(tbl$table_body))
  expect_null(attr(tbl, "hv_trailing"))
})

test_that("hv_tbl_summary compare = 'pvalue' adds a formatted p-value column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "pvalue"
  )
  expect_true("hv_compare_col" %in% names(tbl$table_body))
  expect_true(grepl("^(<)?[0-9.]+$", tbl$table_body$hv_compare_col))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "P"))
})

test_that("hv_tbl_summary compare = 'smd' adds a formatted std. diff. column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "smd"
  )
  expect_true("hv_compare_col" %in% names(tbl$table_body))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "Std. Diff."))
})

test_that("hv_tbl_summary compare = 'both' combines p-value and SMD in one column", {
  dta <- mk_tbl_summary_data()
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Vitals = "age"), continuous = "age",
    compare = "both"
  )
  expect_true(grepl("SMD", tbl$table_body$hv_compare_col))
  expect_identical(attr(tbl, "hv_trailing"), c(hv_compare_col = "P (SMD)"))
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: FAIL — `compare` is accepted (`match.arg()` already validates it, it's already a parameter from Task 2/3's signature) but has no effect yet; `hv_compare_col` is never added.

- [ ] **Step 3: Extend the implementation**

In `R/hv-tbl-summary.R`, replace the final block:

```r
  attr(tbl, "hv_stat_label") <- sprintf(
    "No. (%%) or Median (%sth, %sth percentile)", p_lo, p_hi
  )
  tbl
}
```

with:

```r
  attr(tbl, "hv_stat_label") <- sprintf(
    "No. (%%) or Median (%sth, %sth percentile)", p_lo, p_hi
  )

  effective_compare <- if (is.null(by)) "none" else compare
  if (effective_compare == "none") {
    return(tbl)
  }

  if (effective_compare %in% c("pvalue", "both")) {
    tbl <- gtsummary::add_p(tbl)
  }
  if (effective_compare %in% c("smd", "both")) {
    tbl <- gtsummary::add_difference(tbl, gtsummary::everything() ~ "smd")
  }

  tb <- tbl$table_body
  compare_col <- switch(
    effective_compare,
    pvalue = gtsummary::style_pvalue(tb$p.value, digits = 1),
    smd    = gtsummary::style_sigfig(tb$estimate),
    both   = ifelse(
      is.na(tb$p.value), NA_character_,
      sprintf(
        "%s (SMD %s)",
        gtsummary::style_pvalue(tb$p.value, digits = 1),
        gtsummary::style_sigfig(tb$estimate)
      )
    )
  )
  compare_label <- switch(
    effective_compare, pvalue = "P", smd = "Std. Diff.", both = "P (SMD)"
  )

  tbl <- gtsummary::modify_table_body(
    tbl, function(tb) { tb$hv_compare_col <- compare_col; tb }
  )
  attr(tbl, "hv_stat_label") <- sprintf(
    "No. (%%) or Median (%sth, %sth percentile)", p_lo, p_hi
  )
  attr(tbl, "hv_trailing") <- stats::setNames(compare_label, "hv_compare_col")

  tbl
}
```

Note: `hv_stat_label` is set a second time after the `add_p()`/`add_difference()` calls because `modify_table_body()` and the `add_*()` verbs return fresh `gtsummary` objects — attributes attached to the pre-comparison `tbl` do not automatically survive being passed through `add_p()`/`add_difference()`/`modify_table_body()` again. Re-set it after the LAST reassignment of `tbl` so it is present on the object actually returned. Verify this empirically in Step 4 (if `add_p()`/`add_difference()`/`modify_table_body()` turn out to already preserve custom attributes, the redundant first assignment is harmless dead code, not a bug — but do not remove it without confirming attribute survival first).

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: PASS, all tests (Task 2's 10, Task 3's 3, these 5 = 18 total). If `hv_stat_label`-related assertions fail because the attribute was dropped somewhere in the `add_p()`/`add_difference()`/`modify_table_body()` chain, add an explicit test (`expect_identical(attr(tbl, "hv_stat_label"), "No. (%) or Median (15th, 85th percentile)")` after a `compare = "pvalue"` call) to pin the fix, and confirm it passes before moving on.

- [ ] **Step 5: Commit**

```bash
Rscript -e "devtools::document()"
git add R/hv-tbl-summary.R man/hv_tbl_summary.Rd tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: add compare parameter (pvalue/smd/both/none) to hv_tbl_summary()"
```

---

### Task 5: End-to-end wiring + characterization test against real example tables

**Files:**
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: `hv_tbl_summary()` (Tasks 2-4), `hv_man_table_jtcvs()` (Task 1).
- Produces: nothing new — this task is test-only, proving the two functions compose correctly end to end and reproduce the real example tables' structural shape (group N's, section grouping, comparison column).

**Background:** Two real example tables were examined during the design brainstorm: `~/Downloads/summarytable_overall.docx` (N=7948, ungrouped) and `~/Downloads/summarytable_stratified_grp_res.docx` (N=7948 overall, split PERIMOUNT N=4190 / Resilia N=3758, with a `female` binary variable at 2327/964/1363 and a `race_gp` categorical variable with a "White" level at 7153/3833/3320). Neither file contains the underlying patient-level dataset — only the aggregated table output — so this test cannot recompute the exact reported medians from source data. Instead, following the same pattern the existing `hv_man_table_jtcvs()` characterization test uses (`tests/testthat/test-hv-man-table-jtcvs.R`'s `"reproduces template's header/section shape"` test, built on synthetic data sized to match a real template's actual group counts), this task builds synthetic data engineered to hit the real `female`/`race_gp` counts from `summarytable_stratified_grp_res.docx`, and verifies the rendered structure (group N's, section header, binary/categorical row shape, comparison column) matches.

- [ ] **Step 1: Write the test**

Add to `tests/testthat/test-hv-tbl-summary.R`:

```r
test_that("hv_tbl_summary + hv_man_table_jtcvs reproduce the stratified example's shape", {
  # Group and `female`/`race_gp` counts taken directly from
  # summarytable_stratified_grp_res.docx (PERIMOUNT n=4190, Resilia
  # n=3758; female: 964 of 4190 PERIMOUNT, 1363 of 3758 Resilia; race_gp
  # "White": 3833 of 4190 PERIMOUNT, 3320 of 3758 Resilia).
  set.seed(2026)
  n_perimount <- 4190
  n_resilia <- 3758
  dta <- data.frame(
    tissue = factor(
      rep(c("PERIMOUNT", "Resilia"), c(n_perimount, n_resilia)),
      levels = c("PERIMOUNT", "Resilia")
    ),
    female = c(
      sample(rep(0:1, c(n_perimount - 964, 964))),
      sample(rep(0:1, c(n_resilia - 1363, 1363)))
    ),
    race_gp = factor(c(
      sample(rep(c("White", "Other"), c(3833, n_perimount - 3833))),
      sample(rep(c("White", "Other"), c(3320, n_resilia - 3320)))
    ))
  )

  tbl <- hv_tbl_summary(
    dta, by = "tissue",
    groups = list(Demography = c("female", "race_gp")),
    binary = "female", categorical = "race_gp",
    compare = "pvalue"
  )

  expect_identical(as.integer(table(dta$tissue)), c(4190L, 3758L))
  female_row <- tbl$table_body[tbl$table_body$variable == "female", ]
  expect_true(grepl("^4190 \\|\\|\\| 964 ", female_row$stat_1))
  expect_true(grepl("^3758 \\|\\|\\| 1363 ", female_row$stat_2))

  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(
      stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"
    ),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  )
  expect_s3_class(ft, "flextable")

  body <- ft$body$dataset
  expect_identical(body$label[1], "Demography")
  expect_identical(body$n_stat_1[body$label == "female"], "4190")
  expect_identical(body$n_stat_2[body$label == "female"], "3758")
  expect_true("hv_compare_col" %in% ft$col_keys)
})
```

- [ ] **Step 2: Run the test**

Run: `Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-hv-tbl-summary.R')"`
Expected: PASS. If it fails, the most likely cause is a mismatch between `hv_man_table_jtcvs()`'s expectations of `trailing` (a length-1 named character vector already present as a column in `tbl$table_body`) and what `hv_tbl_summary()`'s `hv_trailing` attribute actually contains — re-read Task 4's Step 3 code and compare against `R/hv-man-table-jtcvs.R`'s `trailing` validation (lines ~114-121) before changing test expectations to match a broken implementation.

- [ ] **Step 3: Run the full test suite**

Run: `Rscript -e "devtools::test()"`
Expected: 0 failures across all test files (this package's existing ~90 tests plus this task's additions).

- [ ] **Step 4: Commit**

```bash
git add tests/testthat/test-hv-tbl-summary.R
git commit -m "test: characterization test for hv_tbl_summary() against real example table shape"
```

---

### Task 6: SAS migration cheat-sheet (README section)

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: nothing (documentation only).

**Background:** A full Quarto/knitr vignette (matching hvtiPlotR's `vignettes/sas-migration-guide.qmd`) would require adding vignette-build infrastructure (`VignetteBuilder` in `DESCRIPTION`, a `vignettes/` directory, `quarto` or `knitr`/`rmarkdown` as new Suggests dependencies) that this package does not currently have. The design spec explicitly leaves the choice open ("repo README section or vignette"); given the user's own request this session was specifically to update the README, and given no other vignette exists yet in this package to amortize that infrastructure cost against, this task adds the cheat-sheet as a README section. Revisit as a vignette later if/when this package grows a `vignettes/` directory for other reasons.

- [ ] **Step 1: Add the section**

Append to `README.md`, after the existing "## JTCVS submission format" section:

```markdown
## Migrating from the `%summarytable` SAS macro

`hv_tbl_summary()` builds a baseline-characteristics table from a grouped,
ordered variable list — the same shape as the `%summarytable` macro's
`LIST=` block — then hands the result straight to `hv_man_table_jtcvs()`.
It always uses a blanket non-parametric test (no per-variable Gaussian
classification) and reports continuous variables as
`median (P15, P85)` by default, not `mean ± SD`.

| `%summarytable` parameter | `hv_tbl_summary()` argument |
|---|---|
| `DATA=` | `data` |
| `CLASS=` | `by` |
| `LIST=` | `groups` |
| `CON1=` | `continuous` |
| `CAT1=` | `binary` |
| `CAT2=` | `categorical` |
| `PVALUES=` / `ASD=` | `compare` |
| `PP=` | `percentiles` |
| `TOTALCOL=` / `NCOL=` | handled automatically |

Not supported in this first pass: `WEIGHT=` (weighted summaries), `PROPENMT=`
(propensity-matched mode), `CON2=`/`CON3=` (Gaussian-classification split —
superseded by the blanket-nonparametric default), `SUBSET=`, `SORTBY=`
(ordering comes directly from `groups`). Ordinal variables (`ORD1=` in the
macro) fold into `categorical` here; no trend test is run.

A real `%summarytable` call, next to its `hv_tbl_summary()` equivalent:

``` sas
%summarytable(data=built,
              class=grp_res,
              con1=&gaussian.,
              cat1=&binary.,
              cat2=&catg.,
              pp=16 84,
              pvalues=1,
              list=
    /* Demography */
       female AGE BSA race_gp

    /* Symptoms */
       surgstat nyha_pr
);
```

``` r
library(gtsummary)
library(hvtiRtables)

tbl <- hv_tbl_summary(
  built,
  by = "grp_res",
  groups = list(
    Demography = c("female", "AGE", "BSA", "race_gp"),
    Symptoms   = c("surgstat", "nyha_pr")
  ),
  continuous  = c("AGE", "BSA"),
  binary      = c("female", "surgstat"),
  categorical = c("race_gp", "nyha_pr"),
  compare     = "pvalue",
  percentiles = c(16, 84)
)
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(
    stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"
  ),
  trailing = attr(tbl, "hv_trailing"),
  stat_label = attr(tbl, "hv_stat_label")
)
hv_man_table_save_jtcvs(
  ft, "table1.docx",
  caption = "Table 1. Baseline Characteristics by Tissue Type"
)
```
```

- [ ] **Step 2: Verify the README examples actually run**

Run:

```bash
Rscript -e '
library(gtsummary); library(hvtiRtables)
tbl <- hv_tbl_summary(
  mtcars, groups = list(Engine = c("mpg", "cyl")),
  continuous = "mpg", categorical = "cyl"
)
print(tbl)
'
```

Expected: prints a `gtsummary` table with no error (this is the function-level `@examples` block from Task 2, already covered by `R CMD check`; this step is a manual smoke check that the concept in the README section is not internally contradictory before Task 7's full check runs).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add SAS %summarytable migration cheat-sheet to README"
```

---

### Task 7: Version bump, NEWS.md, and full package check

**Files:**
- Modify: `DESCRIPTION`
- Modify: `NEWS.md`

**Interfaces:** None — release bookkeeping only.

- [ ] **Step 1: Bump the version**

In `DESCRIPTION`, change line 3 from:

```
Version: 0.9.0
```

to:

```
Version: 0.9.1
```

- [ ] **Step 2: Add a NEWS.md entry**

Insert at the top of `NEWS.md`, above the existing `# hvtiRtables 0.9.0` heading:

```markdown
# hvtiRtables 0.9.1

## New features

- `hv_tbl_summary()`: a thin wrapper over `gtsummary::tbl_summary()` /
  `add_p()` / `add_difference()` modeled on the interface biostats team
  members already know from the `%summarytable` SAS macro — a grouped,
  ordered variable list and variable-type buckets
  (`continuous`/`binary`/`categorical`), rather than gtsummary's own
  tidyselect interface. Always uses a blanket non-parametric test for
  continuous variables (no per-variable Gaussian classification) and
  reports `median (P15, P85)` by default, matching `hv_man_footnotes()`'s
  house convention. `compare` adds a p-value, standardized mean
  difference, or both, as a trailing column. Returns a plain `gtsummary`
  object ready for `hv_man_table_jtcvs()`. See the README's "Migrating
  from the `%summarytable` SAS macro" section for a parameter-mapping
  table and worked example.
- `hv_man_table_jtcvs()` gains a `stat_label` parameter (default
  `"No. (%) or Mean ± SD"`, unchanged for existing callers) so callers
  whose statistic is a median, not a mean, can set an accurate
  sub-header — `hv_tbl_summary()` sets this automatically.

```

- [ ] **Step 3: Run the full package check**

```bash
Rscript -e "devtools::document()"
Rscript -e "lintr::lint_package()"
Rscript -e "devtools::test()"
Rscript -e "devtools::check(manual = TRUE)"
```

Expected: `lint_package()` reports nothing; `test()` reports 0 failures; `check(manual = TRUE)` reports 0 errors, 0 warnings, 0 notes. If `check()` reports a NEWS-vs-DESCRIPTION version mismatch note, confirm both `DESCRIPTION` line 3 and `NEWS.md`'s top `Version:`-equivalent heading (`# hvtiRtables 0.9.1`) say `0.9.1` — this is the standing project rule that every dev-version bump touches both files.

- [ ] **Step 4: Commit**

```bash
git add DESCRIPTION NEWS.md
git commit -m "chore: bump version to 0.9.1 for hv_tbl_summary()"
```

---

## Self-Review Notes

- **Spec coverage:** Interface (Tasks 2-4), Statistical behavior (Tasks 2-4, `add_p()`/`add_difference()` defaults, no custom test-selection code), Architecture's `stat_label` renderer change (Task 1), Scope decisions (Variable column never added — Task 2's `tbl_summary()` call only ever includes `groups`' variables, not an internal-name column; dual-stat display out of scope — not implemented; ordinal folds into categorical — documented in Task 6's README section and the `@param categorical` roxygen), Migration guide (Task 6), Testing (Tasks 2-5: unit tests for `by = NULL`, each `compare=` option, input validation, and a characterization test against real example-table counts).
- **Explicitly deferred, confirmed not implemented:** propensity-matched mode, weighted summaries, per-variable Gaussian/non-Gaussian classification, ordinal trend tests. None of Tasks 1-7 touch these.
- **New design decision surfaced during planning, not in the original spec:** the spec's "Footnote letters marking which test ran per row reuse gtsummary's own test-name reporting from `add_p()`" bullet is satisfied passively — `add_p()`'s `test_name` column survives untouched on the object `hv_tbl_summary()` returns, so a caller can build `hv_man_table_save_jtcvs()`'s existing manual `footnotes = list(list(row=, col=, text=))` argument from it. This plan does **not** add automatic per-row lettered-footnote generation (deriving unique test names, assigning letters, building legend text) — that would be a new, undesigned subsystem, not a one-parameter addition like `stat_label`. Flag this to the user after Task 7 lands as a possible follow-up, rather than silently treating it as done.
- **Type consistency check:** `hv_man_table_jtcvs()`'s `trailing` parameter (Task 1, unchanged from its existing length-1 validation) matches `hv_tbl_summary()`'s `hv_trailing` attribute (Task 4), which is always exactly length-1 regardless of `compare` value (`"both"` combines p-value and SMD into one formatted string in one column, not two columns) — consistent with `hv_man_table_jtcvs()` never being modified in this plan to accept more than one trailing column.
- **Empirically validated, not just read against docs:** every code block in Tasks 2-5 was actually run against a live `gtsummary` 2.5.1 install before this plan was finalized (not just written from API documentation), which caught three real bugs the plan would otherwise have shipped: (1) `tbl_summary(by = by, ...)` with a bare string variable triggers a tidyselect "external vector" deprecation warning — fixed by wrapping `by` in `gtsummary::all_of()` the same way `include` already is; (2) `gtsummary`'s default `N_obs`/`n` formatter inserts thousands separators ("4,190") for any count >= 1000, which both real example tables (N=7948, 4190, 3758) actually reach and which does not match their plain-digit house style — fixed with an explicit `digits = list(everything() ~ list(N_obs = ..., n = ...))` argument and pinned with a dedicated >= 1000-row regression test in Task 2; (3) the original percentile test pinned an exact string built from `stats::quantile(..., type = 2)`, which does not match gtsummary's internal rounding (a raw 80.5 renders as "81", not R's `round()` "80") — replaced with a structural-shape assertion instead of an exact pinned value, since that internal rounding is gtsummary's implementation detail, not this package's.
