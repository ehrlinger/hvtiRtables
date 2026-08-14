# CORR Biostat Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `hvtiRtables` legible to a CORR biostatistician fluent in the `%summarytable` macro — correct reference structure, macro vocabulary in every doc, errors that teach the translation, and the one missing `TOTALCOL=` behavior.

**Architecture:** Everything organizes on the four-stage spine — `%summarytable` fuses computation and document output into one call; this package splits it into compute (`hv_tbl_summary()`), shape (`hv_man_table*()`), write (`hv_man_table_save*()`), verify (`hv_check_docx()`). A single static lookup table maps every macro parameter to a stage, and is consumed by both the error messages and the vignette's parameter map.

**Tech Stack:** R (>= 4.1.0), roxygen2 8.1.0, testthat 3e, pkgdown, knitr/rmarkdown vignettes, gtsummary (>= 2.5.0).

## Global Constraints

- Spec: `design/superpowers/specs/2026-08-14-corr-biostat-alignment-design.md`. Read it before Task 1.
- Branch is `docs/corr-biostat-alignment`. Never commit to `main`; open a PR at the end.
- Validators live in `R/hv-validate.R` and follow the existing `.check_*` (one argument's own shape) / `.assert_*` (relationships between arguments) split. All error via `stop(call. = FALSE)`.
- Error message style is set by `R/hv-validate.R:15-28`: state the problem, then the fix. Match it.
- `tests/testthat/test-contract-parity.R` enforces shared contract sentences across functions. If you change a shared sentence, that file must be updated in the same commit.
- Do **not** change the `percentiles = c(15, 85)` or `compare = "pvalue"` defaults. The spec records why (both already match real house practice).
- Do **not** add real argument aliases. Macro names produce errors, never work as synonyms.
- **Do not set a version.** Do not edit `DESCRIPTION` `Version:` or `NEWS.md` `Version:`; add NEWS bullets under the existing version heading only. This work leads toward `1.0.0`, but that release is cut by the maintainer in a separate commit and triggers the full release gate (CRAN Cookbook audit, `R CMD check --as-cran` **with** the manual, sub-ten-minute check budget, revdep, `urlchecker`). See the spec's Versioning section.
- Task 6 adds a vignette and Task 7 adds pkgdown URLs, both of which the `1.0.0` gate will measure. Keep the vignette's executed chunks cheap — `gtsummary::trial` is 200 rows, and nothing in it should fit a model.
- Executed vignette chunks must use `gtsummary::trial` so the vignette builds on CI. Real template calls appear only in non-executed chunks (` ```r ` with `eval = FALSE`).

---

## File Structure

| Path | Status | Responsibility |
|---|---|---|
| `R/hv-sas-glossary.R` | create | `.sas_param_map` (the one static macro→stage table) and `.check_sas_args()`. Separate from `hv-validate.R` because it is a data table plus one consumer, not a family of validators. |
| `R/hv-validate.R` | unchanged | Existing validators. Referenced for style only. |
| `R/hv-tbl-summary.R` | modify | Add `...` and `overall =`; roxygen already carries macro names. |
| `R/hv-man-table.R`, `R/hv-man-table-jtcvs.R` | modify | Add `...`; add macro names to roxygen. |
| `R/hv-man-table-save.R`, `R/hv-man-table-save-jtcvs.R` | modify | Add `...`; add macro names to roxygen. |
| `R/hv-man-footnotes.R`, `R/hv-test-footnotes-jtcvs.R` | modify | Add macro names to roxygen. |
| `tests/testthat/test-hv-sas-glossary.R` | create | Lookup table and error-message tests. |
| `tests/testthat/test-hv-tbl-summary.R` | modify | `overall =` tests; the `QNTLDEF` regression test. |
| `_pkgdown.yml` | modify | Reference index restructured on the four-stage spine. |
| `vignettes/sas-migration.Rmd` | create | The migration guide. |
| `README.md` | modify | Migration section trimmed to spine table + pointer. |
| `NEWS.md` | modify | Bullets under the existing version heading. |

---

### Task 1: The macro parameter lookup table

**Files:**
- Create: `R/hv-sas-glossary.R`
- Test: `tests/testthat/test-hv-sas-glossary.R`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `.sas_param_map` — named list, each name a lowercased `%summarytable` parameter. Fields: `arg` (character R argument name, or `NA_character_` when unsupported); `stage` (`"compute"` / `"shape"` / `"save"`, or `NA_character_` when `arg` is `NA`); optional `note` (one clause on a behavior difference or why unsupported); optional `only` (`"corr"` / `"jtcvs"` — the family that has this argument) with a required `note_other` for the family that does not.
  - `.stage_fns` — the stage → family → function name table.
  - `.family_of(fn)` — `"jtcvs"`, `"corr"`, or `NA_character_` for family-neutral callers.
  - `.check_sas_args(dots, fn)` — takes `list(...)` and the calling function's name, errors on any name, returns `invisible(NULL)`.

**Why stage rather than a function name.** `hv_man_table_save()` and `hv_man_table_save_jtcvs()` are siblings with *different argument sets* — only the JTCVS saver has `caption`. A map storing one function per parameter sends half the callers to the wrong sibling, and in the `TBLTITLE=` case to an argument that does not exist. The stage is resolved against the caller's family at message time.

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-hv-sas-glossary.R`:

```r
test_that("a same-stage macro name names the R argument to use", {
  expect_error(
    .check_sas_args(list(class = "trt"), "hv_tbl_summary"),
    "`class` is the `%summarytable` name for `by`",
    fixed = TRUE
  )
})

test_that("a different-stage macro name names the function to pass it to", {
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_tbl_summary"),
    "pass `footnotes =` to `hv_man_table_save()`",
    fixed = TRUE
  )
})

test_that("the message names the sibling matching the caller's family", {
  # Same parameter, two families, two different destination functions.
  expect_error(
    .check_sas_args(list(addfn = "note"), "hv_man_table_save_jtcvs"),
    "Use `footnotes =`", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(rtffile = "t.rtf"), "hv_man_table_jtcvs"),
    "pass `file =` to `hv_man_table_save_jtcvs()`", fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(rtffile = "t.rtf"), "hv_man_table"),
    "pass `file =` to `hv_man_table_save()`", fixed = TRUE
  )
})

test_that("TBLTITLE= is honest that the CORR saver has no caption", {
  # hv_man_table_save() genuinely has no `caption` argument; naming one
  # would send the reader to an argument that does not exist.
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_man_table_save"),
    "the CORR saver writes no caption",
    fixed = TRUE
  )
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_man_table_save_jtcvs"),
    "Use `caption =`", fixed = TRUE
  )
  # A family-neutral caller is routed to the family that has the argument.
  expect_error(
    .check_sas_args(list(tbltitle = "Table 1"), "hv_tbl_summary"),
    "pass `caption =` to `hv_man_table_save_jtcvs()`", fixed = TRUE
  )
})

test_that("an unsupported macro parameter says so and does not name an argument", {
  expect_error(
    .check_sas_args(list(weight = "wt"), "hv_tbl_summary"),
    "weighted summaries are not supported",
    fixed = TRUE
  )
})

test_that("CON1 explains the statistic change rather than mapping silently", {
  expect_error(
    .check_sas_args(list(con1 = "age"), "hv_tbl_summary"),
    "mean",
    fixed = TRUE
  )
})

test_that("macro names are matched case-insensitively", {
  expect_error(
    .check_sas_args(list(CLASS = "trt"), "hv_tbl_summary"),
    "`by`",
    fixed = TRUE
  )
})

test_that("a non-macro unused argument still errors, generically", {
  expect_error(
    .check_sas_args(list(colour = "red"), "hv_tbl_summary"),
    "unused argument",
    fixed = TRUE
  )
})

test_that("no dots is silent", {
  expect_null(.check_sas_args(list(), "hv_tbl_summary"))
})

test_that("every map entry is well formed", {
  for (nm in names(.sas_param_map)) {
    entry <- .sas_param_map[[nm]]
    expect_true(is.list(entry), info = nm)
    expect_true(all(c("arg", "stage") %in% names(entry)), info = nm)
    # An entry either routes somewhere or explains why it does not.
    if (is.na(entry$arg)) {
      expect_true(is.na(entry$stage), info = nm)
      expect_true(nzchar(entry$note %||% ""), info = nm)
    } else {
      expect_true(entry$stage %in% names(.stage_fns), info = nm)
    }
    # A family-restricted entry must say what the other family gets.
    if (!is.null(entry$only)) {
      expect_true(entry$only %in% c("corr", "jtcvs"), info = nm)
      expect_true(nzchar(entry$note_other %||% ""), info = nm)
    }
  }
})

test_that("map names are already lowercase", {
  expect_identical(names(.sas_param_map), tolower(names(.sas_param_map)))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-sas-glossary.R")'`
Expected: FAIL — `could not find function ".check_sas_args"`.

- [ ] **Step 3: Write minimal implementation**

Create `R/hv-sas-glossary.R`:

```r
# The one static map from %summarytable parameter to this package's
# four-stage split. Two consumers: .check_sas_args() below, and the
# parameter table in vignettes/sas-migration.Rmd, which is written from
# this list so the two can never disagree.
#
# `arg = NA` means the parameter has no equivalent here; `note` then
# carries the reason. Where a parameter maps but the behavior differs,
# `note` carries the difference -- silently accepting the mapping would
# be worse than erroring, because the number changes without saying so.
#
# Entries store a STAGE, not a function name, because the shape and save
# stages are CORR/JTCVS sibling pairs with different argument sets --
# only hv_man_table_save_jtcvs() has `caption`. Storing one function per
# parameter would send half the callers to the wrong sibling, and for
# TBLTITLE= to an argument that does not exist. `only` marks a parameter
# that exists in one family alone; `note_other` is what the other family
# is told instead.
#
# Deliberately not exhaustive over the macro's ~60 parameters. The
# purely typographic ones (f1..f4, pfmt, perfmt, labeln, out, rtfout)
# have no analogue worth a message and would bury the ones that matter.

`%||%` <- function(x, y) if (is.null(x)) y else x

.stage_fns <- list(
  compute = c(corr = "hv_tbl_summary",      jtcvs = "hv_tbl_summary"),
  shape   = c(corr = "hv_man_table",        jtcvs = "hv_man_table_jtcvs"),
  save    = c(corr = "hv_man_table_save",   jtcvs = "hv_man_table_save_jtcvs")
)

# hv_tbl_summary() is family-neutral: its output feeds either renderer,
# so it returns NA and the caller decides what to do with that.
.family_of <- function(fn) {
  if (grepl("_jtcvs$", fn)) return("jtcvs")
  if (fn %in% c("hv_man_table", "hv_man_table_save")) return("corr")
  NA_character_
}

.sas_param_map <- list(
  # Stage 1 -- compute
  data     = list(arg = "data",        stage = "compute"),
  class    = list(arg = "by",          stage = "compute"),
  list     = list(arg = "groups",      stage = "compute"),
  con3     = list(arg = "continuous",  stage = "compute"),
  cat1     = list(arg = "binary",      stage = "compute"),
  cat2     = list(arg = "categorical", stage = "compute"),
  pp       = list(arg = "percentiles", stage = "compute"),
  pvalues  = list(arg = "compare",     stage = "compute"),
  asd      = list(arg = "compare",     stage = "compute",
                  note = "use `compare = \"smd\"` or `compare = \"both\"`"),
  totalcol = list(arg = "overall",     stage = "compute"),

  con1 = list(
    arg = "continuous", stage = "compute",
    note = paste0(
      "`CON1=` reported mean +/- SD with one-way ANOVA; every continuous ",
      "variable here is summarized as median (percentiles) and tested ",
      "non-parametrically, which is the `CON3=` behavior"
    )
  ),
  con2 = list(
    arg = "continuous", stage = "compute",
    note = paste0(
      "`CON2=` reported median (min, max); this package reports ",
      "median (percentiles), set by `percentiles =`"
    )
  ),
  ord1 = list(
    arg = "categorical", stage = "compute",
    note = paste0(
      "ordinal variables fold into `categorical` and are tested with ",
      "chi-square, not the Kruskal-Wallis test `ORD1=` used"
    )
  ),

  # Stage 3 -- write
  tbltitle = list(
    arg = "caption", stage = "save", only = "jtcvs",
    note_other = paste0(
      "the CORR saver writes no caption; add the table title in the ",
      "document, or use the JTCVS pair if the journal wants one"
    )
  ),
  addfn    = list(arg = "footnotes", stage = "save"),
  printfn  = list(arg = "footnotes", stage = "save",
                  note = "pass `hv_man_footnotes()`, or `NULL` for none"),
  rtffile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),
  pdffile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),
  xmlfile  = list(arg = "file",      stage = "save",
                  note = "output is `.docx`"),

  # No equivalent
  weight    = list(arg = NA_character_, stage = NA_character_,
                   note = "weighted summaries are not supported"),
  propenmt  = list(arg = NA_character_, stage = NA_character_,
                   note = "propensity-matched mode is not supported"),
  mwoutcomes = list(arg = NA_character_, stage = NA_character_,
                    note = "matching-weighted outcomes are not supported"),
  subset    = list(arg = NA_character_, stage = NA_character_,
                   note = "subset the data frame before calling"),
  sortby    = list(arg = NA_character_, stage = NA_character_,
                   note = "display order comes from `groups`"),
  colpct    = list(arg = NA_character_, stage = NA_character_,
                   note = "percentages are always column percentages"),
  misscol   = list(arg = NA_character_, stage = NA_character_,
                   note = "a missing-count column is not supported"),
  adhoc     = list(arg = NA_character_, stage = NA_character_,
                   note = "ad-hoc pairwise comparisons are not supported"),
  oddsratios = list(arg = NA_character_, stage = NA_character_,
                    note = "odds-ratio columns are not supported"),
  cutexact  = list(arg = NA_character_, stage = NA_character_,
                   note = paste0(
                     "the chi-square/Fisher switch is not tunable; ",
                     "gtsummary uses Fisher's exact when any expected ",
                     "count is below 5, where `CUTEXACT=50` used a ",
                     "50% threshold"
                   )),
  style     = list(arg = NA_character_, stage = NA_character_,
                   note = "house font and rounding are fixed"),
  page      = list(arg = NA_character_, stage = NA_character_,
                   note = "page setup belongs to the Word document"),
  papersize = list(arg = NA_character_, stage = NA_character_,
                   note = "page setup belongs to the Word document")
)

