# Table styles: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the table styles and the house standard decided in
`dev/specs/2026-10-17-table-styles-design.md` (#81), so nobody hand-edits a manuscript table.

**Architecture:** Five phases, each shipping working, tested code on its own, in dependency
order. Phase 1, the notation standard inside `hv_tbl_summary()`, is planned here in full; it
changes what every table says and is the base the styles build on. Phases 2 to 5 get their own
detailed plans when Phase 1 has merged, written against the code as it then stands.

**Tech Stack:** R (>= 4.4), gtsummary 2.5.1, flextable, officer, testthat 3, roxygen2.

## Global Constraints

- Patch-digit bumps only; no `Version:` change in a feature PR. Each PR adds a `news/<branch>.md`
  fragment (AGENTS.md).
- `devtools::test()`, `lintr::lint_package()` and `devtools::check()` with the PDF manual at
  0 errors, 0 warnings, 0 notes before a PR opens.
- Every new branch of code is proved red first, and by mutation.
- Run hvtiRtemplates' `dc-tables` tests against the branch in a scratch library before merging
  (`R CMD INSTALL -l <lib> .`, then `R_LIBS=<lib> Rscript -e 'devtools::test(filter = "dc-tables")'`
  in hvtiRtemplates).
- Synthetic data only. No manuscript content in the repository.
- US spelling.

## The standard as Phase 1 builds it

Settled with John on 2026-10-17, after the design merged. Phase 1 also corrects section 5.2 of
the design to match (Task 0).

| element | standard |
|---|---|
| Counts | `30 (42)`: unchanged from today |
| Mean and SD | `63±13`, **unspaced**, EHB paired rounding: unchanged from today. Journals count `63 ± 13` as three words toward table word limits |
| Median | `9.9 [8.5, 11]`: square brackets, a space before them |
| Median digits | each number to **2 significant digits**, and a value of 10 or more to the units place, never coarser (`102 [63, 170]`, not `100 [60, 170]`) |
| P values | today's `gtsummary::style_pvalue(digits = 1)` with the leading zero dropped: `<.001`, `.009`, `.013`, `.12`, `.3`, `>.9` |
| Mixed statistics | the statistic fewer continuous rows use is marked on its cells: `§` on median cells, `¶` on mean ± SD cells, each with its note. The † note names the other, the default |

**Why the median rule changed.** The design proposed rounding a median and its percentiles one
place finer than the first significant digit of their spread. Checked on ranges from the
evidence documents, the spread rule coarsens skewed variables, because the long tail sets the
spread:

| printed in the document | spread rule | spread rule + EHB leading-1 shift | **2 significant digits, whole ≥ 10** |
|---|---|---|---|
| `9.9 [8.5, 11]` | `9.9 [8.5, 11.0]` | `9.9 [8.5, 11.0]` | `9.9 [8.5, 11]` |
| `0.31 [0.21, 0.39]` | `0.31 [0.21, 0.39]` | `0.310 [0.210, 0.390]` | `0.31 [0.21, 0.39]` |
| `102 [63, 170]` | `100 [60, 170]` | `102 [63, 170]` | `102 [63, 170]` |
| `0.84 (0.15, 2.07)` | `0.8 [0.2, 2.1]` | `0.84 [0.15, 2.07]` | `0.84 [0.15, 2.1]` |
| `9.7 (5.5, 27)` | `10 [6, 27]` | `10 [6, 27]` | `9.7 [5.5, 27]` |
| `7 [5, 15]` | `7 [5, 15]` | `7.0 [5.0, 15.0]` | `7.0 [5.0, 15]` |

The last column reproduces ms.1264, BVR rv3 and the CAA proof; only ms.0939, which used 3
digits, differs.

## Roadmap

| phase | what ships | depends on |
|---|---|---|
| **1. Notation standard** (this plan) | brackets and 2-significant-digit medians, P without a leading zero, minority marks `§`/`¶` replacing row-label suffixes, in every table `hv_tbl_summary()` makes. Changes every report's output | nothing |
| 2. Style object and `"manuscript"`/`"compare"` | `hv_table_style()`; `hv_man_table(style =)`; `"report"` and `"manuscript"` with `"compare"`: full grid, two-row spanned header, the overall `n*` column (from `hv_tbl_summary()`, design section 7), shaded section heading rows in every style (fill a property, default `#CAEDFB`), caption, US Letter pages, the document's body font, note wording per style | Phase 1 |
| 3. `"describe"` and the JTCVS rename | the `"describe"` layout (a count beside each group; Overall and comparison columns when the table carries them); `hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()`, `hv_test_footnotes_jtcvs()` deprecated as wrappers that keep existing calls working (design D3) | Phase 2 |
| 4. The "Table styles" article | a pkgdown article rendering one synthetic table in each style and layout beside the matrix, generated from `hv_table_style()`; the house-rules section (design section 6) | Phases 2 and 3 |
| 5. hvtiRtemplates | `dc-tables`: the report in `"report"` with variable names on screen; the Word export in `"manuscript"` with a `MANUSCRIPT_STYLE` layout choice and the fill color as study choices; `SHOW_VARIABLE` becomes report-only (#82 already drops the column from every `.docx`) | an hvtiRtables release with Phases 1 to 3 |

---

## Phase 1: the notation standard

### File structure

| file | change |
|---|---|
| `R/hv-tbl-summary.R` | median template in brackets; `.format_sig2()`; `.format_standard_median()`; `.format_p()`; minority marks replacing the `relabel()` suffixes |
| `R/hv-man-footnotes.R` | `.stat_label()` writes brackets and "percentiles" |
| `R/hv-man-table.R` | `.mark_cells()` puts the minority mark on cells; `hv_body_marks` merges with Fisher's |
| `tests/testthat/test-hv-tbl-summary.R` | new tests per task |
| `tests/testthat/test-hv-man-table.R` | the cell-mark test |
| existing tests asserting the old notation | updated in Task 5 |
| `news/feat-notation-standard.md` | the fragment |
| `dev/specs/2026-10-17-table-styles-design.md` | section 5.2 corrected (Task 0) |

### Task 0: Correct section 5.2 of the design

Done in the PR that adds this plan, so the design and the plan agree.

**Files:** Modify `dev/specs/2026-10-17-table-styles-design.md` (section 5.2 and questions 11,
13 and 14).

- [x] **Step 1:** Replace the median-digits row with the 2-significant-digit rule and the check
  table above; the mean and SD row with the unspaced `63±13` and its word-limit reason; the P
  row's example `>.99` with `>.9` and the rule `style_pvalue(digits = 1)` without the leading
  zero; the "Medians among means" row with the minority rule, `§` and `¶`.
- [x] **Step 2:** Commit with the plan.

### Task 1: `.format_sig2()`, the significant-digit formatter

**Files:**
- Modify: `R/hv-tbl-summary.R` (after `.format_to_place()`, about line 707)
- Test: `tests/testthat/test-hv-tbl-summary.R` (append)

**Interfaces:**
- Produces: `.format_sig2(x)`: numeric vector in, character vector out, `NA` for non-finite.

- [ ] **Step 1: Write the failing test**

```r
test_that(".format_sig2() gives 2 significant digits, and whole numbers from 10 up", {
  x <- c(9.9, 0.31, 102.4, 0.8, 7, 9.96, 0, -0.0123, 18250.4, 2.067, 0.153,
         0.0049, NA, Inf)
  expect_identical(
    .format_sig2(x),
    c("9.9", "0.31", "102", "0.80", "7.0", "10", "0", "-0.012", "18250", "2.1",
      "0.15", "0.0049", NA, NA)
  )
})

test_that(".format_sig2() keeps whole numbers past the integer range", {
  # formatC(format = "d") coerces to R integers: 2.2e9 and 1e12 became "NA"
  # with a warning. Whole numbers stay doubles.
  expect_no_warning(out <- .format_sig2(c(2147483647, 2.2e9, 1e12, -3e10)))
  expect_identical(out, c("2147483647", "2200000000", "1000000000000",
                          "-30000000000"))
})
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`
Expected: FAIL, `could not find function ".format_sig2"`.

- [ ] **Step 3: Implement**

Insert after `.format_to_place()` in `R/hv-tbl-summary.R`:

```r
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
  shown[!whole] <- sub("\\.$", "",
                       formatC(r[!whole], digits = 2, format = "fg", flag = "#"))
  shown[r == 0] <- "0"
  out[ok] <- shown
  out
}
```

- [ ] **Step 4: Run it and confirm it passes**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`
Expected: the new test passes.

- [ ] **Step 5: Prove it by mutation.** (a) Change `abs(r) >= 10` to `abs(r) >= 100`; the first
  test fails on `102` and `18250`. (b) Change `format = "f", digits = 0` back to `format = "d"`;
  the second test fails. Restore both.

- [ ] **Step 6: Commit**

```bash
git add R/hv-tbl-summary.R tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: .format_sig2(), the standard's precision for medians"
```

### Task 2: Medians in brackets, to the standard's precision

**Files:**
- Modify: `R/hv-tbl-summary.R` (the `median_label`/`median_stat` lines near 336-340; a new
  `.format_standard_median()` beside `.format_blackstone_mean_sd()`; its call after the
  Blackstone call near line 491)
- Modify: `R/hv-man-footnotes.R` (`.stat_label()`)
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Consumes: `.format_sig2()` (Task 1).
- Produces: median cells `"<n> ||| <median> [<lo>, <hi>]"`, and in a `"both"` table the
  `hv_median_<col>` cells `"<median> [<lo>, <hi>]"`; `.stat_label()` returning
  `"No. (%) or Median [15th, 85th percentiles]"` for `"median"`.

- [ ] **Step 1: Write the failing tests**

```r
test_that("a median is shown in brackets, to 2 significant digits", {
  d <- data.frame(
    g = rep(c("a", "b"), each = 9),
    x = c(5, 20, 63, 80, 102.4, 110, 150, 170.3, 400,
          0.1, 0.153, 0.21, 0.31, 0.33, 0.39, 0.5, 0.6, 0.9)
  )
  tbl <- hv_tbl_summary(d, by = "g", groups = list(A = "x"),
                        continuous = "x", compare = "none", overall = FALSE,
                        show_variable = FALSE)
  row <- tbl$table_body[tbl$table_body$variable == "x", ]
  want <- function(v) {
    q <- stats::quantile(v, c(0.5, 0.15, 0.85), type = 2, names = FALSE)
    sprintf("9 ||| %s [%s, %s]", .format_sig2(q[1]), .format_sig2(q[2]),
            .format_sig2(q[3]))
  }
  expect_identical(row$stat_1, want(d$x[d$g == "a"]))
  expect_identical(row$stat_2, want(d$x[d$g == "b"]))
  expect_match(row$stat_1, "^9 \\|\\|\\| 102 \\[")
})

test_that("the statistic note names brackets and percentiles", {
  expect_identical(.stat_label("median", c(15, 85)),
                   "No. (%) or Median [15th, 85th percentiles]")
  expect_identical(hv_man_footnotes()[["†"]],
                   "No. (%) or Median [15th, 85th percentiles].")
})

test_that("under \"both\" the median column is in brackets too", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = "marker"), continuous = "marker",
                        continuous_stat = "both", compare = "none",
                        overall = FALSE, show_variable = FALSE)
  med <- tbl$table_body$hv_median_stat_1[tbl$table_body$variable == "marker"]
  expect_match(med, "^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
})
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`
Expected: FAIL; the cells read `102.4 (63, 170)`-style with parentheses and gtsummary's digits,
and `.stat_label()` returns `"No. (%) or Median (15th, 85th percentile)"`.

- [ ] **Step 3: Implement**

In `R/hv-tbl-summary.R`, replace the two template lines:

```r
  median_label <- sprintf(
    "Median [%s, %s percentiles]", ordinal[1], ordinal[2]
  )
