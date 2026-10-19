# Table styles, Phase 3: the manuscript "describe" layout and the JTCVS rename

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the manuscript style's second layout, `hv_man_table(tbl, style = "manuscript",
layout = "describe")`, for tables that describe cohorts or repeated measures side by side, and
fold the three JTCVS functions into it as deprecated wrappers that keep existing calls working
for one release (design D3).

**Architecture:** `"describe"` is built from the same reshaped body (`.reshape_jtcvs_body()`)
and the same dressing as `"compare"`, so the two layouts share the grid, shading, notes, font
and page and differ only in where the counts go: a count column beside each group, each group
spanning its own (n, statistic) pair. The layout is an argument of `hv_man_table()`, recorded
on the flextable as `hv_layout`, which the saver and the display read to place the header
marks. The JTCVS functions become wrappers: each warns, then passes its arguments through to
the describe layout.

**Tech Stack:** R (>= 4.4), gtsummary 2.5.1, flextable 0.10.0, officer 0.7.6, xml2, testthat 3,
roxygen2 with markdown.

## Global Constraints

- Work on branch `feat/style-manuscript-describe`. Patch-digit bumps only, and no `Version:`
  change in this feature PR; it adds `news/feat-style-manuscript-describe.md` (AGENTS.md).
- `NOT_CRAN=true Rscript -e 'devtools::test()'`: 0 failures, 0 warnings, 0 skips. The
  baseline on `main` (62ab8fe) is `FAIL 0 | WARN 0 | SKIP 0`, 1275 expectations.
- **Lint against an installed copy of the branch**, or new functions read as undefined:
  `R CMD INSTALL -l <scratch lib> .` then `R_LIBS=<scratch lib> Rscript -e
  'lintr::lint_package()'`: 0 lints. The line limit is lintr's default, 80 columns.
- **lintr's `object_usage_linter` cannot see testthat helper files.** A test file that calls a
  helper (`helper-fixtures.R`, `helper-word.R`) inside one of its own function definitions
  needs a FILE key in `.lintr` excluding that linter. Today `test-table-styles.R` and
  `test-word-output.R` have one; Task 4 adds `test-hv-check-docx.R` and
  `test-hv-man-table-save-jtcvs.R` (verified: a `jtcvs_quiet()` call inside `mk_jtcvs_ft()`
  lints as "no visible global function definition"; the same call in `helper-fixtures.R`
  itself does not).
- **String literals under `R/` are ASCII**, written with `\u` escapes (`"†"`,
  `"±"`), or `R CMD check` warns. Roxygen comments may carry the characters. This plan's
  test code uses escapes too.
- `devtools::check()` from a clean `git archive` export, with the PDF manual and vignettes
  built: 0 errors, 0 warnings, 0 notes. In a worktree the hidden `.git` NOTE is an artifact.
- **flextable span matrices are doubles:** assert spans with `expect_equal()`, never
  `expect_identical()` against integers.
- **`information_data_chunk()`'s `.col_id` is a factor:** compare it through
  `as.character()` (found while probing this plan).
- **testthat 3's `expect_warning()` returns the condition, not the value:** assign inside it,
  `expect_warning(ft <- f(), ...)`.
- **A helper cannot shadow a package function in a test** (probed: a `hv_man_table_jtcvs()`
  defined in a helper file still resolves to the namespace's), so deprecated calls are wrapped
  where they are made, in `jtcvs_quiet()`.
- `border_outer(part = "all")` leaves the body's first-row top border at 0; the manuscript
  dressing sets it with `flextable::border(ft, i = 1, border.top = line, part = "body")`. Task 1
  moves that line into the shared dressing, so `"describe"` inherits it.
- The manuscript header is bold (`header_bold` is `TRUE` in both styles), and marks the saver
  appends with `.mark_header()` come out bold. The manuscript label column is 2.0 in.
- `hv_check_docx(style =)`'s merged-cell rule allows merges only in Word's header rows (the
  leading run with `w:tblHeader` on) and in body rows that are one cell, or one `w:hMerge`
  group, spanning the table. A describe table must pass it with `style = "manuscript"`.
- Run hvtiRtemplates' `origin/main` `dc-tables` tests against the branch before the PR:
  `R CMD INSTALL -l <lib>` this branch and an `origin/main` `git archive` of hvtiRtemplates,
  then `R_LIBS=<lib> NOT_CRAN=true Rscript -e 'devtools::test(filter = "dc-tables")'` from
  the export. Report the test count and SKIP.
- Every new branch of code is proved red first, and by mutation. Stage files by name; never
  `git add -A` (a failing run writes `tests/testthat/_problems/`).
- Synthetic data only. US spelling. No em-dashes anywhere (a hook blocks them).

## What Phase 3 ships, and what it leaves

From the roadmap in `2026-10-17-table-styles-plan.md`:

| ships here | design reference |
|---|---|
| `hv_man_table(layout = c("compare", "describe"))`, valid with `style = "manuscript"` | 5.1, D3 |
| the describe layout: a count beside each group, each group spanning its (n, statistic) pair, row 2 naming them, Overall and comparison columns when the table carries them | 5.1 |
| describe shares compare's grid, shaded spanning sections, `*`/`†` notes, font, rows and page | 5.1, question 10 |
| the saver and the display place describe's marks: `*` on each `n`, `†` on each statistic | rows 8-10 |
| `hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()`, `hv_test_footnotes_jtcvs()` deprecated, each passing its arguments through | D3 |
| a test that each wrapper keeps an Overall, a P and a standardized-difference column | D3 |
| the JTCVS tests moved to describe | D3 |

**Left for later phases:** the "Table styles" article (Phase 4); hvtiRtemplates (Phase 5). The
**removal** of the three JTCVS functions, their tests, `jtcvs_quiet()`, and the SAS glossary's
`jtcvs` family is the release after this one ships.

**In no phase yet:** turning `^2^` in a variable label into a superscript (design section 7,
third bullet). Still unassigned; the PR asks John where it goes.

**Checked 2026-10-19 on `origin/main`:** no other hvtiR package calls the JTCVS functions.
hvtiRtemplates (caea4d2) mentions `hv_man_table_jtcvs()` only in two prose lines of
`dev/specs/2026-08-10-avr-lvf-temporalhazard-parity-design.md`, no code; its `dc-tables`
template calls `hv_man_table()`, `hv_man_table_save()`, `hv_man_table_display()` and
`hv_check_docx()` without a style. hvtiRutilities (a4425af) and hvtiPlotR (1267f785) do not
mention them.

## Decisions this plan takes

Each is a reading of the design where it is silent or disagrees with itself. The PR lists them
for John. **Decision 1 is confirmed** (John, 2026-10-19: deprecated calls draw the describe
layout during the deprecation release), so Task 5 runs.

1. **A deprecated call draws describe's look, not the JTCVS look ("same columns, new look").**
   Confirmed by John, 2026-10-19.
   D3 says the wrappers keep existing calls "working", which reads either as "same output" or
   as "same columns, new look". This plan takes the second, because D3's own wording
   presupposes it: each wrapper "passes its arguments through", the columns stay the same
   "since describe shows Overall and comparison columns", and "their tests move to describe".
   So a deprecated call gets the grid, the shaded sections, `*`/`†` notes and the document's
   font in place of rules, lettered notes and Times New Roman. **The alternative**, the old
   output plus a warning, keeps the old renderer for one release: Task 5 is then dropped
   (Task 4 already adds the warnings and the column test), and the JTCVS tests move at
   removal instead.
2. **`layout` is an argument of `hv_man_table()`, not a property of `hv_table_style()`.** The
   design says the layout "is chosen by the table, not the journal" (5.1) and D3's message
   names `hv_man_table(style = "manuscript", layout = "describe")`. A journal's style object
   (its fill) then serves Table 1 (`"compare"`) and Table 2 (`"describe"`) alike. Naming a
   layout with the report style is an error, since that style has one.
3. **`layout` sits after `style`, before `...`,** as `style` does, so a fully positional call
   can reach it. The SAS-name check therefore reports a stray positional argument at position
   7, not 6; `test-hv-sas-glossary.R`'s two pinned numbers change.
4. **The public describe path requires an `hv_tbl_summary()` table**, the rule compare has,
   though describe needs no `hv_n`: one rule for the manuscript style, and the group labels
   come from what that function records. The deprecated wrapper still takes any table with
   the `{N_nonmiss} ||| {stat}` convention, as today, since it is given its labels.
5. **Row 2 names each pair: `n`, and the table's statistic label** (`hv_stat_label`, such as
   `No. (%) or Median [15th, 85th percentiles]`), as the JTCVS renderer does and its
   `stat_label` argument sets. The `†` note still says it in compare's words, so the header
   and the note repeat each other; that keeps "row 2 names them" (5.1) and the note identical
   across layouts (question 10).
6. **Marks in describe:** `*` on every group's `n` (each is a count), `†` on every statistic
   sub-header, and `†` on the comparison header when the note names its tests or the
   standardized difference. Any other note symbol goes on the first `n`. Row 2 carries the
   marks; the comparison header, merged down, carries its `†` in row 1. **The targets come
   from the groups the table was built with**, recorded on the flextable as `hv_pairs`
   (`n_<g>` and `disp_<g>` for each name in `groups`), not from a `stat_<k>` pattern: the
   deprecated wrapper accepts any convention-bearing column as a group (an external review
   found a `custom_a`/`custom_b` call that got no `*` and no `†` from the pattern).
7. **Two header rows and no grouping-name row:** `hv_by_label` is not shown in describe, since
   its groups are often separate cohorts. Comparison headers are merged down both rows, as in
   compare, where the JTCVS renderer left a blank cell above each.
8. **`continuous_stat = "both"` is drawn by describe** (each group spans n, statistic and
   median), as Phase 2's decision 2 promised; compare still refuses it.
9. **Describe takes compare's widths:** label 2.0 in, each `n` 0.6, each statistic or median
   1.1, each comparison 0.6. Two groups and a P come to 6.0 in and stay portrait; the JTCVS
   renderer's were 2.5 and 0.9.
10. **An ungrouped table in describe is one pair under `All patients (N = n)`, in two header
    rows**, rather than compare's one-row form. Either keeps the count (5.1).
11. **Deprecation is base R's `.Deprecated()`, a warning of class `deprecatedWarning` on every
    call**, not once per session, and no new dependency. Tests run what a deprecated call still
    does through `jtcvs_quiet()`, which muffles that class only, and assert each function's
    warning once.
12. **`hv_man_table_jtcvs()`'s `font` and `font_size` are checked as before and set nothing**,
    since the manuscript style takes the document's font. A bad value still errors.
13. **How the JTCVS saver maps onto the manuscript saver:** `caption` is the caption (required
    by both); `abbreviations` the key; the `n` header's `a. Patients with data available.`
    becomes describe's `*Patients with non-missing data.`; a test note
    `hv_test_footnotes_jtcvs()` wrote (one of its test texts on `hv_compare_col`) is dropped
    **only when the table already names that test**: a non-Fisher test when the table
    carries `hv_tbl_summary()`'s test sentence (`hv_test_note`, which #87 added to the
    `†` note), Fisher's exact test when the table marks it with `‡`. Otherwise, as on a
    plain gtsummary table, which carries neither, the entry is kept and written like a
    caller's note. A caller's own positional notes keep lettered superscripts on their cells
    for this release, lettered from `a`, written after the table's own notes. (An external
    review found that dropping every recognized test note left a plain table's Wilcoxon test
    unnamed.)
14. **`hv_test_footnotes_jtcvs()` returns what it returns today**, and warns.
15. **`hv_man_table_display()` shows a describe table, the deprecated wrapper's included.** Its
    refusal of a JTCVS table read `hv_header_footnotes`, which nothing sets once Task 5 lands,
    so the refusal goes.
16. **Other test files' JTCVS calls are wrapped, not converted** (`test-hv-tbl-summary.R`,
    `test-hv-check-docx.R`, `test-hv-tbl-compare.R`, `test-contract-parity.R`,
    `test-hv-sas-glossary.R`): they test that those paths still work, which is what the
    deprecation release promises. Converting or deleting them, and the SAS glossary's `jtcvs`
    family, is the removal release's work.
17. **The deprecation message says the functions go "in the next release".** Which release
    removes them is John's call; the message is one string, `.jtcvs_deprecated()`, to change.
18. **Design section 3 contradicts section 5.1.** Section 3's describe row says "no Overall, no
    P"; 5.1 says Overall and comparison columns appear when the table carries them, which D3
    relies on. Task 0 aligns section 3 with 5.1.
19. **A deprecated function's `@examples` show the call that replaces it**, so the manual's
    examples raise no deprecation warnings.

## File structure

| file | change |
|---|---|
| `dev/specs/2026-10-17-table-styles-design.md` | Task 0: section 3's describe row; 5.1's header and marker rows; D3's pointer to decision 1 |
| `R/hv-man-table-compare.R` | Task 1: `.check_manuscript_tbl()`, `.group_labels()`, `.dress_manuscript()` out of `.man_table_compare()`; `.mark_compare(stat_label =)`; `hv_layout` |
| `R/hv-man-table.R` | Task 2: `layout` argument, `.check_layout()`, the describe dispatch |
| `R/hv-man-table-describe.R` (new) | Task 2: `.man_table_describe()` |
| `R/hv-man-table-save.R` | Task 3: `.footnote_cells()`, describe in `.footnote_cols()`, `.mark_header()` by row; Task 5: `.write_man_docx()` |
| `R/hv-man-table-jtcvs.R` | Task 4: `.jtcvs_deprecated()`, the warning; Task 5: the body delegates |
| `R/hv-man-table-save-jtcvs.R` | Task 4: the warning; Task 5: the body maps onto `.write_man_docx()`; `.drop_named_tests()` |
| `R/hv-test-footnotes-jtcvs.R` | Task 4: the warning |
| `R/hv-man-table-display.R` | Task 5: the JTCVS refusal goes |
| `tests/testthat/helper-fixtures.R` | Task 4: `jtcvs_quiet()`; `fx_jtcvs_ft()`, `save_fit()` through it |
| `tests/testthat/test-hv-man-table-describe.R` (new) | Task 2 |
| `tests/testthat/test-table-styles.R` | Task 3: describe, saved, row by row |
| `.lintr` | Task 4: two file keys |
| tests named in each task | each task |
| roxygen, `README.md`, vignettes, `DESCRIPTION`, `_pkgdown.yml`, news fragment | Tasks 4 to 6 |

## Verified by probing, 2026-10-19

The code in Tasks 1 to 5 was built in a scratch copy of `main` (62ab8fe) and run, with
`devtools::load_all()` and the full suite under `NOT_CRAN=true`:

- **Describe's flextable:** for Overall, two groups, P and a joined Std. Diff., the keys are
  `label, n_stat_0, disp_stat_0, n_stat_1, disp_stat_1, n_stat_2, disp_stat_2,
  hv_compare_col, hv_join_1`; header row spans `1 2 0 2 0 2 0 1 1`, column spans merge
  `label` and both comparison columns down two rows; section rows span all 9 columns.
- **Saved XML:** two `w:tblHeader` rows, three `w:gridSpan="2"` cells in row 1, row 2 reading
  `n*` and `No. (%) or Median [15th, 85th percentiles]†` per group, `P†` in row 1, notes
  `*Patients with non-missing data.` and `†Values are ...; P values from the Wilcoxon rank
  sum test and Pearson's chi-square test.`, every header text run bold (18 of 18), and
  `hv_check_docx(style = "manuscript")` 0 findings. **Before Task 3's `.footnote_cells()`, the
  saver put `*` on row 1, so it read `Overall (N = 200)*`, and the `†` vanished into a
  merged-away cell.** That is why Task 3 exists.
