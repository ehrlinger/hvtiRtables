# Table styles, Phase 2: the style object and the manuscript "compare" layout

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `hv_table_style()` and `hv_man_table(style =)` with two styles named by role,
`"report"` and `"manuscript"`, the manuscript style laid out as `"compare"`, so a Table 1 saved
from R matches the submitted manuscripts without hand edits.

**Architecture:** A style is a plain list of the properties in section 5 of the design
(`dev/specs/2026-10-17-table-styles-design.md`). `hv_man_table()` reads it and either keeps
today's CORR path (`"report"`) or builds the `"compare"` table from the same reshaped body the
JTCVS renderer uses (`.reshape_jtcvs_body()`), which is how Phase 3's `"describe"` layout will
share its cells. The flextable carries its style as an attribute, so `hv_man_table_save()` and
`hv_man_table_display()` write that style's notes, caption and page without being told again
(design D2).

**Tech Stack:** R (>= 4.4), gtsummary 2.5.1, flextable 0.10.0, officer 0.7.6, xml2, testthat 3,
roxygen2 with markdown.

## Global Constraints

- Patch-digit bumps only; no `Version:` change in a feature PR. The PR adds
  `news/feat-style-manuscript-compare.md` (AGENTS.md). Work on branch
  `feat/style-manuscript-compare`.
- `devtools::test()` (0 failures, 0 warnings, 0 skips), `lintr::lint_package()` (0 lints; the
  line limit here is the default 80) and `devtools::check()` with the PDF manual at 0 errors,
  0 warnings, 0 notes before the PR opens. In a git worktree the hidden `.git` NOTE is an
  artifact; confirm 0/0/0 from a clean `git archive` build.
- Every new branch of code is proved red first, and by mutation.
- Roxygen is markdown here (`Roxygen: list(markdown = TRUE)`).
- Run hvtiRtemplates' `dc-tables` tests against the branch in a private library before the
  PR: `R CMD INSTALL -l <lib>` this branch and an `origin/main` export of hvtiRtemplates, then
  `R_LIBS=<lib> NOT_CRAN=true Rscript -e 'devtools::test(filter = "dc-tables")'` from the
  export.
- Stage files by name. Never `git add -A`: a failing testthat run writes
  `tests/testthat/_problems/`, which must never be committed.
- Synthetic data only. No manuscript content in the repository.
- US spelling.

## What Phase 2 ships, and what it leaves

From the roadmap in `2026-10-17-table-styles-plan.md`:

| ships here | design reference |
|---|---|
| `hv_table_style(name, fill)`, exported, holding every property of section 5 | D1 |
| `hv_man_table(style =)`: `"report"` as today, `"manuscript"` as `"compare"` | D2, section 5 |
| full grid, two-row spanned header, one overall `n*` column, captions, 300-twip rows kept whole | matrix rows 3, 4, 5, 13, 15 |
| the overall non-missing count and the grouping's name carried by `hv_tbl_summary()` | section 7, D5 |
| shaded section rows in both styles, the fill a property (default `#CAEDFB`) | D4, rows 1 and 2 |
| US Letter pages for every saver | question 4, row 17 |
| the document's body font for `"manuscript"` (no font or size set on the table) | question 5, row 12 |
| note wording and markers per style | rows 8, 9, 10 |

**Left for later phases:** the `"describe"` layout, a `layout =` argument and the JTCVS
rename (Phase 3); the "Table styles" article (Phase 4); hvtiRtemplates (Phase 5).

**In no phase yet:** turning `^2^` in a variable label into a superscript (design section 7,
third bullet). The roadmap assigns it nowhere. This plan does not build it; the PR asks John
where it goes.

## Decisions this plan takes

Each is a reading of the design where it is silent or disagrees with itself. The PR lists them
for John.

1. **The manuscript header is not bold.** Row 14 names a bold header for `"report"` only.
2. **`continuous_stat = "both"` is refused in `"manuscript"`.** A manuscript table shows one
   statistic per group; `hv_tbl_summary()`'s own documentation says choosing one is a matter
   of dropping a column. The error says so. `"describe"` (Phase 3) inherits the JTCVS
   renderer's support for it.
3. **A manuscript save requires `caption`.** Row 13 puts the caption in the style; a table
   saved without one would need it typed in, which is the hand edit this work removes. A
   report save with a caption is refused, as today.
4. **The JTCVS saver moves to Letter too.** Both savers share the page helpers, and
   question 4 says US Letter for every style.
5. **Row 10's wording governs question 8's.** The matrix is "the specification", so the
   manuscript's statistic note is `Values are No. (%) or median [15th, 85th percentiles].`,
   not a `Data:` note. Task 0 aligns question 8.
6. **Header reference marks stay superscript in both styles.** Row 8 concerns the note line:
   in `"manuscript"` the note begins with the plain symbol (`*Patients with non-missing data.`).
7. **`font` and `font_size` are refused with `"manuscript"`.** That style sets no font
   (question 5); accepting the arguments would make the table disagree with its document.
8. **The overall count is computed from the data**, each variable's non-missing values among
   the rows `tbl_summary()` keeps (a missing `by` drops a row). A test checks it against the
   sum of the per-group counts gtsummary prints.

## File structure

| file | change |
|---|---|
| `dev/specs/2026-10-17-table-styles-design.md` | Task 0: row 10's report cell and question 8 |
| `R/hv-tbl-summary.R` | Task 1: `hv_n` column and `hv_by_label` attribute, in `finish()` |
| `R/hv-man-table-save.R` | Task 2: Letter pages; Task 6: caption, note markers per style, header cells per style |
| `R/hv-man-table-save-jtcvs.R` | Task 2: Letter pages |
| `R/hv-table-style.R` (new) | Task 3: `hv_table_style()`, `.as_style()` |
| `_pkgdown.yml` | Task 3: `hv_table_style` in the reference index |
| `R/hv-man-table.R` | Task 4: `style` argument, report shading; Task 5: the manuscript dispatch |
| `R/hv-man-table-compare.R` (new) | Task 5: `.man_table_compare()` |
| `R/hv-man-footnotes.R` | Task 5: `.stat_note()`; Task 6: `hv_man_footnotes(style =)` |
| `R/hv-man-table-display.R` | Task 6: notes per style |
| `tests/testthat/helper-word.R` (new) | Task 7: the Word XML readers, moved from `test-word-output.R` |
| `tests/testthat/test-table-styles.R` (new) | Tasks 3 and 7 |
| tests named in each task | each task |
| roxygen, `README.md`, `news/feat-style-manuscript-compare.md` | Task 8 |

---

### Task 0: Align the design with Phase 1 and decision 5

**Files:**
- Modify: `dev/specs/2026-10-17-table-styles-design.md`

- [ ] **Step 1: Row 10, the report's statistic note.** Phase 1 shipped the bracketed label.
  Replace the cell

  ```
  | `No. (%) or Median (15th, 85th percentile).` |
  ```

  in row 10 with

  ```
  | `No. (%) or Median [15th, 85th percentiles].` |
  ```

- [ ] **Step 2: Question 8.** Replace the sentence
  `The default statistic is named once, in a `Data:` note.` with
  `The default statistic is named once, in the † note (row 10: `Values are No. (%) or
  mean±SD.`).`

- [ ] **Step 3: Commit**

  ```bash
  git add dev/specs/2026-10-17-table-styles-design.md
  git commit -m "spec(table-styles): row 10 follows Phase 1; question 8 follows row 10"
  ```

### Task 1: `hv_tbl_summary()` carries the overall count and the grouping's name

**Files:**
- Modify: `R/hv-tbl-summary.R` (`finish()`, about line 480; a new helper after `.order_notes()`)
- Test: `tests/testthat/test-hv-tbl-summary.R`

**Interfaces:**
- Produces: a `table_body` column `hv_n` (character; the variable's non-missing count on its
  `label` row, `NA` on every other row), hidden from gtsummary's header; an attribute
  `hv_by_label` (the `by` variable's `label` attribute, else its name; `NULL` when `by` is
  `NULL`). Task 5 reads both.

- [ ] **Step 1: Write the failing tests** (append to `test-hv-tbl-summary.R`):

