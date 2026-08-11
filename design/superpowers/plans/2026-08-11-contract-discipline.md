# Public-Surface Contract Discipline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every public argument contract in `hvtiRtables` explicit,
enforced, consistent across sibling functions, documented, and tested.

**Architecture:** A new internal file `R/hv-validate.R` holds two layers —
`.check_*` argument validators (one argument's own shape) and `.assert_*`
precondition assertions (relationships between arguments, or between an
argument and the data it references). Every public function calls them at
entry, before any work. Contract-parity tests assert that sibling
functions reject the same input with the same message, making divergence a
test failure rather than a review finding.

**Tech Stack:** R (>= 4.1.0), `roxygen2` 8.1.0, `testthat` edition 3,
`gtsummary` (>= 2.5.0), `flextable` (>= 0.9.0), `officer`, `xml2`.

**Spec:** `design/superpowers/specs/2026-08-11-contract-discipline-design.md`

## Global Constraints

- **Branch:** `feat/contract-discipline`. Never commit to `main`. Open a PR
  at the end; the maintainer merges.
- **Line length:** 80 characters. `.lintr` is `linters_with_defaults()`,
  whose `line_length_linter` default is 80. CI runs `lint.yaml`.
- **Every `stop()` takes `call. = FALSE`.** Enforced by a meta-test in
  Task 7.
- **Never edit `.claude/house-style.md`.** It is a generated artifact; CI
  (`house-style.yaml`) fails the build when it drifts from its vault
  sources. No task in this plan touches it.
- **Roxygen is the source of truth for `man/*.Rd`.** After editing any
  roxygen block run `devtools::document()` and commit the regenerated
  `.Rd` alongside the `.R` change. Never hand-edit `man/*.Rd`.
- **Internal helpers are dot-prefixed and unexported** (`.check_file`,
  `.assert_stat_convention`), matching the existing convention
  (`.add_abbreviations_key`, `.jtcvs_section_starts`).
- **Run tests with `devtools::test()` or `testthat::test_local()`.**
  `testthat::test_dir()` does not load the package and produces false
  failures.
- **If lintr reports "no visible global function" for a function that
  plainly exists, reinstall the package** — it is a stale-install
  artifact, not a real lint. Do not add `# nolint`.
- **Message wording is specified verbatim in Task 1 and Task 2.** Later
  tasks assert on it with `expect_identical()`. Do not reword without
  updating both.

### Deviation from the spec, applied throughout

The spec's Section 2 sample messages render the "received" clause two
ways — `Received a vector of length 2.` and `Received: numeric of length
1.` This plan standardizes on the colon form everywhere:
`Received: a vector of length 2.` One helper (`.describe()`) produces the
clause, so the two cannot drift.

---

## File Structure

**Create:**

- `R/hv-validate.R` — both validator layers. Sole responsibility:
  input contracts. No rendering, no I/O.
- `R/hvtiRtables-package.R` — package-level roxygen block producing
  `?hvtiRtables`.
- `tests/testthat/helper-fixtures.R` — shared `gtsummary`/`flextable`
  fixtures for parity tests, plus the AST walker the meta-test uses.
- `tests/testthat/test-hv-validate.R` — validator and assertion units.
- `tests/testthat/test-contract-parity.R` — cross-function parity tests
  and the `call. = FALSE` meta-test.
- `vignettes/hvtiRtables.Rmd` — end-to-end worked study table.

**Modify:**

- `R/hv-man-table.R` — adopt validators (Task 3).
- `R/hv-man-table-save.R` — adopt validators, hoist abbreviation
  check out of `.add_abbreviations_key()` (Task 3).
- `R/hv-check-docx.R` — adopt `.check_string()` (Task 3).
- `R/hv-man-table-jtcvs.R` — defects 2, 3, 5 (Task 4).
- `R/hv-man-table-save-jtcvs.R` — defects 4, 6 (Task 5).
- `R/hv-tbl-summary.R` — defect 1 and `by` validation (Task 6).
- `_pkgdown.yml`, `DESCRIPTION`, `NEWS.md`, `CONTRIBUTING.md` (Tasks
  8–10).

---

### Task 1: Layer 1 — argument validators

**Files:**
- Create: `R/hv-validate.R`
- Test: `tests/testthat/test-hv-validate.R`

**Interfaces:**
- Consumes: nothing.
- Produces: `.describe(x)` returning a one-clause character description;
  `.check_gtsummary(x, arg = "tbl")`, `.check_flextable(x, arg = "ft")`,
  `.check_string(x, arg)`, `.check_font_size(x, arg = "font_size")`,
  `.check_file(x, arg = "file")`,
  `.check_abbreviations(x, arg = "abbreviations")`. Each errors via
  `stop(call. = FALSE)` on failure and returns `invisible(x)` on success.

- [ ] **Step 1: Write the failing tests**

Create `tests/testthat/test-hv-validate.R`:

```r
test_that(".describe reports class and length, never the value", {
  expect_identical(.describe(NULL), "NULL")
  expect_identical(.describe(c(11, 12)), "a vector of length 2")
  expect_identical(.describe(character(0)), "a vector of length 0")
  expect_identical(.describe(NA), "NA")
  expect_identical(.describe(10), "numeric of length 1")
  expect_identical(.describe("x"), "character of length 1")
})

test_that(".check_font_size accepts only 11 and 12", {
  expect_identical(.check_font_size(11), 11)
  expect_identical(.check_font_size(12), 12)
  for (bad in list(10, 13, c(11, 12), "12", NA_real_, numeric(0),
                   NULL)) {
    expect_error(.check_font_size(bad), "must be 11 or 12")
  }
})

test_that(".check_font_size message names the house rule", {
  expect_identical(
    tryCatch(.check_font_size(c(11, 12)), error = conditionMessage),
    paste0("`font_size` must be 11 or 12 (house rule: 12pt, 11pt ",
           "permitted for wide tables). Received: a vector of ",
           "length 2.")
  )
})

test_that(".check_string rejects every non-single-string shape", {
  expect_identical(.check_string("ok", "caption"), "ok")
  for (bad in list("", NA_character_, character(0), c("a", "b"), 1,
                   NULL, list("a"))) {
    expect_error(.check_string(bad, "caption"), "caption")
  }
})

test_that(".check_gtsummary and .check_flextable check class", {
  expect_error(.check_gtsummary("nope"), "gtsummary")
  expect_error(.check_flextable("nope"), "flextable")
  expect_error(.check_gtsummary("nope", "x"), "`x`")
})

test_that(".check_file rejects bad paths and missing directories", {
  f <- tempfile(fileext = ".docx")
  expect_identical(.check_file(f), f)
  for (bad in list(1, NA_character_, "", character(0), c("a", "b"),
                   NULL)) {
    expect_error(.check_file(bad), "must be a single non-empty file")
  }
  expect_error(
    .check_file(file.path(tempdir(), "no-such-dir", "x.docx")),
    "Output directory does not exist"
  )
})

test_that(".check_abbreviations enforces the documented type", {
  expect_silent(.check_abbreviations(NULL))
  expect_silent(.check_abbreviations(character(0)))
  expect_silent(.check_abbreviations(c(N = "sample size")))
  expect_error(.check_abbreviations(c("no name")), "non-empty name")
  expect_error(.check_abbreviations(list(N = "x")),
               "named character vector")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-validate")'`
Expected: FAIL, `could not find function ".describe"` and similar.

- [ ] **Step 3: Write the implementation**

Create `R/hv-validate.R`:

```r
# Shared argument validators (.check_*) and precondition assertions
# (.assert_*). Layer 1 validates one argument's own shape; layer 2
# validates relationships between arguments, or between an argument and
# the data it references.
#
# All error via stop(call. = FALSE) and return their input invisibly.
# None has a predicate (is_valid_*) form: every use in this package is
# fail-fast at function entry, and offering both forms would be the
# first place the two could drift apart.
#
# There is deliberately no .check_font(): its contract is identical to
# .check_string(), so `font` is validated by .check_string(font, "font").
# A wrapper would add a name without adding a rule.

# The "Received:" clause. Reports class and length rather than the
# value, which keeps the message short for a data frame or a connection,
# and is the most diagnostic thing for the commonest real mistake -- an
# argument-order slip, where the class mismatch is the tell.
.describe <- function(x) {
  if (is.null(x)) return("NULL")
  if (length(x) != 1L)
    return(sprintf("a vector of length %d", length(x)))
  if (is.atomic(x) && is.na(x)) return("NA")
  sprintf("%s of length 1", class(x)[1])
}

.check_gtsummary <- function(x, arg = "tbl") {
  if (!inherits(x, "gtsummary"))
    stop("`", arg, "` must be a gtsummary table object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_flextable <- function(x, arg = "ft") {
  if (!inherits(x, "flextable"))
    stop("`", arg, "` must be a flextable object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty string. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_font_size <- function(x, arg = "font_size") {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
        !(x %in% c(11, 12)))
    stop("`", arg, "` must be 11 or 12 (house rule: 12pt, 11pt ",
         "permitted for wide tables). Received: ", .describe(x), ".",
         call. = FALSE)
  invisible(x)
}

# Folds the string check and the directory check together because both
# savers already perform exactly those two steps in sequence; splitting
# them would leave two things to remember instead of one.
.check_file <- function(x, arg = "file") {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty file path. Received: ",
         .describe(x), ".", call. = FALSE)
  out_dir <- dirname(x)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  invisible(x)
}

.check_abbreviations <- function(x, arg = "abbreviations") {
  if (is.null(x) || length(x) == 0L) return(invisible(x))
  if (!is.character(x))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)). Received: ", .describe(x),
         ".", call. = FALSE)
  nms <- names(x)
  if (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)); every element must have a ",
         "non-empty name.", call. = FALSE)
  invisible(x)
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-validate")'`
Expected: PASS, 0 failures.

- [ ] **Step 5: Run the full suite for regressions**

Run: `Rscript -e 'devtools::test()'`
Expected: 213 existing tests still pass. Nothing is wired up yet, so
this must not change any existing behavior.

- [ ] **Step 6: Commit**

```bash
git add R/hv-validate.R tests/testthat/test-hv-validate.R
git commit -m "feat: add shared argument validators"
```

---

### Task 2: Layer 2 — precondition assertions

**Files:**
- Modify: `R/hv-validate.R` (append)
- Test: `tests/testthat/test-hv-validate.R` (append)

**Interfaces:**
- Consumes: `.describe()` from Task 1.
- Produces: `.assert_type_buckets(continuous, binary, categorical)`,
  `.assert_jtcvs_groups(tbl, groups, arg = "groups")`,
  `.assert_stat_convention(tb, groups, arg = "tbl")`,
  `.assert_footnote_entries(footnotes, ft, arg = "footnotes")`. Each
  errors via `stop(call. = FALSE)`; all return `invisible(NULL)` except
  `.assert_jtcvs_groups()`, which returns `invisible(groups)`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-hv-validate.R`:

```r
test_that(".assert_type_buckets rejects a variable in two buckets", {
  expect_silent(
    .assert_type_buckets(c("age"), character(0), c("sex"))
  )
  expect_identical(
    tryCatch(
      .assert_type_buckets(c("mpg"), c("mpg"), character(0)),
      error = conditionMessage
    ),
    paste0("`mpg` appears in more than one of `continuous`, `binary`, ",
           "and `categorical`. Every variable must be classified ",
           "exactly once. Overlapping: mpg (continuous, binary).")
  )
})

test_that(".assert_type_buckets requires character vectors", {
  expect_error(.assert_type_buckets(1, character(0), character(0)),
               "`continuous` must be a character vector")
})

test_that(".assert_jtcvs_groups checks names exist in table_body", {
  tbl <- fx_jtcvs_tbl()
  expect_silent(
    .assert_jtcvs_groups(tbl, c(stat_1 = "A", stat_2 = "B"))
  )
  expect_identical(
    tryCatch(
      .assert_jtcvs_groups(tbl, c(stat_3 = "C")),
      error = conditionMessage
    ),
    paste0("`groups` names must be columns in `tbl$table_body`. ",
           "Not found: stat_3. Available: stat_1, stat_2.")
  )
  expect_error(.assert_jtcvs_groups(tbl, c("A", "B")),
               "must have a non-empty name")
  expect_error(.assert_jtcvs_groups(tbl, character(0)),
               "must be a named character vector")
})

test_that(".assert_stat_convention accepts NA cells", {
  # A valid hv_tbl_summary() table carries NA stat cells on the parent
  # label row of a multi-level categorical. Requiring every cell to
  # split would reject correct tables.
  tbl <- fx_hv_tbl()
  expect_true(anyNA(tbl$table_body$stat_1))
  expect_silent(
    .assert_stat_convention(tbl$table_body,
                            c(stat_1 = "A", stat_2 = "B"))
  )
})

test_that(".assert_stat_convention rejects a table without |||", {
  tbl <- fx_plain_tbl()
  msg <- tryCatch(
    .assert_stat_convention(tbl$table_body, c(stat_1 = "A")),
    error = conditionMessage
  )
  expect_match(msg, "was not built with the", fixed = TRUE)
  expect_match(msg, "hv_tbl_summary()", fixed = TRUE)
  expect_match(msg, "First unparseable value:", fixed = TRUE)
})

test_that(".assert_footnote_entries requires a non-empty text", {
  ft <- fx_jtcvs_ft()
  ok <- list(list(row = 1, col = "n_stat_1", text = "Note."))
  expect_silent(.assert_footnote_entries(ok, ft))
  expect_identical(
    tryCatch(
      .assert_footnote_entries(
        list(list(row = 1, col = "n_stat_1")), ft
      ),
      error = conditionMessage
    ),
    paste0("`footnotes[[1]]$text` must be a single non-empty string; ",
           "it is missing. Each footnote needs ",
           "list(row =, col =, text =).")
  )
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1, col = "n_stat_1", text = "")), ft
    ),
    "must be a single non-empty string"
  )
})