- **Pages:** that table is 8.3 in and turns landscape; two groups and P is 6.0 in, and two
  groups without P 5.4 in, both portrait.
- **`"both"`** spans 3 per group with a `Median [15th, 85th percentiles]` sub-header; an
  ungrouped table reads `All patients (N = 200)` over `n*` and the statistic; a mixed table
  marks `¶` on every statistic cell and notes `¶Mean±SD.`; all pass `hv_check_docx()`.
- **Deprecation:** `.Deprecated(msg = )` signals class `deprecatedWarning`;
  `NULL[["*"]] <- "x"` builds a list, so describe's notes work on a plain gtsummary table
  carrying no `hv_footnotes`.
- **The wrappers:** with `groups = c(stat_0 =, stat_1 =, stat_2 =)` and the table's
  `hv_trailing`, the Overall, P and Std. Diff. columns survive all three; the saved notes are
  the table's own and no lettered test line; a caller's two positional notes print as `a.`
  and `b.` after them, their letters on the `n` cells.
- **The suite at the end of Task 5's code, before Task 4's wrapping:** FAIL 0, with only
  unwrapped deprecation warnings left (130). Before the rewrites in Task 5, the delegation
  failed exactly 17 tests: the 15 listed in Task 5, and the two SAS-position tests Task 2 updates.
- **Lint** on that build: clean but for the two lessons recorded in Global Constraints.
- **After the external review of 12273ae**, two fixes were probed on the same build. Group
  columns named `custom_a`/`custom_b`: before `hv_pairs`, the saved row 2 carried no `n*` and
  no `†`; after it, two of each, through `.man_table_describe()` and through the wrapper. A
  plain gtsummary table with `add_p()` and an `hv_compare_col`: before the fix the saver
  dropped both `Wilcoxon rank-sum test.` and `Pearson chi-square test.`, leaving no test
  named; after it they print as `a.` and `b.`, while the `hv_tbl_summary()` round trip still
  drops its own. Mutations: test-sentence check removed (drop always) and `named` emptied
  (drop never) each go red; `*` targets taken from the `^n_stat_` pattern, and the
  `hv_pairs` attribute removed, each go red. Full suite FAIL 0; `dc-tables` again 38 tests,
  FAIL 0, SKIP 0, 153 expectations.
- **hvtiRtemplates `origin/main` `dc-tables`** against that build, `NOT_CRAN=true`: 38 tests,
  FAIL 0, WARN 0, **SKIP 0**, 153 expectations.

---

### Task 0: Align the design with section 5.1 and record the layout's details

**Files:**
- Modify: `dev/specs/2026-10-17-table-styles-design.md`

- [ ] **Step 1: Section 3, the describe row (decision 18).** Replace the cell

  ```
  each group spans its own (n, statistic) pair, a count per group, no Overall, no P (ms.1333)
  ```

  with

  ```
  each group spans its own (n, statistic) pair, a count per group; Overall and comparison columns when the table carries them (ms.1333 carries neither)
  ```

- [ ] **Step 2: Section 5.1, the header and marker rows (decisions 5 and 6).** In the 5.1
  table, replace the describe cell `each group spans its own (n, statistic) pair; row 2 names
  them` with `each group spans its own (n, statistic) pair; row 2 names them: n, and the
  table's statistic label`, and the describe cell `` `*`, `†`, as `"compare"` (ms.1333 used a
  lettered `a`) `` with `` `*`, `†`, as `"compare"`: `*` on each group's n, `†` on each
  statistic (ms.1333 used a lettered `a`) ``.

- [ ] **Step 3: Section 5.1, the argument (decision 2).** After the paragraph that ends "uses
  both in one manuscript.", add: `The layout is an argument of hv_man_table(), not a property
  of the style, so one style object (one journal's fill) serves both tables.`

- [ ] **Step 4: D3 (decision 1).** At the end of D3, after "Their tests move to
  `"describe"`.", add: `What a deprecated call draws during that release is decision 1 of
  2026-10-19-table-styles-phase3-plan.md.`

- [ ] **Step 5: Commit**

  ```bash
  git add dev/specs/2026-10-17-table-styles-design.md
  git commit -m "spec(table-styles): section 3 follows 5.1; record describe's header and marks"
  ```

### Task 1: The pieces both manuscript layouts share

A refactor of `R/hv-man-table-compare.R` with one new behavior, the `hv_layout` attribute.
Every existing compare and table-styles test must pass unchanged.

**Files:**
- Modify: `R/hv-man-table-compare.R` (`.man_table_compare()`, lines 1-91; `.mark_compare()`,
  lines 96-103)
- Test: `tests/testthat/test-hv-man-table-compare.R`

**Interfaces:**
- Produces: `.check_manuscript_tbl(tbl)` (errors unless `tbl` has `hv_n`);
  `.group_labels(tbl)`, a named character vector `stat_<k>` -> `"<level> (N = n)"`, or
  `"All patients (N = n)"` when the table has no grouping; `.dress_manuscript(ft, body, keys,
  style)`, returning `ft` with section spans, padding, alignment, the bold header, the grid,
  the first body row's top border, section bold and fill, no font, valign, row heights, the
  `atleast` rule and the table properties; `.mark_compare(ft, tbl, body, disp, style,
  stat_label = attr(tbl, "hv_stat_label", exact = TRUE))`; `attr(ft, "hv_layout")`, here
  `"compare"`. Tasks 2, 3 and 5 rely on these names.

- [ ] **Step 1: Write the failing test** (append to `test-hv-man-table-compare.R`, which
  defines `cmp()`):

```r
test_that("compare: the flextable records its layout", {
  expect_identical(attr(cmp(), "hv_layout"), "compare")
})
```

- [ ] **Step 2: Run it; it fails** (`NULL`).
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "hv-man-table-compare")'`

- [ ] **Step 3: Implement.** Replace lines 1-91 of `R/hv-man-table-compare.R` (the header
  comment and `.man_table_compare()`) with:

```r
# The "manuscript" style's "compare" layout (design section 5): a full
# grid; a two-row header with "Characteristic" and "n" merged down and
# the grouping's name spanning its levels; one overall n column; shaded
# section rows spanning the table; no font of its own. Built from the
# body the JTCVS renderer reshapes, as the "describe" layout is, so the
# two layouts share their cells and differ in their counts.
.man_table_compare <- function(tbl, style) {
  .check_manuscript_tbl(tbl)
  tb <- tbl$table_body
  if (any(grepl("^hv_median_stat_[0-9]+$", names(tb))))
    stop("A manuscript table shows one statistic per group, and ",
         "continuous_stat = \"both\" shows two. Build it with ",
         "continuous_stat = \"median\" or \"mean\"; \"both\" is for the ",
         "report.", call. = FALSE)

  by_label <- attr(tbl, "hv_by_label", exact = TRUE)
  groups <- .group_labels(tbl)
  stat_cols <- names(groups)
  .assert_stat_convention(tb, groups, caller = "hv_man_table")

  compare <- attr(tbl, "hv_trailing", exact = TRUE)
  body <- .reshape_jtcvs_body(tbl, groups, c(hv_n = "n", compare))
  disp <- paste0("disp_", stat_cols)
  keys <- c("label", "hv_n", disp, names(compare))

  ft <- flextable::flextable(body, col_keys = keys)
  ft <- do.call(flextable::set_header_labels, c(
    list(x = ft, label = "Characteristic", hv_n = "n"),
    as.list(stats::setNames(unname(groups), disp)), as.list(compare)
  ))
  if (!is.null(by_label)) {
    overall <- "stat_0" %in% stat_cols
    top <- c("Characteristic", "n", if (overall) groups[["stat_0"]],
             by_label, unname(compare))
    widths <- c(1L, 1L, if (overall) 1L, sum(stat_cols != "stat_0"),
                rep(1L, length(compare)))
    ft <- flextable::add_header_row(ft, top = TRUE, values = top,
                                    colwidths = widths)
    down <- c("label", "hv_n", if (overall) "disp_stat_0", names(compare))
    ft <- flextable::merge_v(ft, j = down, part = "header")
  }

  ft <- .dress_manuscript(ft, body, keys, style)
  ft <- flextable::width(ft, j = "label", width = 2.0)
  ft <- flextable::width(ft, j = c("hv_n", names(compare)), width = 0.6)
  ft <- flextable::width(ft, j = disp, width = 1.1)

  ft <- .mark_compare(ft, tbl, body, disp, style)
  attr(ft, "hv_layout") <- "compare"
  ft
}

# A manuscript table is drawn from the overall count and the grouping's
# name hv_tbl_summary() records.
.check_manuscript_tbl <- function(tbl) {
  if (!"hv_n" %in% names(tbl$table_body))
    stop("style = \"manuscript\" needs a table from hv_tbl_summary(), ",
         "which carries each variable's overall count for the n column.",
         call. = FALSE)
  invisible(NULL)
}

# Each statistic column's header, "<level> (N = n)", or "All patients
# (N = n)" for a table with no grouping.
.group_labels <- function(tbl) {
  stat_cols <- grep("^stat_[0-9]+$", names(tbl$table_body), value = TRUE)
  hdr <- tbl$table_styling$header
  hdr <- hdr[match(stat_cols, hdr$column), , drop = FALSE]
  by_label <- attr(tbl, "hv_by_label", exact = TRUE)
  level <- if (is.null(by_label)) "All patients" else hdr$modify_stat_level
  stats::setNames(sprintf("%s (N = %s)", level, hdr$modify_stat_n),
                  stat_cols)
}

# What both manuscript layouts share (design section 5.1): section rows
# spanning the table, bold and shaded; a full grid; the header bold; no
# font of its own; 300-twip rows kept whole; the header repeated.
.dress_manuscript <- function(ft, body, keys, style) {
  sec_i <- which(body$is_section)
  for (i in sec_i)
    ft <- flextable::merge_at(ft, i = i, j = keys, part = "body")
  level_i <- which(body$row_type == "level")
  if (length(level_i) > 0L)
    ft <- flextable::padding(ft, i = level_i, j = "label",
                             padding.left = 20)

  ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::align(ft, j = "label", align = "left", part = "all")
  ft <- flextable::bold(ft, bold = style$header_bold, part = "header")
  line <- officer::fp_border(color = "black", width = 0.5)
  ft <- flextable::border_remove(ft)
  ft <- flextable::border_outer(ft, border = line, part = "all")
  ft <- flextable::border_inner(ft, border = line, part = "all")
  # border_outer() over "all" leaves the body's own top edge at 0 (the
  # header's foot draws the line), so the first row's top is set here and
  # Word has no unset border to arbitrate against the header's.
  ft <- flextable::border(ft, i = 1, border.top = line, part = "body")
  if (length(sec_i) > 0L) {
    ft <- flextable::bold(ft, i = sec_i, part = "body", bold = TRUE)
    ft <- flextable::bg(ft, i = sec_i, bg = style$fill, part = "body")
  }
  # NA leaves the run's font and size unset in the .docx, so the table
  # takes the document's body font (design question 5).
  ft <- flextable::font(ft, fontname = style$font, part = "all")
  ft <- flextable::fontsize(ft, size = style$font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")
  ft <- flextable::height_all(ft, height = style$row_height / 1440,
                              part = "all")
  ft <- flextable::hrule(ft, rule = "atleast", part = "all")
  flextable::set_table_properties(ft, opts_word = list(
    split = !style$keep_rows, repeat_headers = style$repeat_header
  ))
}
```

  Then change `.mark_compare()`'s signature and its dagger line. Replace

```r
.mark_compare <- function(ft, tbl, body, disp, style) {
```

  with

```r
.mark_compare <- function(ft, tbl, body, disp, style,
                          stat_label = attr(tbl, "hv_stat_label",
                                            exact = TRUE)) {
```

  and replace

```r
  notes[["\u2020"]] <- .stat_note(attr(tbl, "hv_stat_label", exact = TRUE),
                                  style)
```

  with

```r
  notes[["\u2020"]] <- .stat_note(stat_label, style)
```

- [ ] **Step 4: Run the tests; the new one passes, and nothing else moves.**
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "hv-man-table|table-styles")'`
  Expected: the new test passes; every other test in those files passes unchanged.