```r
test_that("each variable's overall non-missing count rides on its label row", {
  d <- gtsummary::trial
  d$trt[1:3] <- NA # outside every group, so tbl_summary() drops them
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "grade")),
    continuous = "age", categorical = "grade", compare = "none",
    show_variable = FALSE
  )
  tb <- tbl$table_body
  kept <- d[!is.na(d$trt), ]
  lab <- tb$row_type == "label"
  expect_identical(
    tb$hv_n[lab],
    as.character(c(sum(!is.na(kept$age)), sum(!is.na(kept$grade))))
  )
  expect_true(all(is.na(tb$hv_n[!lab])))
  # Independent of the data: the per-group counts gtsummary printed.
  age <- unlist(tb[tb$variable == "age" & lab, c("stat_1", "stat_2")])
  per_group <- as.integer(sub(" \\|\\|\\| .*", "", age))
  expect_identical(tb$hv_n[tb$variable == "age" & lab],
                   as.character(sum(per_group)))
})

test_that("the overall count is hidden from the report", {
  tbl <- fx_hv_tbl()
  hdr <- tbl$table_styling$header
  expect_true(hdr$hide[hdr$column == "hv_n"])
  expect_false("hv_n" %in% hv_man_table(tbl)$col_keys)
})

test_that("the grouping's name is its label, else its name, else NULL", {
  expect_identical(attr(fx_hv_tbl(), "hv_by_label"), "Chemotherapy Treatment")
  d <- gtsummary::trial
  attr(d$trt, "label") <- NULL
  tbl <- hv_tbl_summary(d, by = "trt", groups = list(A = "age"),
                        continuous = "age", compare = "none")
  expect_identical(attr(tbl, "hv_by_label"), "trt")
  none <- hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                         continuous = "age")
  expect_null(attr(none, "hv_by_label"))
  expect_identical(none$table_body$hv_n,
                   as.character(sum(!is.na(gtsummary::trial$age))))
})
```

- [ ] **Step 2: Run them; they fail** (`hv_n` and `hv_by_label` do not exist).
  Run: `Rscript -e 'devtools::test(filter = "hv-tbl-summary")'`

- [ ] **Step 3: Implement.** Replace `finish()`:

```r
  # The grouping's name, for the manuscript header's spanning cell: the
  # variable's label when the data carry one, else its name.
  by_label <- if (!is.null(by)) attr(data[[by]], "label", exact = TRUE) %||% by
  finish <- function(tbl) {
    tbl <- .add_overall_n(tbl, data, by)
    if (show_variable) tbl <- .add_variable_column(tbl)
    attr(tbl, "hv_by_label") <- by_label
    tbl
  }
```

  and add after `.order_notes()`:

```r
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
```

- [ ] **Step 4: Run the tests; they pass.** Then the whole suite. A test that compares a
  table's full set of `table_body` columns now meets `hv_n`: update it to expect the column
  and list it in the report. No rendered output changes, since the column is hidden.

- [ ] **Step 5: Prove it by mutation.** (a) Delete the `!is.na(data[[by]])` filter: the first
  test fails. (b) Write the count on every row (drop the `ifelse()`): the first test fails on
  the level rows. Restore both.

- [ ] **Step 6: Commit**

```bash
git add R/hv-tbl-summary.R tests/testthat/test-hv-tbl-summary.R
git commit -m "feat(hv_tbl_summary): carry each variable's overall count and the grouping's name"
```

### Task 2: US Letter pages in both savers

**Files:**
- Modify: `R/hv-man-table-save.R:145-192` (`.text_width()`, `.landscape()`), the saver body;
  `R/hv-man-table-save-jtcvs.R` (the `.landscape()` call); the roxygen in both that names
  6.3 and 9.7 inches.
- Test: `tests/testthat/test-hv-man-table-save.R`, `tests/testthat/test-hv-man-table-save-jtcvs.R`

**Interfaces:**
- Produces: `.page_section(doc, landscape)`, replacing `.landscape(doc)`; `.text_width()`
  keeps its signature and now returns Letter's text block (6.53 in portrait, 9.03 in
  landscape). Task 6 calls `.page_section()`.

- [ ] **Step 1: Write the failing tests.** Add to `tests/testthat/helper-fixtures.R`, so both
  saver test files read it:

```r
# The section's page size, read from the saved document.
pg_size <- function(f) {
  s <- as.character(xml2::xml_find_first(
    officer::read_docx(f)$doc_obj$get(), "//w:sectPr/w:pgSz"
  ))
  c(w = sub('.*w:w="([0-9]+)".*', "\\1", s),
    h = sub('.*w:h="([0-9]+)".*', "\\1", s))
}
```

  In `test-hv-man-table-save.R`:

```r
test_that("a saved table is on a US Letter page, portrait or landscape", {
  narrow <- hv_man_table(gtsummary::tbl_summary(gtsummary::trial,
                                                include = age))
  f1 <- tempfile(fileext = ".docx")
  hv_man_table_save(narrow, f1)
  expect_identical(pg_size(f1), c(w = "12240", h = "15840"))
  # Four statistic columns (Overall and three grades) turn the page.
  wide <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "grade", groups = list(A = "age"),
    continuous = "age", compare = "none", show_variable = FALSE
  ))
  f2 <- tempfile(fileext = ".docx")
  hv_man_table_save(wide, f2)
  expect_identical(pg_size(f2), c(w = "15840", h = "12240"))
})
```

  and in `test-hv-man-table-save-jtcvs.R`:

```r
test_that("the JTCVS saver writes a US Letter page", {
  f <- tempfile(fileext = ".docx")
  hv_man_table_save_jtcvs(fx_jtcvs_ft(), f, caption = "Table 1. Test")
  expect_setequal(unname(pg_size(f)), c("12240", "15840"))
})
```

- [ ] **Step 2: Run them; they fail** (A4: `11900` by `16840`).

- [ ] **Step 3: Implement.** Replace `.text_width()` and `.landscape()` with:

```r
# US Letter for every style (design question 4), with the margins the
# A4 template had, 1417 twips (about 1 in) each side. The template's own
# page is A4, so the section is set whatever the orientation.
.letter <- c(width = 12240, height = 15840, margin = 1417)

# Inches between the margins.
.text_width <- function(landscape) {
  side <- if (landscape) .letter[["height"]] else .letter[["width"]]
  (side - 2 * .letter[["margin"]]) / 1440
}

# officer swaps width and height itself for a landscape orientation.
.page_section <- function(doc, landscape) {
  twip <- 1 / 1440
  mar <- .letter[["margin"]] * twip
  officer::body_set_default_section(doc, officer::prop_section(
    page_size = officer::page_size(
      width = .letter[["width"]] * twip,
      height = .letter[["height"]] * twip,
      orient = if (landscape) "landscape" else "portrait"
    ),
    page_margins = officer::page_mar(
      bottom = mar, top = mar, right = mar, left = mar,
      header = 708 * twip, footer = 708 * twip, gutter = 0
    )
  ))
}
```

  In `hv_man_table_save()`, replace `if (fit$landscape) doc <- .landscape(doc)` with
  `doc <- .page_section(doc, fit$landscape)`; in `hv_man_table_save_jtcvs()` the same.
  `grep -n "\.landscape(" R/` must then print nothing.

- [ ] **Step 4: Update what assumed A4.** Run the whole suite. Tests that pin widths against
  the old text blocks (`test-hv-man-table-save.R` near lines 344-369, `test-hv-tbl-summary.R`
  near lines 1436-1470, `test-word-output.R` near line 274) compare against 6.3 and 9.73 in.
  Recompute each from `.text_width()` (6.53 in portrait; 9.03 in landscape, 9.02 after the
  0.01 in rounding margin), keep each test's point (turns when wider than portrait, narrows
  when wider than landscape), and rewrite its comment's numbers. If a table now turns or
  narrows where it did not, the test must still assert what its name says; list every such
  change in the report. Change 6.3 to 6.5 and 9.7 to 9.0 inches in the roxygen of both
  savers (`R/hv-man-table-save.R` about line 85, `R/hv-man-table-save-jtcvs.R` about
  line 39), and "A4" to "US Letter". `test-hv-check-docx.R` builds its own section XML and
  is unaffected.

