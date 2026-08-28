# hv_test_footnotes_jtcvs() Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `hv_test_footnotes_jtcvs()`, which reads `gtsummary`'s `test_name` column off an `hv_tbl_summary()` result and returns the lettered-footnote list `hv_man_table_save_jtcvs()` already accepts, so the SAS `%summarytable` macro's per-row test markers come out automatically instead of being hand-built.

**Architecture:** No new renderer and no new statistics. The helper takes the `gtsummary` object rather than the `flextable`, because by render time `test_name` and `groupname_col` have both been discarded. It maps `test_name` to house-readable labels in a fixed canonical order, collapses every row sharing a test onto one letter using a vector-valued `row`, and computes rendered row indices from the same section-start rule `hv_man_table_jtcvs()` uses, extracted into a shared internal so the two cannot drift.

**Tech Stack:** R, gtsummary (>= 2.5.0, already an Import), flextable, officer, testthat edition 3.

**Spec:** [2026-08-05-test-footnotes-design.md](../specs/2026-08-05-test-footnotes-design.md)

## Global Constraints

- No new dependencies. Everything needed is already in Imports.
- Naming: files `kebab-case.R`, functions `hv_<concept>()`. Test files mirror source names (`R/hv-test-footnotes-jtcvs.R` -> `tests/testthat/test-hv-test-footnotes-jtcvs.R`).
- No em-dashes in any code, comment, roxygen block, NEWS entry, or commit message.
- Version: patch digit only. Never bump the minor or major digit. `main` is at `0.9.1`; PR #13 bumps it to `0.9.2`. **Rebase onto `main` after #13 merges and bump `0.9.2` to `0.9.3`** in both `DESCRIPTION` and `NEWS.md`. If #13 has not merged, stop and ask rather than guessing the base version.
- Every exported function needs a complete `@param`/`@return`/`@examples` roxygen block, and `@examples` must be runnable (checked by `R CMD check --as-cran` with the manual build).
- Run `devtools::document()` after any roxygen change so `NAMESPACE` and `man/` stay in sync.
- `lintr::lint_package()` must be clean before each commit.
- Work on a branch. Never commit to `main`. Do not merge the PR; the maintainer merges their own.

## Facts verified against gtsummary 2.5.1 during design

Do not re-derive these; they are settled. Do not "fix" code that matches them.

- The only `test_name` values `hv_tbl_summary()` can produce are `wilcox.test`, `kruskal.test`, `chisq.test.no.correct`, `fisher.test`, and `smd`.
- `wilcox.test` and `kruskal.test` are **mutually exclusive in one table**: which one appears depends on whether `by` has 2 or 3+ levels. No single table can contain all four test names. Do not write a test asserting four footnotes from one table.
- `add_difference()` **errors** when `by` has more than two levels, so `compare = "smd"` and `compare = "both"` are two-group only.
- `test_name` is populated on every row of a variable (`label`, `level`), but the comparison value is non-`NA` only on the `label` row.
- `flextable::append_chunks(i = c(1, 3), ...)` attaches the same superscript to multiple rows, and `hv_man_table_save_jtcvs()` already passes `fn$row` straight through as `i`. Vector-valued `row` needs no change to the append loop.

---

### Task 1: Extract the section-start rule into shared internals

Right now the row-offset rule lives only inside `.reshape_jtcvs_body()`. Task 2 needs the same rule. Extracting it first means one source of truth instead of two copies that drift.

**Files:**
- Modify: `R/hv-man-table-jtcvs.R:1-62` (the `.reshape_jtcvs_body()` helper)
- Test: `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `.jtcvs_section_starts(tb)` -> `integer()`. Takes a `gtsummary` `table_body` data frame. Returns the row indices at which a new section begins, or `integer(0)` when there is no `groupname_col`.
  - `.jtcvs_body_row_index(tb)` -> `integer()`, length `nrow(tb)`. Maps each `table_body` row to its rendered `flextable` body row, accounting for interleaved section headers.

Both are internal (no `@export`, no roxygen `#'` block needed beyond a plain comment).

- [ ] **Step 1: Write the failing test**

Add to `tests/testthat/test-hv-man-table-jtcvs.R`, after the existing `".reshape_jtcvs_body works with no groupname_col (no sections)"` test block:

```r
test_that(".jtcvs_body_row_index agrees with .reshape_jtcvs_body's row order", {
  # Anti-drift guard. hv_test_footnotes_jtcvs() computes rendered row
  # indices from .jtcvs_body_row_index(); the renderer lays rows out via
  # .reshape_jtcvs_body(). If either is edited without the other, this
  # fails rather than silently marking the wrong cells.
  tbl <- mk_jtcvs_tbl()
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  expect_identical(
    hvtiRtables:::.jtcvs_body_row_index(tbl$table_body),
    which(!reshaped$is_section)
  )
})

test_that(".jtcvs_body_row_index offsets every row past its section header", {
  # mk_jtcvs_tbl() has 5 body rows in 2 sections (age under Demographics;
  # nyha plus its 3 levels under Cardiac), rendering as:
  #   1 Demographics  2 age  3 Cardiac  4 nyha  5 I  6 II  7 III
  # Note row 1 maps to 2, not 1: the header inserted before a section's
  # first row pushes that row down too. That is why the rule uses `<=`.
  expect_identical(
    hvtiRtables:::.jtcvs_body_row_index(mk_jtcvs_tbl()$table_body),
    c(2L, 4L, 5L, 6L, 7L)
  )
})

test_that(".jtcvs_section_starts returns integer(0) without groupname_col", {
  tb <- data.frame(label = c("a", "b"), stringsAsFactors = FALSE)
  expect_identical(hvtiRtables:::.jtcvs_section_starts(tb), integer(0))
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-man-table-jtcvs.R")'
```

Expected: 3 failures, each an error reading roughly `'.jtcvs_body_row_index' is not an exported object from 'namespace:hvtiRtables'` (or the same for `.jtcvs_section_starts`). If any test *passes*, stop: the functions already exist and this task is done.

- [ ] **Step 3: Add the two internals**

At the very top of `R/hv-man-table-jtcvs.R`, above the existing `.reshape_jtcvs_body <- function(...)` line, insert:

```r
# Row indices at which a new section begins. hv_man_table_jtcvs() inserts
# one section-header row immediately before each of these.
.jtcvs_section_starts <- function(tb) {
  if (!"groupname_col" %in% names(tb)) return(integer(0))
  which(c(TRUE, tb$groupname_col[-1] != tb$groupname_col[-nrow(tb)]))
}

# Rendered flextable body row for each gtsummary table_body row. `<=`
# rather than `<`: the header inserted before a section's first row pushes
# that row down as well.
.jtcvs_body_row_index <- function(tb) {
  starts <- .jtcvs_section_starts(tb)
  seq_len(nrow(tb)) +
    vapply(seq_len(nrow(tb)), function(i) sum(starts <= i), integer(1))
}
```

- [ ] **Step 4: Rewrite `.reshape_jtcvs_body()` to use the new internal**

In `R/hv-man-table-jtcvs.R`, find these two lines inside `.reshape_jtcvs_body()` (currently lines 33 and 36, after the `if (!has_sections)` early return):

```r
  is_section <- c(TRUE, tb$groupname_col[-1] != tb$groupname_col[-nrow(tb)])

  # Insert one section-header row before each run of same-groupname_col rows
  section_starts <- which(is_section)
```

Replace both with:

```r
  # Insert one section-header row before each run of same-groupname_col rows
  section_starts <- .jtcvs_section_starts(tb)
```

The local `is_section` variable is used only by that `which()` call, so it can go. Do **not** touch the `out$is_section` / `sec_rows$is_section` data frame *columns*, which are different things and are still needed.

- [ ] **Step 5: Run the full suite to verify green**

Run:

```bash
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'
```

Expected: all pass, 0 failures. The pre-existing `.reshape_jtcvs_body` tests passing unchanged is the proof this refactor preserved behavior.

- [ ] **Step 6: Lint**

Run:

```bash
Rscript -e 'lintr::lint_package(".")'
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add R/hv-man-table-jtcvs.R tests/testthat/test-hv-man-table-jtcvs.R
git commit -m "refactor: extract .jtcvs_section_starts/.jtcvs_body_row_index

The section-offset rule lived only inside .reshape_jtcvs_body().
hv_test_footnotes_jtcvs() needs the same rule to compute rendered row
indices, and a second copy would drift. Behavior is unchanged; the
existing .reshape_jtcvs_body tests pass untouched, and a new test asserts
the two agree row for row."
```

---

### Task 2: `hv_test_footnotes_jtcvs()`

**Files:**
- Create: `R/hv-test-footnotes-jtcvs.R`
- Create: `tests/testthat/test-hv-test-footnotes-jtcvs.R`