- [ ] **Step 5: Prove it by mutation.** Delete `attr(ft, "hv_layout") <- "compare"`: the new
  test fails. Delete the `bg()` call in `.dress_manuscript()`: compare's "section rows span
  the table and are shaded" test fails, so compare really runs through the shared dressing.
  Restore both. (Deleting the first-row `border()` line is not a usable mutation: probed, no
  test goes red, since the saved XML draws that edge from the header's foot as well.)

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-compare.R tests/testthat/test-hv-man-table-compare.R
git commit -m "refactor(manuscript): the dressing, labels and notes both layouts share"
```

### Task 2: `hv_man_table(layout =)` and the describe layout

**Files:**
- Create: `R/hv-man-table-describe.R`
- Modify: `R/hv-man-table.R` (signature, dispatch, `.check_layout()`, `@param layout`)
- Modify: `tests/testthat/test-hv-sas-glossary.R` (the two positional tests, decision 3)
- Test: `tests/testthat/test-hv-man-table-describe.R` (new)

**Interfaces:**
- Consumes: `.check_manuscript_tbl()`, `.group_labels()`, `.dress_manuscript()`,
  `.mark_compare(stat_label =)` (Task 1); `.reshape_jtcvs_body(tbl, groups, trailing)`,
  `.assert_stat_convention(tb, groups, arg, caller)`.
- Produces: `hv_man_table(tbl, font = "Times New Roman", font_size = 12, digits = 2,
  style = "report", layout = "compare", ...)`; `.check_layout(layout, style, given)`;
  `.man_table_describe(tbl, style, groups, trailing, stat_label)`, a flextable with keys
  `label`, then per group `n_<g>`, `disp_<g>` and, under `"both"`, `med_<g>`, then the
  comparison columns; attributes `hv_footnotes`, `hv_body_marks`, `hv_style`, `hv_test_note`,
  `hv_smd` (from `.mark_compare()`), `hv_layout = "describe"`, and `hv_pairs`, a list with
  `n` (the `n_<g>` keys) and `stat` (the `disp_<g>` keys) in `groups` order. Tasks 3 and 5
  rely on these.

- [ ] **Step 1: Write the failing tests** (`tests/testthat/test-hv-man-table-describe.R`):

```r
ds_tbl <- function(...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", show_variable = FALSE, ...
  )
}
ds <- function(tbl = ds_tbl(), ...) {
  hv_man_table(tbl, style = "manuscript", layout = "describe", ...)
}
ds_hdr <- function(ft, i) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == "header" & ch$.row_id == i, ]
  vapply(ft$col_keys, function(k) {
    paste(ch$txt[ch$.col_id == k], collapse = "")
  }, character(1))
}

test_that("describe: a count beside each group, Overall and P when carried", {
  ft <- ds()
  expect_identical(
    ft$col_keys,
    c("label", "n_stat_0", "disp_stat_0", "n_stat_1", "disp_stat_1",
      "n_stat_2", "disp_stat_2", "hv_compare_col")
  )
  expect_identical(attr(ft, "hv_layout"), "describe")
  expect_identical(attr(ft, "hv_style"), hv_table_style("manuscript"))
  d <- ft$body$dataset
  age <- which(d$row_type == "label" & d$variable == "age")
  a <- gtsummary::trial$age[gtsummary::trial$trt == "Drug A"]
  expect_identical(d$n_stat_1[age], as.character(sum(!is.na(a))))
  expect_match(d$disp_stat_1[age], "^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
  none <- ds(ds_tbl(overall = FALSE, compare = "none"))
  expect_identical(none$col_keys, c("label", "n_stat_1", "disp_stat_1",
                                    "n_stat_2", "disp_stat_2"))
})

test_that("describe: each group spans its pair; row 2 names them", {
  ft <- ds()
  expect_identical(flextable::nrow_part(ft, "header"), 2L)
  top <- ds_hdr(ft, 1)
  expect_identical(
    unname(top[c("label", "n_stat_0", "n_stat_1", "n_stat_2",
                 "hv_compare_col")]),
    c("Characteristic", "Overall (N = 200)", "Drug A (N = 98)",
      "Drug B (N = 102)", "P")
  )
  stat <- "No. (%) or Median [15th, 85th percentiles]"
  expect_identical(unname(ds_hdr(ft, 2)[-c(1, 8)]),
                   rep(c("n", stat), 3))
  # flextable span matrices are doubles.
  expect_equal(unname(ft$header$spans$rows[1, ]),
               c(1, 2, 0, 2, 0, 2, 0, 1))
  expect_equal(unname(ft$header$spans$columns[, c(1, 8)]),
               matrix(c(2, 0), 2, 2))
})

test_that("describe: the grid, the shaded spanning sections, no font", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age", Disease = "grade"),
    continuous = "age", categorical = "grade", show_variable = FALSE
  )
  ft <- hv_man_table(tbl, layout = "describe",
                     style = hv_table_style("manuscript", fill = "#A5C9EB"))
  sec <- which(ft$body$dataset$is_section)
  n <- length(ft$col_keys)
  expect_length(sec, 2L)
  for (i in sec) {
    expect_equal(unname(ft$body$spans$rows[i, ]), c(n, rep(0, n - 1L)))
    expect_true(all(ft$body$styles$cells$background.color$data[i, ] ==
                      "#A5C9EB"))
  }
  for (side in c("top", "bottom", "left", "right"))
    expect_true(all(ft$body$styles$cells[[paste0("border.width.", side)]]$data
                    == 0.5), info = side)
  expect_true(all(is.na(ft$body$styles$text$font.family$data)))
  expect_true(all(ft$header$styles$text$bold$data))
  expect_true(all(abs(ft$body$rowheights - 300 / 1440) < 1e-9))
  expect_false(ft$properties$opts_word$split)
})

test_that("describe: the manuscript's widths, so two groups and P fit", {
  ft <- ds(ds_tbl(overall = FALSE))
  w <- ft$body$colwidths
  names(w) <- ft$col_keys
  expect_equal(unname(w[c("label", "n_stat_1", "disp_stat_1",
                          "hv_compare_col")]), c(2.0, 0.6, 1.1, 0.6))
  expect_equal(sum(w), 6.0)
})

test_that("describe: the manuscript's notes and the marks on cells", {
  d <- gtsummary::trial
  d$rare <- factor(ifelse(seq_len(nrow(d)) <= 3, "yes", "no"))
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "marker", "rare")),
    continuous = c("age", "marker"), categorical = "rare",
    mean_sd = "age", show_variable = FALSE
  )
  ft <- ds(tbl)
  notes <- attr(ft, "hv_footnotes")
  expect_identical(names(notes), c("*", "\u2020", "\u2021", "\u00B6"))
  expect_identical(notes[["*"]], "Patients with non-missing data.")
  expect_match(notes[["\u2020"]],
               "^Values are No\\. \\(%\\) or median \\[15th, 85th")
  expect_identical(names(attr(ft, "hv_body_marks")), c("\u2021", "\u00B6"))
  ch <- flextable::information_data_chunk(ft)
  body <- ft$body$dataset
  row_of <- function(v) which(body$row_type == "label" & body$variable == v)
  sup <- ch$.part == "body" & ch$vertical.align == "superscript"
  expect_true(any(sup & ch$.row_id == row_of("rare") &
                    ch$.col_id == "hv_compare_col" & ch$txt == "\u2021"))
  for (k in c("disp_stat_0", "disp_stat_1", "disp_stat_2"))
    expect_true(any(sup & ch$.row_id == row_of("age") & ch$.col_id == k &
                      ch$txt == "\u00B6"), info = k)
  expect_false(any(sup & ch$.col_id %in% c("n_stat_1", "n_stat_2")))
})

test_that("describe: under continuous_stat = 'both' a group spans three", {
  ft <- ds(ds_tbl(continuous_stat = "both", compare = "none",
                  overall = FALSE))
  expect_identical(ft$col_keys, c("label", "n_stat_1", "disp_stat_1",
                                  "med_stat_1", "n_stat_2", "disp_stat_2",
                                  "med_stat_2"))
  expect_equal(unname(ft$header$spans$rows[1, ]), c(1, 3, 0, 0, 3, 0, 0))
  expect_identical(unname(ds_hdr(ft, 2)[c("disp_stat_1", "med_stat_1")]),
                   c("No. (%) or Mean\u00B1SD",
                     "Median [15th, 85th percentiles]"))
})

test_that("describe: a table with no grouping keeps its count", {
  ft <- ds(hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                          continuous = "age", show_variable = FALSE))
  expect_identical(ft$col_keys, c("label", "n_stat_0", "disp_stat_0"))
  expect_identical(unname(ds_hdr(ft, 1)[2]), "All patients (N = 200)")
  expect_identical(unname(ds_hdr(ft, 2)[2]), "n")
})

test_that("a layout is the manuscript style's choice, and one of two", {
  expect_error(hv_man_table(ds_tbl(), layout = "describe"),
               "manuscript style's layouts")
  expect_error(
    hv_man_table(ds_tbl(), style = "manuscript", layout = "wide"),
    "\"compare\" or \"describe\""
  )
  # A gtsummary table with the cell convention but not from
  # hv_tbl_summary(): the layout could draw it, and refuses it instead.
  expect_error(
    hv_man_table(fx_jtcvs_tbl(), style = "manuscript", layout = "describe"),
    "overall count for the n column"
  )
  expect_error(ds(font = "Arial"), "document")
  # "compare" is the default, named or not.
  expect_identical(
    attr(hv_man_table(ds_tbl(), style = "manuscript"), "hv_layout"),
    "compare"
  )
  expect_identical(
    hv_man_table(ds_tbl(), style = "manuscript", layout = "compare")$col_keys,
    hv_man_table(ds_tbl(), style = "manuscript")$col_keys
  )
})
```

  In `test-hv-sas-glossary.R`, the positional tests move with the new argument (decision 3).
  Replace

```r
  expect_error(
    .check_sas_args(list("JUNK"), "hv_man_table"),
    "unused argument (position 6)", fixed = TRUE
  )
  expect_error(
    hv_man_table(gtsummary::tbl_summary(gtsummary::trial, include = "age"),
                 "Times New Roman", 12, 2, "report", "JUNK"),
    "unused argument (position 6)", fixed = TRUE
  )
```

  with

```r
  expect_error(
    .check_sas_args(list("JUNK"), "hv_man_table"),
    "unused argument (position 7)", fixed = TRUE
  )
  expect_error(
    hv_man_table(gtsummary::tbl_summary(gtsummary::trial, include = "age"),
                 "Times New Roman", 12, 2, "report", "compare", "JUNK"),
    "unused argument (position 7)", fixed = TRUE
  )