- [ ] **Step 5: Prove it by mutation.** Restore A4's `11900` as `.letter[["width"]]`: the
  Letter tests fail. Restore.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-save.R R/hv-man-table-save-jtcvs.R tests/testthat/helper-fixtures.R tests/testthat/<each changed test file>
git commit -m "feat(savers): US Letter pages for every style"
```

### Task 3: `hv_table_style()`, the style object

**Files:**
- Create: `R/hv-table-style.R`
- Modify: `_pkgdown.yml` (the reference index; this package's index is explicit and errors
  on a missing topic)
- Test: `tests/testthat/test-table-styles.R` (new)

**Interfaces:**
- Produces: `hv_table_style(name = c("report", "manuscript"), fill = "#CAEDFB")`, returning a
  list of class `"hv_table_style"` with elements `name`, `fill`, `section`, `borders`,
  `header`, `count`, `marker`, `count_note`, `stat_lead`, `font`, `font_size`, `caption`,
  `header_bold`, `row_height`, `keep_rows`, `repeat_header`, `page`, `variable`, `merged`;
  and `.as_style(style)`, which accepts a style name or an `hv_table_style`. Tasks 4 to 7
  read these names exactly.

- [ ] **Step 1: Write the failing tests** (`tests/testthat/test-table-styles.R`):

```r
test_that("each style holds the matrix's properties", {
  r <- hv_table_style("report")
  m <- hv_table_style("manuscript")
  expect_s3_class(r, "hv_table_style")
  expect_identical(
    r[c("section", "borders", "header", "count", "marker", "count_note",
        "stat_lead", "font", "font_size", "caption", "header_bold",
        "keep_rows", "repeat_header", "page", "variable", "merged")],
    list(section = "label", borders = "rules", header = "flat",
         count = "per_group", marker = "superscript",
         count_note = "Number of non-missing values.", stat_lead = "",
         font = "Times New Roman", font_size = 12, caption = FALSE,
         header_bold = TRUE, keep_rows = FALSE, repeat_header = TRUE,
         page = "letter", variable = TRUE, merged = "none")
  )
  expect_null(r$row_height)
  expect_identical(
    m[c("section", "borders", "header", "count", "marker", "count_note",
        "stat_lead", "font", "font_size", "caption", "header_bold",
        "row_height", "keep_rows", "repeat_header", "page", "variable",
        "merged")],
    list(section = "spanned", borders = "grid", header = "spanned",
         count = "overall", marker = "leading",
         count_note = "Patients with non-missing data.",
         stat_lead = "Values are ", font = NA_character_,
         font_size = NA_real_, caption = TRUE, header_bold = FALSE,
         row_height = 300, keep_rows = TRUE, repeat_header = TRUE,
         page = "letter", variable = FALSE,
         merged = "header and section rows")
  )
  expect_identical(c(r$fill, m$fill), c("#CAEDFB", "#CAEDFB"))
})

test_that("the fill is a property a journal can change", {
  expect_identical(hv_table_style("manuscript", fill = "#A5C9EB")$fill,
                   "#A5C9EB")
  expect_error(hv_table_style("manuscript", fill = "blue"), "#RRGGBB")
  expect_error(hv_table_style("manuscript", fill = c("#A5C9EB", "#CAEDFB")),
               "#RRGGBB")
  expect_error(hv_table_style("jtcvs"), "should be one of")
})

test_that("a style is given by name or as an object", {
  expect_identical(.as_style("manuscript"), hv_table_style("manuscript"))
  s <- hv_table_style("report", fill = "#A5C9EB")
  expect_identical(.as_style(s), s)
  expect_error(.as_style("corr"), "hv_table_style")
  expect_error(.as_style(NA_character_), "hv_table_style")
})
```

- [ ] **Step 2: Run them; they fail** (no such function).

- [ ] **Step 3: Implement** `R/hv-table-style.R`:

```r
#' A table style, named by its role
#'
#' The properties a table is drawn with, from the style matrix of the
#' table-styles design: section rows, fill, borders, header, count
#' column, note markers and wording, font, caption, row height, page and
#' merged cells. A style is named for what the table is for, not for a
#' journal. `"report"` is the working table of an analysis report, as
#' [hv_man_table()] has always drawn it. `"manuscript"` is the table a
#' manuscript submits: a full grid, a two-row header with the grouping
#' spanning its levels, one overall `n` column, shaded section rows
#' spanning the table, a caption, and no font of its own, so it takes the
#' font of the document it is saved into.
#'
#' Both styles follow the same house notation (medians, P values, marks),
#' which [hv_tbl_summary()] writes, so a report reads like the manuscript
#' and only the layout differs.
#'
#' @param name `"report"` (default) or `"manuscript"`.
#' @param fill The section rows' shading, one color written `"#RRGGBB"`.
#'   Default `"#CAEDFB"`. Journals differ here (one submission used
#'   `"#A5C9EB"`), so the fill is the property a study changes.
#'
#' @return A list of class `"hv_table_style"`, one element per property,
#'   for [hv_man_table()]'s `style` argument.
#'
#' @seealso [hv_man_table()], which draws a table in a style.
#'
#' @examples
#' hv_table_style("manuscript", fill = "#A5C9EB")$fill
#'
#' @export
hv_table_style <- function(name = c("report", "manuscript"),
                           fill = "#CAEDFB") {
  name <- match.arg(name)
  if (!is.character(fill) || length(fill) != 1L || is.na(fill) ||
        !grepl("^#[0-9A-Fa-f]{6}$", fill))
    stop("`fill` must be one color written \"#RRGGBB\", such as ",
         "\"#CAEDFB\".", call. = FALSE)
  props <- switch(
    name,
    report = list(
      section = "label", borders = "rules", header = "flat",
      count = "per_group", marker = "superscript",
      count_note = "Number of non-missing values.", stat_lead = "",
      font = "Times New Roman", font_size = 12, caption = FALSE,
      header_bold = TRUE, row_height = NULL, keep_rows = FALSE,
      repeat_header = TRUE, page = "letter", variable = TRUE,
      merged = "none"
    ),
    manuscript = list(
      section = "spanned", borders = "grid", header = "spanned",
      count = "overall", marker = "leading",
      count_note = "Patients with non-missing data.",
      stat_lead = "Values are ", font = NA_character_,
      font_size = NA_real_, caption = TRUE, header_bold = FALSE,
      row_height = 300, keep_rows = TRUE, repeat_header = TRUE,
      page = "letter", variable = FALSE,
      merged = "header and section rows"
    )
  )
  structure(c(list(name = name, fill = fill), props),
            class = "hv_table_style")
}

# A style given by name or as an object.
.as_style <- function(style) {
  if (inherits(style, "hv_table_style")) return(style)
  if (is.character(style) && length(style) == 1L && !is.na(style) &&
        style %in% c("report", "manuscript"))
    return(hv_table_style(style))
  stop("`style` must be \"report\", \"manuscript\" or a style from ",
       "hv_table_style().", call. = FALSE)
}
```

  Note `row_height = NULL` inside `list()` keeps the element (a `NULL` entry); the report
  test's `expect_null(r$row_height)` reads it.

- [ ] **Step 4: Add the topic to `_pkgdown.yml`.** Rename the section titled
  `"2. Shape the table - house style is fixed"` to `"2. Shape the table: a style by role"`,
  rewrite its `desc` in one sentence ("A style is named by its role, report or manuscript;
  hv_table_style() holds its properties."), and add `- hv_table_style` to its `contents`.

- [ ] **Step 5: Run the tests; they pass.** `Rscript -e 'devtools::document()'` writes
  `man/hv_table_style.Rd` and the `NAMESPACE` export.

- [ ] **Step 6: Prove it by mutation.** (a) Change the manuscript `count_note` to `"Patients
  with data available."`: the first test fails. (b) Drop the `grepl()` check: the second test
  fails. Restore both.

- [ ] **Step 7: Commit**

```bash
git add R/hv-table-style.R _pkgdown.yml NAMESPACE man/hv_table_style.Rd tests/testthat/test-table-styles.R
git commit -m "feat: hv_table_style(), the properties of a table named by its role"
```