test_that(".assert_footnote_entries keeps the row and col checks", {
  ft <- fx_jtcvs_ft()
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1.5, col = "n_stat_1", text = "x")), ft
    ),
    "must be whole numbers"
  )
  expect_error(
    .assert_footnote_entries(
      list(list(row = 1, col = "nope", text = "x")), ft
    ),
    "is not a column in `ft`"
  )
})
```

These tests use fixtures created in Task 7. To keep this task
independently runnable, create the fixture file now with only the four
functions used above.

- [ ] **Step 2: Create the fixture file**

Create `tests/testthat/helper-fixtures.R`:

```r
# Shared fixtures. Named fx_* rather than mk_* so they cannot collide
# with the per-file mk_tbl() helpers already defined in
# test-hv-man-table.R and its siblings.

# A gtsummary table built WITH the "{N_obs} ||| {stat}" convention.
fx_jtcvs_tbl <- function() {
  gtsummary::tbl_summary(
    gtsummary::trial,
    by = "trt",
    statistic = list(
      gtsummary::all_continuous() ~ "{N_obs} ||| {mean} ({sd})"
    ),
    include = c("age", "grade")
  )
}

# A gtsummary table built WITHOUT the convention.
fx_plain_tbl <- function() {
  gtsummary::tbl_summary(
    gtsummary::trial, by = "trt", include = c("age", "grade")
  )
}