```

  and, in "a mixed named-and-positional dots list is handled sensibly",
  `"unused argument (position 6)"` with `"unused argument (position 7)"`.

- [ ] **Step 2: Run them; they fail** (unused argument `layout`; the glossary tests still read
  position 6). Run: `NOT_CRAN=true Rscript -e
  'devtools::test(filter = "hv-man-table-describe|hv-sas-glossary")'`

- [ ] **Step 3: Implement.** In `R/hv-man-table.R`, replace the signature and the start of
  `hv_man_table()`:

```r
hv_man_table <- function(tbl, font = "Times New Roman", font_size = 12,
                         digits = 2, style = "report", layout = "compare",
                         ...) {
  .check_sas_args(list(...), "hv_man_table")
  .check_gtsummary(tbl)
  style <- .as_style(style)
  .check_layout(layout, style, given = !missing(layout))
  if (identical(style$name, "manuscript")) {
    if (!missing(font) || !missing(font_size))
      stop("`font` and `font_size` set the report style. A manuscript ",
           "table sets no font, so it takes the font of the document it ",
           "is saved into.", call. = FALSE)
    if (identical(layout, "describe")) {
      .check_manuscript_tbl(tbl)
      return(.man_table_describe(
        tbl, style, groups = .group_labels(tbl),
        trailing = attr(tbl, "hv_trailing", exact = TRUE),
        stat_label = attr(tbl, "hv_stat_label", exact = TRUE)
      ))
    }
    return(.man_table_compare(tbl, style))
  }
```

  (the report path below is unchanged), and add before `.drop_gtsummary_notes()`:

```r
# A manuscript layout, chosen by what the table does (design section
# 5.1): "compare" puts one overall n column beside groups it compares,
# "describe" a count beside each group it describes. The report style
# has one layout, so naming one there is a mistake, not a choice.
.check_layout <- function(layout, style, given) {
  if (!is.character(layout) || length(layout) != 1L || is.na(layout) ||
        !layout %in% c("compare", "describe"))
    stop("`layout` must be \"compare\" or \"describe\".", call. = FALSE)
  if (given && !identical(style$name, "manuscript"))
    stop("`layout` chooses between the manuscript style's layouts. ",
         "The report style has one; drop `layout`, or use ",
         "style = \"manuscript\".", call. = FALSE)
  invisible(NULL)
}
```

  Add the roxygen parameter after `@param style`:

```r
#' @param layout The manuscript style's layout, chosen by what the table
#'   does: `"compare"` (default), one overall `n` column for groups it
#'   compares, or `"describe"`, a count beside each group, for cohorts or
#'   repeated measures it describes side by side. Either shows an Overall
#'   column and comparison columns when the table carries them. Only with
#'   `style = "manuscript"`.
```

  Create `R/hv-man-table-describe.R`:

```r
# The "manuscript" style's "describe" layout (design section 5.1), for a
# table that describes cohorts or repeated measures side by side: each
# group spans its own (n, statistic) pair, and row 2 names them. An
# Overall column and comparison columns appear when the table carries
# them. Everything else is "compare"'s: the grid, the shaded section
# rows, the notes, the font and the page.
#
# `groups` maps each statistic column to its header, `trailing` each
# comparison column to its header (NULL for none), and `stat_label`
# names the statistic in row 2. hv_man_table() passes the table's own;
# the deprecated hv_man_table_jtcvs() passes its caller's, unchanged.
.man_table_describe <- function(tbl, style, groups, trailing, stat_label) {
  stat_label <- stat_label %||% "No. (%) or Mean\u00B1SD"
  .assert_stat_convention(tbl$table_body, groups, caller = "hv_man_table")
  body <- .reshape_jtcvs_body(tbl, groups, trailing)
  g <- names(groups)
  n_cols <- paste0("n_", g)
  disp <- paste0("disp_", g)
  med <- intersect(paste0("med_", g), names(body))
  pair <- lapply(g, function(k) {
    intersect(paste0(c("n_", "disp_", "med_"), k), names(body))
  })
  keys <- c("label", unlist(pair), names(trailing))

  ft <- flextable::flextable(body, col_keys = keys)
  sub <- c(
    list(label = "Characteristic"),
    stats::setNames(as.list(rep("n", length(g))), n_cols),
    stats::setNames(as.list(rep(stat_label, length(g))), disp),
    stats::setNames(as.list(rep(
      attr(tbl, "hv_median_label", exact = TRUE) %||% "Median",
      length(med)
    )), med),
    as.list(trailing)
  )
  ft <- do.call(flextable::set_header_labels, c(list(x = ft), sub))
  ft <- flextable::add_header_row(
    ft, top = TRUE,
    values = c("Characteristic", unname(groups), unname(trailing)),
    colwidths = c(1L, lengths(pair), rep(1L, length(trailing)))
  )
  ft <- flextable::merge_v(ft, j = c("label", names(trailing)),
                           part = "header")

  ft <- .dress_manuscript(ft, body, keys, style)
  ft <- flextable::width(ft, j = "label", width = 2.0)
  ft <- flextable::width(ft, j = c(n_cols, names(trailing)), width = 0.6)
  ft <- flextable::width(ft, j = c(disp, med), width = 1.1)

  ft <- .mark_compare(ft, tbl, body, disp, style, stat_label)
  attr(ft, "hv_layout") <- "describe"
  # The saver and the display mark these columns, named for the groups
  # the table was built with, whatever those columns are called.
  attr(ft, "hv_pairs") <- list(n = n_cols, stat = disp)
  ft
}
```

  Then `Rscript -e 'devtools::document()'` (`man/hv_man_table.Rd` gains `layout`).

- [ ] **Step 4: Run the tests; they pass,** and then the whole suite: nothing else moves.

- [ ] **Step 5: Prove it by mutation.** (a) Delete the describe dispatch in `hv_man_table()`:
  every describe test but the refusals fails. (b) Make `given` always `FALSE`: the
  report-plus-layout refusal fails. (c) Drop the `merge_v()` call: the spans test fails.
  (d) Replace `lengths(pair)` with `rep(2L, length(g))`: the `"both"` test fails
  (`add_header_row()` errors). (e) Delete `.check_manuscript_tbl(tbl)` from the describe
  dispatch: the convention-table refusal fails. Restore all. (Each mutation in Tasks 2, 3
  and 5 was run on the probe build and went red.)

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table.R R/hv-man-table-describe.R man/hv_man_table.Rd tests/testthat/test-hv-man-table-describe.R tests/testthat/test-hv-sas-glossary.R
git commit -m "feat(hv_man_table): the manuscript style's describe layout"
```

### Task 3: The saver and the display place describe's marks

**Files:**
- Modify: `R/hv-man-table-save.R` (`.mark_header()`, `.footnote_cols()`, a new
  `.footnote_cells()`)
- Test: `tests/testthat/test-table-styles.R`

**Interfaces:**
- Consumes: `attr(ft, "hv_pairs")` (Task 2), the describe layout's mark targets whatever
  the group columns are called; `.compare_noted(ft)`.
- Produces: `.footnote_cells(ft, sym)`, a `data.frame(i, j)` of header rows and column indices;
  `.mark_header(ft, footnotes)` marking by row. Both the saver and `hv_man_table_display()`
  call `.mark_header()`, so both follow.

- [ ] **Step 1: Write the failing tests** (append to `test-table-styles.R`, which defines
  `st_tbl()`, `xq()`, `ncols()` and `sec_row()`):

```r
# -- the manuscript's describe layout, saved ------------------------------

dsc_save <- function(tbl = st_tbl(), fill = "#CAEDFB") {
  ft <- hv_man_table(tbl, style = hv_table_style("manuscript", fill = fill),
                     layout = "describe")
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 2. Cohorts")
  f
}

test_that("describe, rows 1-3: spanning shaded sections and a full grid", {
  x <- wx_doc(dsc_save(fill = "#A5C9EB"))
  tc <- xq(sec_row(x), "./w:tc")
  expect_length(tc, 1L)
  expect_identical(xml2::xml_attr(xq(tc, ".//w:gridSpan"), "val"),
                   as.character(ncols(x)))
  expect_identical(xml2::xml_attr(xq(tc, ".//w:shd"), "fill"), "A5C9EB")
  n_tc <- length(xq(x, "//w:tc"))
  for (side in c("top", "bottom", "left", "right")) {
    path <- sprintf("//w:tcBorders/w:%s[@w:val='single' and @w:sz='4']", side)
    expect_length(xq(x, path), n_tc)
  }
})

test_that("describe, rows 4-5: each group spans its pair; n* on each", {
  x <- wx_doc(dsc_save())
  expect_length(xq(x, "//w:tr[w:trPr/w:tblHeader]"), 2L)
  top <- vapply(xq(x, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(top[1:4], c("Characteristic", "Overall (N = 200)",
                               "Drug A (N = 98)", "Drug B (N = 102)"))
  expect_identical(top[5], "P\u2020")
  expect_length(xq(x, "//w:tr[1]/w:tc[.//w:gridSpan[@w:val='2']]"), 3L)
  sub <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
  stat <- "No. (%) or Median [15th, 85th percentiles]\u2020"
  expect_identical(sub[2:7], rep(c("n*", stat), 3))
})

test_that("describe, rows 8-10: the notes, as compare writes them", {
  x <- wx_doc(dsc_save())
  notes <- vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text,
                  character(1))
  expect_identical(notes[1], "*Patients with non-missing data.")
  expect_match(notes[2], "^\u2020Values are No\\. \\(%\\) or median")
  sup <- xq(x, paste0("//w:tbl/following-sibling::w:p//",
                      "w:vertAlign[@w:val='superscript']"))
  expect_length(sup, 0L)
})

test_that("describe: no font, a caption, Letter, and hv_check_docx() passes", {
  f <- dsc_save()
  x <- wx_doc(f)
  expect_length(xq(x, "//w:tbl//w:rFonts[@w:ascii]"), 0L)
  expect_identical(wx_text(xq(x, "//w:body/*[1]")[[1]]), "Table 2. Cohorts")
  expect_setequal(unname(pg_size(f)), c("12240", "15840"))
  expect_identical(nrow(hv_check_docx(f, style = "manuscript")), 0L)
})

test_that("a replica of a two-cohort describe table: no Overall, no P", {
  # ms.1333's shape: two separate cohorts side by side, a count each.
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "marker"), Disease = "stage"),
    continuous = c("age", "marker"), categorical = "stage",
    overall = FALSE, compare = "none", show_variable = FALSE
  )
  f <- dsc_save(tbl)
  x <- wx_doc(f)
  top <- vapply(xq(x, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(top, c("Characteristic", "Drug A (N = 98)",
                          "Drug B (N = 102)"))
  sub <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(fit_geometry(f)$landscape, FALSE)
  expect_identical(nrow(hv_check_docx(f, style = "manuscript")), 0L)
})

test_that("a describe table displays with its marks where Word has them", {
  shown <- hv_man_table_display(hv_man_table(
    st_tbl(), style = "manuscript", layout = "describe"
  ))
  ch <- flextable::information_data_chunk(shown)
  marks <- ch[ch$.part == "header" & ch$vertical.align == "superscript", ]
  stars <- as.character(marks$.col_id[marks$txt == "*"])
  expect_identical(sort(unique(stars)), c("n_stat_0", "n_stat_1", "n_stat_2"))
  expect_true(all(marks$.row_id[marks$txt == "*"] == 2L))
  foot <- ch[ch$.part == "footer" & ch$.row_id == 1, ]
  expect_identical(paste(foot$txt, collapse = ""),
                   "*Patients with non-missing data.")
})

test_that("describe marks the groups it was built with, whatever their names", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$custom_a <- tbl$table_body$stat_1
  tbl$table_body$custom_b <- tbl$table_body$stat_2
  ft <- .man_table_describe(tbl, hv_table_style("manuscript"),
                            groups = c(custom_a = "A", custom_b = "B"),
                            trailing = NULL, stat_label = NULL)
  expect_identical(attr(ft, "hv_pairs"),
                   list(n = c("n_custom_a", "n_custom_b"),
                        stat = c("disp_custom_a", "disp_custom_b")))
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 2. Cohorts")
  sub <- vapply(xq(wx_doc(f), "//w:tr[2]/w:tc"), wx_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(sum(endsWith(sub, "\u2020")), 2L)
})
```

- [ ] **Step 2: Run them; they fail.** Rows 4-5 read `Overall (N = 200)*` in row 1 and no
  `†` on any statistic; the display test finds one `*`, in row 1; the custom-column test
  finds no `n*` and no dagger in row 2.
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "table-styles")'`

- [ ] **Step 3: Implement.** In `R/hv-man-table-save.R`, replace `.mark_header()` with:

```r
# Superscript each footnote symbol onto its header cells. A symbol
# already on body cells needs no header mark.
.mark_header <- function(ft, footnotes) {
  body_marks <- attr(ft, "hv_body_marks", exact = TRUE)
  for (sym in setdiff(names(footnotes), names(body_marks))) {
    cells <- .footnote_cells(ft, sym)
    for (i in unique(cells$i))
      ft <- flextable::append_chunks(ft, i = i, j = cells$j[cells$i == i],
                                     part = "header", flextable::as_sup(sym))
  }
  ft
}

# The header cells, as (row, column), one footnote symbol attaches to.
# Every mark goes on the first header row, which is the visible cell of
# any column merged down, except in the describe layout, where each
# group's name spans its pair in row 1 and row 2 names the count and
# the statistic: their marks go on row 2.
.footnote_cells <- function(ft, sym) {
  j <- which(ft$col_keys %in% .footnote_cols(ft, sym))
  i <- rep(1L, length(j))
  pairs <- attr(ft, "hv_pairs", exact = TRUE)
  i[ft$col_keys[j] %in% unlist(pairs)] <- 2L
  data.frame(i = i, j = j)
}
```

  and add, as the first lines of `.footnote_cols()`'s body:

```r
  # Each group in the describe layout has its own count, so every count
  # carries the count's mark and every statistic the dagger. The columns
  # are the groups the table was built with (hv_pairs), not a stat_<k>
  # pattern: the deprecated wrapper takes any column as a group.
  pairs <- attr(ft, "hv_pairs", exact = TRUE)
  if (!is.null(pairs)) {
    if (identical(sym, "*")) return(pairs$n)
    if (!identical(sym, "\u2020")) return(pairs$n[1])
    cols <- pairs$stat
    if (.compare_noted(ft))
      cols <- c(cols, intersect("hv_compare_col", ft$col_keys))
    return(cols)
  }
```

- [ ] **Step 4: Run the tests; they pass,** then the whole suite: report and compare output
  is unchanged (every `.footnote_cells()` row is 1 for them).

- [ ] **Step 5: Prove it by mutation.** (a) In `.footnote_cells()`, leave every row at 1: the
  rows 4-5 and display tests fail. (b) Return `n[1]` for `*`: rows 4-5 fail (one `n*`).
  (c) Drop the `.compare_noted()` line: rows 4-5 fail on `P†`. (d) Take the `*` targets
  from `grep("^n_stat_[0-9]+$", ft$col_keys, value = TRUE)` instead of `pairs$n`: the
  custom-column test fails. (e) Delete the `hv_pairs` line in `.man_table_describe()`: every
  describe mark test fails. Restore all.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-save.R tests/testthat/test-table-styles.R