# Errors on any name in `dots`. Macro names get a message routing them to
# the right argument and stage; anything else gets the message R itself
# would have given had the function not taken `...`. Taking `...` is what
# makes the macro messages possible, so this restores the default
# strictness that `...` silently removed.
.check_sas_args <- function(dots, fn) {
  nms <- names(dots)
  if (length(nms) == 0L) return(invisible(NULL))

  key <- tolower(nms[1])
  entry <- .sas_param_map[[key]]

  if (is.null(entry))
    stop("unused argument (", nms[1], ")", call. = FALSE)

  note <- entry$note %||% ""

  if (is.na(entry$arg))
    stop("`", toupper(key), "=` is a `%summarytable` parameter: ", note, ".",
         call. = FALSE)

  fam <- .family_of(fn)

  # A family-restricted parameter: the family that lacks the argument is
  # told so plainly rather than sent to an argument that does not exist.
  # A family-neutral caller is routed to the family that has it.
  if (!is.null(entry$only)) {
    if (!is.na(fam) && !identical(fam, entry$only))
      stop("`", toupper(key), "=` is a `%summarytable` parameter: ",
           entry$note_other, ".", call. = FALSE)
    fam <- entry$only
  }
  if (is.na(fam)) fam <- "corr"

  target <- .stage_fns[[entry$stage]][[fam]]

  fix <- if (identical(target, fn)) {
    paste0("`", key, "` is the `%summarytable` name for `", entry$arg,
           "`. Use `", entry$arg, " =`.")
  } else {
    paste0("`", key, "` is a `%summarytable` parameter this package handles ",
           "at a different stage: pass `", entry$arg, " =` to `", target,
           "()`.")
  }

  stop(fix, if (nzchar(note)) paste0(" Note: ", note, "."), call. = FALSE)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-sas-glossary.R")'`
Expected: PASS, 11 tests.

- [ ] **Step 5: Commit**

```bash
git add R/hv-sas-glossary.R tests/testthat/test-hv-sas-glossary.R
git commit -m "feat: macro parameter map and teaching errors for SAS argument names"
```

---

### Task 2: Wire the teaching errors into the public functions

**Files:**
- Modify: `R/hv-tbl-summary.R:127-128` (signature), `R/hv-man-table.R:54-55`, `R/hv-man-table-jtcvs.R:158-160`, `R/hv-man-table-save.R:55-56`, `R/hv-man-table-save-jtcvs.R:81-82`
- Test: `tests/testthat/test-hv-sas-glossary.R`

**Interfaces:**
- Consumes: `.check_sas_args(dots, fn)` from Task 1.
- Produces: every public function accepts `...` and errors on any argument passed through it. No change to any existing argument.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-hv-sas-glossary.R`:

```r
test_that("each public function routes SAS names through the glossary", {
  tbl <- gtsummary::tbl_summary(gtsummary::trial, by = "trt",
                                include = "age")
  ft <- hv_man_table(tbl)

  expect_error(
    hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                   continuous = "age", class = "trt"),
    "Use `by =`", fixed = TRUE
  )
  expect_error(hv_man_table(tbl, style = "journal"),
               "house font and rounding are fixed", fixed = TRUE)
  expect_error(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                       style = "journal"),
    "house font and rounding are fixed", fixed = TRUE
  )
  expect_error(
    hv_man_table_save(ft, tempfile(fileext = ".docx"), tbltitle = "T1"),
    "the CORR saver writes no caption", fixed = TRUE
  )
  expect_error(
    hv_man_table_save_jtcvs(ft, tempfile(fileext = ".docx"),
                            caption = "T1", addfn = "note"),
    "`footnotes =`", fixed = TRUE
  )
})