```

```r
  # Brackets, the house standard: they keep the percentiles apart from
  # the n (%) parentheses in the same table. The numbers are re-formatted
  # from gtsummary's cards by .format_standard_median() below.
  median_stat <- sprintf("{median} [{p%s}, {p%s}]", p_lo, p_hi)
```

After the line `tbl <- .format_blackstone_mean_sd(tbl, mean_vars)`, add:

```r
  median_vars <- if (continuous_stat %in% c("median", "both"))
    nonnormal else character(0)
  tbl <- .format_standard_median(tbl, median_vars, percentiles)
```

Add beside `.format_blackstone_mean_sd()`:

```r
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
    m <- get("median"); lo <- get(lo_name); hi <- get(hi_name)
    if (length(m) != 1L || length(lo) != 1L || length(hi) != 1L) next
    text <- sprintf("%s [%s, %s]", .format_sig2(m), .format_sig2(lo),
                    .format_sig2(hi))
    for (target in c(col, paste0("hv_median_", col))) {
      if (!target %in% names(tbl$table_body)) next
      cells <- tbl$table_body[[target]]
      hit <- tbl$table_body$variable == v & !is.na(cells) &
        grepl("[", cells, fixed = TRUE)
      if (sum(hit) != 1L) next
      parts <- strsplit(cells[hit], " ||| ", fixed = TRUE)[[1]]
      tbl$table_body[[target]][hit] <- if (length(parts) == 2L)
        paste(parts[1], text, sep = " ||| ") else text
    }
  }
  tbl
}
```

In `R/hv-man-footnotes.R`, change `.stat_label()`'s median label:

```r
  median_label <- sprintf(
    "Median [%s, %s percentiles]", ordinal[1], ordinal[2]
  )
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`
Expected: the three new tests pass. Older tests asserting `Median (15th, 85th percentile)` or
parenthesized medians now fail; they are updated in Task 5.

- [ ] **Step 5: Prove it by mutation.** Remove the `.format_standard_median()` call; the first
  test fails. Restore.

- [ ] **Step 6: Commit**

```bash
git add R/hv-tbl-summary.R R/hv-man-footnotes.R tests/testthat/test-hv-tbl-summary.R
git commit -m "feat: medians in brackets, to 2 significant digits"
```

### Task 3: P values without a leading zero

Two columns carry P, and both must change. `hv_compare_col` is what the JTCVS renderer shows
(through `trailing`). The CORR renderer, `hv_man_table()`, shows gtsummary's own `p.value`
column, formatted by the function `add_p()` registered on it, so changing `hv_compare_col`
alone leaves CORR printing `0.7`.

**Files:**
- Modify: `R/hv-tbl-summary.R` (the `compare_col` switch near line 581; after `add_p()` near
  line 572; a new `.format_p()`)
- Test: `tests/testthat/test-hv-tbl-summary.R`, `tests/testthat/test-hv-man-table.R`,
  `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Produces: `.format_p(p)`: numeric in, character out; `hv_compare_col` P values without a
  leading zero; the `p.value` column's format function set to `.format_p`.