**Interfaces:**
- Consumes: `.jtcvs_body_row_index(tb)` from Task 1.
- Produces: `hv_test_footnotes_jtcvs(tbl)` -> `list()` of `list(row = <integer vector>, col = <string>, text = <string>)`, one element per distinct test, in canonical order. Returns `list()` when there is nothing to mark.

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-hv-test-footnotes-jtcvs.R`:

```r
# Categorical variable deliberately placed FIRST so that canonical
# ordering and order-of-first-appearance give different answers. If the
# implementation ever regresses to first-appearance, the letters flip and
# these tests fail.
mk_footnote_tbl_2grp <- function() {
  set.seed(5)
  n <- 200
  dta <- data.frame(
    grp  = factor(rep(c("A", "B"), each = n / 2)),
    sex  = factor(sample(c("F", "M"), n, replace = TRUE)),
    age  = rnorm(n, 60, 12),
    rare = factor(
      sample(c("y", "n"), n, replace = TRUE, prob = c(0.985, 0.015))
    )
  )
  hv_tbl_summary(
    dta, by = "grp",
    groups = list(Demography = c("sex", "age"), Other = "rare"),
    continuous = "age", categorical = c("sex", "rare"),
    compare = "pvalue"
  )
}

mk_footnote_tbl_3grp <- function() {
  set.seed(9)
  n <- 300
  dta <- data.frame(
    grp  = factor(rep(c("A", "B", "C"), each = n / 3)),
    age  = rnorm(n, 60, 12),
    sex  = factor(sample(c("F", "M"), n, replace = TRUE)),
    rare = factor(
      sample(c("y", "n"), n, replace = TRUE, prob = c(0.99, 0.01))
    )
  )
  hv_tbl_summary(
    dta, by = "grp",
    groups = list(Demography = c("age", "sex"), Other = "rare"),
    continuous = "age", categorical = c("sex", "rare"),
    compare = "pvalue"
  )
}

test_that("hv_test_footnotes_jtcvs rejects a non-gtsummary object", {
  expect_error(
    hv_test_footnotes_jtcvs(data.frame(a = 1)),
    "must be a gtsummary"
  )
})

test_that("hv_test_footnotes_jtcvs orders tests canonically, not by row", {
  # sex (chi-square) is body row 1 and age (Wilcoxon) is body row 4, yet
  # Wilcoxon takes letter a. Order of first appearance would invert this.
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_length(fns, 3)
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Wilcoxon rank-sum test.", "Pearson chi-square test.",
      "Fisher exact test.")
  )
})

test_that("hv_test_footnotes_jtcvs targets the comparison column", {
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_true(all(vapply(fns, function(f) f$col, character(1)) ==
                    "hv_compare_col"))
})

test_that("hv_test_footnotes_jtcvs points at rendered rows, not body rows", {
  # Rendered layout, with section headers interleaved:
  #   1 Demography  2 sex  3 F  4 M  5 age  6 Other  7 rare  8 n  9 y
  # Rows are deliberately non-monotonic across footnotes (5, 2, 7),
  # because canonical test order is independent of row order.
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_2grp())
  expect_identical(fns[[1]]$row, 5L)  # age, Wilcoxon
  expect_identical(fns[[2]]$row, 2L)  # sex, chi-square
  expect_identical(fns[[3]]$row, 7L)  # rare, Fisher
})

test_that("hv_test_footnotes_jtcvs uses Kruskal-Wallis for 3+ groups", {
  fns <- hv_test_footnotes_jtcvs(mk_footnote_tbl_3grp())
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Kruskal-Wallis test.", "Pearson chi-square test.",
      "Fisher exact test.")
  )
})

test_that("hv_test_footnotes_jtcvs collapses shared tests onto one letter", {
  # Two categorical variables both tested by chi-square must produce ONE
  # footnote with two row indices, not two footnotes.
  set.seed(21)
  n <- 200
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    sex = factor(sample(c("F", "M"), n, replace = TRUE)),
    hx  = factor(sample(c("yes", "no"), n, replace = TRUE))
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Demography = c("sex", "hx")),
    categorical = c("sex", "hx"), compare = "pvalue"
  )
  fns <- hv_test_footnotes_jtcvs(tbl)
  expect_length(fns, 1)
  expect_identical(fns[[1]]$text, "Pearson chi-square test.")
  expect_length(fns[[1]]$row, 2L)
})