git commit -m "feat(savers): describe's marks, an asterisk on each n and a dagger on each statistic"
```

### Task 4: The JTCVS functions warn, and every test call is muffled

The old bodies stay in this task, so it holds under either answer to decision 1. The warning
makes every unmuffled call a test warning, so `WARN 0` proves the wrapping complete.

**Files:**
- Modify: `R/hv-man-table-jtcvs.R`, `R/hv-man-table-save-jtcvs.R`,
  `R/hv-test-footnotes-jtcvs.R` (the warning, the roxygen lead paragraph, `@examples`);
  `.lintr`; `tests/testthat/helper-fixtures.R`
- Modify (wrap calls): `tests/testthat/test-hv-man-table-jtcvs.R`,
  `test-hv-man-table-save-jtcvs.R`, `test-hv-test-footnotes-jtcvs.R`, `test-word-output.R`,
  `test-hv-check-docx.R`, `test-contract-parity.R`, `test-hv-tbl-compare.R`,
  `test-hv-tbl-summary.R`, `test-hv-sas-glossary.R`
- Test: `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Produces: `.jtcvs_deprecated(old, instead)`, the message; `jtcvs_quiet(expr)` in
  `helper-fixtures.R`, muffling `deprecatedWarning` only. Task 5 uses both.

- [ ] **Step 1: Write the failing tests** (at the top of `test-hv-man-table-jtcvs.R`, after
  the `library()` lines):