### Task 4: `hv_man_table(style =)` and the report's shaded section rows

**Files:**
- Modify: `R/hv-man-table.R` (`hv_man_table()`)
- Test: `tests/testthat/test-hv-man-table.R`

**Interfaces:**
- Consumes: `.as_style()`, `hv_table_style()` (Task 3).
- Produces: `hv_man_table(tbl, font = "Times New Roman", font_size = 12, digits = 2,
  style = "report", ...)`. `style` goes after `digits` so positional calls keep working. The
  result carries `attr(ft, "hv_style")`, the resolved style. Task 6 reads it.

- [ ] **Step 1: Write the failing tests** (append to `test-hv-man-table.R`):

```r
test_that("the report shades every cell of a section row, unmerged", {
  ft <- hv_man_table(fx_hv_tbl())
  sec <- which(ft$body$dataset$label == "Demography")
  expect_length(sec, 1L)
  fills <- ft$body$styles$cells$background.color$data[sec, ]
  expect_true(all(fills == "#CAEDFB"))
  expect_true(all(ft$body$spans$rows[sec, ] == 1L))
  other <- ft$body$styles$cells$background.color$data[-sec, ]
  expect_false(any(other == "#CAEDFB"))
})

test_that("a report style can carry a journal's fill", {
  ft <- hv_man_table(fx_hv_tbl(),
                     style = hv_table_style("report", fill = "#A5C9EB"))
  sec <- which(ft$body$dataset$label == "Demography")
  expect_true(all(ft$body$styles$cells$background.color$data[sec, ] ==
                    "#A5C9EB"))
  expect_identical(attr(ft, "hv_style")$fill, "#A5C9EB")
})

test_that("the report style is the default, and an unknown style errors", {
  expect_identical(attr(hv_man_table(fx_hv_tbl()), "hv_style"),
                   hv_table_style("report"))
  expect_error(hv_man_table(fx_hv_tbl(), style = "jtcvs"), "hv_table_style")
})
```

- [ ] **Step 2: Run them; they fail** (unused argument `style`; no fill).

- [ ] **Step 3: Implement.** Change the signature to
  `hv_man_table <- function(tbl, font = "Times New Roman", font_size = 12, digits = 2,
  style = "report", ...)`, add `style <- .as_style(style)` after `.check_gtsummary(tbl)`,
  and change the section block to:

```r
  if (length(sec_i) > 0L) {
    ft <- flextable::bold(ft, i = sec_i, part = "body", bold = TRUE)
    # Design D4: every cell of the row is filled and nothing is merged,
    # so the report keeps house rule 3.
    ft <- flextable::bg(ft, i = sec_i, bg = style$fill, part = "body")
  }
```

  and before `ft` is returned, `attr(ft, "hv_style") <- style`.

- [ ] **Step 4: Run the tests; they pass,** and the whole suite: any test that pinned an
  unfilled section row now sees the fill; that is matrix row 1's † change. List each in the
  report.

- [ ] **Step 5: Prove it by mutation.** Remove the `bg()` call: the first two tests fail.
  Restore.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table.R tests/testthat/test-hv-man-table.R
git commit -m "feat(hv_man_table): style argument; the report shades its section rows"
```

### Task 5: The manuscript style's "compare" layout

**Files:**
- Create: `R/hv-man-table-compare.R`
- Modify: `R/hv-man-table.R` (the dispatch), `R/hv-man-footnotes.R` (`.stat_note()`)
- Test: `tests/testthat/test-hv-man-table-compare.R` (new)

**Interfaces:**
- Consumes: `hv_n` and `hv_by_label` (Task 1); `hv_table_style()` (Task 3); the existing
  `.reshape_jtcvs_body(tbl, groups, trailing)`, `.assert_stat_convention(tb, groups, arg,
  caller)` and `.order_notes(notes)`.
- Produces: `.man_table_compare(tbl, style)`, a flextable with column keys `label`, `hv_n`,
  `disp_stat_<k>` (one per statistic column, `disp_stat_0` the Overall column) and
  `hv_compare_col` when the table compares; attributes `hv_footnotes` (manuscript wording),
  `hv_body_marks` (`‡`, `§` or `¶` on cells) and `hv_style`. `.stat_note(stat_label, style)`.
  Task 6 relies on the `hv_n` and `disp_stat_<k>` keys.

- [ ] **Step 1: Write the failing tests** (`tests/testthat/test-hv-man-table-compare.R`):

```r
cmp_tbl <- function(...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", ...
  )
}
cmp <- function(tbl = cmp_tbl()) hv_man_table(tbl, style = "manuscript")
hdr_text <- function(ft, i) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == "header" & ch$.row_id == i, ]
  vapply(ft$col_keys, function(k) {
    paste(ch$txt[ch$.col_id == k], collapse = "")
  }, character(1))
}

test_that("compare: one overall n column, the statistic without its count", {
  tbl <- cmp_tbl()
  ft <- cmp(tbl)
  expect_identical(
    ft$col_keys,
    c("label", "hv_n", "disp_stat_0", "disp_stat_1", "disp_stat_2",
      "hv_compare_col")
  )
  d <- ft$body$dataset
  age <- which(d$row_type == "label" & d$variable == "age")
  expect_identical(d$hv_n[age],
                   tbl$table_body$hv_n[tbl$table_body$variable == "age" &
                                         tbl$table_body$row_type == "label"])
  expect_match(d$disp_stat_1[age], "^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
  expect_false(any(grepl("|||", unlist(d[grep("^disp_", names(d))]),
                         fixed = TRUE)))
})

test_that("compare: a two-row header, the grouping spanning its levels", {
  ft <- cmp()
  expect_identical(flextable::nrow_part(ft, "header"), 2L)
  top <- hdr_text(ft, 1)
  bottom <- hdr_text(ft, 2)
  expect_identical(unname(top[c("label", "hv_n", "disp_stat_0",
                                "disp_stat_1", "hv_compare_col")]),
                   c("Characteristic", "n", "Overall (N = 200)",
                     "Chemotherapy Treatment", "P"))
  expect_identical(unname(bottom[c("disp_stat_1", "disp_stat_2")]),
                   c("Drug A (N = 98)", "Drug B (N = 102)"))
  spans <- ft$header$spans$rows
  expect_identical(unname(spans[1, ]), c(1L, 1L, 1L, 2L, 0L, 1L))
  # Characteristic, n, Overall and P each merged down the two rows.
  down <- ft$header$spans$columns
  expect_identical(unname(down[, c(1, 2, 3, 6)]),
                   matrix(c(2L, 0L), 2, 4))
})

test_that("compare: section rows span the table and are shaded", {
  ft <- hv_man_table(cmp_tbl(),
                     style = hv_table_style("manuscript", fill = "#A5C9EB"))
  sec <- which(ft$body$dataset$is_section)
  expect_length(sec, 1L)
  expect_identical(unname(ft$body$spans$rows[sec, ]),
                   c(length(ft$col_keys), rep(0L, length(ft$col_keys) - 1L)))
  expect_true(all(ft$body$styles$cells$background.color$data[sec, ] ==
                    "#A5C9EB"))
})

test_that("compare: a full grid, no font set, rows of 300 twips kept whole", {
  ft <- cmp()
  for (side in c("top", "bottom", "left", "right"))
    expect_true(all(ft$body$styles$cells[[paste0("border.width.", side)]]$data
                    == 0.5), info = side)
  expect_true(all(is.na(ft$body$styles$text$font.family$data)))
  expect_true(all(is.na(ft$body$styles$text$font.size$data)))
  expect_true(all(ft$body$styles$text$bold$data[!ft$body$dataset$is_section, ]
                  == FALSE))
  expect_true(all(ft$header$styles$text$bold$data == FALSE))
  expect_true(all(abs(ft$body$rowheights - 300 / 1440) < 1e-9))
  expect_false(ft$properties$opts_word$split)
  expect_true(ft$properties$opts_word$repeat_headers)
})

test_that("compare: manuscript notes, and the marks the cells carry", {
  d <- gtsummary::trial
  d$rare <- factor(ifelse(seq_len(nrow(d)) <= 3, "yes", "no"))
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "marker", "rare")),
    continuous = c("age", "marker"), categorical = "rare",
    mean_sd = "age", show_variable = FALSE
  )
  ft <- cmp(tbl)
  notes <- attr(ft, "hv_footnotes")
  expect_identical(names(notes), c("*", "†", "‡", "¶"))
  expect_identical(notes[["*"]], "Patients with non-missing data.")
  expect_identical(notes[["†"]],
                   "Values are No. (%) or median [15th, 85th percentiles].")
  expect_identical(names(attr(ft, "hv_body_marks")), c("‡", "¶"))
  ch <- flextable::information_data_chunk(ft)
  body <- ft$body$dataset
  row_of <- function(v) which(body$row_type == "label" & body$variable == v)
  sup <- ch$.part == "body" & ch$vertical.align == "superscript"
  expect_true(any(sup & ch$.row_id == row_of("rare") &
                    ch$.col_id == "hv_compare_col" & ch$txt == "‡"))
  for (k in c("disp_stat_0", "disp_stat_1", "disp_stat_2"))
    expect_true(any(sup & ch$.row_id == row_of("age") & ch$.col_id == k &
                      ch$txt == "¶"), info = k)
  expect_false(any(sup & ch$.row_id == row_of("marker")))
})