- [ ] **Step 1: Write the failing tests**

```r
test_that(".format_p() drops the leading zero and keeps today's digits", {
  expect_identical(
    .format_p(c(0.0004, 0.001, 0.0094, 0.013, 0.043, 0.12, 0.3, 0.7, 0.95, NA)),
    c("<.001", ".001", ".009", ".013", ".043", ".12", ".3", ".7", ">.9", NA)
  )
})

test_that("CORR's rendered P column has no leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(tbl), path)
  text <- officer::docx_summary(officer::read_docx(path))$text
  p <- text[grepl("^[<>]?0?\\.[0-9]+$", text)]
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})

test_that("the JTCVS comparison column has no leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  ft <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"),
                           trailing = attr(tbl, "hv_trailing"))
  p <- stats::na.omit(ft$body$dataset$hv_compare_col)
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})

test_that("the comparison column prints P without a leading zero", {
  skip_if_not_installed("broom")
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "grade")),
                        continuous = "age", categorical = "grade",
                        compare = "pvalue", show_variable = FALSE)
  p <- stats::na.omit(tbl$table_body$hv_compare_col)
  expect_true(length(p) > 0L)
  expect_false(any(grepl("^[<>]?0\\.", p)))
})
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`
Expected: FAIL, `could not find function ".format_p"`.