```r
dep_tbl <- function() {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", overall = TRUE,
    compare = "pvalue", show_variable = FALSE
  )
  hv_tbl_compare(tbl, c(age = "0.1", grade = "0.2"), "Std. Diff.")
}

test_that("each JTCVS function warns, naming the call that replaces it", {
  skip_if_not_installed("broom")
  tbl <- dep_tbl()
  g <- c(stat_1 = "A", stat_2 = "B")
  new <- "hv_man_table(tbl, style = \"manuscript\", layout = \"describe\")"
  expect_warning(ft <- hv_man_table_jtcvs(tbl, g),
                 new, fixed = TRUE, class = "deprecatedWarning")
  expect_warning(hv_test_footnotes_jtcvs(tbl),
                 new, fixed = TRUE, class = "deprecatedWarning")
  expect_warning(
    hv_man_table_save_jtcvs(ft, tempfile(fileext = ".docx"),
                            caption = "Table 1. X"),
    new, fixed = TRUE, class = "deprecatedWarning"
  )
})

test_that("the wrappers keep the Overall, P and Std. Diff. columns", {
  # Design D3: groups and trailing choose the same columns as before.
  skip_if_not_installed("broom")
  tbl <- dep_tbl()
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_0 = "Overall", stat_1 = "A", stat_2 = "B"),
    trailing = attr(tbl, "hv_trailing")
  ))
  expect_true(all(c("disp_stat_0", "hv_compare_col", "hv_join_1") %in%
                    ft$col_keys))
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
  expect_gt(length(notes), 0L)
  expect_true(all(vapply(notes, `[[`, "", "col") == "hv_compare_col"))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "Table 1. X",
                                      footnotes = notes))
  x <- officer::read_docx(f)$doc_obj$get()
  head <- vapply(
    xml2::xml_find_all(x, "//w:tbl/w:tr[position() <= 2]/w:tc"),
    xml2::xml_text, character(1)
  )
  expect_true("Overall" %in% head)
  expect_true(any(startsWith(head, "P")))
  expect_true("Std. Diff." %in% head)
})
```

- [ ] **Step 2: Run them; they fail** (no warning; `jtcvs_quiet` not found).
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "hv-man-table-jtcvs")'`

- [ ] **Step 3: Implement the warning.** At the end of `R/hv-man-table-jtcvs.R`:

```r
# The deprecation every JTCVS function raises (design D3): it names the
# call that replaces it and says when the function goes.
.jtcvs_deprecated <- function(old, instead) {
  paste0(old, "() is deprecated and goes in the next release. ", instead)
}
```

  As the first statement of `hv_man_table_jtcvs()`'s body:

```r
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_man_table_jtcvs",
    paste0("Use hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\"), which draws the same columns.")
  ))
```

  of `hv_man_table_save_jtcvs()`'s:

```r
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_man_table_save_jtcvs",
    paste0("Use hv_man_table_save(ft, file, caption = ) on a table from ",
           "hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\").")
  ))
```

  and of `hv_test_footnotes_jtcvs()`'s:

```r
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_test_footnotes_jtcvs",
    paste0("A table from hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\") names its tests in its dagger note.")
  ))
```

  The warning comes first, so a call that then errors still warns: wrap error-path calls too.

- [ ] **Step 4: The roxygen.** Insert, as the first paragraph after each title line, the
  deprecation (for `hv_man_table_jtcvs()`; the other two name themselves and their
  replacement the same way):

```r
#' **Deprecated.** Use
#' `hv_man_table(tbl, style = "manuscript", layout = "describe")`, the
#' manuscript style's describe layout, which this layout became. This
#' function warns on every call and goes in the next release.
#'
```

  For `hv_man_table_save_jtcvs()`: "Use `hv_man_table_save(ft, file, caption = )` on a table
  from `hv_man_table(tbl, style = "manuscript", layout = "describe")`." For
  `hv_test_footnotes_jtcvs()`: "A table from `hv_man_table(tbl, style = "manuscript",
  layout = "describe")` names its tests in its dagger note and marks Fisher's exact test on
  its P values, so it needs no test footnotes." Prefix each title with `Deprecated: `.
  Replace each `@examples` block with the call that replaces it (decision 19); for
  `hv_man_table_jtcvs()` and `hv_man_table_save_jtcvs()`:

```r
#' @examples
#' # Instead of hv_man_table_jtcvs() and hv_man_table_save_jtcvs():
#' tbl <- hv_tbl_summary(
#'   gtsummary::trial, by = "trt",
#'   groups = list(Demography = c("age", "grade")),
#'   continuous = "age", categorical = "grade", compare = "none"
#' )
#' ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save(ft, out, caption = "Table 2. Baseline Characteristics")
```

  and for `hv_test_footnotes_jtcvs()` the same, built with `compare = "pvalue"`, ending
  `attr(ft, "hv_footnotes")[["†"]]` (the dagger note naming the tests). Then
  `Rscript -e 'devtools::document()'`.

- [ ] **Step 5: `jtcvs_quiet()` and the fixtures.** In `tests/testthat/helper-fixtures.R`,
  before `fx_jtcvs_ft()`:

```r
# The three JTCVS functions are deprecated (design D3) and warn on every
# call. A test of what such a call still does runs it through this,
# which muffles that warning and no other; test-hv-man-table-jtcvs.R
# asserts the warning itself. It goes with the functions.
jtcvs_quiet <- function(expr) {
  withCallingHandlers(expr, deprecatedWarning = function(w) {
    invokeRestart("muffleWarning")
  })
}
```

  and route `fx_jtcvs_ft()` and `save_fit()` through it:

```r
fx_jtcvs_ft <- function() {
  jtcvs_quiet(hv_man_table_jtcvs(
    fx_jtcvs_tbl(), groups = c(stat_1 = "A", stat_2 = "B")
  ))
}
```

```r
save_fit <- function(tbl, groups) {
  path <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(
    hv_man_table_jtcvs(tbl, groups = groups,
                       trailing = attr(tbl, "hv_trailing")),
    path, caption = "T1."
  ))
  fit_geometry(path)
}
```

- [ ] **Step 6: Wrap every other call.** List them:

  ```bash
  grep -n "hv_man_table_jtcvs(\|hv_man_table_save_jtcvs(\|hv_test_footnotes_jtcvs(" tests/testthat/*.R
  ```

  Wrap each call (not a comment, not a string inside `grepl()` or an error message, not a
  `.check_sas_args()` call naming the function) in `jtcvs_quiet()`. Where calls nest, wrap
  the outermost: its arguments are evaluated inside the handler. The two Step 1 tests call the
  functions bare on purpose. The pattern, inside `expect_error()` and `tryCatch()` alike:

```r
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B")
  ))
  expect_error(
    jtcvs_quiet(hv_man_table_jtcvs(tbl, c(stat_3 = "C"))),
    "must be columns"
  )
  m2 <- tryCatch(jtcvs_quiet(hv_man_table_jtcvs(jt, g, font_size = bad)),
                 error = conditionMessage)
```

  On `main` (62ab8fe) the sites outside the three JTCVS test files are:
  `test-word-output.R` 28 and 32 (inside `wx_save_jtcvs()`) and 356-360;
  `test-hv-check-docx.R` 15 and 19, 37 and 46, 239 and 248 (inside its three `mk_*_docx()`
  helpers), and 464; `test-contract-parity.R` 13, 26, 39, 49, 51, 61, 83 and 121;
  `test-hv-tbl-compare.R` 48, 55 and 74; `test-hv-tbl-summary.R` 362, 521, 1091, 1259, 1386,
  1414, 1428 and 1641; `test-hv-sas-glossary.R` 139 and 148. In
  `test-hv-man-table-save-jtcvs.R`, wrap the call inside `mk_jtcvs_ft()` as well as each
  call in a test.

- [ ] **Step 7: `.lintr`.** Two test files now call `jtcvs_quiet()` inside their own function
  definitions (`mk_*_docx()`, `mk_jtcvs_ft()`), which `object_usage_linter` cannot see:

```
linters: linters_with_defaults()
exclusions: list(
    "tests/testthat/test-hv-check-docx.R" = list(object_usage_linter = Inf),
    "tests/testthat/test-hv-man-table-save-jtcvs.R" = list(object_usage_linter = Inf),
    "tests/testthat/test-table-styles.R" = list(object_usage_linter = Inf),
    "tests/testthat/test-word-output.R" = list(object_usage_linter = Inf)
  )
```

- [ ] **Step 8: Run the whole suite.**
  Run: `NOT_CRAN=true Rscript -e 'devtools::test()'`
  Expected: `FAIL 0 | WARN 0 | SKIP 0`. Any warning names an unwrapped call; wrap it. Then
  lint against an installed copy (Global Constraints): 0 lints.

- [ ] **Step 9: Prove it by mutation.** (a) Delete the `.Deprecated()` call from
  `hv_test_footnotes_jtcvs()`: the warning test fails. (b) Remove `jtcvs_quiet()` from
  `fx_jtcvs_ft()`: the suite reports warnings. (c) In `hv_man_table_jtcvs()`, lay out only
  `names(groups)[-1]`: the column test fails. Restore all.

- [ ] **Step 10: Commit**

```bash
git add R/hv-man-table-jtcvs.R R/hv-man-table-save-jtcvs.R R/hv-test-footnotes-jtcvs.R man/hv_man_table_jtcvs.Rd man/hv_man_table_save_jtcvs.Rd man/hv_test_footnotes_jtcvs.Rd .lintr tests/testthat/helper-fixtures.R tests/testthat/test-hv-man-table-jtcvs.R tests/testthat/test-hv-man-table-save-jtcvs.R tests/testthat/test-hv-test-footnotes-jtcvs.R tests/testthat/test-word-output.R tests/testthat/test-hv-check-docx.R tests/testthat/test-contract-parity.R tests/testthat/test-hv-tbl-compare.R tests/testthat/test-hv-tbl-summary.R tests/testthat/test-hv-sas-glossary.R
git commit -m "feat: deprecate the JTCVS functions; tests run them through jtcvs_quiet()"
```

### Task 5: The wrappers draw the describe layout (decision 1, confirmed)

John confirmed decision 1 on 2026-10-19: during the deprecation release the wrappers draw the
describe layout.

**Files:**
- Modify: `R/hv-man-table-jtcvs.R` (`hv_man_table_jtcvs()`'s body and roxygen),
  `R/hv-man-table-save-jtcvs.R` (body, roxygen, `.drop_named_tests()`),
  `R/hv-test-footnotes-jtcvs.R` (roxygen), `R/hv-man-table-save.R` (`.write_man_docx()`),
  `R/hv-man-table-display.R` (the JTCVS refusal and its Common mistakes entry)
- Test: `tests/testthat/test-hv-man-table-jtcvs.R`, `test-hv-man-table-save-jtcvs.R`,
  `test-hv-test-footnotes-jtcvs.R`, `test-word-output.R`, `test-hv-man-table-display.R`

**Interfaces:**
- Consumes: `.man_table_describe()` (Task 2); `.jtcvs_deprecated()`, `jtcvs_quiet()` (Task 4);
  `.footnote_cells()` (Task 3); `.hv_test_labels`; `.assert_footnote_entries()`.
- Produces: `.write_man_docx(ft, file, footnotes, abbreviations, caption, style,
  lettered = list())`, which `hv_man_table_save()` now ends in; `.drop_named_tests(ft,
  footnotes)`.

Delegating fails exactly these 15 tests, each asserting the JTCVS look on purpose; Step 1
rewrites or retires each, and the PR lists them. In `test-hv-man-table-jtcvs.R`: "bolds and
merges section rows, without fill", "sets column widths to avoid wrapping", "applies the house
font", "the JTCVS minority mark reaches every display column", "the JTCVS table letters the
minority mark and its note". In `test-hv-man-table-save-jtcvs.R`: "attaches lettered
footnotes to cells". In `test-hv-test-footnotes-jtcvs.R`: "round-trips through a saved
.docx". In `test-hv-man-table-display.R`: "display refuses a JTCVS table, whose notes are
lettered". In `test-word-output.R`: "JTCVS: n carries a real superscript a, footnoted below",
"JTCVS: caller footnotes letter from b after the n footnote", "JTCVS: the statistic label
follows the table's statistic", "JTCVS: under continuous_stat = 'both', the stats sit side by
side", "JTCVS: no fill colour anywhere in the table", "both renderers mark the minority
statistic's cells in Word", "JTCVS: caption, footnotes and Key use the table's font".
One more passes only by accident:
"a narrow JTCVS table stays portrait at its own widths" asserts 5.5 in with
`tolerance = 2`, which `expect_equal()` reads as relative; describe's table is 5.4 in.

- [ ] **Step 1: Write the tests.**

  In `test-hv-man-table-jtcvs.R`, delete the five tests named above (their describe
  equivalents are Task 2's widths, grid and marks tests) and add:

```r
test_that("the wrapper passes groups, trailing and stat_label through", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$a <- "x"
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_2 = "Second", stat_1 = "First"),
    trailing = c(a = "Own"), stat_label = "Mean (SD)"
  ))
  expect_identical(attr(ft, "hv_layout"), "describe")
  expect_identical(ft$col_keys, c("label", "n_stat_2", "disp_stat_2",
                                  "n_stat_1", "disp_stat_1", "a"))
  head <- flextable::information_data_chunk(ft)
  head <- head[head$.part == "header", ]
  txt <- function(i, k) {
    paste(head$txt[head$.row_id == i & head$.col_id == k], collapse = "")
  }
  expect_identical(c(txt(1, "n_stat_2"), txt(1, "n_stat_1"), txt(1, "a"),
                     txt(2, "disp_stat_2")),
                   c("Second", "First", "Own", "Mean (SD)"))
})

test_that("the deprecated call marks the minority statistic with a pilcrow", {
  # One mean row against one median row: a tie, so the median stays the
  # default and the mean row carries the standard's mark.
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker")),
                        continuous = c("age", "marker"), mean_sd = "age",
                        compare = "none", show_variable = FALSE)
  ft <- jtcvs_quiet(
    hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
  )
  expect_identical(attr(ft, "hv_body_marks"),
                   c("\u00B6" = "Mean\u00B1SD."))
  ch <- flextable::information_data_chunk(ft)
  age <- which(ft$body$dataset$variable == "age")
  for (col in c("disp_stat_1", "disp_stat_2"))
    expect_true(any(ch$.part == "body" & ch$.row_id == age &
                      ch$.col_id == col & ch$txt == "\u00B6" &
                      ch$vertical.align == "superscript"), info = col)
  path <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, path, caption = "Table 1. Test"))
  text <- officer::docx_summary(officer::read_docx(path))$text
  expect_true("\u00B6Mean\u00B1SD." %in% text)
  expect_false(any(grepl("Age, Mean", text, fixed = TRUE)))
})

test_that("the wrapper's marks follow custom group columns", {
  tbl <- fx_jtcvs_tbl()
  tbl$table_body$custom_a <- tbl$table_body$stat_1
  tbl$table_body$custom_b <- tbl$table_body$stat_2
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(custom_a = "A", custom_b = "B")
  ))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "Table 1. X"))
  x <- officer::read_docx(f)$doc_obj$get()
  sub <- vapply(xml2::xml_find_all(x, "//w:tbl/w:tr[2]/w:tc"),
                xml2::xml_text, character(1))
  expect_identical(sum(sub == "n*"), 2L)
  expect_identical(sum(endsWith(sub, "\u2020")), 2L)
})

test_that("a test note the table does not name itself is kept, lettered", {
  # A plain gtsummary table carries no test sentence in its dagger note,
  # so the note hv_test_footnotes_jtcvs() wrote is the only place the
  # test is named.
  skip_if_not_installed("broom")
  tbl <- gtsummary::add_p(fx_jtcvs_tbl())
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$hv_compare_col <- ifelse(is.na(tb$p.value), NA_character_,
                                sprintf("%.2f", tb$p.value))
    tb
  })
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    tbl, groups = c(stat_1 = "A", stat_2 = "B"),
    trailing = c(hv_compare_col = "P")
  ))
  notes <- jtcvs_quiet(hv_test_footnotes_jtcvs(tbl))
  expect_identical(vapply(notes, `[[`, "", "text"),
                   c("Wilcoxon rank-sum test.", "Pearson chi-square test."))
  f <- tempfile(fileext = ".docx")
  jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "Table 1. X",
                                      footnotes = notes))
  text <- officer::docx_summary(officer::read_docx(f))$text
  expect_true("a. Wilcoxon rank-sum test." %in% text)
  expect_true("b. Pearson chi-square test." %in% text)
})
```

  In `test-hv-man-table-save-jtcvs.R`, replace "hv_man_table_save_jtcvs attaches lettered
  footnotes to cells" with:

```r
test_that("the deprecated saver keeps a caller's notes, lettered from a", {
  ft <- mk_jtcvs_ft()
  f <- tempfile(fileext = ".docx")
  on.exit(unlink(f), add = TRUE)
  jtcvs_quiet(hv_man_table_save_jtcvs(
    ft, f, caption = "Table 1. Baseline Characteristics",
    footnotes = list(
      list(row = 1, col = "n_stat_1", text = "First footnote."),
      list(row = 1, col = "n_stat_2", text = "Second footnote.")
    )
  ))
  x <- wx_doc(f)
  notes <- vapply(
    xml2::xml_find_all(x, "//w:tbl/following-sibling::w:p", wx_ns),
    wx_text, character(1)
  )
  # The table's own notes first, in the manuscript's symbols, then the
  # caller's, lettered from a now that no n carries an "a".
  expect_identical(notes, c("*Patients with non-missing data.",
                            "\u2020Values are No. (%) or mean\u00B1SD.",
                            "a. First footnote.", "b. Second footnote."))
  age <- wx_rows(x)[[3]] # two header rows, then age
  expect_identical(vapply(age, `[[`, "", "sup"), c("", "a", "", "b", ""))
})
```

  and in "a narrow JTCVS table stays portrait at its own widths" replace the last two lines
  with:

```r
  # 2.0 + 2 x (0.6 + 1.1) inches, the describe layout's, untouched.
  expect_equal(g$table, 5.4 * 1440, tolerance = 1e-3)
```

  In `test-hv-test-footnotes-jtcvs.R`, "round-trips through a saved .docx": replace its four
  `grepl()` expectations on `xml` with:

```r
  # The describe table names its own tests, so the saver drops these
  # entries rather than say each twice.
  notes <- vapply(
    xml2::xml_find_all(wx_doc(out), "//w:tbl/following-sibling::w:p",
                       wx_ns),
    wx_text, character(1)
  )
  expect_identical(notes, c(
    "*Patients with non-missing data.",
    paste0("\u2020Values are No. (%) or median [15th, 85th percentiles]; ",
           "P values from the Kruskal-Wallis test and Pearson's ",
           "chi-square test."),
    "\u2021Fisher exact test."
  ))
  expect_false(grepl("ANOVA", xml, fixed = TRUE))
```

  In `test-hv-man-table-display.R`, replace "display refuses a JTCVS table, whose notes are
  lettered" with:

```r
test_that("display shows the deprecated JTCVS call's describe table", {
  shown <- hv_man_table_display(fx_jtcvs_ft())
  expect_true(isTRUE(attr(shown, "hv_display")))
  foot <- flextable::information_data_chunk(shown)
  foot <- foot[foot$.part == "footer" & foot$.row_id == 1, ]
  expect_identical(paste(foot$txt, collapse = ""),
                   "*Patients with non-missing data.")
})
```

  In `test-word-output.R`, the JTCVS section moves to describe. Replace `wx_save_jtcvs()`
  with:

```r
wx_save_describe <- function(tbl = wx_tbl(), ...) {
  ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, caption = "Table 1. Test", ...)
  f
}
```

  replace everything from `# -- JTCVS renderer` to `# -- Mixed statistics` with:

```r
# -- The manuscript's describe layout (the JTCVS renderer's, renamed) ---

test_that("describe: Characteristic appears once, spanning both header rows", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  all_cells <- unlist(lapply(wx_rows(doc), cell_text))
  expect_identical(sum(all_cells == "Characteristic"), 1L)
  vmerge <- xml2::xml_find_all(
    doc, "//w:tbl//w:tr[position() <= 2]/w:tc[1]//w:vMerge", wx_ns
  )
  expect_length(vmerge, 2L)
})

test_that("describe: every n carries the count's mark, noted below", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  sub <- wx_rows(doc)[[2]]
  n_cells <- Filter(function(cell) cell$text == "n*", sub)
  # Overall and two groups, three n columns; the mark is a superscript.
  expect_length(n_cells, 3L)
  expect_true(all(vapply(n_cells, `[[`, "", "sup") == "*"))
  notes <- wx_paragraphs_after_table(doc)
  expect_identical(notes[1], "*Patients with non-missing data.")
})

test_that("describe: the statistic label follows the table's statistic", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  sub <- cell_text(wx_rows(wx_doc(f))[[2]])
  expect_true(
    "No. (%) or Median [15th, 85th percentiles]\u2020" %in% sub
  )
  expect_false(any(grepl("Mean", sub, fixed = TRUE)))

  f2 <- wx_save_describe(wx_tbl("mean"))
  on.exit(unlink(f2), add = TRUE)
  sub2 <- cell_text(wx_rows(wx_doc(f2))[[2]])
  expect_true("No. (%) or Mean\u00B1SD\u2020" %in% sub2)
})

test_that("describe: under continuous_stat = 'both', stats sit side by side", {
  f <- wx_save_describe(wx_tbl("both"))
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  labels <- vapply(rows, function(r) r[[1]]$text, "")
  age <- which(labels == "Age")
  # No sub-rows under the variable.
  expect_false(labels[age + 1] %in% c("Mean\u00B1SD",
                                      "Median [15th, 85th percentiles]"))
  sub <- cell_text(rows[[2]])
  expect_true("No. (%) or Mean\u00B1SD\u2020" %in% sub)
  expect_true("Median [15th, 85th percentiles]" %in% sub)
})

test_that("describe: only the section rows are shaded", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  for (r in wx_rows(wx_doc(f))) {
    fills <- vapply(r, `[[`, "", "fill")
    fills <- toupper(fills[!is.na(fills)])
    if (cell_text(r)[1] %in% c("Demography", "Disease")) {
      expect_identical(fills, "CAEDFB")
    } else {
      expect_true(all(fills %in% c("FFFFFF", "AUTO")))
    }
  }
})

test_that("describe: no % sign in any body cell, label column left", {
  f <- wx_save_describe()
  on.exit(unlink(f), add = TRUE)
  rows <- wx_rows(wx_doc(f))
  body <- unlist(lapply(rows[-(1:2)], cell_text))
  expect_true(any(grepl("^[0-9]+ \\([0-9.]+\\)$", body)))
  expect_false(any(grepl("%", body, fixed = TRUE)))
  jc <- vapply(rows, function(r) r[[1]]$jc, "")
  expect_true(all(jc %in% c("left", "start")))
})

```

  in "both renderers mark the minority statistic's cells in Word", replace the comment's
  second clause with "a pilcrow in both the report and the manuscript's describe layout." and
  everything from `f2 <- wx_save_jtcvs(wx_mixed())` to the test's end with:

```r
  f2 <- wx_save_describe(wx_mixed())
  on.exit(unlink(f2), add = TRUE)
  doc2 <- wx_doc(f2)
  rows2 <- wx_rows(doc2)
  labels2 <- vapply(rows2, function(r) r[[1]]$text, "")
  expect_true("Age" %in% labels2)
  expect_true("No. (%) or Median [15th, 85th percentiles]\u2020" %in%
                cell_text(rows2[[2]]))
  age2 <- cell_text(rows2[[which(labels2 == "Age")]])
  expect_true(all(grepl("\u00B6$", age2[c(3, 5, 7)])))
  expect_true("\u00B6Mean\u00B1SD." %in% wx_paragraphs_after_table(doc2))
})
```

  and replace "JTCVS: caption, footnotes and Key use the table's font" with:

```r
test_that("describe: caption, notes and Key set no font of their own", {
  # The manuscript style takes the document's font, below the table too.
  f <- wx_save_describe(abbreviations = c(SMD = "standardized difference"))
  on.exit(unlink(f), add = TRUE)
  doc <- wx_doc(f)
  runs <- xml2::xml_find_all(doc, "//w:tbl/following-sibling::w:p/w:r", wx_ns)
  expect_gt(length(runs), 3L)
  expect_length(
    xml2::xml_find_all(doc, "//w:body/w:p//w:rFonts[@w:ascii]", wx_ns), 0L
  )
})
```

  The caller-footnote test this section had moved to `test-hv-man-table-save-jtcvs.R` above.

- [ ] **Step 2: Run them; they fail** against Task 4's old bodies: the lettered notes read
  `a. Patients with data available.`, the round trip writes lettered test lines, describe has
  no `hv_layout` from the wrapper, the custom-columns test finds lettered `a`s rather than
  `n*`, the plain-table test reads `b.` and `c.` (the old saver keeps `a` for the `n`
  header), and so on. Mutation (e) below shows the plain-table test also catches the
  drop-everything rule the external review found.
  Run: `NOT_CRAN=true Rscript -e 'devtools::test()'`

- [ ] **Step 3: `hv_man_table_jtcvs()` delegates.** Replace everything in its body from the
  comment `# Runs before .reshape_jtcvs_body(), so a table lacking the` to the function's
  closing brace with:

```r
  # Runs before .reshape_jtcvs_body(), so a table lacking the
  # convention errors rather than rendering every cell blank.
  .assert_stat_convention(tbl$table_body, groups)
  # Design D3: the same columns, `groups` and `trailing` as given, drawn
  # in the manuscript style's describe layout. `font` and `font_size`
  # are checked as before and set nothing: the manuscript style takes
  # the font of the document it is saved into.
  .man_table_describe(tbl, hv_table_style("manuscript"), groups, trailing,
                      stat_label)
}
```

  `grep -rn "hv_header_footnotes" R/` must then print only roxygen lines, which Step 7 fixes.

- [ ] **Step 4: The saver maps onto the manuscript saver (decision 13).** In
  `R/hv-man-table-save.R`, replace `hv_man_table_save()`'s body from
  `if (use_default_footnotes) footnotes <- .default_footnotes(ft)` to its end, and add the
  document writer it now ends in:

```r
  if (use_default_footnotes) footnotes <- .default_footnotes(ft)
  # Hoisted out of .add_abbreviations_key() so it fires at entry
  # rather than mid-render: no partial .docx on a bad argument.
  .check_abbreviations(abbreviations)
  .write_man_docx(ft, file, footnotes, abbreviations, caption, style)
}

# The document from a checked table: the caption, the table, its notes,
# the key and the page. `lettered` holds the deprecated JTCVS saver's
# positional notes, as runs, written after the table's own.
.write_man_docx <- function(ft, file, footnotes, abbreviations, caption,
                            style, lettered = list()) {
  abbreviations <- .with_table_abbreviations(ft, abbreviations)
  footnotes <- .resolve_footnotes(ft, footnotes)
  ft <- .mark_header(ft, footnotes)

  fit <- .fit_page(ft, landscape = .is_wide(ft))
  ft <- fit$ft

  doc <- officer::read_docx()
  font <- .table_font(ft)
  if (!is.null(caption))
    doc <- officer::body_add_fpar(doc, officer::fpar(officer::ftext(
      caption, prop = .note_prop(font, bold = TRUE)
    )), style = "Normal")
  doc <- flextable::body_add_flextable(doc, ft)

  leading <- identical(style$marker, "leading")
  for (sym in names(footnotes)) {
    doc <- officer::body_add_fpar(
      doc, .runs_fpar(.note_runs(sym, footnotes[[sym]], leading), font),
      style = "Normal"
    )
  }
  for (runs in lettered)
    doc <- officer::body_add_fpar(doc, .runs_fpar(runs, font),
                                  style = "Normal")

  doc <- .add_abbreviations_key(doc, abbreviations, font)
  doc <- .page_section(doc, fit$landscape)

  print(doc, target = file)
  invisible(file)
}
```

  In `R/hv-man-table-save-jtcvs.R`, replace `hv_man_table_save_jtcvs()` (its roxygen stays
  above it) with:

```r
hv_man_table_save_jtcvs <- function(ft, file, caption, footnotes = NULL,
                                    abbreviations = NULL, ...) {
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_man_table_save_jtcvs",
    paste0("Use hv_man_table_save(ft, file, caption = ) on a table from ",
           "hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\").")
  ))
  .check_sas_args(list(...), "hv_man_table_save_jtcvs")
  .check_flextable(ft)
  .check_not_display(ft)
  .check_file(file)
  ft <- .drop_variable_column(ft)
  .check_string(caption, "caption")
  .check_abbreviations(abbreviations)
  if (!is.null(footnotes) && length(footnotes) > length(letters))
    stop("Too many footnotes (max ", length(letters), " letters).",
         call. = FALSE)
  .assert_footnote_entries(footnotes, ft)

  # The caller's own notes keep their letters on their cells for this
  # release. A test note hv_test_footnotes_jtcvs() wrote is dropped only
  # where the table already names that test; otherwise it is lettered
  # like the caller's own.
  footnotes <- .drop_named_tests(ft, footnotes)
  lettered <- list()
  for (k in seq_along(footnotes)) {
    fn <- footnotes[[k]]
    ft <- flextable::append_chunks(ft, i = fn$row, j = fn$col, part = "body",
                                   flextable::as_sup(letters[k]))
    lettered[[k]] <- data.frame(
      text = c(letters[k], paste0(". ", fn$text)), sup = c(TRUE, FALSE),
      italic = FALSE, stringsAsFactors = FALSE
    )
  }
  .write_man_docx(ft, file, .default_footnotes(ft), abbreviations, caption,
                  .table_style(ft), lettered)
}

# The entries hv_test_footnotes_jtcvs() writes: a test named on the
# comparison column. A describe table from hv_tbl_summary() names those
# tests itself, the others in its dagger note (its hv_test_note) and
# Fisher's under its double dagger, so such an entry would say it twice.
# A test the table does not name, as on a plain gtsummary table, keeps
# its entry, which the saver letters.
.drop_named_tests <- function(ft, footnotes) {
  if (!identical(attr(ft, "hv_layout", exact = TRUE), "describe"))
    return(footnotes)
  fisher <- .hv_test_labels[["fisher.test"]]
  named <- c(
    if (!is.null(attr(ft, "hv_test_note", exact = TRUE)))
      setdiff(.hv_test_labels, fisher),
    if ("\u2021" %in% names(attr(ft, "hv_body_marks", exact = TRUE)))
      fisher
  )
  Filter(function(fn) {
    !(identical(fn$col, "hv_compare_col") && fn$text %in% named)
  }, footnotes)
}
```

- [ ] **Step 5: The display shows a describe table (decision 15).** In
  `R/hv-man-table-display.R`, delete the block that begins
  `# A JTCVS table letters its notes and has no stat_ columns for the` and ends with its
  `stop(...)`, and the Common mistakes entry beginning `**"`ft` is a JTCVS table ..."**`.

- [ ] **Step 6: Run the tests; they pass,** then the whole suite: `FAIL 0 | WARN 0 | SKIP 0`.
  `test-hv-check-docx.R`'s JTCVS-built documents now carry describe tables and still check
  clean.

- [ ] **Step 7: The roxygen says what a deprecated call now draws.** In
  `hv_man_table_jtcvs()`, replace the paragraphs from "Use this instead of
  [hv_man_table()] ..." through "... letter from `c` rather than `b`." with:

```r
#' Until it goes, it passes its arguments through to that layout: `groups`
#' and `trailing` choose the same group, Overall and comparison columns,
#' and `stat_label` names the statistic under each group. The table is
#' drawn in the manuscript style, not the JTCVS look it drew before: a
#' full grid, shaded section rows spanning the table, `*` and `†` notes,
#' and no font of its own. `font` and `font_size` are checked and set
#' nothing.
```

  and its `@return` with "A `flextable` in the manuscript style's describe layout, ready for
  [hv_man_table_save()]." In `hv_man_table_save_jtcvs()`, replace the paragraph "JTCVS
  counterpart to [hv_man_table_save()] ... written first, as `a`." with:

```r
#' Until it goes, it writes the table as [hv_man_table_save()] does, with
#' `caption` above it and the table's own notes below. A test footnote
#' from [hv_test_footnotes_jtcvs()] is dropped when the table already
#' names that test, as a table from [hv_tbl_summary()] does in its dagger
#' note; every other `footnotes` entry, a plain gtsummary table's test
#' notes included, keeps a lettered superscript on its cells, lettered
#' from `a`, and its line after the table's own notes.
```

  and, in `@param footnotes`, "A table from [hv_man_table_jtcvs()] already uses `a` for its
  `n` header ("Patients with data available."), written first, so these start at `b`; other
  flextables start at `a`." with "They are lettered from `a`." In `hv_test_footnotes_jtcvs()`,
  after "...so you do not have to map test identifiers or count body rows by hand.", add
  "[hv_man_table_save_jtcvs()] drops them from a describe table, which names its tests
  itself." Then `Rscript -e 'devtools::document()'`.

- [ ] **Step 8: Prove it by mutation.** (a) Pass `trailing = NULL` in the delegation: the
  Task 4 column test fails. (b) Make `.drop_named_tests()` return `footnotes`: the round trip
  fails on lettered test lines. (c) Leave `lettered` empty: the caller-notes test fails.
  (d) Pass `stat_label = NULL` in the delegation: the pass-through test fails. (e) Set
  `named <- .hv_test_labels` before the `Filter()` (drop every recognized test note): the
  plain-table test fails. (f) Set `named <- character(0)` (drop none): the round trip fails.
  (g) Take the `*` targets from the `^n_stat_` pattern: the custom-columns wrapper test fails.
  Restore all.

- [ ] **Step 9: Commit**

```bash
git add R/hv-man-table-jtcvs.R R/hv-man-table-save-jtcvs.R R/hv-test-footnotes-jtcvs.R R/hv-man-table-save.R R/hv-man-table-display.R man/hv_man_table_jtcvs.Rd man/hv_man_table_save_jtcvs.Rd man/hv_test_footnotes_jtcvs.Rd man/hv_man_table_display.Rd tests/testthat/test-hv-man-table-jtcvs.R tests/testthat/test-hv-man-table-save-jtcvs.R tests/testthat/test-hv-test-footnotes-jtcvs.R tests/testthat/test-word-output.R tests/testthat/test-hv-man-table-display.R
git commit -m "feat: the deprecated JTCVS functions draw the describe layout, their columns unchanged"
```

### Task 6: Documentation, news, gates, the dependent

**Files:**
- Modify: roxygen in `R/hv-man-table.R`, `R/hv-man-table-save.R`, `R/hv-tbl-summary.R`,
  `R/hv-tbl-compare.R`, `R/hv-check-docx.R`, `R/hvtiRtables-package.R`; `README.md`;
  `vignettes/hvtiRtables.qmd`; `vignettes/sas-migration.qmd`; `DESCRIPTION`'s `Description`;
  `_pkgdown.yml`
- Create: `news/feat-style-manuscript-describe.md`

- [ ] **Step 1: Roxygen.**
  - `hv_man_table()`: replace the paragraph "Submitting to JTCVS instead? Use
    [hv_man_table_jtcvs()] ... from the same header row." with:

```r
#' A manuscript table that describes cohorts or repeated measures side by
#' side, rather than comparing groups, takes `layout = "describe"`: each
#' group spans its own count and statistic, so every group has its count.
#' Everything else is the comparison layout's. The JTCVS functions, whose
#' layout this is, are deprecated.
```

    In the next paragraph replace "works here as well as in the JTCVS renderer" with "works
    in every style and layout", and "Those are the same two values JTCVS mode puts under a
    merged spanning header, without the merge." with "Those are the same two values the
    describe layout puts under each group's spanning header, without the merge." Add to
    Common mistakes:

```r
#' **"`layout` chooses between the manuscript style's layouts."** You
#' named a layout with the report style, which has one. Drop `layout`, or
#' add `style = "manuscript"`.
#'
```

    Replace the `@seealso`'s "[hv_man_table_jtcvs()] for the JTCVS submission format instead."
    with "[hv_table_style()] for each style's properties." Add to `@examples`:
    `ft <- hv_man_table(hv_tbl_summary(trial, by = "trt", groups = list(A = c("age",
    "grade")), continuous = "age", categorical = "grade"), style = "manuscript", layout =
    "describe")`, wrapped to 80 columns.
  - `hv_man_table_save()`, `@param footnotes`: after "In a manuscript table the dagger goes on
    the grouping's spanning cell and `*` on its `n` column." add "In the describe layout `*`
    goes on every group's `n` and the dagger on every statistic."
  - `hv_tbl_summary()`: "ready for [hv_man_table()] or [hv_man_table_jtcvs()]." becomes "ready
    for [hv_man_table()]." in the description and in `@return` ("A `gtsummary` object,
    ready for [hv_man_table()] or [hv_man_table_jtcvs()].", which wraps across two lines);
    `@seealso`'s "[hv_man_table()] or [hv_man_table_jtcvs()] to render the result" becomes
    "[hv_man_table()] to render the result"; "ready to pass as [hv_man_table_jtcvs()]'s `trailing` argument
    when `compare` produced a comparison column" becomes "naming the comparison columns the
    manuscript style shows, when `compare` produced one"; delete the Common mistakes entry
    "The Overall column is missing from the JTCVS table." and, in `@param overall`, the
    sentence beginning "[hv_man_table_jtcvs()] lays out only"; in `@param show_variable`,
    "while [hv_man_table_save()] and [hv_man_table_save_jtcvs()] always drop it and
    [hv_man_table_jtcvs()] never shows it, so a saved or JTCVS table is a manuscript table
    whatever this says" becomes "while [hv_man_table_save()] always drops it and the
    manuscript style never shows it, so a saved table is a manuscript table whatever this
    says"; "footnoted "Fisher exact test."; the JTCVS route letters it through
    [hv_test_footnotes_jtcvs()]." becomes "footnoted "Fisher exact test.", in every style."
  - `hv_tbl_compare()`: "[hv_man_table_jtcvs()] shows it when you pass the table's
    `hv_trailing` attribute as `trailing`, which this function extends." becomes "The
    manuscript style shows it too, from the table's `hv_trailing` attribute, which this
    function extends."; delete the Common mistakes entry "The new column is missing from the
    JTCVS table."
  - `hv_check_docx()`: the example builds the table with `hv_tbl_summary()` and saves
    `hv_man_table(tbl, style = "manuscript", layout = "describe")` with
    `hv_man_table_save(ft, out, caption = "Table 1. X")`; "[hv_man_table_save()] or
    [hv_man_table_save_jtcvs()]" becomes "[hv_man_table_save()]" in Common mistakes and
    `@seealso`.
  - `R/hvtiRtables-package.R`: replace the description and the "Which mode do I want?"
    section with:

```r
#' Turns `gtsummary` table objects into MS Word tables that comply with
#' HVTI CORR's "Table Construction for Manuscripts" rules. A table is
#' drawn in a style named by its role, and a manuscript table in the
#' layout its content needs.
#'
#' @section Which style do I want?:
#' **The report style** has a flat, non-merged header, a count beside
#' each group, and footnotes as text below the table. Use it for analysis
#' reports.
#'
#' ```
#' tbl <- gtsummary::tbl_summary(dta, by = "trt")
#' ft  <- hv_man_table(tbl)
#' hv_man_table_save(ft, "table1.docx")
#' ```
#'
#' **The manuscript style** is the table a journal receives: a full
#' grid, a two-row header, shaded section rows, and the document's own
#' font. Its `"compare"` layout gives groups it compares one overall `n`
#' column; its `"describe"` layout gives cohorts it describes side by
#' side a count each. The JTCVS functions are deprecated: their layout is
#' `"describe"`.
#'
#' ```
#' tbl <- hv_tbl_summary(
#'   dta, by = "trt",
#'   groups = list(Demography = c("age", "sex")),
#'   continuous = "age", categorical = "sex"
#' )
#' ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
#' hv_man_table_save(ft, "table2.docx", caption = "Table 2. Cohorts")
#' ```
```

  Then `Rscript -e 'devtools::document()'`.

- [ ] **Step 2: `DESCRIPTION`.** Replace "A JTCVS submission mode is also available, with merged
  spanning headers and lettered cell-targeted footnotes matching that journal's own template."
  with "The manuscript style lays a table out to compare groups or to describe cohorts side by
  side."

- [ ] **Step 3: `_pkgdown.yml`.** Remove `hv_man_table_jtcvs`, `hv_man_table_save_jtcvs` and
  `hv_test_footnotes_jtcvs` from sections 2 and 3, and add, before the "Package overview"
  section:

```yaml
- title: "Deprecated"
  desc: >
    The JTCVS functions, whose layout is now the manuscript style's
    describe layout. They warn on every call and go in the next release.
  contents:
  - hv_man_table_jtcvs
  - hv_man_table_save_jtcvs
  - hv_test_footnotes_jtcvs
```

- [ ] **Step 4: README.** Replace the paragraph beginning "Two house styles exist because two
  audiences" with: "Tables are drawn in a style named by its role. A report table
  (`hv_man_table()`) is the working table of an analysis report. A manuscript table
  (`hv_man_table(style = "manuscript")`) is what a journal receives, laid out by what it does:
  `"compare"` for groups it compares, `"describe"` for cohorts or repeated measures it
  describes side by side." Replace the "## JTCVS submission format" section with:

````markdown
## Describing cohorts side by side

A table that describes separate cohorts, or the same patients at several
times, gives each group its own count. Name the layout:

``` r
ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
hv_man_table_save(ft, "table2.docx", caption = "Table 2. Cohorts")
```

`hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()` and
`hv_test_footnotes_jtcvs()` are deprecated and go in the next release;
their layout is this one.
````

  and, in the migration table, `` `hv_man_table()` / `hv_man_table_jtcvs()` `` with
  `` `hv_man_table()` ``.

- [ ] **Step 5: Vignettes.** In `vignettes/hvtiRtables.qmd`: the opening paragraph becomes
  "This walks one complete manuscript table, from a data frame to a checked `.docx`, and then
  lays the same table out to describe its groups side by side. The report path is shorter and
  covered in `?hv_man_table`." Section 1's last paragraph becomes "The result records what the
  manuscript style reads: the statistic it shows and the comparison column." Replace sections
  2 to 4 with:

````markdown
## 2. Shape the manuscript table

```{r}
ft <- hv_man_table(tbl, style = "manuscript")
```

The `"compare"` layout, the default, for groups the table compares: one
overall `n` column, the grouping spanning its levels, and the P column.

## 3. Or describe the groups side by side

```{r}
ft2 <- hv_man_table(tbl, style = "manuscript", layout = "describe")
```

The `"describe"` layout gives each group its own count, for separate
cohorts or repeated measures. The P column stays, because the table
carries it. Either layout names the tests behind the p-values in its
dagger note, so there is no separate step for test footnotes.

## 4. Save and check

```{r}
out <- tempfile(fileext = ".docx")
hv_man_table_save(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  abbreviations = c(SMD = "standardized mean difference")
)
```

Neither saver checks its own output, so run `hv_check_docx()` on the
path, as the style that wrote it. Zero rows means clean.

```{r}
hv_check_docx(out, style = "manuscript")
```
````

  and replace the first "What the package refuses" chunk with:

````markdown
```{r, error = TRUE}
hv_man_table(
  gtsummary::tbl_summary(gtsummary::trial, by = "trt", include = "age"),
  style = "manuscript"
)
```
````

  In `vignettes/sas-migration.qmd`: in the stage table, "Shape the table" lists
  `` `hv_man_table()` `` alone and its note reads "`STYLE=` is `style =` in `hv_man_table()`,
  and a manuscript table's `layout =` chooses compare or describe; `PAGE=` has none (pages are
  US Letter)"; "Write the file" lists `` `hv_man_table_save()` `` alone. The sentence
  "`hv_man_table_jtcvs()` lays out only the `stat_<k>` columns its `groups` vector names, so
  name `stat_0` there to show the Overall column." becomes "Both manuscript layouts show the
  Overall column when the table carries it." In the `PRINTFN=` row, delete from "**CORR
  only.**" through "or use `hv_test_footnotes_jtcvs()`. ". "and `hv_man_table_jtcvs()` reads
  it when `stat_label` is left at its default, so the sub-header names the statistic the cells
  hold" becomes "and the describe layout's second header row reads it, so the sub-header names
  the statistic the cells hold".

  Then confirm no page steers to a deprecated function:

  ```bash
  grep -n "_jtcvs" README.md vignettes/*.qmd R/*.R | grep -v "^R/hv-man-table-jtcvs.R\|^R/hv-man-table-save-jtcvs.R\|^R/hv-test-footnotes-jtcvs.R\|^R/hv-sas-glossary.R\|^R/hv-validate.R"
  ```

  Expected, and nothing else: `.reshape_jtcvs_body()` calls (an internal name, kept);
  comments naming the deprecated functions (`R/hv-man-table-describe.R`,
  `R/hv-tbl-summary.R` near lines 564 and 610); and the two Common mistakes entries about
  passing one saver's `footnotes` to the other (`R/hv-man-table-save.R` near line 47,
  `R/hv-man-footnotes.R` near line 33), which stay true until the functions go. The SAS
  glossary and `R/hv-validate.R` keep their JTCVS routes for the same release (decision 16).

- [ ] **Step 6: News fragment** `news/feat-style-manuscript-describe.md`:

```markdown
* The manuscript style gains its second layout, `"describe"`, for tables that describe
  cohorts or repeated measures side by side (dev/specs/2026-10-17-table-styles-design.md,
  section 5.1): `hv_man_table(tbl, style = "manuscript", layout = "describe")`. Each group
  spans its own count and statistic, so every group has its count, and an Overall column and
  comparison columns appear when the table carries them. Everything else is the comparison
  layout's: the full grid, shaded section rows spanning the table, the `*` and `†` notes
  (`*` on each group's `n`, `†` on each statistic), no font of its own, and US Letter pages.
  `layout = "compare"` is the default.
  - `hv_man_table()`'s `layout` argument follows `style`, so a call passing every argument
    by position reaches `...` at the seventh, not the sixth.
* **Deprecated:** `hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()` and
  `hv_test_footnotes_jtcvs()` warn on every call and go in the next release. Until then their
  arguments keep their meaning: `groups` and `trailing` choose the same columns.
  - **Their output changes:** the table is drawn in the describe layout, with the
    manuscript's grid, shading and notes (`*Patients with non-missing data.` for
    `a. Patients with data available.`) and the document's font. The saver drops a test
    footnote `hv_test_footnotes_jtcvs()` wrote when the table already names that test, as an
    `hv_tbl_summary()` table does in its dagger note and with Fisher's mark on its P values;
    any other positional note, a plain gtsummary table's test notes included, keeps its
    letter, from `a`.
  - `hv_man_table_display()` shows such a table; it refused one before.
```

  If John chose the old output (decision 1), replace the "Their output changes" bullet with
  "Their output is unchanged." and drop the display bullet.

- [ ] **Step 7: Gates.**

```bash
NOT_CRAN=true Rscript -e 'devtools::test()'
R CMD INSTALL -l <scratch lib> . && R_LIBS=<scratch lib> Rscript -e 'lintr::lint_package()'
Rscript -e 'devtools::check()'
```

  Expected: `FAIL 0 | WARN 0 | SKIP 0`; 0 lints; 0/0/0 with the manual and vignettes, from a
  clean `git archive` build. Check that no `R/` string literal is non-ASCII:
  `Rscript -e 'print(tools:::.check_package_ASCII_code("."))'` prints
  `character(0)`, as it does on `main` (probed: a raw `±` in a string under `R/` makes it
  name the file).

- [ ] **Step 8: The dependent.** As in Global Constraints. `dc-tables` calls the report path
  only, so it should pass unchanged; the probe build gave 38 tests, 0 failures, 0 skips.
  Report the count and SKIP in the PR.

- [ ] **Step 9: Commit, run `/code-review` locally, open the PR**

```bash
git add R/hv-man-table.R R/hv-man-table-save.R R/hv-tbl-summary.R R/hv-tbl-compare.R R/hv-check-docx.R R/hvtiRtables-package.R man/hv_man_table.Rd man/hv_man_table_save.Rd man/hv_tbl_summary.Rd man/hv_tbl_compare.Rd man/hv_check_docx.Rd man/hvtiRtables-package.Rd README.md vignettes/hvtiRtables.qmd vignettes/sas-migration.qmd DESCRIPTION _pkgdown.yml news/feat-style-manuscript-describe.md
git commit -m "docs: the describe layout in every page; the JTCVS functions marked deprecated; news"
```

  The PR body lists the decisions above for John, the 15 tests Task 5 rewrote or retired and
  why, the 5.5 in tolerance fix, the two SAS-position numbers, the dependent's count, and
  says whether the local review stood in for Copilot.

---

## Suggested allocation for subagent-driven execution

| task | implementer | why |
|---|---|---|
| 0 | haiku, low | four text edits |
| 1 | sonnet, medium | a refactor with complete code; proof is that nothing moves |
| 2, 3 | sonnet, medium | complete code and tests, verified on a scratch build |
| 4 | sonnet, medium | about 70 mechanical wraps; `WARN 0` is the check |
| 5 | sonnet, high | multi-file, 15 rewritten tests, a saver refactor; gated on decision 1 |
| 6 | sonnet, medium | docs and gates |

Task reviewers on haiku at low effort, escalating to sonnet on a flag; the whole-branch review
on the most capable model.

## Self-review

- **Spec coverage.** Design 5.1, the describe layout: counts per group, each group spanning
  its pair, row 2 naming them, Overall and comparison columns when carried (Task 2); its
  shared borders, markers, wording, font, page, shading and digits (Tasks 1, 2, 3); repeated
  measures and the ungrouped table (Task 2's ungrouped test; repeated measures are the same
  shape as cohorts); the layout chosen by the table (decision 2, Task 2). 5.2: describe's
  notation is `hv_tbl_summary()`'s, unchanged. Section 6: `hv_check_docx()` passes on describe
  (Task 3). D2: the saver and the display follow the layout (Task 3). D3: the three functions
  deprecated with the message naming the new call (Task 4), passing their arguments through
  (Tasks 4 and 5), the three-column test (Task 4), their tests moved (Task 5), the
  other-package check (above). Questions 9 and 10: grid and `*`, `†` in describe (Tasks 2,
  3). Section 9: the matrix rows for describe as a saved-docx fixture and a two-cohort replica
  (Task 3).
- **Not covered, by design:** D6 (Phase 4); D7 (Phase 5); the removal of the deprecated
  functions (the release after). **In no phase:** label superscripts (section 7).
- **Placeholders.** None: every code step carries its code, and the mechanical wraps of Task 4
  carry the pattern, the site list on `main` and `WARN 0` as their completeness check.
- **Names used across tasks:** `.check_manuscript_tbl()`, `.group_labels()`,
  `.dress_manuscript()`, `.mark_compare(stat_label =)`, `hv_layout` (Task 1);
  `.check_layout()`, `.man_table_describe(tbl, style, groups, trailing, stat_label)`,
  `hv_pairs` (Task 2);
  `.footnote_cells()` (Task 3); `.jtcvs_deprecated()`, `jtcvs_quiet()` (Task 4);
  `.write_man_docx()`, `.drop_named_tests()` (Task 5), spelled the same in every task.