test_that("hv_test_footnotes_jtcvs returns list() when there is no p-value", {
  set.seed(5)
  n <- 100
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    age = rnorm(n, 60, 12)
  )
  args <- list(
    dta, groups = list(Demography = "age"), continuous = "age"
  )

  no_by <- do.call(hv_tbl_summary, args)
  expect_identical(hv_test_footnotes_jtcvs(no_by), list())

  none <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "none")))
  expect_identical(hv_test_footnotes_jtcvs(none), list())

  smd <- do.call(hv_tbl_summary, c(args, list(by = "grp", compare = "smd")))
  expect_identical(hv_test_footnotes_jtcvs(smd), list())
})

test_that("hv_test_footnotes_jtcvs still marks tests when compare = 'both'", {
  # "both" renders "0.7 (SMD -0.03)" in one cell; the letter marks the
  # p-value portion. This works only because hv_tbl_summary() calls
  # add_difference() before add_p(); the reverse order overwrites
  # test_name with "smd". See NEWS 0.9.2.
  set.seed(5)
  n <- 100
  dta <- data.frame(
    grp = factor(rep(c("A", "B"), each = n / 2)),
    age = rnorm(n, 60, 12)
  )
  tbl <- hv_tbl_summary(
    dta, by = "grp", groups = list(Demography = "age"),
    continuous = "age", compare = "both"
  )
  fns <- hv_test_footnotes_jtcvs(tbl)
  expect_length(fns, 1)
  expect_identical(fns[[1]]$text, "Wilcoxon rank-sum test.")
})

test_that("hv_test_footnotes_jtcvs warns on an unmapped test_name", {
  tbl <- mk_footnote_tbl_2grp()
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$test_name[tb$variable == "age"] <- "mcnemar.test"
    tb
  })
  expect_warning(
    fns <- hv_test_footnotes_jtcvs(tbl),
    "mcnemar.test"
  )
  # Unmapped names sort after the canonical four, using the raw name.
  expect_identical(
    vapply(fns, function(f) f$text, character(1)),
    c("Pearson chi-square test.", "Fisher exact test.", "mcnemar.test")
  )
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-test-footnotes-jtcvs.R")'
```

Expected: every test errors with `could not find function "hv_test_footnotes_jtcvs"`.

- [ ] **Step 3: Write the implementation**

Create `R/hv-test-footnotes-jtcvs.R`:

```r
# gtsummary's internal test identifiers, in the order their letters are
# assigned. Canonical rather than first-appearance so two tables using the
# same set of tests get the same letters. "smd" is listed deliberately as
# a non-test: add_difference() writes it into test_name, and a
# standardized difference has no test to name.
.HV_TEST_LABELS <- c(
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

  known <- intersect(names(.HV_TEST_LABELS), present)
  unknown <- sort(setdiff(present, names(.HV_TEST_LABELS)))
  if (length(unknown) > 0)
    warning("Unrecognized `test_name` value(s), using the raw name as the ",
            "footnote text: ", paste(unknown, collapse = ", "),
            call. = FALSE)

  tests <- c(known, unknown)
  texts <- c(unname(.HV_TEST_LABELS[known]), unknown)
  row_index <- .jtcvs_body_row_index(tb)

  lapply(seq_along(tests), function(k) {
    hit <- shown & !is.na(tb$test_name) & tb$test_name == tests[k]
    list(row = row_index[hit], col = col, text = texts[k])
  })
}
```

`intersect()` preserves the order of its **first** argument, which is what makes the canonical ordering work. Do not swap the arguments.

- [ ] **Step 4: Regenerate docs and run tests to verify green**

Run:

```bash
Rscript -e 'devtools::document()'
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'
```

Expected: all pass, 0 failures. `NAMESPACE` should now contain `export(hv_test_footnotes_jtcvs)` and `man/hv_test_footnotes_jtcvs.Rd` should exist.

- [ ] **Step 5: Lint**

Run:

```bash
Rscript -e 'lintr::lint_package(".")'
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add R/hv-test-footnotes-jtcvs.R tests/testthat/test-hv-test-footnotes-jtcvs.R NAMESPACE man/
git commit -m "feat: add hv_test_footnotes_jtcvs()

Builds the lettered p-value footnotes the SAS %summarytable macro emits
from gtsummary's test_name column, returning the list
hv_man_table_save_jtcvs() already accepts.