test_that("a typo in a real argument name is still caught", {
  expect_error(
    hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                   continuous = "age", percentile = c(16, 84)),
    "unused argument", fixed = TRUE
  )
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-sas-glossary.R")'`
Expected: FAIL — `unused argument (class = "trt")` raised by R itself, not matching `"Use \`by =\`"`.

- [ ] **Step 3: Write minimal implementation**

In each of the five files, add `...` as the **last** formal and call `.check_sas_args()` as the **first** statement in the body, before any existing `.check_*` call. Adding it last keeps every existing positional call working; checking it first means a SAS name is reported before an unrelated validation failure masks it.

`R/hv-tbl-summary.R` — change the signature ending at line 128 and the first body line:

```r
                           percentiles = c(15, 85),
                           overall = FALSE,
                           ...) {
  .check_sas_args(list(...), "hv_tbl_summary")
```

(`overall` is added here by Task 3; if Task 3 has not run yet, omit that line and add it there.)

`R/hv-man-table.R`:

```r
hv_man_table <- function(tbl, font = "Times New Roman", font_size = 12,
                         digits = 2, ...) {
  .check_sas_args(list(...), "hv_man_table")
```

`R/hv-man-table-jtcvs.R`:

```r
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               stat_label = "No. (%) or Mean ± SD",
                               font = "Times New Roman", font_size = 12,
                               ...) {
  .check_sas_args(list(...), "hv_man_table_jtcvs")
```

`R/hv-man-table-save.R`:

```r
hv_man_table_save <- function(ft, file, footnotes = hv_man_footnotes(),
                              abbreviations = NULL, ...) {
  .check_sas_args(list(...), "hv_man_table_save")
```

`R/hv-man-table-save-jtcvs.R`:

```r
hv_man_table_save_jtcvs <- function(ft, file, caption, footnotes = NULL,
                                    abbreviations = NULL, ...) {
  .check_sas_args(list(...), "hv_man_table_save_jtcvs")
```

Add to each function's roxygen block, immediately after the last existing `@param`:

```r
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
```

- [ ] **Step 4: Run tests and document**

Run: `Rscript -e 'devtools::document(); devtools::load_all("."); testthat::test_dir("tests/testthat")'`
Expected: PASS, all files. `man/*.Rd` regenerate with the new `\item{...}` entries.

- [ ] **Step 5: Commit**

```bash
git add R/ man/ tests/testthat/test-hv-sas-glossary.R
git commit -m "feat: route %summarytable parameter names to teaching errors"
```

---

### Task 3: `overall =`, the `TOTALCOL=` equivalent

**Files:**
- Modify: `R/hv-tbl-summary.R` (signature ~line 127, validation block ~line 168, pipeline ~line 300-320)
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `hv_tbl_summary(..., overall = FALSE)`. When `TRUE` and `by` is non-`NULL`, the returned `gtsummary` object carries one extra leading column (`stat_0`) from `gtsummary::add_overall()`. When `TRUE` and `by` is `NULL`, errors.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-hv-tbl-summary.R`:

```r
test_that("overall = TRUE adds exactly one column", {
  base <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age"
  )
  with_total <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age",
    overall = TRUE
  )
  expect_equal(
    ncol(with_total$table_body) - ncol(base$table_body), 1L
  )
  expect_true("stat_0" %in% names(with_total$table_body))
})