test_that("compare: an ungrouped table keeps its count column", {
  tbl <- hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                        continuous = "age", show_variable = FALSE)
  ft <- cmp(tbl)
  expect_identical(flextable::nrow_part(ft, "header"), 1L)
  expect_identical(unname(hdr_text(ft, 1)),
                   c("Characteristic", "n", "All patients (N = 200)"))
})

test_that("compare refuses what it cannot draw", {
  expect_error(
    hv_man_table(gtsummary::tbl_summary(gtsummary::trial, include = age),
                 style = "manuscript"),
    "hv_tbl_summary"
  )
  expect_error(cmp(cmp_tbl(continuous_stat = "both")), "one statistic")
  expect_error(hv_man_table(cmp_tbl(), font = "Arial", style = "manuscript"),
               "document")
})

test_that("the statistic note in each style's words", {
  m <- hv_table_style("manuscript")
  r <- hv_table_style("report")
  expect_identical(.stat_note("No. (%) or Mean±SD", m),
                   "Values are No. (%) or mean±SD.")
  expect_identical(.stat_note("No. (%) or Mean±SD", r),
                   "No. (%) or Mean±SD.")
})
```

  The fixture's `rare` level (3 of 200) makes its chi-square expected counts fall below 5,
  so `hv_tbl_summary()` runs Fisher's exact test. `mean_sd = "age"` with `marker` a median
  is a one-to-one tie, so the median is the default and `¶` marks age (Phase 1's rule).

- [ ] **Step 2: Run them; they fail** (`style = "manuscript"` draws the report).
  Run: `Rscript -e 'devtools::test(filter = "hv-man-table-compare")'`

- [ ] **Step 3: Implement.** In `R/hv-man-footnotes.R`, after `.stat_label()`:

```r
# The dagger note in a style's words. The manuscript style leads with
# "Values are" and lowers the statistic's capital, as the submissions
# wrote it: "Values are No. (%) or median [15th, 85th percentiles]."
.stat_note <- function(stat_label, style) {
  if (!nzchar(style$stat_lead)) return(paste0(stat_label, "."))
  paste0(style$stat_lead,
         sub(" or ([A-Z])", " or \\L\\1", stat_label, perl = TRUE), ".")
}
```

  In `hv_man_table()`, right after `style <- .as_style(style)`:

```r
  if (identical(style$name, "manuscript")) {
    if (!missing(font) || !missing(font_size))
      stop("`font` and `font_size` set the report style. A manuscript ",
           "table sets no font, so it takes the font of the document it ",
           "is saved into.", call. = FALSE)
    return(.man_table_compare(tbl, style))
  }
```

  Create `R/hv-man-table-compare.R`:

```r
# The "manuscript" style's "compare" layout (design section 5): a full
# grid; a two-row header with "Characteristic" and "n" merged down and
# the grouping's name spanning its levels; one overall n column; shaded
# section rows spanning the table; no font of its own. Built from the
# body the JTCVS renderer reshapes, whose layout becomes "describe" in
# Phase 3, so the two layouts share their cells and differ in their
# counts.
.man_table_compare <- function(tbl, style) {
  tb <- tbl$table_body
  if (!"hv_n" %in% names(tb))
    stop("style = \"manuscript\" needs a table from hv_tbl_summary(), ",
         "which carries each variable's overall count for the n column.",
         call. = FALSE)
  if (any(grepl("^hv_median_stat_[0-9]+$", names(tb))))
    stop("A manuscript table shows one statistic per group, and ",
         "continuous_stat = \"both\" shows two. Build it with ",
         "continuous_stat = \"median\" or \"mean\"; \"both\" is for the ",
         "report.", call. = FALSE)

  by_label <- attr(tbl, "hv_by_label", exact = TRUE)
  stat_cols <- grep("^stat_[0-9]+$", names(tb), value = TRUE)
  hdr <- tbl$table_styling$header
  hdr <- hdr[match(stat_cols, hdr$column), , drop = FALSE]
  level <- if (is.null(by_label)) "All patients" else hdr$modify_stat_level
  groups <- stats::setNames(
    sprintf("%s (N = %s)", level, hdr$modify_stat_n), stat_cols
  )
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
  ft <- flextable::set_table_properties(ft, opts_word = list(
    split = !style$keep_rows, repeat_headers = style$repeat_header
  ))
  ft <- flextable::width(ft, j = "label", width = 2.5)
  ft <- flextable::width(ft, j = c("hv_n", names(compare)), width = 0.6)
  ft <- flextable::width(ft, j = disp, width = 1.1)

  .mark_compare(ft, tbl, body, disp, style)
}

# The notes in the manuscript's words, and the marks on cells: Fisher's
# double dagger on its P, and the minority statistic's section sign or
# pilcrow on every statistic cell of its rows (Phase 1's rule).
.mark_compare <- function(ft, tbl, body, disp, style) {
  tb <- tbl$table_body
  notes <- attr(tbl, "hv_footnotes", exact = TRUE)
  notes[["*"]] <- style$count_note
  notes[["†"]] <- .stat_note(attr(tbl, "hv_stat_label", exact = TRUE),
                                  style)
  rows <- function(vars) {
    which(body$row_type == "label" & body$variable %in% vars)
  }
  marks <- character(0)
  ddag <- "‡"
  if (!is.null(notes[[ddag]]) && "hv_compare_col" %in% ft$col_keys &&
        "test_name" %in% names(tb)) {
    fisher <- tb$variable[!is.na(tb$test_name) &
                            tb$test_name == "fisher.test"]
    i <- rows(fisher)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = "hv_compare_col",
                                     part = "body", flextable::as_sup(ddag))
      marks[[ddag]] <- notes[[ddag]]
    }
  }
  cm <- attr(tbl, "hv_cell_marks", exact = TRUE)
  if (!is.null(cm) && !is.null(notes[[cm$symbol]])) {
    i <- rows(cm$variables)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = disp, part = "body",
                                     flextable::as_sup(cm$symbol))
      marks[[cm$symbol]] <- notes[[cm$symbol]]
    }
  }
  attr(ft, "hv_footnotes") <- .order_notes(notes)
  attr(ft, "hv_body_marks") <- if (length(marks) > 0L) marks
  attr(ft, "hv_style") <- style
  ft
}
```

- [ ] **Step 4: Run the tests; they pass.** Two points to check while they do, and to fix in
  the code (not in the test) if they fail: `merge_at()` over every key must give the section
  row one span of `length(keys)`; `information_data_chunk()` must report the header text per
  `.row_id`/`.col_id`, and a merged-away cell repeats the visible text (the test reads the
  first cell of each span only).

- [ ] **Step 5: Prove it by mutation.** (a) Drop `merge_v()`: the header test fails.
  (b) Use `sum(stat_cols != "stat_0") - 1L` in `widths`: `add_header_row()` errors, so the
  header test fails. (c) Drop the `bg()` call: the section test fails. (d) Drop the Fisher
  `append_chunks()`: the marks test fails. (e) Delete the manuscript dispatch in
  `hv_man_table()`: every test but the last fails. Restore all.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-compare.R R/hv-man-table.R R/hv-man-footnotes.R tests/testthat/test-hv-man-table-compare.R
git commit -m "feat(hv_man_table): the manuscript style's compare layout"
```