# An hv_tbl_summary() table, which carries NA stat cells on the parent
# label row of the multi-level categorical.
fx_hv_tbl <- function() {
  hv_tbl_summary(
    gtsummary::trial,
    by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade",
    compare = "none"
  )
}

# A rendered JTCVS flextable.
fx_jtcvs_ft <- function() {
  hv_man_table_jtcvs(
    fx_jtcvs_tbl(), groups = c(stat_1 = "A", stat_2 = "B")
  )
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-validate")'`
Expected: FAIL, `could not find function ".assert_type_buckets"`.

- [ ] **Step 4: Write the implementation**

Append to `R/hv-validate.R`:

```r
# ---- Layer 2: precondition assertions ----------------------------

.assert_type_buckets <- function(continuous, binary, categorical) {
  buckets <- list(continuous = continuous, binary = binary,
                  categorical = categorical)
  for (nm in names(buckets)) {
    b <- buckets[[nm]]
    if (!is.character(b) || anyNA(b))
      stop("`", nm, "` must be a character vector of variable names. ",
           "Received: ", .describe(b), ".", call. = FALSE)
  }
  all_vars <- unlist(buckets, use.names = FALSE)
  dup <- unique(all_vars[duplicated(all_vars)])
  if (length(dup) == 0L) return(invisible(NULL))
  where <- vapply(dup, function(v) {
    hits <- names(buckets)[
      vapply(buckets, function(b) v %in% b, logical(1))
    ]
    sprintf("%s (%s)", v, paste(hits, collapse = ", "))
  }, character(1))
  stop("`", dup[1], "` appears in more than one of `continuous`, ",
       "`binary`, and `categorical`. Every variable must be ",
       "classified exactly once. Overlapping: ",
       paste(where, collapse = "; "), ".", call. = FALSE)
}

.assert_jtcvs_groups <- function(tbl, groups, arg = "groups") {
  if (!is.character(groups) || length(groups) == 0L || anyNA(groups))
    stop("`", arg, "` must be a named character vector, stat_<k> ",
         "column name -> spanning header label, e.g. ",
         "c(stat_1 = \"Drug A (n=98)\"). Received: ",
         .describe(groups), ".", call. = FALSE)
  nms <- names(groups)
  if (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))
    stop("`", arg, "` must be a named character vector; every element ",
         "must have a non-empty name, e.g. ",
         "c(stat_1 = \"Drug A (n=98)\").", call. = FALSE)
  available <- names(tbl$table_body)
  not_found <- setdiff(nms, available)
  if (length(not_found) > 0L) {
    # Show the stat_ columns, which is what a group name always is.
    # Fall back to every column when a hand-built object has none, so
    # the message never ends with an empty "Available:".
    shown <- grep("^stat_", available, value = TRUE)
    if (length(shown) == 0L) shown <- available
    stop("`", arg, "` names must be columns in `tbl$table_body`. ",
         "Not found: ", paste(not_found, collapse = ", "),
         ". Available: ", paste(shown, collapse = ", "), ".",
         call. = FALSE)
  }
  invisible(groups)
}

# The non-NA qualifier is load-bearing and was established empirically:
# a valid hv_tbl_summary() table carries NA stat cells on the parent
# label row of a multi-level categorical variable. A rule requiring
# every cell to split would reject correct tables.
.assert_stat_convention <- function(tb, groups, arg = "tbl") {
  for (col in names(groups)) {
    vals <- tb[[col]]
    keep <- !is.na(vals)
    if (!any(keep)) next
    parts <- strsplit(vals[keep], " \\|\\|\\| ")
    bad <- which(lengths(parts) != 2L)
    if (length(bad) == 0L) next
    stop("`", arg, "` was not built with the \"{N_obs} ||| {stat}\" ",
         "convention hv_man_table_jtcvs() requires, so column `", col,
         "` cannot be split into its N and statistic parts. Build it ",
         "with hv_tbl_summary(), or pass statistic = ",
         "list(all_continuous() ~ \"{N_obs} ||| {mean} ± {sd}\")",
         ". First unparseable value: \"", vals[keep][bad[1]], "\".",
         call. = FALSE)
  }
  invisible(NULL)
}