test_that("overall = FALSE reproduces the previous output exactly", {
  a <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age"), continuous = "age"
  )
  expect_false("stat_0" %in% names(a$table_body))
})

test_that("overall = TRUE without `by` errors rather than doing nothing", {
  expect_error(
    hv_tbl_summary(gtsummary::trial, groups = list(D = "age"),
                   continuous = "age", overall = TRUE),
    "`overall = TRUE` needs a `by` variable",
    fixed = TRUE
  )
})

test_that("overall must be a single TRUE or FALSE", {
  expect_error(
    hv_tbl_summary(gtsummary::trial, by = "trt",
                   groups = list(D = "age"), continuous = "age",
                   overall = "yes"),
    "`overall` must be TRUE or FALSE", fixed = TRUE
  )
})

test_that("SAS QNTLDEF=5 corresponds to quantile type 2, not R's default", {
  # Guards the equivalence vignettes/sas-migration.Rmd documents. If a
  # future change routes percentiles through stats::quantile() directly
  # rather than gtsummary's {pXX}, this is the value that must hold.
  expect_equal(stats::quantile(c(1, 2, 3, 4), 0.25, type = 2,
                               names = FALSE), 1.5)
  expect_equal(stats::quantile(c(1, 2, 3, 4), 0.25, type = 7,
                               names = FALSE), 1.75)
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-hv-tbl-summary.R")'`
Expected: FAIL — `unused argument (overall = TRUE)`.

- [ ] **Step 3: Write minimal implementation**

Add to the signature (see Task 2 for the combined form), then add validation beside the existing `percentiles` checks (after `R/hv-tbl-summary.R:181`):

```r
  if (!is.logical(overall) || length(overall) != 1L || is.na(overall))
    stop("`overall` must be TRUE or FALSE.", call. = FALSE)

  # The macro's TOTALCOL= only ever produced an Overall column alongside
  # class levels; with no CLASS= the single column already is the
  # overall one. Erroring rather than ignoring, because a caller who
  # passed it believes a column is coming.
  if (overall && is.null(by))
    stop("`overall = TRUE` needs a `by` variable; with `by = NULL` the ",
         "single column is already the overall one.", call. = FALSE)
```

Then, in the pipeline, after the `tbl_summary()` call and **before** `add_p()`/`add_difference()` (gtsummary requires `add_overall()` ahead of comparison columns so the comparison stays rightmost):

```r
  if (overall)
    out <- gtsummary::add_overall(out, last = FALSE)
```

Add the roxygen `@param`, matching the file's existing style of naming the macro parameter:

```r
#' @param overall Single `TRUE`/`FALSE`. When `TRUE`, prepends an Overall
#'   column across all groups (`%summarytable` `TOTALCOL=` equivalent).
#'   Requires `by`. Defaults to `FALSE`, unlike the macro's `TOTALCOL=1`:
#'   the renderers take a `groups` vector naming each `stat_<k>` column,
#'   so adding a column by default would silently break existing calls.
```

- [ ] **Step 4: Run tests**

Run: `Rscript -e 'devtools::document(); devtools::load_all("."); testthat::test_dir("tests/testthat")'`
Expected: PASS, all files.

- [ ] **Step 5: Commit**

```bash
git add R/hv-tbl-summary.R man/hv_tbl_summary.Rd tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: add overall = argument, the %summarytable TOTALCOL= equivalent"
```

---

### Task 4: Macro vocabulary in the renderer and saver roxygen

**Files:**
- Modify: `R/hv-man-table.R`, `R/hv-man-table-jtcvs.R`, `R/hv-man-table-save.R`, `R/hv-man-table-save-jtcvs.R`, `R/hv-man-footnotes.R`, `R/hv-test-footnotes-jtcvs.R` (roxygen blocks only)

**Interfaces:**
- Consumes: nothing. Documentation only — no code changes.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the stage sentence to each function's `@description`**

Every one of the six gets a sentence naming its stage. Exact text, one per file:

- `hv_man_table` / `hv_man_table_jtcvs`: `#' Stage 2 of the `%summarytable` split: shapes the table. The macro did this with `STYLE=` and `PAGE=`; here the house style is fixed and the only choice is flat header versus JTCVS spanning header.`
- `hv_man_table_save` / `hv_man_table_save_jtcvs`: `#' Stage 3 of the `%summarytable` split: writes the document. Replaces the macro's `RTFFILE=`/`PDFFILE=` output block.`
- `hv_man_footnotes`: `#' The house footnote block the macro emitted under `PRINTFN=1`.`
- `hv_test_footnotes_jtcvs`: `#' Reproduces the macro's lettered test footnotes. The letters differ by design: `%summarytable` emitted `a=ANOVA` for `CON1=` variables, and this package tests every continuous variable non-parametrically, so ANOVA never appears.`

- [ ] **Step 2: Add macro names to the savers' `@param` entries**

In `R/hv-man-table-save.R` and `R/hv-man-table-save-jtcvs.R`, extend the existing text (do not replace it) so each names its macro parameter:

```r
#' @param file Path to the `.docx` to write (`%summarytable` `RTFFILE=`/
#'   `PDFFILE=` equivalent; output here is always `.docx`).
#' @param caption Table caption (`%summarytable` `TBLTITLE=` equivalent).
#' @param footnotes Footnotes below the table (`%summarytable` `ADDFN=`
#'   equivalent; `PRINTFN=1`'s house block is [hv_man_footnotes()]).
```

Apply only the `@param` entries each file actually has — `hv_man_table_save()` has no `caption`.

- [ ] **Step 3: Regenerate and check**

Run: `Rscript -e 'devtools::document()'`
Then: `Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'`
Expected: PASS. `test-contract-parity.R` in particular — if it fails, a shared contract sentence was edited rather than extended; restore the original wording and add the macro clause after it.

- [ ] **Step 4: Commit**

```bash
git add R/ man/
git commit -m "docs: name the %summarytable parameter behind each renderer and saver argument"
```

---

### Task 5: Reference index on the four-stage spine

**Files:**
- Modify: `_pkgdown.yml` (the `reference:` block)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Replace the `reference:` block**

Replace the entire existing `reference:` block with:

```yaml
reference:
- title: "1. Compute the table — `%summarytable`"
  desc: >
    Where the macro's `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=` and
    `TOTALCOL=` land. Takes a grouped, ordered variable list and returns a
    `gtsummary` object for the stages below.
  contents:
  - hv_tbl_summary

- title: "2. Shape the table — `STYLE=` / `PAGE=`"
  desc: >
    House style is fixed, so the only choice here is the header shape.
    Flat single-row headers for CORR reports and manuscripts; merged
    spanning headers for a JTCVS submission.
  contents:
  - hv_man_table
  - hv_man_table_jtcvs

- title: "3. Write the document — `RTFFILE=` / `PDFFILE=`"
  desc: >
    The macro's output block: `TBLTITLE=` becomes `caption`, `ADDFN=` and
    `PRINTFN=` become `footnotes`. Output is always `.docx`.
  contents:
  - hv_man_table_save
  - hv_man_table_save_jtcvs
  - hv_man_footnotes
  - hv_test_footnotes_jtcvs

- title: "4. Verify the written file"
  desc: >
    No macro analogue. Inspects a written `.docx` for structural layers the
    manuscript rules prohibit, reading the file rather than the object that
    produced it — so it catches anything introduced later, including by a
    hand edit.
  contents:
  - hv_check_docx

- title: "Package overview"
  desc: >
    Which rendering mode to use, and both pipelines end to end.
  contents:
  - hvtiRtables-package
```

- [ ] **Step 2: Verify every exported function is still indexed**

Run: `Rscript -e 'pkgdown::check_pkgdown()'`
Expected: no output, or an explicit "All topics are included" message. Any "missing topics" error means a `contents:` entry was dropped — compare against `NAMESPACE`, which lists all 8 exports.

- [ ] **Step 3: Commit**

```bash
git add _pkgdown.yml
git commit -m "docs: restructure the reference index on the four-stage %summarytable spine"
```

---

### Task 6: The migration vignette

**Files:**
- Create: `vignettes/sas-migration.Rmd`
- Modify: `_pkgdown.yml` (add an `articles:` block)

**Interfaces:**
- Consumes: `overall =` from Task 3 (section 2 documents it). Run Task 3 first.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the vignette**

Create `vignettes/sas-migration.Rmd`. Executed chunks use `gtsummary::trial`; the ported call in section 3 is `eval = FALSE`.

````markdown
---
title: "Porting a %summarytable program to R"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Porting a %summarytable program to R}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

```{r, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
```

```{r setup}
library(hvtiRtables)
```

This is written for someone who knows `%summarytable` and the `tp.dc.*`
templates, and does not want to learn `gtsummary` beyond what the port
requires. It ends at the summary object; rendering it is covered in
`vignette("hvtiRtables")`.

## One macro call becomes three

`%summarytable` computes the table *and* writes the document. Its
`RTFFILE=`, `TBLTITLE=`, `ADDFN=`, `STYLE=` and `PAGE=` parameters sit in
the same call as `CON1=` and `CLASS=`. This package splits that work, so
the parameters you know are distributed across separate calls:

| Stage | Function | Macro parameters that land here |
|---|---|---|
| Compute stats and tests | `hv_tbl_summary()` | `DATA=`, `CLASS=`, `CON*=`, `CAT*=`, `ORD1=`, `LIST=`, `PP=`, `PVALUES=`, `ASD=`, `TOTALCOL=` |
| Shape the table | `hv_man_table()`, `hv_man_table_jtcvs()` | `STYLE=`, `PAGE=` |
| Write the file | `hv_man_table_save()`, `hv_man_table_save_jtcvs()` | `RTFFILE=`, `PDFFILE=`, `TBLTITLE=`, `ADDFN=`, `PRINTFN=` |
| Verify the file | `hv_check_docx()` | *(no analogue)* |

If you pass a macro parameter to the wrong stage, the error says which
function takes it:

```{r, error = TRUE}
hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = "age"), continuous = "age",
  tbltitle = "Table 1"
)
```

## Defaults that differ

Five places where a faithful-looking port produces different numbers.

| Macro | Default there | Default here | Fix |
|---|---|---|---|
| `TOTALCOL=` | `1` — Overall column included | `overall = FALSE` | `overall = TRUE` |
| `CON1=` | mean ± SD, one-way ANOVA | median (percentiles), Kruskal-Wallis | none — see below |
| `PP=` | `16 84` nominal; house templates use both `15 85` and `16 84` | `percentiles = c(15, 85)` | `percentiles = c(16, 84)` |
| `CUTEXACT=` | Fisher when ≥50% of cells have expected < 5 | Fisher when *any* expected < 5 | none — not tunable |
| `ORD1=` | `n (%)`, Kruskal-Wallis | folds into `categorical`, chi-square | none |

`overall = FALSE` is the one deliberate departure from a macro default.
The renderers take a `groups` vector naming each `stat_<k>` column, so a
column appearing by default would break every existing call.

## A ported call

The `%summarytable` call from `tp.dc.stddiff.summarytable.sas`:

```sas
%summarytable(data=built,
              class=grp_res,
              con3=&nongau.,
              cat1=&binary.,
              cat2=&catg.,
              pp=15 85,
              totalcol=0,
              pvalues=1,
              list=
    /* Demography */
       female AGE BSA race_gp
    /* Symptoms */
       surgstat nyha_pr
);
```

and its equivalent. Note that `pp=` and `list=` map straight across,
`totalcol=0` is the default here so it disappears, and `pvalues=1` becomes
`compare = "pvalue"`:

```{r eval = FALSE}
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
  percentiles = c(15, 85)
)
```

## Parameter map

| `%summarytable` | Here | Notes |
|---|---|---|
| `DATA=` | `data` | |
| `CLASS=` | `by` | |
| `LIST=` | `groups` | a named list; the section comments become the names |
| `CON1=` | `continuous` | **statistic changes** — mean ± SD becomes median (percentiles) |
| `CON2=` | `continuous` | **statistic changes** — median (min, max) becomes median (percentiles) |
| `CON3=` | `continuous` | direct equivalent; this is the behavior `continuous` reproduces |
| `CAT1=` | `binary` | |
| `CAT2=` | `categorical` | |
| `ORD1=` | `categorical` | **test changes** — Kruskal-Wallis becomes chi-square |
| `PP=` | `percentiles` | |
| `PVALUES=` | `compare = "pvalue"` | |
| `ASD=` | `compare = "smd"` / `"both"` | |
| `TOTALCOL=` | `overall` | default differs — see above |
| `NCOL=` | automatic | per-group Ns always shown; `NCOL=3`'s overall N needs `overall = TRUE` |
| `TBLTITLE=` | `caption` | **JTCVS only** — `hv_man_table_save()` writes no caption |
| `ADDFN=` | `footnotes` | on the save function |
| `PRINTFN=` | `footnotes = hv_man_footnotes()` | on the save function |
| `RTFFILE=`, `PDFFILE=`, `XMLFILE=` | `file` | output is always `.docx` |

The save stage is a sibling pair, and the two do not take the same
arguments: only `hv_man_table_save_jtcvs()` has `caption`. For a flat-header
CORR table the title goes in the document, not the call.

Not supported: `WEIGHT=`, `PROPENMT=`, `MWOUTCOMES=`, `SUBSET=` (subset the
data frame first), `SORTBY=` (order comes from `groups`), `COLPCT=0` (row
percentages), `MISSCOL=`, `ADHOC=`, `ODDSRATIOS=`, `CUTEXACT=`, `STYLE=`,
`PAGE=`, `CWIDTH1-3=`, `PAPERSIZE=`.

## Why my p-value moved

Three causes, in order of how often they explain it.

1. **A `CON1=` variable.** The macro ran one-way ANOVA on it. Every
   continuous variable here is tested non-parametrically. This is also why
   no footnote letter reads `a=ANOVA`.
2. **An `ORD1=` variable.** The macro ran Kruskal-Wallis; folded into
   `categorical`, it gets chi-square. No trend test is run.
3. **A sparse categorical variable.** Both switch to Fisher's exact, at
   different thresholds — `CUTEXACT=50` needs half the cells to have
   expected counts below 5, `gtsummary` needs one.

## Percentiles and QNTLDEF

SAS's house `QNTLDEF=5` is not R's default quantile definition. It
corresponds to `type = 2`:

```{r}
stats::quantile(c(1, 2, 3, 4), 0.25, type = 2, names = FALSE)  # QNTLDEF=5
stats::quantile(c(1, 2, 3, 4), 0.25, type = 7, names = FALSE)  # R default
```

Medians agree at every n; Q1, Q3 and `pNN` diverge silently. `gtsummary`'s
`{pXX}` statistics already use `type = 2`, so `hv_tbl_summary()` matches
SAS without intervention. **Any `stats::quantile()` call you write by hand
in ported code does not** — pin `type = 2` explicitly.

The percentiles actually used are always printed in the sub-header, so a
table can never silently misreport which pair produced a column:

```{r}
tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "marker")),
  continuous = c("age", "marker"),
  percentiles = c(16, 84)
)
attr(tbl, "hv_stat_label")
```

## Reading the SAS data in

`haven::read_sas()` returns `haven_labelled` columns over doubles, because
every SAS numeric is an 8-byte float. A 0/1 flag therefore arrives looking
like a continuous variable, and type guessers classify it as one.

This is why `binary` and `categorical` are stated rather than inferred:
name every variable in exactly one of `continuous`, `binary` or
`categorical`, and a misclassification is an error rather than a wrong
table.

```{r, error = TRUE}
hv_tbl_summary(
  gtsummary::trial, groups = list(D = "age"),
  continuous = "age", binary = "age"
)
```
````

- [ ] **Step 2: Add the articles block to `_pkgdown.yml`**

Insert after the `reference:` block:

```yaml
articles:
- title: "Guides"
  navbar: ~
  contents:
  - hvtiRtables
  - sas-migration
```

- [ ] **Step 3: Build the vignette and verify it executes**

Run: `Rscript -e 'devtools::build_vignettes()'`
Expected: builds without error. Confirm the quantile chunk printed `1.5` and `1.75`, and that the two `error = TRUE` chunks show errors rather than halting the build.

- [ ] **Step 4: Commit**

```bash
git add vignettes/sas-migration.Rmd _pkgdown.yml
git commit -m "docs: add the %summarytable porting vignette"
```

---

### Task 7: Trim the README and record the changes

**Files:**
- Modify: `README.md` (the "Migrating from the `%summarytable` SAS macro" section and everything under it)
- Modify: `NEWS.md` (bullets under the existing version heading)

**Interfaces:**
- Consumes: `vignettes/sas-migration.Rmd` from Task 6 (the README links to it).
- Produces: nothing.

- [ ] **Step 1: Replace the README migration section**

Delete from `## Migrating from the %summarytable SAS macro` through the end of the `### Lettered test footnotes` subsection, and replace with:

```markdown
## Migrating from the `%summarytable` SAS macro

`%summarytable` computes the table and writes the document in one call.
This package splits that into stages, so the parameters you know are
spread across separate calls:

| Stage | Function | Macro parameters |
|---|---|---|
| Compute | `hv_tbl_summary()` | `CLASS=`, `CON*=`, `CAT*=`, `LIST=`, `PP=`, `PVALUES=`, `TOTALCOL=` |
| Shape | `hv_man_table()` / `hv_man_table_jtcvs()` | `STYLE=`, `PAGE=` |
| Write | `hv_man_table_save*()` | `RTFFILE=`, `ADDFN=`, `TBLTITLE=` (JTCVS only) |
| Verify | `hv_check_docx()` | *(no analogue)* |

The one thing worth knowing before you start: `CON1=` variables change
statistic. The macro reported them as mean ± SD with one-way ANOVA; every
continuous variable here is a median with a non-parametric test, which is
the `CON3=` behavior. Nothing else silently changes a number.

Full parameter map, the five defaults that differ, and the `QNTLDEF`
quantile trap: **[Porting a `%summarytable` program to R](https://ehrlinger.github.io/hvtiRtables/articles/sas-migration.html)**.
```

**Verify the deletion removed the incorrect `CON1=` → `continuous` mapping row.** It must not survive anywhere in the repo outside the vignette's corrected table.

Run: `grep -rn 'CON1' README.md`
Expected: only the sentence above, which states the statistic change.

- [ ] **Step 2: Add NEWS bullets**

Under the existing top version heading in `NEWS.md`, add:

```markdown
* `hv_tbl_summary()` gains `overall =`, the `%summarytable` `TOTALCOL=`
  equivalent, adding an Overall column across all groups. Defaults to
  `FALSE`; the macro's own default is `TOTALCOL=1`.
* Every public function now errors on a `%summarytable` parameter name,
  naming the R argument and the function that takes it, rather than
  silently ignoring it.
* New vignette, "Porting a `%summarytable` program to R".
* The README's migration table stated that `CON1=` maps to `continuous`.
  It does not: `CON1=` was mean ± SD with ANOVA, and `continuous`
  reproduces `CON3=`. Corrected.
```

- [ ] **Step 3: Full check**

Run: `Rscript -e 'devtools::document(); devtools::check(document = FALSE)'`
Expected: 0 errors, 0 warnings, 0 notes.

Run: `Rscript -e 'lintr::lint_package()'`
Expected: no lints. If "no visible global function" appears for `.check_sas_args`, reinstall the package rather than adding `# nolint` — that lint is a stale-install artifact.

- [ ] **Step 4: Commit and open the PR**

```bash
git add README.md NEWS.md man/
git commit -m "docs: trim README migration section to the stage table and a pointer"
git push -u origin docs/corr-biostat-alignment
gh pr create --title "docs: align hvtiRtables for CORR biostatisticians" --body "$(cat <<'EOF'
Implements design/superpowers/specs/2026-08-14-corr-biostat-alignment-design.md.

A sweep of summarytable.sas and the real tp.dc.* template calls against this
package's docs found six defects and one feature gap.

- `overall =` closes the gap: `TOTALCOL=` had no equivalent at all.
- `%summarytable` parameter names now produce errors naming the R argument
  and the function that takes it.
- Reference index, roxygen, README and a new vignette all restructured on
  the four-stage spine: the macro fuses computation and document output,
  this package splits them.
- Corrects the README's inverted `CON1=` mapping. `CON1=` was mean ± SD
  with ANOVA; `continuous` reproduces `CON3=`.

Defaults deliberately unchanged: `percentiles` and `compare` already match
house practice, verified against the template call sites.

Version digit left for the maintainer — `overall =` and the new errors make
this more than a docs release.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**Spec coverage.** D1 → Task 5. D2 → Task 4. D3 → Tasks 1–2. D4 → Task 3. D5 → Task 6. D6 → Task 7. Findings 1–6 → the corrected map (Task 6 §Parameter map, Task 7 §Step 1 for finding 1), the stage split (finding 2, Tasks 5–6), `overall =` (finding 3, Task 3), the `CUTEXACT` row (finding 4, Task 6), the extended unsupported list (finding 5, Tasks 1 and 6), the `QNTLDEF` and `haven_labelled` sections (finding 6, Task 6). Testing section → Tasks 1, 2, 3 (including the `QNTLDEF` regression test, placed in Task 3 with the other `hv_tbl_summary` tests).

**Type consistency.** `.check_sas_args(dots, fn)` — two arguments, called identically in Tasks 1 and 2. `.sas_param_map` entries carry `arg`/`fn`/`note` throughout. `overall` is logical everywhere.

**Known ordering constraint.** Task 2 and Task 3 both edit the `hv_tbl_summary()` signature. Task 2's code block shows the combined form and says what to omit if Task 3 has not run. Run them in numeric order and the question does not arise.