Letters follow a fixed canonical order rather than order of first
appearance, so two tables using the same tests agree. Rows sharing a test
collapse onto one letter via a vector-valued row."
```

---

### Task 3: Validate footnote targets in the save function

The `footnotes` argument's `row` is computed against one object and applied to another. A wrong index currently marks the wrong cell silently. This makes it error instead, and corrects the `@param` text that wrongly describes `row` as a single index.

**Files:**
- Modify: `R/hv-man-table-save-jtcvs.R:14-21` (roxygen `@param footnotes`) and `:62-75` (the letters/append block)
- Test: `tests/testthat/test-hv-man-table-save-jtcvs.R`

**Interfaces:**
- Consumes: nothing new. `hv_man_table_save_jtcvs()`'s signature is unchanged.
- Produces: no new function. Behavior change only, for input that previously misbehaved silently.

- [ ] **Step 1: Write the failing tests**

Add to `tests/testthat/test-hv-man-table-save-jtcvs.R`, at the end of the file:

```r
test_that("hv_man_table_save_jtcvs rejects an out-of-range footnote row", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 999, col = "n_stat_1", text = "note"))
    ),
    "body row indices"
  )
})

test_that("hv_man_table_save_jtcvs rejects an unknown footnote column", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "Table 1. X",
      footnotes = list(list(row = 1, col = "nope", text = "note"))
    ),
    "not a column"
  )
})