- [ ] **Step 3: Implement**

Add near `.format_sig2()`:

```r
# P values, the house standard: gtsummary's style_pvalue(digits = 1),
# which hv_tbl_summary() has always used, with the leading zero dropped,
# as AMA style and the typeset JTCVS tables print them (.013, <.001, >.9).
.format_p <- function(p) {
  sub("^([<>]?)0\\.", "\\1.", gtsummary::style_pvalue(p, digits = 1))
}
```

In the `compare_col` switch, replace each `gtsummary::style_pvalue(tb$p.value, digits = 1)`
(three occurrences) with `.format_p(tb$p.value)`.

Right after the `gtsummary::add_p(...)` call, set the displayed column's format too, so the CORR
renderer prints what the JTCVS one does:

```r
    # hv_man_table() shows gtsummary's own p.value column, not
    # hv_compare_col, so its format function has to follow the standard
    # as well.
    tbl <- gtsummary::modify_fmt_fun(tbl, p.value ~ .format_p)
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary|hv-man-table")'`
Expected: the four new tests pass.

- [ ] **Step 5: Prove it by mutation.** (a) Make `.format_p()` return `style_pvalue()` unchanged;
  all four fail. (b) Remove the `modify_fmt_fun()` call; only the CORR test fails, which shows
  it is what covers the displayed column. Restore both.