### Task 6: The saver and the display follow the style

**Files:**
- Modify: `R/hv-man-table-save.R` (`hv_man_table_save()`, `.note_runs()`, `.footnote_col()`,
  `.footnote_cols()`, a new `.check_caption()`), `R/hv-man-table-display.R`,
  `R/hv-man-footnotes.R` (`hv_man_footnotes()`)
- Test: `tests/testthat/test-hv-man-table-save.R`, `tests/testthat/test-hv-man-table-display.R`,
  `tests/testthat/test-hv-man-footnotes.R`

**Interfaces:**
- Consumes: `attr(ft, "hv_style")` (Tasks 4, 5); `.page_section()` (Task 2); `.as_style()`.
- Produces: `hv_man_table_save(ft, file, footnotes = NULL, abbreviations = NULL,
  caption = NULL, ...)`; `hv_man_footnotes(continuous_stat, percentiles, style = "report")`;
  `.note_runs(sym, text, leading = FALSE)`.

- [ ] **Step 1: Write the failing tests.** In `test-hv-man-table-save.R`:

```r
ms_ft <- function() {
  hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", show_variable = FALSE
  ), style = "manuscript")
}
ms_doc <- function(ft = ms_ft(), ...) {
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, f, ...)
  officer::read_docx(f)$doc_obj$get()
}

test_that("a manuscript table is saved with its caption above it, in bold", {
  x <- ms_doc(caption = "Table 1. Baseline characteristics")
  first <- xml2::xml_find_first(x, "//w:body/*[1]")
  expect_identical(xml2::xml_name(first), "p")
  expect_identical(xml2::xml_text(first), "Table 1. Baseline characteristics")
  expect_length(xml2::xml_find_all(first, ".//w:rPr/w:b[not(@w:val='false')]"),
                1L)
})

test_that("a manuscript note begins with its plain symbol", {
  x <- ms_doc(caption = "Table 1. Test")
  ps <- xml2::xml_find_all(x, "//w:tbl/following-sibling::w:p")
  text <- vapply(ps, xml2::xml_text, character(1))
  expect_identical(text[1], "*Patients with non-missing data.")
  expect_identical(
    text[2], "†Values are No. (%) or median [15th, 85th percentiles]."
  )
  sup <- xml2::xml_find_all(ps[[1]], ".//w:vertAlign[@w:val='superscript']")
  expect_length(sup, 0L)
})

test_that("manuscript header marks: * on n, the dagger on the grouping", {
  x <- ms_doc(caption = "Table 1. Test")
  top <- xml2::xml_find_first(x, "//w:tbl/w:tr[1]")
  cells <- vapply(xml2::xml_find_all(top, "./w:tc"), xml2::xml_text,
                  character(1))
  expect_true("n*" %in% cells)
  expect_true("Chemotherapy Treatment†" %in% cells)
})

test_that("the caption follows the style", {
  expect_error(ms_doc(), "caption")
  f <- tempfile(fileext = ".docx")
  expect_error(hv_man_table_save(hv_man_table(fx_hv_tbl()), f,
                                 caption = "Table 1. Test"),
               "report style writes no caption")
})
```

  In `test-hv-man-table-display.R`:

```r
test_that("a manuscript display writes its notes in the manuscript's words", {
  ft <- hv_man_table_display(hv_man_table(fx_hv_tbl(), style = "manuscript"))
  foot <- flextable::information_data_chunk(ft)
  foot <- foot[foot$.part == "footer", ]
  first <- foot[foot$.row_id == 1, ]
  expect_identical(paste(first$txt, collapse = ""),
                   "*Patients with non-missing data.")
  expect_false(any(first$vertical.align == "superscript"))
})
```

  In `test-hv-man-footnotes.R`:

```r
test_that("hv_man_footnotes() speaks each style's words", {
  expect_identical(hv_man_footnotes(), hv_man_footnotes(style = "report"))
  expect_identical(
    hv_man_footnotes(continuous_stat = "mean", style = "manuscript"),
    list(`*` = "Patients with non-missing data.",
         `†` = "Values are No. (%) or mean±SD.")
  )
})
```

- [ ] **Step 2: Run them; they fail.**

- [ ] **Step 3: Implement.** `hv_man_footnotes()` gains `style = "report"` as its last
  argument:

```r
  style <- .as_style(style)
  out <- list(`*` = style$count_note)
  out[["†"]] <- .stat_note(.stat_label(continuous_stat, percentiles),
                                style)
  out
```

  (`.stat_note()` with the report style returns `paste0(label, ".")`, so the report's
  output is unchanged.)

  In `R/hv-man-table-save.R`:

```r
# One note line as runs. The report superscripts the symbol and spaces
# it from the text; the manuscript begins the line with the plain
# symbol, as the submissions did: "*Patients with non-missing data."
.note_runs <- function(sym, text, leading = FALSE) {
  if (leading)
    return(data.frame(text = paste0(sym, text), sup = FALSE, italic = FALSE,
                      stringsAsFactors = FALSE))
  data.frame(text = c(sym, paste0(" ", text)), sup = c(TRUE, FALSE),
             italic = FALSE, stringsAsFactors = FALSE)
}

# The style decides whether the table has a caption: the manuscript's
# is part of the table, so it is written with it rather than typed in.
.check_caption <- function(caption, style) {
  if (isTRUE(style$caption)) {
    if (is.null(caption))
      stop("A manuscript table needs `caption`, such as \"Table 1. ",
           "Baseline characteristics\": it is written with the table, ",
           "not typed in later.", call. = FALSE)
    .check_string(caption, "caption")
  } else if (!is.null(caption)) {
    stop("The report style writes no caption; a report titles its table ",
         "in the text around it. Use style = \"manuscript\" for a ",
         "captioned table.", call. = FALSE)
  }
  invisible(NULL)
}
```

  `.footnote_col()` gains a first line, `if ("hv_n" %in% ft$col_keys) return("hv_n")`.
  `.footnote_cols()` becomes:

```r
.footnote_cols <- function(ft, sym) {
  if (identical(sym, "†")) {
    # A spanned header names the grouping once, above its levels, and
    # the statistic note belongs on that name.
    if (identical(attr(ft, "hv_style", exact = TRUE)$header, "spanned")) {
      disp <- grep("^disp_stat_[0-9]+$", ft$col_keys, value = TRUE)
      group <- setdiff(disp, "disp_stat_0")
      return(if (length(group) > 0L) group[1] else disp[1])
    }
    stat <- grep("^stat_[0-9]+$", ft$col_keys, value = TRUE)
    if (length(stat) > 0L) return(stat)
  }
  .footnote_col(ft)
}
```

  `hv_man_table_save()` takes `caption = NULL` after `abbreviations`, reads
  `style <- attr(ft, "hv_style", exact = TRUE) %||% hv_table_style("report")` after
  `.check_file(file)`, calls `.check_caption(caption, style)`, writes the caption before the
  table:

```r
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
```

  (remove the later `font <- .table_font(ft)` line), and ends with
  `doc <- .page_section(doc, fit$landscape)` (Task 2) before `print()`.

  In `hv_man_table_display()`, read the same `style` after `.check_not_display(ft)` and pass
  `identical(style$marker, "leading")` as `.note_runs()`'s `leading`.

- [ ] **Step 4: Run the tests; they pass,** and the whole suite: the report's saved output is
  unchanged apart from Task 2's page and Task 4's fill.