test_that("hv_man_table_save_jtcvs marks every row of a vector-valued row", {
  ft <- mk_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. X",
    footnotes = list(list(row = c(1, 2), col = "n_stat_1", text = "note"))
  )
  xml <- read_docx_text(out)
  # One superscript "a" per marked cell, plus one in the footnote line.
  expect_gte(lengths(regmatches(xml, gregexpr("superscript", xml))), 3)
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-man-table-save-jtcvs.R")'
```

Expected: the two `expect_error` tests fail because no error is raised (or a different, flextable-internal error is). The vector-row test may already pass, since the append loop already supports it; that is fine and expected. Note which ones failed before continuing.

- [ ] **Step 3: Add the guard**

In `R/hv-man-table-save-jtcvs.R`, find this block:

```r
  letters_seq <- letters
  if (!is.null(footnotes) && length(footnotes) > length(letters_seq))
    stop("Too many footnotes (max ", length(letters_seq), " letters).",
         call. = FALSE)
```

Insert immediately after it:

```r
  if (!is.null(footnotes)) {
    n_body <- flextable::nrow_part(ft, "body")
    for (k in seq_along(footnotes)) {
      fn <- footnotes[[k]]
      if (!is.numeric(fn$row) || length(fn$row) == 0L || anyNA(fn$row) ||
            any(fn$row < 1) || any(fn$row > n_body))
        stop("`footnotes[[", k, "]]$row` must be body row indices between ",
             "1 and ", n_body, ". Row indices count the section-header ",
             "rows hv_man_table_jtcvs() interleaves; hv_test_footnotes_",
             "jtcvs() computes them for you.", call. = FALSE)
      if (!is.character(fn$col) || length(fn$col) != 1L ||
            !fn$col %in% ft$col_keys)
        stop("`footnotes[[", k, "]]$col` is not a column in `ft`: ",
             paste(fn$col, collapse = ", "), call. = FALSE)
    }
  }
```

- [ ] **Step 4: Correct the `@param footnotes` documentation**

In the same file, replace this roxygen block:

```r
#' @param footnotes Optional list of `list(row =, col =, text =)`, one per
#'   footnote, in the order letters should be assigned (`a`, `b`, ...).
#'   `row`/`col` address a body cell in `ft` (`col` is a `col_keys` name).
#'   `row` indexes `ft`'s body rows as shown: for a sectioned table (built
#'   with `groupname_col`), that includes the section-header rows
#'   [hv_man_table_jtcvs()] interleaves into the body, so you need to count
#'   those rows too when computing the target row index, not just the data
#'   rows.
```

with:

```r
#' @param footnotes Optional list of `list(row =, col =, text =)`, one per
#'   footnote, in the order letters should be assigned (`a`, `b`, ...).
#'   `col` is a single `col_keys` name. `row` may be a vector, in which
#'   case the one letter marks every row named, which is how several rows
#'   share a footnote. `row` indexes `ft`'s body rows as shown: for a
#'   sectioned table (built with `groupname_col`), that includes the
#'   section-header rows [hv_man_table_jtcvs()] interleaves into the body,
#'   so count those too. [hv_test_footnotes_jtcvs()] computes these
#'   indices for you when the footnotes mark statistical tests.
```

- [ ] **Step 5: Regenerate docs, run tests, lint**

Run:

```bash
Rscript -e 'devtools::document()'
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'
Rscript -e 'lintr::lint_package(".")'
```

Expected: all tests pass, 0 failures, no lint output.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-save-jtcvs.R tests/testthat/test-hv-man-table-save-jtcvs.R man/
git commit -m "fix: validate footnote row/col targets before rendering

A footnote row computed against a different object than the one being
rendered previously marked the wrong cell silently, or failed inside
flextable with a message that did not name the footnote. Both now error
with the offending entry's position.

Also corrects @param footnotes, which described row as a single index
when the append loop has always accepted a vector."
```

---

### Task 4: End-to-end test, package docs, and version bump

**Files:**
- Modify: `_pkgdown.yml` (the `Footnotes` reference section)
- Modify: `README.md` (the `%summarytable` migration section)
- Modify: `NEWS.md`, `DESCRIPTION`
- Test: `tests/testthat/test-hv-test-footnotes-jtcvs.R`

**Interfaces:**
- Consumes: `hv_test_footnotes_jtcvs()` from Task 2.
- Produces: no new code.

- [ ] **Step 1: Write the failing end-to-end test**

Append to `tests/testthat/test-hv-test-footnotes-jtcvs.R`:

```r
test_that("hv_test_footnotes_jtcvs round-trips through a saved .docx", {
  # Characterization against the SAS example's shape: a stratified table
  # whose letters are Kruskal-Wallis, chi-square, and Fisher. ANOVA is
  # absent by design, since this package tests continuous variables
  # non-parametrically throughout.
  tbl <- mk_footnote_tbl_3grp()
  ft <- hv_man_table_jtcvs(
    tbl,
    groups = c(stat_1 = "A (n=100)", stat_2 = "B (n=100)",
               stat_3 = "C (n=100)"),
    trailing = attr(tbl, "hv_trailing"),
    stat_label = attr(tbl, "hv_stat_label")
  )
  out <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(
    ft, out, caption = "Table 1. Baseline Characteristics",
    footnotes = hv_test_footnotes_jtcvs(tbl)
  )
  expect_true(file.exists(out))

  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(out, exdir = xdir)
  xml <- paste(
    readLines(file.path(xdir, "word", "document.xml"), warn = FALSE),
    collapse = ""
  )
  expect_true(grepl("Kruskal-Wallis test.", xml, fixed = TRUE))
  expect_true(grepl("Pearson chi-square test.", xml, fixed = TRUE))
  expect_true(grepl("Fisher exact test.", xml, fixed = TRUE))
  expect_false(grepl("ANOVA", xml, fixed = TRUE))
})
```

- [ ] **Step 2: Run it to verify it fails**

Run:

```bash
Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-test-footnotes-jtcvs.R")'
```

Expected: this is an integration test over code that already exists after Tasks 1 to 3, so it may pass immediately. If it does, that is acceptable here and is the one exception in this plan: it composes already-tested units rather than driving new code. If it *fails*, the failure is a real integration defect. Fix the code, not the test.

- [ ] **Step 3: Add the pkgdown reference entry**

In `_pkgdown.yml`, find:

```yaml
- title: "Footnotes"
  contents:
  - hv_man_footnotes
```

Replace with:

```yaml
- title: "Footnotes"
  contents:
  - hv_man_footnotes
  - hv_test_footnotes_jtcvs
```

- [ ] **Step 4: Add the README migration step**

In `README.md`, inside the "Migrating from the `%summarytable` SAS macro" section, after the worked example, add:

````markdown
### Lettered test footnotes

`%summarytable` marks each p-value with a superscript letter naming the
test behind it, and defines the letters below the table. Pass
`hv_test_footnotes_jtcvs()` to the save function to reproduce that:

```r
hv_man_table_save_jtcvs(
  ft, "table1.docx",
  caption   = "Table 1. Baseline Characteristics",
  footnotes = hv_test_footnotes_jtcvs(tbl)
)
```

Add study-specific footnotes alongside with `c()`; letters are assigned in
list order.

The letter set differs from the SAS macro's by design. `%summarytable`
classifies each continuous variable as Gaussian or non-Gaussian and emits
`a=ANOVA` for the Gaussian ones. This package tests continuous variables
non-parametrically throughout, so ANOVA never appears.
````

- [ ] **Step 5: Bump the version**

First confirm the base version. Run:

```bash
git fetch origin && git log --oneline origin/main -1 && grep '^Version:' DESCRIPTION
```

`DESCRIPTION` should read `Version: 0.9.2` (PR #13 merged). If it still reads `0.9.1`, **stop and ask the maintainer** rather than guessing.

Set `DESCRIPTION` line 3 to:

```
Version: 0.9.3
```

Add to the top of `NEWS.md`:

```markdown
# hvtiRtables 0.9.3

## New features

- `hv_test_footnotes_jtcvs()`: builds the lettered p-value footnotes the
  SAS `%summarytable` macro emits, reading `gtsummary`'s `test_name`
  column off an `hv_tbl_summary()` result and returning the list
  `hv_man_table_save_jtcvs()` already accepts. Letters follow a fixed
  order (Wilcoxon, Kruskal-Wallis, chi-square, Fisher), filtered to the
  tests used, so two tables using the same tests agree. ANOVA never
  appears, since this package tests continuous variables
  non-parametrically throughout.

## Bug fixes

- `hv_man_table_save_jtcvs()` now validates each footnote's `row` and
  `col` against the table being rendered. A row index computed against a
  different object previously marked the wrong cell silently.

```

- [ ] **Step 6: Run the full check**

Run:

```bash
Rscript -e 'devtools::document()'
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'
Rscript -e 'lintr::lint_package(".")'
```

Expected: all tests pass, 0 failures, no lint output.

Then the CRAN-style check, built from a clean export rather than the working tree (in a git worktree `.git` is a *file*, so `R CMD build`'s VCS exclusion misses it and it lands in the tarball as a spurious "hidden files" NOTE):

```bash
rm -rf /tmp/hvti-check && mkdir -p /tmp/hvti-check && git archive HEAD | tar -x -C /tmp/hvti-check && R CMD build /tmp/hvti-check && R CMD check --as-cran hvtiRtables_0.9.3.tar.gz
```

Expected: 0 errors, 0 warnings, 0 notes.

- [ ] **Step 7: Commit and open the PR**

```bash
git add _pkgdown.yml README.md NEWS.md DESCRIPTION tests/testthat/test-hv-test-footnotes-jtcvs.R man/
git commit -m "docs: document hv_test_footnotes_jtcvs(), bump to 0.9.3

Adds the pkgdown reference entry, a README migration step noting that the
R letter set omits ANOVA by design, and an end-to-end test asserting the
three expected labels reach the saved .docx and ANOVA does not."
git push -u origin <branch-name>
gh pr create --base main --title "feat: automatic lettered test footnotes" --body "<summary>"
```

Do not merge. The maintainer merges their own PRs.

---

## Self-Review Notes

**Spec coverage.** Every section of the spec maps to a task: architecture and naming to Task 2; test-label mapping to Task 2 Step 3; row-index computation and the shared internal to Task 1; which-cells-get-a-marker and the empty cases to Task 2 Step 1; the save-function guard to Task 3; testing, docs, and version to Tasks 2 through 4. The spec's "compare = both fix" section is already done in PR #13 and is correctly absent from this plan.

**Deviation from the spec, deliberate.** The spec's testing section calls for a case with "all four tests present." That is impossible: `wilcox.test` and `kruskal.test` are selected by group count and cannot co-occur in one table. Task 2 covers the two reachable three-test combinations instead, using a 2-group and a 3-group fixture. This is recorded under Global Constraints so an implementer does not try to "fix" it.

**Ordering is load-bearing.** Task 1 must precede Task 2; `hv_test_footnotes_jtcvs()` calls `.jtcvs_body_row_index()`. Task 3 is independent of Tasks 1 and 2 and could run in parallel. Task 4 depends on all three.

**Type consistency.** `.jtcvs_body_row_index()` returns `integer` (`seq_len()` plus a `vapply(..., integer(1))`), so `fns[[k]]$row` is `integer` and the tests use `2L` style literals. `col` is always a length-1 character. `text` is always a length-1 character.

**One honest exception to TDD.** Task 4 Step 1's end-to-end test may pass on first run, since it composes units already built and tested in Tasks 1 to 3. Task 4 Step 2 says so explicitly rather than pretending otherwise.