- [ ] **Step 6: Commit**

```bash
git add R/hv-tbl-summary.R tests/testthat/test-hv-tbl-summary.R tests/testthat/test-hv-man-table.R tests/testthat/test-hv-man-table-jtcvs.R
git commit -m "feat: P values without a leading zero, in both renderers"
```

### Task 4: Mark the minority statistic on its cells

Replaces the row-label suffixes (`"Age, Mean±SD"`, the macro's `DESCLABEL=1`) with a mark on
the cells of whichever statistic fewer continuous rows use: `§` on median cells, `¶` on
mean ± SD cells. The † note names the other, the default.

**Both renderer families take the mark in this task.** The suffixes were the only thing telling
a JTCVS reader which rows differ: without a replacement there, a JTCVS table shows `47±14.7`
under a "Median" header with nothing to explain it. The JTCVS renderer letters every note, so it
marks the cells with the next free letter (`b`; `a` is its count note) and registers the note
in `hv_header_footnotes`, which its saver already writes. Phase 3 moves that layout onto the
standard's `§` and `¶`.

**Files:**
- Modify: `R/hv-tbl-summary.R` (`relabel()`, `label_stat`, the footnotes block near 483-488)
- Modify: `R/hv-man-table.R` (a new `.mark_cells()`, called after `.mark_fisher()`; merge
  `hv_body_marks`)
- Modify: `R/hv-man-table-jtcvs.R` (`.reshape_jtcvs_body()` keeps `variable`;
  `hv_man_table_jtcvs()` marks the cells and adds the note to `hv_header_footnotes`)
- Test: `tests/testthat/test-hv-tbl-summary.R`, `tests/testthat/test-hv-man-table.R`,
  `tests/testthat/test-hv-man-table-jtcvs.R`

**Interfaces:**
- Produces: `attr(tbl, "hv_cell_marks")`, `list(symbol = "§" or "¶", variables = <chr>)` or
  `NULL`; the footnote under that symbol; `hv_man_table()` superscripting the symbol on the
  marked rows' `stat_N` cells and adding it to `attr(ft, "hv_body_marks")`; `hv_man_table_jtcvs()`
  superscripting `b` on the marked rows' `disp_` cells and setting
  `attr(ft, "hv_header_footnotes")$b` to the same note.

- [ ] **Step 1: Write the failing tests**

In `tests/testthat/test-hv-tbl-summary.R`:

```r
test_that("medians among means are marked with a section sign", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = c("age", "ttdeath"), compare = "none",
                        show_variable = FALSE)
  expect_identical(attr(tbl, "hv_cell_marks"),
                   list(symbol = "§", variables = "marker"))
  fn <- attr(tbl, "hv_footnotes")
  expect_identical(fn[["§"]], "Median [15th, 85th percentiles].")
  expect_identical(fn[["†"]], "No. (%) or Mean±SD.")
  labels <- tbl$table_body$label[tbl$table_body$row_type == "label"]
  expect_false(any(grepl(", (Mean|Median)", labels)))
})

test_that("means among medians are marked with a pilcrow", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = "age", compare = "none",
                        show_variable = FALSE)
  expect_identical(attr(tbl, "hv_cell_marks"),
                   list(symbol = "¶", variables = "age"))
  fn <- attr(tbl, "hv_footnotes")
  expect_identical(fn[["¶"]], "Mean±SD.")
  expect_identical(fn[["†"]], "No. (%) or Median [15th, 85th percentiles].")
})

test_that("a table showing one statistic carries no cell marks", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker")),
                        continuous = c("age", "marker"), compare = "none",
                        show_variable = FALSE)
  expect_null(attr(tbl, "hv_cell_marks"))
})
```

In `tests/testthat/test-hv-man-table.R`:

```r
test_that("hv_man_table() superscripts the minority mark on its cells", {
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker", "ttdeath")),
                        continuous = c("age", "marker", "ttdeath"),
                        mean_sd = c("age", "ttdeath"), compare = "none",
                        show_variable = FALSE)
  ft <- hv_man_table(tbl)
  expect_identical(attr(ft, "hv_body_marks")[["§"]],
                   "Median [15th, 85th percentiles].")
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path)
  text <- officer::docx_summary(officer::read_docx(path))$text
  expect_true(any(grepl("§", text, fixed = TRUE)))
})
```

In `tests/testthat/test-hv-man-table-jtcvs.R`:

```r
test_that("the JTCVS table letters the minority mark and its note", {
  # One mean row and one median row: a tie, so the default stays median
  # and the mean row is the one marked.
  tbl <- hv_tbl_summary(gtsummary::trial, by = "trt",
                        groups = list(A = c("age", "marker")),
                        continuous = c("age", "marker"), mean_sd = "age",
                        compare = "none", show_variable = FALSE)
  ft <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
  expect_identical(attr(ft, "hv_header_footnotes")$b, "Mean\u00B1SD.")
  ch <- flextable::information_data_chunk(ft)
  age_row <- which(ft$body$dataset$variable == "age")
  marked <- ch$txt[ch$.part == "body" & ch$.row_id == age_row &
                     ch$.col_id == "disp_stat_1"]
  expect_true("b" %in% marked)
  path <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(ft, path, caption = "Table 1. Test")
  text <- officer::docx_summary(officer::read_docx(path))$text
  expect_true(any(grepl("Mean\u00B1SD.", text, fixed = TRUE)))
  expect_false(any(grepl("Age, Mean", text, fixed = TRUE)))
})
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary|hv-man-table")'`
Expected: FAIL; `hv_cell_marks` is `NULL`, the labels carry `", Median (…)"` suffixes, and the
JTCVS table has no `b` note.

- [ ] **Step 3: Implement in `R/hv-tbl-summary.R`**

Replace the `relabel` function and its `mixed` logic:

```r
  # Mixed: rows of one table show different continuous statistics. The
  # house standard names the statistic most rows use once, in the dagger
  # note, and marks the cells of the other: a section sign on medians, a
  # pilcrow on means. It replaces the macro's DESCLABEL=1 row suffixes.
  mixed <- length(shown_mean) > 0L && length(nonnormal) > 0L &&
    continuous_stat == "median"
  mean_default <- mixed && length(shown_mean) > length(nonnormal)
  cell_marks <- if (!mixed) NULL else if (mean_default) {
    list(symbol = "§", variables = nonnormal)
  } else {
    list(symbol = "¶", variables = shown_mean)
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
```

Change `finish()` so it no longer calls `relabel()`, and delete `relabel()`:

```r
  finish <- function(tbl) {
    if (show_variable) tbl <- .add_variable_column(tbl)
    tbl
  }
```

After the `attr(tbl, "hv_footnotes") <- …` assignment, add:

```r
  if (!is.null(cell_marks)) {
    attr(tbl, "hv_cell_marks") <- cell_marks
    attr(tbl, "hv_footnotes")[[cell_marks$symbol]] <-
      if (identical(cell_marks$symbol, "§")) paste0(median_label, ".")
      else paste0(mean_label, ".")
  }
```

- [ ] **Step 4: Implement in `R/hv-man-table.R`**

Call it after `.mark_fisher()` in `hv_man_table()`:

```r
  ft <- .mark_fisher(ft, tbl$table_body, footnotes)
  ft <- .mark_cells(ft, tbl$table_body, attr(tbl, "hv_cell_marks"), footnotes)
```

Add after `.mark_fisher()`:

```r
# The house standard marks the cells of the statistic fewer rows use (a
# section sign on medians, a pilcrow on means; hv_tbl_summary() decides).
# Superscripted on each statistic cell of those rows, as Fisher's double
# dagger is on its p-values, and recorded in `hv_body_marks` so the saver
# requires the matching note and leaves the symbol off the header.
.mark_cells <- function(ft, tb, marks, footnotes) {
  if (is.null(marks) || is.null(footnotes[[marks$symbol]])) return(ft)
  i <- which(tb$row_type == "label" & tb$variable %in% marks$variables)
  cols <- intersect(grep("^stat_[0-9]+$", names(tb), value = TRUE), ft$col_keys)
  if (length(i) == 0L || length(cols) == 0L) return(ft)
  ft <- flextable::append_chunks(ft, i = i, j = cols, part = "body",
                                 flextable::as_sup(marks$symbol))
  attr(ft, "hv_body_marks") <- c(
    attr(ft, "hv_body_marks", exact = TRUE),
    stats::setNames(footnotes[[marks$symbol]], marks$symbol)
  )
  ft
}
```

- [ ] **Step 5: Implement in `R/hv-man-table-jtcvs.R`**

In `.reshape_jtcvs_body()`, carry the variable name, so a row can be found by it (section rows
inserted later get `NA`, since the section-row code sets every column but `label`,
`is_section` and `row_type` to `NA`):

```r
  out <- data.frame(
    label = tb$label,
    is_section = FALSE,
    row_type = tb$row_type,
    variable = tb$variable,
    stringsAsFactors = FALSE
  )
```

In `hv_man_table_jtcvs()`, replace the `attr(ft, "hv_header_footnotes") <- list(...)` assignment:

```r
  # The minority statistic's mark (hv_tbl_summary()'s hv_cell_marks). This
  # renderer letters its notes, so the cells take the next free letter,
  # "b", and the note joins the header notes, which the saver writes.
  # Phase 3 moves this layout onto the standard's section sign and pilcrow.
  header_notes <- list(a = "Patients with data available.")
  marks <- attr(tbl, "hv_cell_marks", exact = TRUE)
  mark_note <- if (!is.null(marks))
    attr(tbl, "hv_footnotes", exact = TRUE)[[marks$symbol]]
  if (!is.null(mark_note)) {
    i <- which(reshaped$row_type == "label" &
                 reshaped$variable %in% marks$variables)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = disp_cols, part = "body",
                                     flextable::as_sup("b"))
      header_notes$b <- mark_note
    }
  }
  attr(ft, "hv_header_footnotes") <- header_notes
```

- [ ] **Step 6: Run them and confirm they pass**

Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary|hv-man-table")'`
Expected: the five new tests pass.

- [ ] **Step 7: Prove it by mutation.** (a) Swap `>` for `<` in `mean_default`; the section
  sign test fails. (b) Remove the `.mark_cells()` call; the `hv_man_table()` test fails.
  (c) Remove the JTCVS `append_chunks()` call; the JTCVS test fails. Restore all three.

- [ ] **Step 8: Commit**

```bash
git add R/hv-tbl-summary.R R/hv-man-table.R R/hv-man-table-jtcvs.R tests/testthat/test-hv-tbl-summary.R tests/testthat/test-hv-man-table.R tests/testthat/test-hv-man-table-jtcvs.R
git commit -m "feat: mark the minority statistic on its cells in both renderers, replacing row-label suffixes"
```

### Task 5: Update what asserted the old notation; docs; gates

The standard changes output on purpose. Every test that pinned the old notation is updated to
the new one, never loosened, and each change is listed in the PR.

**Files:**
- Modify: `tests/testthat/test-hv-man-footnotes.R`, `test-hv-man-table-save.R`,
  `test-hv-tbl-summary.R`, `test-hv-man-table-jtcvs.R`, `test-word-output.R` (found by the grep
  below)
- Modify: roxygen in `R/hv-tbl-summary.R` (`@param continuous_stat`, `@param mean_sd`,
  `@details`) and `R/hv-man-footnotes.R`; `vignettes/sas-migration.qmd` where it shows a median
- Create: `news/feat-notation-standard.md`

- [ ] **Step 1: List every assertion of the old notation**

Run:

```bash
grep -rn -E "Median \(15th|85th percentile\)|\([0-9.]+, [0-9.]+\)|0\.0[0-9]{2}\"|, Mean.SD\"|as labeled" tests/testthat/ vignettes/ R/
```

Each hit is an old-notation expectation or doc string. Update it to the standard: brackets and
`percentiles`; P without the leading zero; the `§`/`¶` marks instead of `", Mean±SD"` suffixes
and `"No. (%) or as labeled"`.

- [ ] **Step 2: Run the whole suite**

Run: `Rscript -e 'devtools::test()'`
Expected: 0 failures, 0 warnings, 0 skips.

- [ ] **Step 3: Update the roxygen and the vignette text**, then `Rscript -e 'devtools::document()'`.

- [ ] **Step 4: Write the news fragment** `news/feat-notation-standard.md`:

```markdown
* Tables follow the house notation standard (dev/specs/2026-10-17-table-styles-design.md,
  section 5.2). **Existing tables change:**
  - Medians are shown in brackets, each number to 2 significant digits and a value of 10 or
    more to the units place: `102 [63, 170]`, `0.31 [0.21, 0.39]`. The statistic note reads
    "Median [15th, 85th percentiles]".
  - P values drop the leading zero: `.013`, `<.001`, `>.9`.
  - A table mixing medians and means marks the cells of whichever statistic fewer rows use, a
    section sign on medians and a pilcrow on means, with a note for each; the row-label
    suffixes ("Age, Mean±SD") and the "No. (%) or as labeled" note are gone.
  - Mean ± SD is unchanged: `63±13`, unspaced, EHB paired rounding.
```

- [ ] **Step 5: Gates**

Run:

```bash
Rscript -e 'devtools::test()'
Rscript -e 'lintr::lint_package()'
Rscript -e 'devtools::check()'
```

Expected: 0 failures, 0 lints, 0/0/0 with the PDF manual.

- [ ] **Step 6: Run the dependent's tests.** In a scratch library, install this branch, then run
  hvtiRtemplates' `dc-tables` tests against it (Global Constraints). Expected: 0 failures, or
  failures that are only the old notation, which go to hvtiRtemplates as a follow-up and are
  named in this PR.

- [ ] **Step 7: Commit, run `/code-review` locally, open the PR**

```bash
git add -A tests/testthat R vignettes man news
git commit -m "test, docs: the notation standard in every expectation and page"
```

The PR body lists each changed expectation by file and says the local review stood in for
Copilot if its quota is spent.

---

## Self-review

- **Design coverage:** section 5.2's notation (Tasks 1 to 4); section 7's median rounding
  (Tasks 1, 2); the overall count (Phase 2); shading, layouts, page, font, caption, note
  wording per style (Phase 2); `"describe"` and the JTCVS rename (Phase 3); the article and the
  house-rules section (Phase 4); hvtiRtemplates (Phase 5). Mean ± SD needs no task: the
  standard keeps today's form.
- **Names used across tasks:** `.format_sig2()` (Task 1; used in 2), `.format_standard_median()`
  (2), `.format_p()` (3), `hv_cell_marks` and `.mark_cells()` (4), `hv_body_marks` (existing;
  merged in 4), `hv_header_footnotes` (existing; extended with `b` in 4).
- **Both renderer families:** P (Task 3) and the minority mark (Task 4) are tested through
  `hv_man_table()` and `hv_man_table_jtcvs()`, after the review of `99b2a4b` found each covered
  in only one.
- **Changed output on purpose:** every report's medians, P values and mixed-statistic labels.
  Task 5 lists each changed expectation.