- [ ] **Step 5: Prove it by mutation.** (a) `leading` always `FALSE`: the note tests fail.
  (b) Drop the spanned branch of `.footnote_cols()`: the header-marks test fails (the dagger
  lands on `n`). (c) Drop the caption `body_add_fpar()`: the caption test fails. Restore all.

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-save.R R/hv-man-table-display.R R/hv-man-footnotes.R tests/testthat/test-hv-man-table-save.R tests/testthat/test-hv-man-table-display.R tests/testthat/test-hv-man-footnotes.R
git commit -m "feat(savers): notes, marks and caption follow the table's style"
```

### Task 7: The matrix is the fixture: the saved .docx, row by row

**Files:**
- Create: `tests/testthat/helper-word.R` (move `wx_ns`, `wx_doc()`, `wx_text()`, `wx_rows()`
  out of `test-word-output.R`, unchanged)
- Modify: `tests/testthat/test-word-output.R` (delete the moved definitions)
- Test: `tests/testthat/test-table-styles.R`

Design section 9: a structural test reads each style's saved `.docx` and asserts every row of
the matrix, and synthetic replicas of the two submissions' Table 1 shapes must match their
measured properties.

- [ ] **Step 1: Move the helpers,** then run `test-word-output.R`: unchanged results.

- [ ] **Step 2: Write the tests** (append to `test-table-styles.R`):

```r
st_tbl <- function(by = "trt") {
  hv_tbl_summary(
    gtsummary::trial, by = by,
    groups = list(Demography = c("age", "marker"),
                  Disease = c("stage", "grade")),
    continuous = c("age", "marker"), categorical = c("stage", "grade")
  )
}
st_save <- function(name, fill = "#CAEDFB", tbl = st_tbl()) {
  ft <- hv_man_table(tbl, style = hv_table_style(name, fill = fill))
  f <- tempfile(fileext = ".docx")
  caption <- if (name == "manuscript") "Table 1. Baseline characteristics"
  hv_man_table_save(ft, f, caption = caption)
  f
}
st_xml <- function(f) wx_doc(f)
xq <- function(x, path) xml2::xml_find_all(x, path, wx_ns)
ncols <- function(x) length(xq(x, "//w:tblGrid/w:gridCol"))
sec_row <- function(x) {
  xml2::xml_find_first(x, "//w:tr[normalize-space(.)='Demography']", wx_ns)
}

test_that("rows 1-2: shaded section rows, unmerged or spanned", {
  r <- st_xml(st_save("report"))
  tcs <- xq(sec_row(r), "./w:tc")
  expect_length(tcs, ncols(r))
  expect_true(all(xml2::xml_attr(
    xml2::xml_find_first(tcs, ".//w:shd", wx_ns), "fill") == "CAEDFB"))
  m <- st_xml(st_save("manuscript", fill = "#A5C9EB"))
  tc <- xq(sec_row(m), "./w:tc")
  expect_length(tc, 1L)
  expect_identical(xml2::xml_attr(xq(tc, ".//w:gridSpan"), "val"),
                   as.character(ncols(m)))
  expect_identical(xml2::xml_attr(xq(tc, ".//w:shd"), "fill"), "A5C9EB")
})

test_that("row 3: rules in the report, a full grid in the manuscript", {
  r <- st_xml(st_save("report"))
  expect_length(xq(r, "//w:tcBorders/w:left[@w:val='single']"), 0L)
  m <- st_xml(st_save("manuscript"))
  n_tc <- length(xq(m, "//w:tc"))
  for (side in c("top", "bottom", "left", "right"))
    expect_length(xq(m, sprintf(
      "//w:tcBorders/w:%s[@w:val='single' and @w:sz='4']", side)), n_tc)
})