.assert_footnote_entries <- function(footnotes, ft,
                                     arg = "footnotes") {
  if (is.null(footnotes)) return(invisible(NULL))
  n_body <- flextable::nrow_part(ft, "body")
  for (k in seq_along(footnotes)) {
    fn <- footnotes[[k]]
    # Fractional rows are checked explicitly: flextable accepts them
    # silently rather than erroring, so without this they would mark
    # whatever cell they truncate to, which is the silent-wrong-cell
    # failure this validation exists to prevent.
    if (!is.numeric(fn$row) || length(fn$row) == 0L ||
          anyNA(fn$row) || any(!is.finite(fn$row)) ||
          any(fn$row %% 1 != 0) || any(fn$row < 1) ||
          any(fn$row > n_body))
      stop("`", arg, "[[", k, "]]$row` must be whole numbers between ",
           "1 and ", n_body, ", indexing `ft`'s body rows. Row ",
           "indices count the section-header rows ",
           "hv_man_table_jtcvs() interleaves; ",
           "hv_test_footnotes_jtcvs() computes them for you.",
           call. = FALSE)
    if (!is.character(fn$col) || length(fn$col) != 1L ||
          !fn$col %in% ft$col_keys)
      stop("`", arg, "[[", k, "]]$col` is not a column in `ft`: ",
           paste(fn$col, collapse = ", "), call. = FALSE)
    if (!is.character(fn$text) || length(fn$text) != 1L ||
          is.na(fn$text) || !nzchar(fn$text)) {
      got <- if (is.null(fn$text)) "missing" else .describe(fn$text)
      stop("`", arg, "[[", k, "]]$text` must be a single non-empty ",
           "string; it is ", got, ". Each footnote needs ",
           "list(row =, col =, text =).", call. = FALSE)
    }
  }
  invisible(NULL)
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-validate")'`
Expected: PASS.

- [ ] **Step 6: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: all existing tests still pass.

- [ ] **Step 7: Commit**

```bash
git add R/hv-validate.R tests/testthat/test-hv-validate.R \
  tests/testthat/helper-fixtures.R
git commit -m "feat: add precondition assertions for input contracts"
```

---

### Task 3: Adopt validators in the CORR branch

Behavior-preserving except for three deliberate tightenings, each noted
inline. This task proves the shared layer is a drop-in before the
defect fixes depend on it.

**Files:**
- Modify: `R/hv-man-table.R:51-59`
- Modify: `R/hv-man-table-save.R:51-58`, `R/hv-man-table-save.R:101-107`
- Modify: `R/hv-check-docx.R:201-203`
- Modify: `R/hv-test-footnotes-jtcvs.R:78-79`
- Test: existing `tests/testthat/test-hv-man-table.R`,
  `test-hv-man-table-save.R`, `test-hv-check-docx.R`,
  `test-hv-test-footnotes-jtcvs.R`

**Interfaces:**
- Consumes: `.check_gtsummary()`, `.check_flextable()`,
  `.check_string()`, `.check_font_size()`, `.check_file()`,
  `.check_abbreviations()` from Task 1.
- Produces: no new interfaces.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-hv-man-table.R`:

```r
test_that("hv_man_table validates font", {
  expect_error(hv_man_table(mk_tbl(), font = 12), "`font`")
  expect_error(hv_man_table(mk_tbl(), font = c("a", "b")), "`font`")
  expect_error(hv_man_table(mk_tbl(), font = ""), "`font`")
})
```

Append to `tests/testthat/test-hv-man-table-save.R`:

```r
test_that("hv_man_table_save rejects a non-character abbreviations", {
  ft <- hv_man_table(mk_tbl())
  f <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save(ft, f, abbreviations = list(N = "x")),
    "named character vector"
  )
  expect_false(file.exists(f))
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-man-table")'`
Expected: FAIL — `font = 12` currently succeeds, and the
`abbreviations` list currently writes the file.

- [ ] **Step 3: Rewrite `hv_man_table()`'s validation block**

In `R/hv-man-table.R`, replace lines 53-59 (the two `if` blocks) with:

```r
  .check_gtsummary(tbl)
  .check_string(font, "font")
  .check_font_size(font_size)
```

- [ ] **Step 4: Rewrite `hv_man_table_save()`'s validation block**

In `R/hv-man-table-save.R`, replace lines 53-58 with:

```r
  .check_flextable(ft)
  .check_file(file)
  # Hoisted out of .add_abbreviations_key() so it fires at entry
  # rather than mid-render: no partial .docx on a bad argument.
  .check_abbreviations(abbreviations)
```

Then in the same file remove the validation from
`.add_abbreviations_key()` — delete these lines:

```r
  abbr_names <- names(abbreviations)
  if (is.null(abbr_names) || anyNA(abbr_names) ||
        any(!nzchar(abbr_names)))
    stop("`abbreviations` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)); every element must have a ",
         "non-empty name.", call. = FALSE)
```

leaving the function starting:

```r
.add_abbreviations_key <- function(doc, abbreviations) {
  if (is.null(abbreviations) || length(abbreviations) == 0) return(doc)
  ordered <- abbreviations[order(names(abbreviations))]
```

- [ ] **Step 5: Tighten `hv_check_docx()`**

In `R/hv-check-docx.R`, replace lines 202-203 with:

```r
  .check_string(path, "path")
```

- [ ] **Step 6: Route `hv_test_footnotes_jtcvs()` through the validator**

This function also checks `tbl`'s class, and Task 7 asserts its message
is identical to the other two consumers'. In
`R/hv-test-footnotes-jtcvs.R`, replace lines 78-79:

```r
  if (!inherits(tbl, "gtsummary"))
    stop("`tbl` must be a gtsummary table object.", call. = FALSE)
```

with:

```r
  .check_gtsummary(tbl)
```

- [ ] **Step 7: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: PASS. The three tightenings — `font` shape, `abbreviations`
type, `path` non-empty — are the only behavior changes; existing tests
assert on message fragments (`"font_size"`, `"flextable"`,
`"gtsummary"`), which the appended `Received:` clause does not disturb.

- [ ] **Step 8: Commit**

```bash
git add R/hv-man-table.R R/hv-man-table-save.R R/hv-check-docx.R \
  R/hv-test-footnotes-jtcvs.R \
  tests/testthat/test-hv-man-table.R \
  tests/testthat/test-hv-man-table-save.R
git commit -m "refactor: adopt shared validators in the CORR branch"
```

---

### Task 4: JTCVS renderer — defects 2, 3, and 5

**Files:**
- Modify: `R/hv-man-table-jtcvs.R:128-145`
- Test: `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Consumes: `.check_gtsummary()`, `.check_string()`,
  `.check_font_size()` (Task 1); `.assert_jtcvs_groups()`,
  `.assert_stat_convention()` (Task 2); `fx_plain_tbl()`,
  `fx_jtcvs_tbl()` (Task 2 fixture file).
- Produces: no new interfaces.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-hv-man-table-jtcvs.R`:

```r
test_that("hv_man_table_jtcvs enforces the house font_size rule", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_s3_class(hv_man_table_jtcvs(tbl, g, font_size = 11),
                  "flextable")
  for (bad in list(10, c(11, 12), "12", NA_real_, numeric(0))) {
    expect_error(hv_man_table_jtcvs(tbl, g, font_size = bad),
                 "must be 11 or 12")
  }
})

test_that("hv_man_table_jtcvs validates font and stat_label", {
  tbl <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  expect_error(hv_man_table_jtcvs(tbl, g, font = 12), "`font`")
  expect_error(hv_man_table_jtcvs(tbl, g, stat_label = ""),
               "`stat_label`")
})

test_that("hv_man_table_jtcvs rejects unknown groups names", {
  tbl <- fx_jtcvs_tbl()
  expect_identical(
    tryCatch(hv_man_table_jtcvs(tbl, c(stat_3 = "C")),
             error = conditionMessage),
    paste0("`groups` names must be columns in `tbl$table_body`. ",
           "Not found: stat_3. Available: stat_1, stat_2.")
  )
})

test_that("hv_man_table_jtcvs refuses a table lacking the convention", {
  # Regression for the silent defect: this previously returned a
  # complete, correctly styled, entirely empty flextable.
  tbl <- fx_plain_tbl()
  expect_error(
    hv_man_table_jtcvs(tbl, c(stat_1 = "A", stat_2 = "B")),
    "was not built with the"
  )
})

test_that("hv_man_table_jtcvs accepts an hv_tbl_summary table", {
  # Guards the non-NA qualifier: this table has NA stat cells and must
  # still render.
  ft <- hv_man_table_jtcvs(fx_hv_tbl(),
                           c(stat_1 = "A", stat_2 = "B"))
  expect_s3_class(ft, "flextable")
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-man-table-jtcvs")'`
Expected: FAIL — `font_size = 10` succeeds, `stat_3` gives
`non-character argument`, and the plain table renders empty.

- [ ] **Step 3: Rewrite the validation block**

In `R/hv-man-table-jtcvs.R`, replace lines 131-143 with:

```r
  .check_gtsummary(tbl)
  .assert_jtcvs_groups(tbl, groups)
  .check_string(stat_label, "stat_label")
  .check_string(font, "font")
  .check_font_size(font_size)
  if (!is.null(trailing)) {
    if (!is.character(trailing) || length(trailing) != 1L ||
          is.null(names(trailing)) || !nzchar(names(trailing)))
      stop("`trailing` must be a named character vector of length 1 ",
           "(e.g. c(std_diff = \"Std. Diff.\")).", call. = FALSE)
    if (!names(trailing) %in% names(tbl$table_body))
      stop("`trailing` name `", names(trailing), "` is not a column ",
           "in `tbl$table_body`.", call. = FALSE)
  }
  # Runs before .reshape_jtcvs_body(), so a table lacking the
  # convention errors rather than rendering every cell blank.
  .assert_stat_convention(tbl$table_body, groups)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-man-table-jtcvs")'`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: PASS. Watch for existing tests that build a JTCVS table from
a non-conventional `tbl_summary()` — if any fail, they were relying on
the silent-empty behavior and must be updated to use the convention,
not have the assertion weakened.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-jtcvs.R tests/testthat/test-hv-man-table-jtcvs.R
git commit -m "fix: enforce font_size, groups, and stat convention in JTCVS mode"
```

---

### Task 5: JTCVS saver — defects 4 and 6

**Files:**
- Modify: `R/hv-man-table-save-jtcvs.R:52-89`
- Test: `tests/testthat/test-hv-man-table-save-jtcvs.R`

**Interfaces:**
- Consumes: `.check_flextable()`, `.check_file()`, `.check_string()`,
  `.check_abbreviations()` (Task 1); `.assert_footnote_entries()`
  (Task 2); `fx_jtcvs_ft()` (Task 2 fixture file).
- Produces: no new interfaces.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-hv-man-table-save-jtcvs.R`:

```r
test_that("hv_man_table_save_jtcvs validates file", {
  ft <- fx_jtcvs_ft()
  for (bad in list(1, NA_character_, "", character(0))) {
    expect_error(hv_man_table_save_jtcvs(ft, bad, caption = "T1."),
                 "must be a single non-empty file")
  }
})

test_that("hv_man_table_save_jtcvs rejects a footnote with no text", {
  # Regression for the silent defect: this previously wrote a .docx
  # with a dangling superscript marker and an empty footnote line.
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(
      ft, out, caption = "T1.",
      footnotes = list(list(row = 1, col = "n_stat_1"))
    ),
    "must be a single non-empty string"
  )
  expect_false(file.exists(out))
})

test_that("hv_man_table_save_jtcvs writes nothing when it rejects", {
  ft <- fx_jtcvs_ft()
  out <- tempfile(fileext = ".docx")
  expect_error(
    hv_man_table_save_jtcvs(ft, out, caption = "T1.",
                            abbreviations = list(N = "x")),
    "named character vector"
  )
  expect_false(file.exists(out))
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "save-jtcvs")'`
Expected: FAIL — `file = 1` gives `a character vector argument
expected`; the text-less footnote writes the file with no error.

- [ ] **Step 3: Rewrite the validation block**

In `R/hv-man-table-save-jtcvs.R`, replace lines 54-89 with:

```r
  .check_flextable(ft)
  .check_file(file)
  .check_string(caption, "caption")
  .check_abbreviations(abbreviations)

  letters_seq <- letters
  if (!is.null(footnotes) && length(footnotes) > length(letters_seq))
    stop("Too many footnotes (max ", length(letters_seq),
         " letters).", call. = FALSE)

  .assert_footnote_entries(footnotes, ft)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "save-jtcvs")'`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-save-jtcvs.R \
  tests/testthat/test-hv-man-table-save-jtcvs.R
git commit -m "fix: validate file and footnote text in the JTCVS saver"
```

---

### Task 6: `hv_tbl_summary()` — defect 1 and `by`

**Files:**
- Modify: `R/hv-tbl-summary.R:81-125`
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: `.check_string()` (Task 1), `.assert_type_buckets()`
  (Task 2).
- Produces: no new interfaces.

- [ ] **Step 1: Write the failing tests**

Append to `tests/testthat/test-hv-tbl-summary.R`:

```r
test_that("hv_tbl_summary rejects a variable in two type buckets", {
  expect_identical(
    tryCatch(
      hv_tbl_summary(mtcars, groups = list(Engine = "mpg"),
                     continuous = "mpg", binary = "mpg"),
      error = conditionMessage
    ),
    paste0("`mpg` appears in more than one of `continuous`, `binary`, ",
           "and `categorical`. Every variable must be classified ",
           "exactly once. Overlapping: mpg (continuous, binary).")
  )
})

test_that("hv_tbl_summary validates by in the package's own words", {
  expect_error(
    hv_tbl_summary(mtcars, by = "nope", groups = list(E = "mpg"),
                   continuous = "mpg"),
    "Variable(s) not found in `data`: nope", fixed = TRUE
  )
  expect_error(
    hv_tbl_summary(mtcars, by = c("am", "vs"),
                   groups = list(E = "mpg"), continuous = "mpg"),
    "`by`"
  )
  expect_error(
    hv_tbl_summary(mtcars, by = 1, groups = list(E = "mpg"),
                   continuous = "mpg"),
    "`by`"
  )
})

test_that("hv_tbl_summary rejects non-character type buckets", {
  expect_error(
    hv_tbl_summary(mtcars, groups = list(E = "mpg"), continuous = 1),
    "`continuous` must be a character vector"
  )
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e 'devtools::test(filter = "tbl-summary")'`
Expected: FAIL — the overlap case dies inside `gtsummary` with
`Summary type is "dichotomous" ...`; `by = "nope"` produces
`gtsummary::all_of()` vocabulary.

- [ ] **Step 3: Insert the new validation**

In `R/hv-tbl-summary.R`, immediately after the existing `data` check
(line 82, ending `stop("\`data\` must be a data frame.", ...)`), insert:

```r
  .assert_type_buckets(continuous, binary, categorical)
  # `by` fails the same way `groups` variables do, in this function's
  # own words. gtsummary's own error here is unusually good, but having
  # `by` fail differently from `groups` inside one function is exactly
  # the inconsistency this contract removes.
  if (!is.null(by)) {
    .check_string(by, "by")
    if (!by %in% names(data))
      stop("Variable(s) not found in `data`: ", by, call. = FALSE)
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "tbl-summary")'`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add R/hv-tbl-summary.R tests/testthat/test-hv-tbl-summary.R
git commit -m "fix: enforce single type classification and validate by"
```

---

### Task 7: Contract-parity tests and the `call. = FALSE` meta-test

**Files:**
- Create: `tests/testthat/test-contract-parity.R`
- Modify: `tests/testthat/helper-fixtures.R` (append the AST walker)

**Interfaces:**
- Consumes: every public function; fixtures from Task 2.
- Produces: `.fx_stop_calls(expr)`, a test-only AST walker returning a
  list of `stop()` call objects found anywhere in an expression.

- [ ] **Step 1: Append the AST walker to the fixture file**

Append to `tests/testthat/helper-fixtures.R`:

```r
# Collect every stop() call in an expression tree. A regex over
# deparsed source cannot be trusted here: nested parentheses inside a
# message string would end the match early and let an offender pass.
.fx_stop_calls <- function(expr, out = list()) {
  if (!is.call(expr)) return(out)
  if (identical(expr[[1]], quote(stop))) out <- c(out, list(expr))
  for (i in seq_along(expr)) {
    part <- tryCatch(expr[[i]], error = function(e) NULL)
    if (!is.null(part)) out <- .fx_stop_calls(part, out)
  }
  out
}
```

- [ ] **Step 2: Write the failing tests**

Create `tests/testthat/test-contract-parity.R`:

```r
# These tests make sibling divergence a test failure rather than a
# review finding. expect_identical() is deliberately stricter than
# expect_match(): the requirement is that the two messages are the
# same sentence, so the test must fail when they drift by a word.

test_that("font_size contract is identical across both renderers", {
  corr <- fx_plain_tbl()
  jt <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  for (bad in list(10, 13, c(11, 12), "12", NA_real_, numeric(0))) {
    m1 <- tryCatch(hv_man_table(corr, font_size = bad),
                   error = conditionMessage)
    m2 <- tryCatch(hv_man_table_jtcvs(jt, g, font_size = bad),
                   error = conditionMessage)
    expect_identical(m1, m2)
  }
})

test_that("font contract is identical across both renderers", {
  corr <- fx_plain_tbl()
  jt <- fx_jtcvs_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  for (bad in list(12, c("a", "b"), "", NA_character_)) {
    m1 <- tryCatch(hv_man_table(corr, font = bad),
                   error = conditionMessage)
    m2 <- tryCatch(hv_man_table_jtcvs(jt, g, font = bad),
                   error = conditionMessage)
    expect_identical(m1, m2)
  }
})

test_that("file contract is identical across both savers", {
  ft_corr <- hv_man_table(fx_plain_tbl())
  ft_jt <- fx_jtcvs_ft()
  for (bad in list(1, NA_character_, "", character(0))) {
    m1 <- tryCatch(hv_man_table_save(ft_corr, bad),
                   error = conditionMessage)
    m2 <- tryCatch(
      hv_man_table_save_jtcvs(ft_jt, bad, caption = "T1."),
      error = conditionMessage
    )
    expect_identical(m1, m2)
  }
})

test_that("tbl-class contract is identical across all consumers", {
  g <- c(stat_1 = "A")
  m1 <- tryCatch(hv_man_table("nope"), error = conditionMessage)
  m2 <- tryCatch(hv_man_table_jtcvs("nope", g),
                 error = conditionMessage)
  m3 <- tryCatch(hv_test_footnotes_jtcvs("nope"),
                 error = conditionMessage)
  expect_identical(m1, m2)
  expect_identical(m1, m3)
})

test_that("ft-class contract is identical across both savers", {
  m1 <- tryCatch(hv_man_table_save("nope", tempfile()),
                 error = conditionMessage)
  m2 <- tryCatch(
    hv_man_table_save_jtcvs("nope", tempfile(), caption = "T1."),
    error = conditionMessage
  )
  expect_identical(m1, m2)
})

test_that("every stop() in the package passes call. = FALSE", {
  ns <- asNamespace("hvtiRtables")
  offenders <- character(0)
  for (nm in ls(ns, all.names = TRUE)) {
    obj <- get(nm, envir = ns)
    if (!is.function(obj) || is.null(body(obj))) next
    for (cl in .fx_stop_calls(body(obj))) {
      args <- as.list(cl)[-1]
      ok <- "call." %in% names(args) &&
        identical(args[["call."]], FALSE)
      if (!ok) offenders <- c(offenders, nm)
    }
  }
  expect_identical(unique(offenders), character(0))
})
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `Rscript -e 'devtools::test(filter = "contract-parity")'`
Expected: PASS. Tasks 3–6 already aligned the messages; this task
locks that in. If any parity test fails, the fix is to route both
siblings through the same validator — never to relax the assertion.

- [ ] **Step 4: Deliberately break parity to prove the test bites**

Temporarily change `hv_man_table.R`'s `.check_font_size(font_size)` to
`.check_font_size(font_size, "size")`, then run:

Run: `Rscript -e 'devtools::test(filter = "contract-parity")'`
Expected: FAIL on the `font_size` parity test. Revert the change and
re-run to confirm PASS. A parity test that cannot fail is worthless;
this step verifies it can.

- [ ] **Step 5: Run the full suite**

Run: `Rscript -e 'devtools::test()'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add tests/testthat/test-contract-parity.R \
  tests/testthat/helper-fixtures.R
git commit -m "test: assert contract parity across sibling functions"
```

---

### Task 8: Documentation — Rd contract and package-level topic

**Files:**
- Create: `R/hvtiRtables-package.R`
- Modify: roxygen blocks in `R/hv-man-table.R`,
  `R/hv-man-table-jtcvs.R`, `R/hv-man-table-save-jtcvs.R`,
  `R/hv-tbl-summary.R`
- Modify: `_pkgdown.yml`
- Regenerate: `man/*.Rd`, `NAMESPACE`

**Interfaces:**
- Consumes: the enforced contracts from Tasks 3–6.
- Produces: `?hvtiRtables` topic.

- [ ] **Step 1: Create the package-level roxygen block**

Create `R/hvtiRtables-package.R`:

```r
#' hvtiRtables: Manuscript-Compliant Table Construction
#'
#' Turns `gtsummary` table objects into MS Word tables that comply with
#' HVTI CORR's "Table Construction for Manuscripts" rules. Two
#' rendering modes exist because CORR reports and JTCVS submissions
#' want different things from the same header row.
#'
#' @section Which mode do I want?:
#' **CORR house style** — flat, non-merged header, no hidden spacer
#' columns, footnotes as text below the table. Use for internal reports
#' and any journal without its own template.
#'
#' ```
#' tbl <- gtsummary::tbl_summary(dta, by = "trt")
#' ft  <- hv_man_table(tbl)
#' hv_man_table_save(ft, "table1.docx")
#' ```
#'
#' **JTCVS submission format** — two-row merged spanning header,
#' shaded section rows, lettered cell-targeted footnotes. Use when
#' submitting to that journal.
#'
#' ```
#' tbl <- hv_tbl_summary(
#'   dta, by = "trt",
#'   groups = list(Demography = c("age", "sex")),
#'   continuous = "age", categorical = "sex"
#' )
#' ft <- hv_man_table_jtcvs(
#'   tbl, groups = c(stat_1 = "A (n=98)", stat_2 = "B (n=102)"),
#'   stat_label = attr(tbl, "hv_stat_label"),
#'   trailing = attr(tbl, "hv_trailing")
#' )
#' hv_man_table_save_jtcvs(
#'   ft, "table1.docx", caption = "Table 1. Baseline Characteristics",
#'   footnotes = hv_test_footnotes_jtcvs(tbl)
#' )
#' ```
#'
#' @section Checking a finished document:
#' [hv_check_docx()] reads any `.docx` and reports the structural
#' patterns the house rules forbid. Neither saver runs it on its own
#' output, so call it on the path afterwards.
#'
#' @keywords internal
"_PACKAGE"
```

- [ ] **Step 2: Regenerate and verify the topic resolves**

Run:
```bash
Rscript -e 'devtools::document()'
Rscript -e 'pkgload::load_all("."); print(utils::help("hvtiRtables"))'
```
Expected: `man/hvtiRtables-package.Rd` created; the help lookup returns
a path rather than erroring.

- [ ] **Step 3: Update `@param` entries to state accepted values**

In `R/hv-man-table-jtcvs.R`, replace the `font_size` param (line 105-106):

```r
#' @param font_size Font size in points. Default `12` (house rule 5);
#'   pass `11` for wide tables. No other values are permitted --
#'   the same rule [hv_man_table()] enforces.
```

In the same file, replace the `groups` param (lines 94-96):

```r
#' @param groups Named character vector, `stat_<k>` column name in
#'   `tbl$table_body` -> spanning header label (include the group's N
#'   in the label text yourself, e.g. `c(stat_1 = "Group A (n=60)")`).
#'   Every name must be a column of `tbl$table_body`; unknown names
#'   are rejected with the available ones listed.
```

And the `tbl` param (lines 91-92):

```r
#' @param tbl A `gtsummary` table object whose `statistic` argument
#'   used `"{N_obs} ||| {<stat>}"` for every group column.
#'   [hv_tbl_summary()] applies this convention for you. A table
#'   without it is rejected, since its cells cannot be split into
#'   their N and statistic parts.
```

In `R/hv-man-table.R`, replace the `font` param to match the enforced
contract (insert above `font_size`, line 31):

```r
#' @param font Font family. Default `"Times New Roman"` (house rule).
#'   Any single non-empty string is accepted: `flextable` silently
#'   substitutes an unknown font name, so a typo would otherwise pass
#'   unnoticed, while a deliberate override is legitimate.
```

Copy that same `font` param text verbatim into
`R/hv-man-table-jtcvs.R`, replacing its line 104.

- [ ] **Step 4: Add `@section Common mistakes:` blocks**

In `R/hv-man-table-jtcvs.R`, insert before `@param tbl`:

```r
#' @section Common mistakes:
#' **"`tbl` was not built with the `{N_obs} ||| {stat}` convention."**
#' The table came from a plain [gtsummary::tbl_summary()] call. Build
#' it with [hv_tbl_summary()], which applies the convention
#' automatically, or pass
#' `statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ({sd})")`.
#' Before this check existed, such a table rendered every cell blank.
#'
#' **"`groups` names must be columns in `tbl$table_body`."** Group
#' names are the `stat_<k>` columns `gtsummary` creates, one per level
#' of the `by` variable -- not the group labels. Two groups give
#' `stat_1` and `stat_2`.
#'
#' **"`font_size` must be 11 or 12."** House rule 5. Use `11` only for
#' wide tables.
```

In `R/hv-man-table-save-jtcvs.R`, insert before `@param ft`:

```r
#' @section Common mistakes:
#' **"`footnotes[[k]]$text` must be a single non-empty string."** Every
#' footnote needs all three of `row`, `col`, and `text`. Before this
#' check existed, an entry missing `text` wrote a document with a
#' dangling superscript marker and an empty footnote line.
#'
#' **"`footnotes[[k]]$row` must be whole numbers ..."** Row indices
#' count the section-header rows [hv_man_table_jtcvs()] interleaves
#' into the body. [hv_test_footnotes_jtcvs()] computes them for you.
#'
#' **"`file` must be a single non-empty file path."** Check the
#' argument order: it is `(ft, file, caption)`.
```

In `R/hv-tbl-summary.R`, insert before `@param data`:

```r
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
```

- [ ] **Step 5: Replace the toy example in `hv_tbl_summary()`**

In `R/hv-tbl-summary.R`, replace the `@examples` block (lines 64-70)
with a baseline-characteristics table:

```r
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
```

- [ ] **Step 6: Register the new topic in pkgdown**

In `_pkgdown.yml`, add a section at the end of the `reference:` list:

```yaml
- title: "Package overview"
  desc: >
    Which rendering mode to use, and both pipelines end to end.
  contents:
  - hvtiRtables-package
```

- [ ] **Step 7: Regenerate docs and verify**

Run:
```bash
Rscript -e 'devtools::document()'
Rscript -e 'pkgdown::check_pkgdown()'
Rscript -e 'devtools::run_examples()'
```
Expected: `check_pkgdown()` reports no unregistered topics; every
example runs without error.

- [ ] **Step 8: Commit**

```bash
git add R/ man/ NAMESPACE _pkgdown.yml
git commit -m "docs: state accepted values, add common-mistakes sections and package topic"
```

---

### Task 9: End-to-end vignette

**Files:**
- Create: `vignettes/hvtiRtables.Rmd`
- Modify: `DESCRIPTION`

**Interfaces:**
- Consumes: every public function.
- Produces: no code interfaces.

- [ ] **Step 1: Add the vignette machinery to DESCRIPTION**

In `DESCRIPTION`, add to `Suggests:` (keeping alphabetical order):

```
    knitr,
    rmarkdown,
```

and add a new field after `Config/testthat/edition: 3`:

```
VignetteBuilder: knitr
```

- [ ] **Step 2: Write the vignette**

Create `vignettes/hvtiRtables.Rmd`:

````markdown
---
title: "Building a manuscript table end to end"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Building a manuscript table end to end}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
```

```{r setup}
library(hvtiRtables)
```

This walks one complete JTCVS submission table, from a data frame to a
checked `.docx`. The CORR house-style path is shorter and covered in
`?hv_man_table`.

## 1. Summarize the data

`hv_tbl_summary()` takes a grouped, ordered variable list and type
buckets, the way the SAS `%summarytable` macro does. Every variable in
`groups` appears in exactly one of `continuous`, `binary`, or
`categorical`.

```{r}
tbl <- hv_tbl_summary(
  gtsummary::trial,
  by = "trt",
  groups = list(
    Demography = c("age", "marker"),
    Disease = c("stage", "grade")
  ),
  continuous = c("age", "marker"),
  categorical = c("stage", "grade"),
  compare = "pvalue"
)
```

The result carries two attributes the renderer wants: the
percentile-aware sub-header text, and a ready-made `trailing` argument
for the comparison column.

```{r}
attr(tbl, "hv_stat_label")
attr(tbl, "hv_trailing")
```

## 2. Render the JTCVS shape

```{r}
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)"),
  stat_label = attr(tbl, "hv_stat_label"),
  trailing = attr(tbl, "hv_trailing")
)
```

`groups` names are the `stat_<k>` columns `gtsummary` built, one per
level of `trt`. The labels are yours, including each arm's N.

## 3. Build the test footnotes

`hv_test_footnotes_jtcvs()` reads which test produced each p-value and
returns footnotes in the shape the saver expects, with the body-row
indices already computed.

```{r}
notes <- hv_test_footnotes_jtcvs(tbl)
length(notes)
notes[[1]]$text
```

## 4. Save and check

```{r}
out <- tempfile(fileext = ".docx")
hv_man_table_save_jtcvs(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  footnotes = notes,
  abbreviations = c(SMD = "standardized mean difference")
)
```

Neither saver checks its own output, so run `hv_check_docx()` on the
path. Zero rows means clean.

```{r}
hv_check_docx(out)
```

## What the package refuses

Every public function rejects out-of-spec input with a message naming
the fix, rather than letting it reach `gtsummary` or `flextable`.

```{r, error = TRUE}
hv_man_table_jtcvs(
  gtsummary::tbl_summary(gtsummary::trial, by = "trt", include = "age"),
  groups = c(stat_1 = "A", stat_2 = "B")
)
```

```{r, error = TRUE}
hv_tbl_summary(
  gtsummary::trial, groups = list(D = "age"),
  continuous = "age", binary = "age"
)
```
````

- [ ] **Step 3: Build the vignette and measure the cost**

Run:
```bash
Rscript -e 'devtools::build_vignettes()'
```
Expected: builds without error.

Then measure the gate, building from a clean `git archive` export as the
release rules require:

```bash
Rscript -e '
  d <- tempfile(); dir.create(d)
  system(paste("git archive HEAD | tar -x -C", d))
  t <- system.time(
    system(paste("R CMD build", d), ignore.stdout = TRUE)
  )
  print(t)
'
```

Record the elapsed time. Then run the full check and read the per-step
timings:

```bash
Rscript -e 'devtools::check(document = FALSE)'
```

- [ ] **Step 4: Report the measurement against the 10-minute gate**

Write the measured overall `R CMD check` time into the PR description
and into `NEWS.md` under Task 10. If the total exceeds 9 minutes, stop
and report rather than proceeding — the levers in order are
precomputing expensive vignette calls to `.rds`, lightening the
`gtsummary` tables, then trimming tests. Do not silently drop the
vignette.

- [ ] **Step 5: Commit**

```bash
git add DESCRIPTION vignettes/
git commit -m "docs: add end-to-end vignette for the JTCVS pipeline"
```

---

### Task 10: CONTRIBUTING, NEWS, and the release gate

**Files:**
- Modify: `CONTRIBUTING.md`
- Modify: `NEWS.md`
- Modify: `DESCRIPTION` (version line)

**Interfaces:**
- Consumes: everything above.
- Produces: nothing.

- [ ] **Step 1: Document the test-invocation papercut**

In `CONTRIBUTING.md`, add to the testing section:

```markdown
Run the suite with `devtools::test()` or `testthat::test_local()`. Both
load the package first. `testthat::test_dir("tests/testthat")` does
not, so its failures are artifacts of the invocation rather than
package defects.
```

- [ ] **Step 2: Bump the patch version**

This branch changes behavior, so it needs its own version. In
`DESCRIPTION` line 4, change `Version: 0.9.4` to `Version: 0.9.5`.

This is a patch-digit bump only. **Surface it in the PR description**:
the minor and major digits are the maintainer's call, not this
branch's.

- [ ] **Step 3: Write the NEWS entry**

At the top of `NEWS.md`, above the `# hvtiRtables 0.9.4` heading:

```markdown
# hvtiRtables 0.9.5

## Breaking changes

- `hv_man_table_jtcvs()` now enforces `font_size` of 11 or 12, the same
  house rule `hv_man_table()` has always enforced. Calls passing any
  other value, or a vector, now error.
- `abbreviations` must be a character vector, as documented. A list
  previously worked by accident.

## Bug fixes

- `hv_man_table_jtcvs()` now errors when `tbl` was not built with the
  `{N_obs} ||| {stat}` statistic convention. It previously rendered a
  complete, correctly styled, entirely empty table.
- `hv_man_table_save_jtcvs()` now errors when a footnote entry has no
  `text`. It previously wrote a document with a dangling superscript
  marker and an empty footnote line.
- `hv_tbl_summary()` now enforces its documented "exactly one type
  bucket" contract instead of failing inside `gtsummary`.
- `hv_man_table_jtcvs()` validates `groups` names against
  `tbl$table_body`, replacing a base-R `non-character argument` error.
- `hv_man_table_save_jtcvs()` validates `file`, replacing a base-R
  `a character vector argument expected` error.
- `hv_tbl_summary()` validates `by` in the package's own vocabulary.

## Documentation

- New `?hvtiRtables` package topic explaining which rendering mode to
  use, with both pipelines end to end.
- New vignette walking a complete JTCVS table from data frame to
  checked `.docx`.
- Every function's help now states its arguments' accepted values
  exhaustively and carries a "Common mistakes" section.
```

- [ ] **Step 4: Run the full release gate**

Run:
```bash
Rscript -e 'devtools::document()'
Rscript -e 'devtools::test()'
Rscript -e 'lintr::lint_package()'
Rscript -e '
  d <- tempfile(); dir.create(d)
  system(paste("git archive HEAD | tar -x -C", d))
  system(paste("R CMD build", d))
'
R CMD check --as-cran hvtiRtables_0.9.5.tar.gz
```

Expected: `devtools::test()` passes with roughly 280–295 tests;
`lint_package()` returns zero lints; `R CMD check --as-cran` is
0 errors / 0 warnings / 0 notes, with the manual built (no
`--no-manual`) and overall time under 10 minutes.

Note the check is run against a `git archive` export, not the working
tree: an empty `inst/doc` fabricates two vignette WARNINGs, and in a
worktree `.git` is a file that `R CMD build`'s VCS exclusion misses,
landing in the tarball as a spurious hidden-files NOTE. Both look like
package defects and are not.

- [ ] **Step 5: Commit and open the PR**

```bash
git add CONTRIBUTING.md NEWS.md DESCRIPTION
git commit -m "docs: record 0.9.5 contract changes and test invocation"
git push -u origin feat/contract-discipline
gh pr create --title "Public-surface contract discipline" --body "$(cat <<'EOF'
Makes every public argument contract explicit, enforced, consistent
across sibling functions, documented, and tested.

Fixes six defects. Four were raised in review; two were found during
the audit and are more severe because they fail silently:
`hv_man_table_jtcvs()` rendered a complete but entirely empty table
when the `|||` statistic convention was absent, and
`hv_man_table_save_jtcvs()` wrote a `.docx` with a dangling footnote
marker when an entry lacked `$text`.

Adds `R/hv-validate.R` (argument validators plus precondition
assertions), contract-parity tests that make sibling divergence a test
failure, a `?hvtiRtables` topic, and an end-to-end vignette.

Spec: `design/superpowers/specs/2026-08-11-contract-discipline-design.md`
Plan: `design/superpowers/plans/2026-08-11-contract-discipline.md`

**Version:** patch bump 0.9.4 -> 0.9.5. The minor digit is deliberately
untouched; consolidating into a minor release is the maintainer's call.

**Release gate:** `R CMD check --as-cran` with the manual built, from a
`git archive` export: <FILL IN result and overall time from Task 9
Step 4 and Task 10 Step 4>.

Breaking: `hv_man_table_jtcvs()` now rejects `font_size` outside
`c(11, 12)`; `abbreviations` must be a character vector.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

The PR body's release-gate line is the one place a measured number must
be pasted in by the implementer. Everything else is written.

---

## Self-Review

**Spec coverage:**

| Spec requirement | Task |
| --- | --- |
| Layer 1 validators | 1 |
| Layer 2 assertions | 2 |
| No `.check_font()` | 1 (comment in file header) |
| Ordering rule (validate before work) | 3, 5 (hoist), asserted in 5 |
| Defect 1 (type buckets) | 6 |
| Defect 2 (`font_size`) | 4 |
| Defect 3 (`groups` names) | 4 |
| Defect 4 (`file`) | 5 |
| Defect 5 (`\|\|\|` convention) | 4 |
| Defect 6 (footnote `text`) | 5 |
| `by` validation | 6 |
| M1–M6 message rules | 1, 2 (verbatim text) |
| `call. = FALSE` meta-test | 7 |
| Contract-parity tests | 7 |
| `expect_false(file.exists())` pattern | 5 |
| `@param` accepted values | 8 |
| Defaults explained by origin | 8 |
| `@section Common mistakes:` | 8 |
| Real-workflow examples | 8 |
| Package-level Rd | 8 |
| pkgdown registration | 8 |
| Vignette + timing | 9 |
| CONTRIBUTING test-invocation line | 10 |
| Release gate | 10 |

No gaps.

**Placeholder scan:** One intentional placeholder remains — the
release-gate result in the PR body (Task 10, Step 5), which cannot be
known before the check runs. It is explicitly flagged in the step. No
other TBDs.

**Type consistency:** `.describe()`, `.check_*()`, `.assert_*()`, and
`.fx_stop_calls()` are named identically wherever they appear.
`.assert_jtcvs_groups()` is called with `(tbl, groups)` in both Task 2's
tests and Task 4's implementation. `.assert_stat_convention()` takes
`tb` (the data frame) not `tbl` (the gtsummary object) — Task 4 passes
`tbl$table_body`, matching Task 2's signature. Fixture names `fx_*` do
not collide with the existing per-file `mk_tbl()` helpers.