test_that("rows 4-5: the header and the count column", {
  r <- st_xml(st_save("report"))
  expect_length(xq(r, "//w:tr[w:trPr/w:tblHeader]"), 1L)
  r_head <- vapply(xq(r, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(sum(startsWith(r_head, "No.")), 3L) # Overall + 2 groups
  m <- st_xml(st_save("manuscript"))
  expect_length(xq(m, "//w:tr[w:trPr/w:tblHeader]"), 2L)
  m_head <- vapply(xq(m, "//w:tr[1]/w:tc"), wx_text, character(1))
  expect_identical(sum(m_head == "n*"), 1L)
  grouping <- xq(m, "//w:tr[1]/w:tc[.//w:gridSpan[@w:val='2']]")
  expect_identical(wx_text(grouping[[1]]), "Chemotherapy Treatment†")
  expect_length(xq(m, "//w:tr[1]/w:tc[1]//w:vMerge[@w:val='restart']"), 1L)
})

test_that("rows 8-10: note markers and wording", {
  after <- function(x) vapply(xq(x, "//w:tbl/following-sibling::w:p"),
                              wx_text, character(1))
  r <- st_xml(st_save("report"))
  expect_identical(after(r)[1], "* Number of non-missing values.")
  first <- xq(r, "//w:tbl/following-sibling::w:p[1]/w:r[1]")
  expect_length(xq(first[[1]], ".//w:vertAlign[@w:val='superscript']"), 1L)
  m <- st_xml(st_save("manuscript"))
  expect_identical(after(m)[1:2], c(
    "*Patients with non-missing data.",
    "†Values are No. (%) or median [15th, 85th percentiles]."
  ))
})

test_that("rows 12-13: the font and the caption", {
  r <- st_xml(st_save("report"))
  expect_gt(length(xq(r, "//w:tbl//w:rFonts[@w:ascii='Times New Roman']")),
            0L)
  expect_identical(xml2::xml_name(xq(r, "//w:body/*[1]")[[1]]), "tbl")
  m <- st_xml(st_save("manuscript"))
  expect_length(xq(m, "//w:tbl//w:rFonts[@w:ascii]"), 0L)
  expect_length(xq(m, "//w:tbl//w:sz"), 0L)
  cap <- xq(m, "//w:body/*[1]")[[1]]
  expect_identical(wx_text(cap), "Table 1. Baseline characteristics")
})

test_that("rows 14-16: weight, row height, rows kept whole, header repeated", {
  m <- st_xml(st_save("manuscript"))
  head_runs <- xq(m, "//w:tr[w:trPr/w:tblHeader]//w:rPr")
  expect_length(xq(m, paste0("//w:tr[w:trPr/w:tblHeader]//w:rPr/",
                             "w:b[not(@w:val='false')]")), 0L)
  expect_gt(length(head_runs), 0L)
  n_tr <- length(xq(m, "//w:tr"))
  expect_length(xq(m, "//w:trHeight[@w:val='300' and @w:hRule='atLeast']"),
                n_tr)
  expect_length(xq(m, "//w:trPr/w:cantSplit"), n_tr)
  r <- st_xml(st_save("report"))
  expect_length(xq(r, "//w:trPr/w:cantSplit"), 0L)
})

test_that("rows 17-19: Letter, no Variable column, merges where allowed", {
  for (name in c("report", "manuscript")) {
    x <- st_xml(st_save(name))
    sz <- xq(x, "//w:sectPr/w:pgSz")[[1]]
    expect_setequal(
      c(xml2::xml_attr(sz, "w"), xml2::xml_attr(sz, "h")),
      c("12240", "15840")
    )
    cells <- vapply(xq(x, "//w:tc"), wx_text, character(1))
    expect_false("Variable" %in% cells, info = name)
  }
  r <- st_xml(st_save("report"))
  expect_length(xq(r, "//w:gridSpan | //w:vMerge"), 0L)
  m <- st_xml(st_save("manuscript"))
  merged_rows <- xq(m, "//w:tr[.//w:gridSpan or .//w:vMerge]")
  ok <- vapply(merged_rows, function(tr) {
    length(xq(tr, "./w:trPr/w:tblHeader")) > 0L ||
      trimws(wx_text(tr)) %in% c("Demography", "Disease")
  }, logical(1))
  expect_true(all(ok))
})

test_that("hv_check_docx() passes on every style", {
  for (name in c("report", "manuscript"))
    expect_identical(nrow(hv_check_docx(st_save(name))), 0L, info = name)
})

test_that("replicas of the two submissions' Table 1 shapes", {
  # ms.1264: two groups, fill #CAEDFB. BVR rv3: three clusters, #A5C9EB.
  for (case in list(list(by = "trt", fill = "#CAEDFB", span = "2"),
                    list(by = "grade", fill = "#A5C9EB", span = "3"))) {
    tbl <- hv_tbl_summary(
      gtsummary::trial, by = case$by,
      groups = list(Demography = c("age", "marker"), Disease = "stage"),
      continuous = c("age", "marker"), categorical = "stage",
      overall = FALSE, show_variable = FALSE
    )
    x <- st_xml(st_save("manuscript", fill = case$fill, tbl = tbl))
    expect_length(xq(x, sprintf("//w:tr[1]/w:tc[.//w:gridSpan[@w:val='%s']]",
                                case$span)), 1L)
    body_spans <- paste0("//w:tr[not(w:trPr/w:tblHeader)]",
                         "/w:tc[.//w:gridSpan]//w:shd")
    expect_identical(unique(xml2::xml_attr(xq(x, body_spans), "fill")),
                     sub("#", "", case$fill))
    cells <- vapply(xq(x, "//w:tr[not(w:trPr/w:tblHeader)]/w:tc"), wx_text,
                    character(1))
    expect_true(any(grepl("^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$", cells)))
    expect_true(any(grepl("^[0-9]+ \\([0-9.]+\\)$", cells)))
    expect_false(any(grepl("[0-9]\\[", cells))) # a space before brackets
    head <- vapply(xq(x, "//w:tr[2]/w:tc"), wx_text, character(1))
    expect_true(all(grepl("\\(N = [0-9]+\\)$", head[nzchar(head)])))
    notes <- vapply(xq(x, "//w:tbl/following-sibling::w:p"), wx_text,
                    character(1))
    expect_true(any(grepl("15th, 85th percentiles", notes, fixed = TRUE)))
  }
})
```

  `xml_attr()` reads a `w:` attribute by its local name (`"w"`, `"val"`, `"fill"`), as
  `wx_rows()` already does.

- [ ] **Step 3: Run them.** They exercise Tasks 1 to 6, so they pass on the branch; prove
  each is live by mutation instead: (a) the manuscript `row_height` set to 360: the rows
  14-16 test fails; (b) the report fill removed (Task 4's `bg()`): rows 1-2 fail;
  (c) `.page_section()` writing A4: rows 17-19 fail; (d) the manuscript `count_note`
  changed: rows 8-10 fail. Restore all, and record each in the report.

- [ ] **Step 4: Commit**

```bash
git add tests/testthat/helper-word.R tests/testthat/test-word-output.R tests/testthat/test-table-styles.R
git commit -m "test: the style matrix as the fixture, row by row, and the submission replicas"
```

### Task 8: Documentation, news, gates, the dependent

**Files:**
- Modify: roxygen in `R/hv-man-table.R`, `R/hv-man-table-save.R`, `R/hv-man-table-display.R`,
  `R/hv-man-footnotes.R`, `R/hv-tbl-summary.R`; `README.md`; `DESCRIPTION`'s `Description`
- Create: `news/feat-style-manuscript-compare.md`

- [ ] **Step 1: Roxygen.** `hv_man_table()`: replace "house style is fixed, and the only
  choice is flat header versus JTCVS spanning header" with the two styles; document
  `@param style` (a name or [hv_table_style()]; `"manuscript"` needs an [hv_tbl_summary()]
  table, refuses `continuous_stat = "both"`, `font` and `font_size`); add a Common mistakes
  entry for each refusal; `@return` names the `hv_style` attribute.
  `hv_man_table_save()`: `@param caption` (required by `"manuscript"`, refused by
  `"report"`); rewrite the "unused argument (caption)" Common mistakes entry into the
  report-style refusal; the page paragraph says US Letter for every style. `hv_man_footnotes()`:
  `@param style`. `hv_man_table_display()`: the notes follow the style. `hv_tbl_summary()`:
  `@details` names `hv_by_label` and the hidden `hv_n` column. `DESCRIPTION`: one sentence,
  "Tables are drawn in a style named by its role: a report style and a manuscript style."
  Then `Rscript -e 'devtools::document()'`.

- [ ] **Step 2: README.** Where it shows `hv_man_table()`, add the manuscript call:
  `hv_man_table(tbl, style = "manuscript")` saved with
  `hv_man_table_save(ft, file, caption = "Table 1. ...")`.

- [ ] **Step 3: News fragment** `news/feat-style-manuscript-compare.md`:

```markdown
* Tables are drawn in a style named by its role (dev/specs/2026-10-17-table-styles-design.md).
  `hv_table_style()` holds a style's properties; `hv_man_table(style =)` takes `"report"`
  (the default, today's table) or `"manuscript"`.
  - The manuscript style lays out a comparison table as the submissions did: a full grid, a
    two-row header with the grouping spanning its levels, one overall `n` column, shaded
    section rows spanning the table, a bold caption, 300-twip rows kept whole, and no font
    of its own, so it takes the document's body font. Its notes begin with the plain symbol:
    `*Patients with non-missing data.`, `†Values are No. (%) or median [15th, 85th
    percentiles].`
  - `hv_man_table_save()` takes `caption`, which the manuscript style requires and the
    report style refuses.
  - `hv_tbl_summary()` carries each variable's overall non-missing count and the grouping's
    name for the manuscript header.
  - **Existing tables change:** the report shades its section rows (`#CAEDFB` by default,
    every cell, unmerged), and both savers write US Letter pages instead of A4, so a wide
    table now fits a 9.0 in landscape text block instead of 9.7 in.
```

- [ ] **Step 4: Gates.**

```bash
Rscript -e 'devtools::test()'
Rscript -e 'lintr::lint_package()'
Rscript -e 'devtools::check()'
```

  Expected: 0 failures, 0 warnings, 0 skips; 0 lints; 0/0/0 with the manual (the worktree
  `.git` NOTE aside, confirmed from a clean `git archive` build).

- [ ] **Step 5: The dependent.** As in Global Constraints. `dc-tables` saves through
  `hv_man_table_save()` without a caption in the report style, so it should pass unchanged;
  its rendered Word page is now Letter. Name any failure in the PR.

- [ ] **Step 6: Commit, run `/code-review` locally, open the PR**

```bash
git add <each changed file, by name>
git commit -m "docs: the styles in every page; news"
```

  The PR body lists the changed expectations by file, the decisions above for John, and
  says the local review stood in for Copilot if its quota is spent.

---

## Suggested allocation for subagent-driven execution

| task | implementer | why |
|---|---|---|
| 0 | haiku, low | two text edits |
| 1, 3 | sonnet, medium | complete code in the plan |
| 2, 4, 7 | sonnet, medium | complete code, plus re-deriving tests that move |
| 5, 6 | sonnet, high | multi-file, flextable and Word XML behavior to verify |
| 8 | sonnet, medium | docs and gates |

Task reviewers on haiku at low effort, escalating to sonnet on a flag; the whole-branch review
on the most capable model.

## Self-review

- **Spec coverage.** D1 (Task 3); D2, the renderer, saver and display carrying the style
  (Tasks 4 to 6); D4, shading in every style (Tasks 4, 5); D5, the overall count (Task 1);
  section 9's structural test, replicas and `hv_check_docx()` (Task 7). Matrix rows: 1, 2
  (Tasks 4, 5); 3, 4, 5, 13, 14, 15, 16, 19 (Task 5); 8, 9, 10 (Tasks 5, 6); 12 (Task 5);
  17 (Task 2); 18 (Task 5 draws no Variable column; the saver already drops it); 6, 7, 11
  need nothing new (Phase 1's notation; the key is unchanged). Question 4 (Task 2); 5
  (Task 5); 6, 7 (Tasks 3 to 5); 3 (Task 3).
- **Not covered, by design:** D3 and `"describe"` (Phase 3); D6 (Phase 4); D7 (Phase 5).
  **Not covered, and in no phase:** label superscripts (section 7), raised in the PR.
- **`hv_check_docx()`** has no merged-cell rule to set per style (design section 9 assumed
  one); it checks floating layers, hidden columns, embedded footnotes and width, and Task 7
  asserts it passes on both styles.
- **Names used across tasks:** `hv_n`, `hv_by_label`, `hv_style`, `disp_stat_<k>`,
  `.as_style()`, `.stat_note()`, `.page_section()`, `.note_runs(leading =)`, and the style
  elements of Task 3, spelled the same in every task.
