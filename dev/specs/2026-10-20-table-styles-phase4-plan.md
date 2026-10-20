# Table styles, Phase 4: the "Table styles" article

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the table styles as the design's D6 asks: a pkgdown article, "Table styles",
that draws one synthetic table in each style and layout (report; manuscript compare;
manuscript describe) beside the style matrix of design section 5, with the matrix GENERATED
from `hv_table_style()` so the two cannot drift, and a table of the house rules saying which
are content rules and which are hand-edit rules, and which styles keep each (design section 6).
`hv_man_table()`'s details link to it.

**Architecture:** Two internal functions in a new file, `R/hv-table-style-matrix.R`, write the
article's tables from the style objects: `.style_matrix()` maps each style property to the
matrix's wording, one row function per property, with the manuscript style as two columns,
one per layout; `.house_rules()` does the same for the rules, reading from the style where a
property decides whether a rule is kept. Tests hold the generated matrix to the design's
facts, hold every property of `hv_table_style()` to some row, and cross-check the note and key
cells against the words the saver writes. The article is pkgdown-only
(`vignettes/articles/`, build-ignored), renders the three tables with
`hv_man_table_display()` and links the three `.docx` files it saves. One package fix ships
with it: a manuscript table's display took the browser's default font in HTML.

**Tech Stack:** R (>= 4.4), gtsummary 2.5.1, flextable 0.10.0, officer 0.7.6, xml2, testthat 3,
roxygen2 8.1.0 with markdown, pkgdown 2.2.1, Quarto CLI 1.10.18 (R package `quarto` 1.5.1),
knitr 1.51.

## Global Constraints

- Work on branch `feat/table-styles-article`, cut from `origin/main`. Patch-digit bumps only,
  and no `Version:` change in this feature PR; it adds `news/feat-table-styles-article.md`
  (AGENTS.md). The change ships (`R/`, `man/`), so the fragment is required.
- `NOT_CRAN=true Rscript -e 'devtools::test()'`: 0 failures, 0 warnings, 0 skips. The
  baseline on `main` is `FAIL 0 | WARN 0 | SKIP 0 | PASS 1382`; with this plan's tests it is
  `PASS 1413` (measured on the probe build).
- **Lint against an installed copy of the branch**, or new functions read as undefined:
  `R CMD INSTALL -l <scratch lib> .` then `R_LIBS=<scratch lib> Rscript -e
  'lintr::lint_package()'`: 0 lints. The line limit is lintr's default, **80 columns**, and
  it applies to roxygen comments and to the article's R chunks too: `lint_package()` lints
  `vignettes/articles/table-styles.qmd` (probed: a hanging indent in an article chunk was a
  lint).
- **`.lintr` excludes `object_usage_linter` by FILE key only** for a test file that calls
  `helper-word.R` or `helper-fixtures.R` functions inside a function of its own.
  `test-table-styles.R` already has its key; the new tests here live in it and in
  `test-hv-man-table-display.R`, whose new calls sit directly in `test_that()` blocks and lint
  clean (probed). No `.lintr` change.
- **String literals under `R/` are ASCII**, written with a `\u` escape for each non-ASCII
  character (the dagger is `\u2020`, the plus-minus `\u00B1`, the ellipsis `\u2026`), or
  `R CMD check` warns. Roxygen comments may carry the characters. This plan's test code uses
  escapes too. **The Write tool, and a heredoc typed through Bash, can turn a typed escape
  into the raw character.** After writing any `R/` or `tests/` file, run
  `grep -nP '[^\x00-\x7F]' R/hv-table-style-matrix.R R/hv-man-table-display.R` and expect
  nothing outside comments; `Rscript -e 'print(tools:::.check_package_ASCII_code("."))'`
  must print `character(0)`.
- `devtools::check()` from a clean `git archive` export, with the PDF manual and vignettes
  built: 0 errors, 0 warnings, 0 notes, apart from CRAN's "New submission" NOTE when the
  incoming checks run. In a worktree the hidden `.git` NOTE is an artifact; build from the
  export.
- **`pkgdown::check_pkgdown()` is clean.** The reference and articles indexes in
  `_pkgdown.yml` are explicit, so the article must be listed there; no new export is added,
  so the reference index does not change.
- **The site build is a gate, since this phase's output is the site.** Build it locally
  into a scratch export (`pkgdown::build_site(new_process = FALSE, install = FALSE)` with the
  branch installed in a private library), and open the article in a browser, light and dark
  theme. `pkgdown.yaml` runs on every pull request, and an error in an article chunk fails it
  (probed: a misspelled function in the article made `build_article()` exit 1).
- **flextable span matrices are doubles:** assert spans with `expect_equal()`, never
  `expect_identical()` against integers. (No new span assertions here; the rule stands.)
- Every new branch of code is proved red first, and by mutation. Stage files by name; never
  `git add -A` (a failing run writes `tests/testthat/_problems/`, and rendering the article
  leaves `.docx` files beside it).
- Run hvtiRtemplates' `origin/main` `dc-tables` tests against the branch before the PR:
  `R CMD INSTALL -l <lib>` this branch and an `origin/main` `git archive` of hvtiRtemplates,
  then `R_LIBS=<lib> NOT_CRAN=true Rscript -e 'devtools::test(filter = "dc-tables")'` from
  the export. Report the test count and SKIP.
- Run `/code-review` locally before opening the PR, and say in the PR body that it stood in
  for the Copilot review on later pushes.
- Synthetic data only (`gtsummary::trial`). US spelling. No em-dashes anywhere (a hook blocks
  them, even in grep patterns; write `\x{2014}` with `grep -P`).

## What Phase 4 ships, and what it leaves

From the roadmap in `2026-10-17-table-styles-plan.md` and design D6:

| ships here | design reference |
|---|---|
| a pkgdown article, "Table styles", drawing one synthetic table in each style and layout | D6, 5.1 |
| the style matrix in the article, generated from `hv_table_style()` by `.style_matrix()` | D6, section 5, decision 8 |
| describe's differences (5.1) as the matrix's third column | 5.1 |
| rows the same in every style stated once | 5.2 |
| the house rules: content or hand edit, which styles keep each | section 6, D6 |
| tests holding the generated matrix to the design's facts | D6 ("cannot drift"), section 9 |
| `hv_man_table()`'s details, and `hv_table_style()`'s see-also, link to the article | D6 |
| `hv_man_table_display()` shows a manuscript table in the page's font (a defect the article exposed) | D2, question 5 |
| the site's flextable output readable in the dark theme | none; the article needs it |

**Left for later phases:** hvtiRtemplates (Phase 5, design D7). The removal of the deprecated
JTCVS functions is the release after Phase 3's.

**In no phase yet:** turning `^2^` in a variable label into a superscript (design section 7,
third bullet). Still unassigned, and not here (decision 12).

**Checked 2026-10-20 against live state.** `origin/main` is `665f91d`; it moved from the cut
point `d65fc14` by one spec-only commit (#91, Phase 3 decision 6's wording), so the code this
plan builds on is the code probed. No open pull request or issue touches the article. The
design's D6 has no article yet on `main`; `_pkgdown.yml` lists two articles.

## Decisions this plan takes

Each is a reading of the design where it is silent, or a choice it leaves open. The PR lists
them for John.

1. **The article is pkgdown-only, in `vignettes/articles/table-styles.qmd`, build-ignored and
   not shipped.** D6 asks for "a pkgdown article", and its readers read it on the site, beside
   the reference pages it links. Not shipping it means: `R CMD check` neither builds nor times
   it (probed: `R CMD build` with `^vignettes/articles$` in `.Rbuildignore` builds the two
   vignettes and leaves the article out of the tarball); it adds no dependency (it uses
   `knitr`, already in Suggests, and the Imports); it may call the internal `.style_matrix()`
   and `.house_rules()` through `:::` without presenting that as public usage; and the three
   `.docx` files it saves become downloads on the site (probed: pkgdown copies files the
   render writes beside the article into `docs/articles/`). Its gate is `pkgdown.yaml`, which
   runs on every pull request and fails when a chunk errors. **The cost:** `vignette()` does
   not list it offline, and the help pages link to the site's URL, which answers 404 until
   the merge deploys the site. A shipped vignette would instead run on every `R CMD check`
   leg, about 12 s of rendering, and would ship three `.docx` writes into the check's build
   directory.
2. **The article is listed under the existing "Guides" heading**, third, as
   `articles/table-styles`. A heading of its own for one article adds a menu level. pkgdown
   adds a redirect from `articles/articles/table-styles.html` by itself (seen in the build log).
3. **The matrix is generated by an internal function, `.style_matrix()`, not an exported
   one.** Nobody has asked for the matrix in the console, and an export adds a reference
   entry, a manual page and API surface for a documentation need. It lives in its own file,
   `R/hv-table-style-matrix.R`, since it documents the styles and does not draw them.
4. **How the matrix is generated.** The style object holds codes (`borders = "grid"`), so
   each matrix row is a function from `(style, layout)` to the cell's words, keyed on the
   property's value with `switch()`. A value with no words gives `NULL`, which `vapply()`
   refuses, so a new value cannot reach the article blank. Each row names the properties it
   reads, and a test asserts that every property of `hv_table_style()` is read by some row
   (the style's `name` heads its column), so a property added later cannot go undocumented.
   **The layout is an argument, not a property** (design 5.1, Phase 3 decision 2), so the
   matrix has three columns: report, manuscript with `"compare"`, manuscript with
   `"describe"`. **Describe's differences (5.1) are its column**: the header and the count
   rows differ, and its borders and markers match compare's, which the generated cells show
   by being equal.
5. **Twenty rows: the design's nineteen and 5.1's "Overall and comparison columns".** A row
   whose three cells are equal is listed once, after the matrix, under "What every style
   shares" (`shared` in the result). Today that is eight rows: fill, Overall and comparison
   columns, continuous and categorical values, abbreviations, alignment and weight, header
   repeat, page. The split is computed, so a style that changes a shared row moves it into the
   matrix by itself (the fill does, when a journal's fill is passed).
6. **The notation rows (6 and 7) are not style properties.** They are the house standard
   (5.2), which `hv_tbl_summary()` writes for every style; their cells are fixed strings, and
   the article's prose names the rest of the standard (P without a leading zero, the `§`/`¶`
   marks). The rendered tables beside the matrix show the notation live.
7. **The design's facts, not its wording, are what the test holds.** The test transcribes
   the design's matrix and 5.1 table in the generated wording, so a change to a style changes
   a cell the test pins, and whoever makes it updates the design in the same PR. Where the
   wording differs from the design only by form (`auto` for "auto, about 600 twips", which is
   Word's measurement and not a property), the design is not changed. **One row is a fact the
   design states wrongly: row 11.** The design writes the key as `Key: A=...; B=...` (house
   rule 14); the saver has always written `Key: A, ...; B, ...` with the abbreviation in
   italics, and the generated cell reads that from `.key_runs()`, the saver's own code. Task 0
   corrects the design to the code. **If house rule 14 wants `A=...`, that is a saver change
   for John to call, not this phase's.**
8. **The note and key cells are cross-checked against the saved `.docx`**, so the matrix is
   held to the output as well as to the design: the count note, the statistic note and the
   key in the matrix must equal the paragraphs the saver writes.
9. **The tables are shown as `hv_man_table_display()`'s HTML, with the saved `.docx` files
   linked beside them.** The display shares the saver's code for marks, notes and key, so
   fill, grid, spans, weight, alignment, marks and wording are the saved file's (probed in a
   browser: section fills `rgb(202, 237, 251)`; the report's body cells borderless and its
   section cells unmerged; the manuscript's cells 0.5 px on four sides and its sections
   spanning 6 and 8 columns). **What HTML cannot show is stated in the article**: the page
   (US Letter, landscape when wide), the document's body font, row heights in twips, rows kept
   whole and the header repeated on a new page, and the notes and caption as paragraphs. The
   downloads are the answer to all five. Images of the `.docx` were rejected: rendering them
   needs Word or LibreOffice in CI, and committed images would drift from the code, which is
   the defect D6 exists to prevent. The caption is a bold markdown line above each manuscript
   table, because `flextable::set_caption()` printed nothing in the Quarto render (probed).
10. **`hv_man_table_display()` makes a fontless style take the page's font in HTML.** The
    manuscript style sets no font (question 5), which flextable writes into HTML as
    `font-family:'NA'`. No browser has that font, so the table's body fell back to the
    browser's default, a serif, while its footer lines kept flextable's Helvetica (seen in a
    browser on `main`: a manuscript table read like the report's Times New Roman, the row
    the matrix says differs). The fix gives such a table an HTML class whose CSS makes every
    run inherit the page's font and size, and sets the footer lines' font to none, as the
    body's is. It ships, because any HTML report showing a manuscript table had the defect,
    not only the article. Fixing it in the article's CSS alone was rejected for that reason.
11. **The site's flextable output sits on white in the dark theme.** flextable sets its text
    black and its cells transparent, so in the site's dark theme (`light-switch: true`) the
    tables were black on near-black and their grid invisible (seen in a browser). A rule in
    `pkgdown/extra.css` gives `.flextable-shadow-host` a white background, as on paper. It
    covers every flextable on the site, the reference examples included. `pkgdown/` is
    build-ignored, so this ships nothing.
12. **Label superscripts (`^2^`, design section 7) are not in Phase 4**, and remain
    unassigned. They change what the renderer draws, not what the article documents; the PR
    asks John where they go.
13. **The house-rules table: eleven rows, from section 6.** Rules 2, 3, 5, 8 and 14 are
    hand-edit rules; the bans on footnotes inside the table (rule 13), hidden spacing columns
    and floating layers are classed as **content** rules, because section 6's last paragraph
    keeps them in every style ("those are content problems whatever produced the file") and
    `hv_check_docx()` checks them in every style; the three content rules of section 6 follow.
    Rules 3, 5 and 8's cells are read from the style (`merged`, `font`, `count_note`), so a
    style that kept rule 5 would say so; the others read "kept" in both styles, as the code
    keeps them. A "Checked" column marks the rules `hv_check_docx()` checks in a saved file
    (3, 13, hidden columns, layers). **The rule texts are paraphrased** from the package's own
    references to the memo, which is not in the repository: rule 2 from the saver's roxygen
    ("the insertion point"), rule 8's wording from `hv_man_footnotes()`, rule 14 from the
    saver. John should check them against *Table Construction for Manuscripts* (7/14/2026).
14. **The example table is `gtsummary::trial`, with age as mean±SD and the marker as a
    median**, so it shows the house standard's minority mark (`¶`) and its note, and the marker
    difference between styles (row 8) on a real cell. `show_variable = FALSE`, since every
    saved `.docx` drops that column and each table is drawn as it is saved.
15. **The links:** `hv_man_table()`'s details (D6) and `hv_table_style()`'s see-also, the
    object the article prints, link to the article by its site URL. The README's paragraph on
    styles gains one sentence pointing to it. The URL is split across two roxygen lines
    (`[Table styles](` then the URL), since one line is 85 columns; CommonMark allows the
    break and roxygen writes one `\href{}` (probed).

## File structure

| file | change |
|---|---|
| `dev/specs/2026-10-17-table-styles-design.md` | Task 0: section 5 records that the matrix is generated; row 11's key form; D6's pointer to this plan |
| `R/hv-table-style-matrix.R` (new) | Task 1: `.style_matrix()`, `.matrix_reads()`, `.mrow()`, `.matrix_rows()`; Task 2: `.house_rules()`, `.hrule()`, `.rule_rows()` |
| `tests/testthat/test-table-styles.R` | Tasks 1 and 2: five tests, appended |
| `R/hv-man-table-display.R`, `man/hv_man_table_display.Rd` | Task 3: `.document_font_html()`, called for a fontless style; roxygen |
| `tests/testthat/test-hv-man-table-display.R` | Task 3: two tests, appended |
| `vignettes/articles/table-styles.qmd` (new) | Task 4 |
| `_pkgdown.yml` | Task 4: the article under Guides |
| `.Rbuildignore` | Task 4: `^vignettes/articles$` |
| `.gitignore` | Task 4: the article's rendered `.docx` and `_files/` |
| `pkgdown/extra.css` | Task 4: the dark-theme rule |
| `R/hv-man-table.R`, `R/hv-table-style.R`, `man/` | Task 5: the links |
| `README.md` | Task 5: one sentence |
| `news/feat-table-styles-article.md` (new) | Task 5 |

## Verified by probing, 2026-10-20

All code in Tasks 1 to 5 was built in a scratch `git archive` of `d65fc14` (code identical to
`origin/main` `665f91d`), installed into a private library, and run:

- **The matrix**, `.style_matrix()`, returns the twenty rows and the three columns transcribed
  in Task 1's test; eight rows come out shared. `.matrix_reads()` equals
  `names(hv_table_style())` both ways. The key cell, read from `.key_runs()`, is
  `Key: A, ...; B, ...` (with the ellipsis character), not the design's `A=...`.
- **The house rules**, `.house_rules()`, give the eleven rows of Task 2's test; the manuscript
  sets aside rules 3, 5 and 8 and keeps the rest.
- **Red first:** with the new tests on `main`'s code, five display expectations fail and the
  five matrix and rules tests error ("could not find function"). With the code: the two files
  `PASS 182` (from 151), the full suite `FAIL 0 | WARN 0 | SKIP 0 | PASS 1413`.
- **Mutations, each red:** the "Merged cells" row dropped (property test and matrix test);
  the fill cell hard-coded (the object test, two expectations); the display fix not called
  (four expectations); `opts_word` not passed back (one); the footer font left set (one); the
  class applied to every style (the report test and the existing footer-font test); rule 5
  hard-coded "kept" (the rules test); the saver's key written `A=` (the matrix and the
  display tests).
- **HTML, in a browser:** on `main`, a manuscript display's body declared `font-family:'NA'`
  and rendered in the browser's default serif while its footer lines were Helvetica; with the
  fix, body and footer computed to the page's `Outfit`, 16 px. The report kept
  `"Times New Roman"`. The `opts_word` of the displayed table (`split = FALSE`,
  `repeat_headers = TRUE`) survives the fix; `set_table_properties()` alone reset `split` to
  `TRUE`. flextable renders each table inside a shadow DOM, so Bootstrap's `.table` rules do
  not reach the cells.
- **Dark theme:** with `data-bs-theme="dark"`, the body was `rgb(33, 37, 41)` and the table
  text `rgb(0, 0, 0)` on a transparent cell; the `extra.css` rule made it legible.
- **The site:** `pkgdown::build_site(new_process = FALSE, install = FALSE)` built in 49 s;
  the article rendered, its two manuscript tables carry the `hv-document-font` class, the
  three `.docx` files were copied to `docs/articles/`, the articles menu and index list
  "Table styles", and both reference pages link to it. `pkgdown::check_pkgdown()`: "No
  problems found." The saved files: report and describe on landscape Letter, compare on
  portrait Letter; `hv_check_docx()` finds 0 rows in each.
- **Not shipped:** `R CMD build` with `^vignettes/articles$` built only the two vignettes; the
  tarball has no `vignettes/articles`. Rendering leaves `table-styles-*.docx` and an empty
  `table-styles_files/` beside the `.qmd`, hence the `.gitignore` lines.
- **Lint** on the installed probe: 0 lints, the article included, once its one hanging indent
  was fixed (the code below is the fixed form). The roxygen link split over two lines lints
  clean and documents as one `\href{}`.

---

### Task 0: Record in the design that the matrix is generated

**Files:**
- Modify: `dev/specs/2026-10-17-table-styles-design.md`

- [ ] **Step 1: Section 5 (decisions 4 and 7).** After the paragraph that ends "The JTCVS
  column records today's renderer, whose layout becomes `"describe"` (D3, section 5.1).",
  add:

  ```
  Since Phase 4 the matrix is generated: `.style_matrix()` writes it from `hv_table_style()`,
  with the manuscript style as two columns, one per layout, and the "Table styles" article
  prints it. This table is the record of the decision; `test-table-styles.R` holds the
  generated matrix to its facts, and a change to a style updates both in one PR.
  ```

- [ ] **Step 2: Row 11 (decision 7).** In the matrix, replace the row

  ```
  | 11 | Abbreviations | `Key: A=…; B=…` (house rule 14) | `Key: A=…; B=…` | its own key |
  ```

  with

  ```
  | 11 | Abbreviations | `Key: A, …; B, …`, each abbreviation in italics (house rule 14) | `Key: A, …; B, …` | its own key |
  ```

  Match the existing row by `grep -n "| 11 |"` first; copy the ellipsis from the file rather
  than typing it.

- [ ] **Step 3: D6 (decision 1).** At the end of D6, after "The `@details` of
  `hv_man_table()` link to the article.", add: `How it is built is
  2026-10-20-table-styles-phase4-plan.md.`

- [ ] **Step 4: Commit**

  ```bash
  git add dev/specs/2026-10-17-table-styles-design.md
  git commit -m "spec(table-styles): the matrix is generated; row 11 is the key the saver writes"
  ```

### Task 1: `.style_matrix()`, the matrix from the style objects

**Files:**
- Create: `R/hv-table-style-matrix.R`
- Test: `tests/testthat/test-table-styles.R` (append; it defines `st_tbl()`, `st_save()` and
  `xq()`, and `helper-word.R` gives `wx_doc()` and `wx_text()`)

**Interfaces:**
- Consumes: `hv_table_style(name, fill)`; `.stat_note(stat_label, style)` and
  `.stat_label(continuous_stat, percentiles)` (`R/hv-man-footnotes.R`); `.key_runs(abbreviations)`
  (`R/hv-man-table-save.R`), a data frame whose `text` column joins to the key line.
- Produces: `.style_matrix(report = hv_table_style("report"), manuscript =
  hv_table_style("manuscript"))`, a data frame with character columns `property`, `report`,
  `compare`, `describe` and a logical `shared`, one row per property, twenty rows;
  `.matrix_reads()`, a character vector of the style properties the matrix reads. Task 4's
  article calls `hvtiRtables:::.style_matrix()`.

- [ ] **Step 1: Write the failing tests** (append to `tests/testthat/test-table-styles.R`):

```r

# -- the matrix the "Table styles" article prints (design D6) -------------

# The design's section 5 matrix and its 5.1 describe column, as facts:
# the wording is the generated matrix's, the content the design's. A
# change to a style changes a cell here, and the design records it.
test_that("the style matrix states the design's matrix", {
  dag <- "\u2020"
  m <- .style_matrix()
  expect_identical(m$property, c(
    "Section row", "Fill color", "Borders", "Header", "Non-missing count",
    "Overall and comparison columns", "Continuous values",
    "Categorical values", "Note markers", "Count note", "Statistic note",
    "Abbreviations", "Font", "Caption", "Alignment and weight",
    "Row height", "Header repeated on a new page", "Page",
    "Variable column", "Merged cells"
  ))
  shared <- c(
    "`#CAEDFB`; `hv_table_style(fill =)` sets it",
    "shown when the table carries them",
    "`9.9 [8.5, 11]`, `63\u00B113`: the house standard",
    "`30 (42)`: the house standard",
    "`Key: A, \u2026; B, \u2026`",
    "header bold; first column left, others centered",
    "yes", "US Letter, landscape when wide, else portrait"
  )
  expect_identical(m$property[m$shared], c(
    "Fill color", "Overall and comparison columns", "Continuous values",
    "Categorical values", "Abbreviations", "Alignment and weight",
    "Header repeated on a new page", "Page"
  ))
  expect_identical(m$report[m$shared], shared)
  expect_identical(m$report[!m$shared], c(
    paste0("label in the first cell, bold, left; fill on every cell of ",
           "the row, unmerged"),
    "horizontal rules only",
    paste0("one row: a `No.` column before each group's `<group> N = n`; ",
           "`*` on the first `No.`, `", dag, "` on each group"),
    "one column per group",
    "the house symbols by meaning, superscript, then a space",
    "`Number of non-missing values.`",
    "`No. (%) or Median [15th, 85th percentiles].`",
    "Times New Roman 12 pt",
    "optional: bold, above the table, when given",
    "auto",
    "on screen only; every saved `.docx` drops it",
    "none"
  ))
  ms <- c(
    "spans the full width, bold; filled",
    "full grid: box plus all inner lines, single 0.5 pt",
    NA, NA,
    paste0("the house symbols by meaning, at the start of the note, not ",
           "superscript"),
    "`Patients with non-missing data.`",
    "`Values are No. (%) or median [15th, 85th percentiles].`",
    "none set: the document's body font",
    "required: bold, above the table",
    "at least 300 twips, rows kept on one page",
    "never",
    "header and section rows"
  )
  ms_cmp <- ms
  ms_cmp[3:4] <- c(
    paste0("two rows: `Characteristic` and `n*` merged down, the ",
           "grouping's name with `", dag, "` spanning its levels; row 2 ",
           "`<level> (N = n)`"),
    "one overall `n*` column"
  )
  ms_dsc <- ms
  ms_dsc[3:4] <- c(
    paste0("two rows: each group, `<level> (N = n)`, spans its own (n, ",
           "statistic) pair; row 2 names them, `n*` and the statistic ",
           "with `", dag, "`"),
    "one `n*` column per group, Overall's included"
  )
  expect_identical(m$compare[!m$shared], ms_cmp)
  expect_identical(m$describe[!m$shared], ms_dsc)
})

test_that("every style property is written into the matrix", {
  expect_setequal(.matrix_reads(), names(hv_table_style()))
})

test_that("the matrix is read from the style objects, not written", {
  fill <- .style_matrix(manuscript = hv_table_style("manuscript",
                                                    fill = "#A5C9EB"))
  i <- fill$property == "Fill color"
  expect_identical(fill$compare[i],
                   "`#A5C9EB`; `hv_table_style(fill =)` sets it")
  expect_false(fill$shared[i])
  s <- hv_table_style("report")
  s$borders <- "grid"
  b <- .style_matrix(report = s)
  expect_identical(b$report[b$property == "Borders"],
                   "full grid: box plus all inner lines, single 0.5 pt")
  s$borders <- "dotted"
  expect_error(.style_matrix(report = s))
})

test_that("the matrix's notes and key are the words the saver writes", {
  m <- .style_matrix()
  cell <- function(col, prop) gsub("`", "", m[[col]][m$property == prop])
  after <- function(f) {
    vapply(xq(wx_doc(f), "//w:tbl/following-sibling::w:p"), wx_text,
           character(1))
  }
  r <- after(st_save("report"))
  expect_identical(r[1], paste("*", cell("report", "Count note")))
  expect_identical(r[2], paste0("\u2020 ", sub("\\.$", "", cell(
    "report", "Statistic note"
  )), "; P values from the Wilcoxon rank sum test and Pearson's ",
  "chi-square test."))
  x <- after(st_save("manuscript"))
  expect_identical(x[1], paste0("*", cell("compare", "Count note")))
  # The manuscript's dagger note goes on to name the tests.
  stat <- sub("\\.$", ";", cell("compare", "Statistic note"))
  expect_true(startsWith(x[2], paste0("\u2020", stat)))
  f <- tempfile(fileext = ".docx")
  hv_man_table_save(hv_man_table(st_tbl()), f,
                    abbreviations = c(B = "\u2026", A = "\u2026"))
  expect_identical(utils::tail(after(f), 1),
                   cell("report", "Abbreviations"))
})
```

- [ ] **Step 2: Run them; they fail.**
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "table-styles")'`
  Expected: four errors, `could not find function ".style_matrix"` (and
  `".matrix_reads"`).

- [ ] **Step 3: Implement.** Create `R/hv-table-style-matrix.R`:

```r
# The style matrix of the table-styles design (section 5), written from
# the style objects rather than by hand, so the "Table styles" article
# and the package cannot disagree (design D6). One row per property.
# Each row names the style properties it is written from (`reads`), and
# a test holds every property of hv_table_style() to some row, so a new
# property cannot go undocumented. The layout is an argument of
# hv_man_table(), not a property, so the manuscript style is two
# columns, one per layout (design section 5.1).
.style_matrix <- function(report = hv_table_style("report"),
                          manuscript = hv_table_style("manuscript")) {
  cols <- list(
    report = list(style = report, layout = NA_character_),
    compare = list(style = manuscript, layout = "compare"),
    describe = list(style = manuscript, layout = "describe")
  )
  rows <- .matrix_rows()
  cells <- lapply(cols, function(k) {
    vapply(rows, function(r) r$cell(k$style, k$layout), character(1))
  })
  out <- data.frame(
    property = vapply(rows, function(r) r$property, character(1)),
    cells, stringsAsFactors = FALSE
  )
  out$shared <- out$report == out$compare & out$compare == out$describe
  out
}

# The style properties the matrix reads: every row's, and the style's
# name, which heads its column.
.matrix_reads <- function() {
  unique(c("name", unlist(lapply(.matrix_rows(), function(r) r$reads))))
}

.mrow <- function(property, reads, cell) {
  list(property = property, reads = reads, cell = cell)
}

# One function per row, from (style, layout) to the cell's words. A
# property value with no words errors in vapply(), so a new value cannot
# reach the article blank.
.matrix_rows <- function() {
  dag <- "\u2020"
  list(
    .mrow("Section row", "section", function(s, layout) {
      switch(s$section,
             label = paste0("label in the first cell, bold, left; fill on ",
                            "every cell of the row, unmerged"),
             spanned = "spans the full width, bold; filled")
    }),
    .mrow("Fill color", "fill", function(s, layout) {
      sprintf("`%s`; `hv_table_style(fill =)` sets it", s$fill)
    }),
    .mrow("Borders", "borders", function(s, layout) {
      switch(s$borders,
             rules = "horizontal rules only",
             grid = paste0("full grid: box plus all inner lines, single ",
                           "0.5 pt"))
    }),
    .mrow("Header", "header", function(s, layout) {
      if (identical(s$header, "flat"))
        return(paste0("one row: a `No.` column before each group's ",
                      "`<group> N = n`; `*` on the first `No.`, `", dag,
                      "` on each group"))
      switch(layout,
             compare = paste0("two rows: `Characteristic` and `n*` merged ",
                              "down, the grouping's name with `", dag,
                              "` spanning its levels; row 2 ",
                              "`<level> (N = n)`"),
             describe = paste0("two rows: each group, `<level> (N = n)`, ",
                               "spans its own (n, statistic) pair; row 2 ",
                               "names them, `n*` and the statistic with `",
                               dag, "`"))
    }),
    .mrow("Non-missing count", "count", function(s, layout) {
      if (identical(s$count, "per_group")) return("one column per group")
      switch(layout,
             compare = "one overall `n*` column",
             describe = "one `n*` column per group, Overall's included")
    }),
    .mrow("Overall and comparison columns", character(0),
          function(s, layout) "shown when the table carries them"),
    .mrow("Continuous values", character(0), function(s, layout) {
      "`9.9 [8.5, 11]`, `63\u00B113`: the house standard"
    }),
    .mrow("Categorical values", character(0), function(s, layout) {
      "`30 (42)`: the house standard"
    }),
    .mrow("Note markers", "marker", function(s, layout) {
      switch(s$marker,
             superscript = paste0("the house symbols by meaning, ",
                                  "superscript, then a space"),
             leading = paste0("the house symbols by meaning, at the start ",
                              "of the note, not superscript"))
    }),
    .mrow("Count note", "count_note", function(s, layout) {
      sprintf("`%s`", s$count_note)
    }),
    .mrow("Statistic note", "stat_lead", function(s, layout) {
      sprintf("`%s`", .stat_note(.stat_label("median", c(15, 85)), s))
    }),
    .mrow("Abbreviations", character(0), function(s, layout) {
      key <- .key_runs(c(A = "\u2026", B = "\u2026"))
      sprintf("`%s`", paste(key$text, collapse = ""))
    }),
    .mrow("Font", c("font", "font_size"), function(s, layout) {
      if (is.na(s$font)) return("none set: the document's body font")
      sprintf("%s %g pt", s$font, s$font_size)
    }),
    .mrow("Caption", "caption", function(s, layout) {
      switch(s$caption,
             optional = "optional: bold, above the table, when given",
             required = "required: bold, above the table")
    }),
    .mrow("Alignment and weight", "header_bold", function(s, layout) {
      paste0(if (s$header_bold) "header bold" else "header plain",
             "; first column left, others centered")
    }),
    .mrow("Row height", c("row_height", "keep_rows"), function(s, layout) {
      h <- if (is.null(s$row_height)) "auto" else
        sprintf("at least %g twips", s$row_height)
      paste0(h, if (s$keep_rows) ", rows kept on one page")
    }),
    .mrow("Header repeated on a new page", "repeat_header",
          function(s, layout) if (s$repeat_header) "yes" else "no"),
    .mrow("Page", "page", function(s, layout) {
      switch(s$page,
             letter = "US Letter, landscape when wide, else portrait")
    }),
    .mrow("Variable column", "variable", function(s, layout) {
      if (s$variable) "on screen only; every saved `.docx` drops it" else
        "never"
    }),
    .mrow("Merged cells", "merged", function(s, layout) s$merged)
  )
}
```

  Then check the escapes survived:
  `grep -nP '[^\x00-\x7F]' R/hv-table-style-matrix.R` prints nothing.

- [ ] **Step 4: Run them; they pass.**
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "table-styles")'`
  Expected: `FAIL 0 | WARN 0 | SKIP 0`.

- [ ] **Step 5: Mutations, each red, each reverted.**
  - Replace the "Merged cells" row with `NULL`: the property test and the matrix test fail.
  - Replace the fill cell's `sprintf(..., s$fill)` with the literal
    ``"`#CAEDFB`; `hv_table_style(fill =)` sets it"``: the object test fails twice.
  - In `R/hv-man-table-save.R`'s `.key_runs()`, write `paste0("=", unname(ordered)` for
    `paste0(", ", unname(ordered)`: the matrix test and the saver cross-check fail (the
    display tests fail too, which is expected).

- [ ] **Step 6: Commit**

```bash
git add R/hv-table-style-matrix.R tests/testthat/test-table-styles.R
git commit -m "feat: .style_matrix() writes the style matrix from the style objects"
```

### Task 2: `.house_rules()`, which rules each style keeps

**Files:**
- Modify: `R/hv-table-style-matrix.R` (append)
- Test: `tests/testthat/test-table-styles.R` (append)

**Interfaces:**
- Consumes: `hv_table_style()`.
- Produces: `.house_rules(report = hv_table_style("report"), manuscript =
  hv_table_style("manuscript"))`, a data frame with character columns `rule`, `says`, `kind`
  (`"hand edit"` or `"content"`), `report`, `manuscript` (`"kept"` or `"set aside: ..."`) and
  a logical `checked`, eleven rows. Task 4's article calls `hvtiRtables:::.house_rules()`.

- [ ] **Step 1: Write the failing test** (append to `tests/testthat/test-table-styles.R`):

```r

test_that("the house rules: content binds every style, hand edits vary", {
  h <- .house_rules()
  expect_identical(h$rule, c("2", "3", "5", "8", "13", "14", "", "", "",
                             "", ""))
  expect_identical(h$kind, c(rep("hand edit", 4), "content", "hand edit",
                             rep("content", 5)))
  expect_true(all(h$report == "kept"))
  expect_identical(h$manuscript[h$kind == "content"], rep("kept", 6))
  expect_identical(h$manuscript[2:4], c(
    "set aside: merges its header and section rows",
    "set aside: the document's body font",
    "set aside: \"Patients with non-missing data.\""
  ))
  expect_identical(h$checked, c(FALSE, TRUE, FALSE, FALSE, TRUE, FALSE,
                                TRUE, TRUE, FALSE, FALSE, FALSE))
  s <- hv_table_style("manuscript")
  s$font <- "Times New Roman"
  expect_identical(.house_rules(manuscript = s)$manuscript[3], "kept")
})
```

- [ ] **Step 2: Run it; it fails** (`could not find function ".house_rules"`).
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "table-styles")'`

- [ ] **Step 3: Implement.** Append to `R/hv-table-style-matrix.R`:

```r

# The house rules of "Table Construction for Manuscripts" (7/14/2026)
# that design section 6 names. A content rule binds every style; a
# hand-edit rule exists so a table edited by hand stays editable, and a
# style keeps it or sets it aside. Where a style property decides that,
# the cell is read from the style, as the matrix is. `checked` marks the
# rules hv_check_docx() checks in a saved file.
.house_rules <- function(report = hv_table_style("report"),
                         manuscript = hv_table_style("manuscript")) {
  rules <- .rule_rows()
  data.frame(
    rule = vapply(rules, function(r) r$rule, character(1)),
    says = vapply(rules, function(r) r$says, character(1)),
    kind = vapply(rules, function(r) r$kind, character(1)),
    report = vapply(rules, function(r) r$keep(report), character(1)),
    manuscript = vapply(rules, function(r) r$keep(manuscript),
                        character(1)),
    checked = vapply(rules, function(r) r$checked, logical(1)),
    stringsAsFactors = FALSE
  )
}

.hrule <- function(rule, says, kind, keep = function(s) "kept",
                   checked = FALSE) {
  list(rule = rule, says = says, kind = kind, keep = keep,
       checked = checked)
}

.rule_rows <- function() {
  rule_8 <- "Number of non-missing values."
  list(
    .hrule("2", "No blank paragraph where the table is pasted",
           "hand edit"),
    .hrule("3", "No merged cells", "hand edit", function(s) {
      if (identical(s$merged, "none")) "kept" else
        paste("set aside: merges its", s$merged)
    }, checked = TRUE),
    .hrule("5", "Times New Roman, 12 pt (11 pt for a wide table)",
           "hand edit", function(s) {
             if (identical(s$font, "Times New Roman")) return("kept")
             if (is.na(s$font))
               return("set aside: the document's body font")
             paste("set aside:", s$font)
           }),
    .hrule("8", sprintf("The count note reads \"%s\"", rule_8),
           "hand edit", function(s) {
             if (identical(s$count_note, rule_8)) "kept" else
               sprintf("set aside: \"%s\"", s$count_note)
           }),
    .hrule("13", "Notes below the table, never inside it", "content",
           checked = TRUE),
    .hrule("14", "One abbreviation key, sorted, below the notes",
           "hand edit"),
    .hrule("", "No hidden spacing columns", "content", checked = TRUE),
    .hrule("", "No floating layers (text boxes, frames)", "content",
           checked = TRUE),
    .hrule("", paste("The non-missing count is shown, and its note says",
                     "what it counts"), "content"),
    .hrule("", "Every statistic is named and every mark explained",
           "content"),
    .hrule("", "Every abbreviation in the table is defined", "content")
  )
}
```

- [ ] **Step 4: Run it; it passes.** Same command, `FAIL 0 | WARN 0 | SKIP 0`.

- [ ] **Step 5: Mutation.** Make rule 5's `keep` return `"kept"` on its first line: the test
  fails on its last expectation, then the third. Revert.

- [ ] **Step 6: Commit**

```bash
git add R/hv-table-style-matrix.R tests/testthat/test-table-styles.R
git commit -m "feat: .house_rules() says which house rules each style keeps"
```

### Task 3: A manuscript table's display takes the page's font

**Files:**
- Modify: `R/hv-man-table-display.R` (the end of `hv_man_table_display()`, and a new helper
  after it; one roxygen sentence)
- Test: `tests/testthat/test-hv-man-table-display.R` (append; it defines `dp_ft()` and
  `dp_abbr`, and `helper-fixtures.R` gives `fx_hv_tbl()`)

**Interfaces:**
- Consumes: `.table_style(ft)` (already called as `style` in `hv_man_table_display()`).
- Produces: `.document_font_html(ft)`, returning `ft` with its footer font and size unset,
  HTML class `hv-document-font` and the CSS that makes its runs inherit the page's font and
  size, every other table property unchanged. `hv_man_table_display()` calls it when
  `is.na(style$font)`.

- [ ] **Step 1: Write the failing tests** (append):

```r

test_that("a fontless style's display takes the page's font in HTML", {
  ft <- hv_man_table(fx_hv_tbl(), style = "manuscript")
  shown <- hv_man_table_display(ft)
  expect_identical(shown$properties$opts_html$extra_class,
                   "hv-document-font")
  html <- as.character(flextable::htmltools_value(shown))
  expect_match(html, "class='[^']*hv-document-font'")
  expect_match(html, paste0(".hv-document-font span { font-family: ",
                            "inherit !important;"), fixed = TRUE)
  sty <- shown$footer$styles$text
  expect_true(all(is.na(sty$font.family$data)))
  expect_true(all(is.na(sty$font.size$data)))
  # Its other properties survive: rows kept whole, the header repeated.
  expect_identical(shown$properties$opts_word, ft$properties$opts_word)
})

test_that("a report display keeps its own font, with no class", {
  shown <- hv_man_table_display(dp_ft(), abbreviations = dp_abbr)
  expect_null(shown$properties$opts_html$extra_class)
  html <- as.character(flextable::htmltools_value(shown))
  expect_false(grepl("hv-document-font", html, fixed = TRUE))
})
```

- [ ] **Step 2: Run them; the first fails** (five expectations: the class, both HTML
  matches, both footer checks; `opts_word` already matches).
  Run: `NOT_CRAN=true Rscript -e 'devtools::test(filter = "hv-man-table-display")'`

- [ ] **Step 3: Implement.** In `hv_man_table_display()`, replace

```r
  attr(ft, "hv_display") <- TRUE
  ft
}
```

  with

```r
  if (is.na(style$font)) ft <- .document_font_html(ft)
  attr(ft, "hv_display") <- TRUE
  ft
}

# A style that sets no font takes the document's (design question 5).
# In Word that is a run with no font; in HTML flextable writes the
# missing name as font-family 'NA', which no browser has, so the browser
# fell back to its own default, a serif, and a manuscript table looked
# set in the report's Times New Roman. The class makes every run of the
# table, its footer lines included, take the page's font and size. The
# table's other properties are passed back, since
# set_table_properties() resets any it is not given.
.document_font_html <- function(ft) {
  if (flextable::nrow_part(ft, "footer") > 0L) {
    ft <- flextable::font(ft, fontname = NA_character_, part = "footer")
    ft <- flextable::fontsize(ft, size = NA_real_, part = "footer")
  }
  p <- ft$properties
  flextable::set_table_properties(
    ft, layout = p$layout, width = p$width, align = p$align,
    opts_word = unclass(p$opts_word), opts_pdf = unclass(p$opts_pdf),
    opts_html = list(
      extra_class = "hv-document-font",
      extra_css = paste0(".hv-document-font span { font-family: inherit ",
                         "!important; font-size: inherit !important; }")
    )
  )
}
```

  In the roxygen, replace

```r
#' The notes follow the table's style: a manuscript table's notes begin
#' with the plain symbol and use the submissions' wording, as they do in
#' the saved file.
```

  with

```r
#' The notes follow the table's style: a manuscript table's notes begin
#' with the plain symbol and use the submissions' wording, as they do in
#' the saved file. A manuscript table sets no font, so in HTML it takes
#' the font and size of the page around it, as in Word it takes the
#' document's.
```

  Then `Rscript -e 'devtools::document()'`, which rewrites `man/hv_man_table_display.Rd`.

- [ ] **Step 4: Run them; they pass.** Same command, `FAIL 0 | WARN 0 | SKIP 0`.

- [ ] **Step 5: Mutations, each red, each reverted.**
  - Delete the `if (is.na(style$font))` line: the first test fails (four expectations).
  - Drop `opts_word = unclass(p$opts_word), ` from the call: the `opts_word` expectation
    fails (`split` comes back `TRUE`).
  - Delete the footer `font()` line: the footer font expectation fails.
  - Call `.document_font_html(ft)` for every style: the report test fails, and so does the
    existing "the footer lines take the table's font and size".

- [ ] **Step 6: Commit**

```bash
git add R/hv-man-table-display.R man/hv_man_table_display.Rd tests/testthat/test-hv-man-table-display.R
git commit -m "fix: a manuscript table's display takes the page's font in HTML"
```

### Task 4: The article, its index entry and the site

**Files:**
- Create: `vignettes/articles/table-styles.qmd`
- Modify: `_pkgdown.yml`, `.Rbuildignore`, `.gitignore`, `pkgdown/extra.css`

**Interfaces:**
- Consumes: `hvtiRtables:::.style_matrix()` (Task 1), `hvtiRtables:::.house_rules()`
  (Task 2), `hv_man_table_display()` with Task 3's fix.
- Produces: the page `articles/table-styles.html` on the site, and three downloads,
  `articles/table-styles-report.docx`, `-compare.docx` and `-describe.docx`. Task 5 links
  `https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html`.

- [ ] **Step 1: Write the article.** Create `vignettes/articles/table-styles.qmd`:

````markdown
---
title: "Table styles"
description: >
  One table drawn in each style and layout, beside the matrix of their
  properties, and the house rules each style keeps.
---

```{r, include = FALSE}
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
```

A table is drawn in a style named by its role. The report style is the
working table of an analysis report. The manuscript style is the table a
journal receives, laid out by what the table does: `"compare"` for
groups it compares, `"describe"` for cohorts or repeated measures it
describes side by side.

This page draws one table in each, then prints the matrix of what
differs. The matrix is read from `hv_table_style()` when the page is
built, so it says what the package does, not what someone remembered
to write down.

## One table

```{r setup}
library(hvtiRtables)
```

The data are `gtsummary::trial`, a simulated trial that ships with
gtsummary. Age is shown as mean±SD and the marker level as a median, so
the table also carries the mark the house standard puts on the
statistic fewer rows use (`¶`).

```{r}
tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "marker"),
                Disease = c("stage", "grade")),
  continuous = c("age", "marker"), categorical = c("stage", "grade"),
  mean_sd = "age", show_variable = FALSE
)
key <- c(SD = "standard deviation")
```

`show_variable = FALSE` leaves out the Variable column a report shows on
screen. Every saved `.docx` drops it, and each table here is drawn as it
is saved.

## The report style

```{r}
report <- hv_man_table(tbl)
hv_man_table_save(report, "table-styles-report.docx",
                  abbreviations = key)
```

```{r, echo = FALSE}
hv_man_table_display(report, abbreviations = key)
```

The saved file: [table-styles-report.docx](table-styles-report.docx).

## The manuscript style, compare

```{r}
compare <- hv_man_table(tbl, style = "manuscript")
hv_man_table_save(compare, "table-styles-compare.docx",
                  abbreviations = key,
                  caption = "Table 1. Baseline characteristics")
```

**Table 1. Baseline characteristics**

```{r, echo = FALSE}
hv_man_table_display(compare, abbreviations = key)
```

The saved file: [table-styles-compare.docx](table-styles-compare.docx).

## The manuscript style, describe

```{r}
describe <- hv_man_table(tbl, style = "manuscript", layout = "describe")
hv_man_table_save(describe, "table-styles-describe.docx",
                  abbreviations = key,
                  caption = "Table 2. The treatment arms side by side")
```

**Table 2. The treatment arms side by side**

```{r, echo = FALSE}
hv_man_table_display(describe, abbreviations = key)
```

The saved file: [table-styles-describe.docx](table-styles-describe.docx).

## What a web page cannot show

The tables above are `hv_man_table_display()`'s HTML, built from the
same code the saver uses for its marks and notes. Fill, grid, spans,
weight, alignment, marks and note wording are the saved file's. Some
of the `.docx` is Word's alone; open the saved files to see it:

- **The page.** Every style saves to US Letter, turned landscape when
  the table is wider than a portrait page.
- **The manuscript's font.** The manuscript style sets no font, so in
  Word the table takes the document's body font. Here it takes this
  page's font.
- **Rows and pages.** Row heights in twips, rows kept whole on a page,
  and the header repeated on a new page are Word's pagination.
- **Notes and caption.** Here the notes are footer lines of the table
  and the caption a bold line above it. In Word both are paragraphs,
  the caption above the table and the notes below it, in the same
  words.
- **The dark theme.** The tables are shown on white, as on paper.

## The matrix

```{r, include = FALSE}
m <- hvtiRtables:::.style_matrix()
```

The manuscript style takes two columns because its layout is an
argument of `hv_man_table()`, not a property of the style, so one style
object serves both tables. A row the same in every style is listed once,
after the matrix.

```{r, echo = FALSE}
knitr::kable(
  m[!m$shared, c("property", "report", "compare", "describe")],
  col.names = c("Property", "report", "manuscript, compare",
                "manuscript, describe"),
  row.names = FALSE
)
```

What every style shares:

```{r, echo = FALSE}
knitr::kable(m[m$shared, c("property", "report")],
             col.names = c("Property", "Every style"), row.names = FALSE)
```

The values are the house standard, which `hv_tbl_summary()` writes for
every style: P values without a leading zero (`.013`, `<.001`, `>.9`),
and the statistic fewer rows use marked on its cells, `§` on a median
among means and `¶` on a mean among medians. A journal that prints the
submitted table can change the fill:
`hv_table_style("manuscript", fill = "#A5C9EB")`.

## The house rules

*Table Construction for Manuscripts* (7/14/2026) was written for tables
edited by hand for submission. A generated table is never edited by
hand, so a rule that exists to keep a hand-edited table editable became
a style property: the report keeps it, and the manuscript keeps it or
sets it aside where the submissions did. A content rule says what a
reader needs whoever made the table, and binds every style.
`hv_check_docx()` checks the rules marked checked in any saved file.

```{r, echo = FALSE}
h <- hvtiRtables:::.house_rules()
h$checked <- ifelse(h$checked, "yes", "")
knitr::kable(h, col.names = c("Rule", "What it asks", "Kind", "report",
                              "manuscript", "Checked"),
             row.names = FALSE)
```

Each file saved above passes, checked as the style that wrote it:

```{r}
nrow(hv_check_docx("table-styles-report.docx", style = "report"))
nrow(hv_check_docx("table-styles-compare.docx", style = "manuscript"))
nrow(hv_check_docx("table-styles-describe.docx", style = "manuscript"))
```
````

  The article's prose may carry `±`, `¶` and `§` as characters; it is not under `R/`. It must
  carry no em-dash: `grep -nP '\x{2014}' vignettes/articles/table-styles.qmd` prints nothing.

- [ ] **Step 2: Index it, keep it out of the tarball and out of git's way.**
  - `_pkgdown.yml`: in `articles:`, under the "Guides" contents, after `- sas-migration`, add
    `  - articles/table-styles`.
  - `.Rbuildignore`: add the line `^vignettes/articles$`.
  - `.gitignore`: add

    ```
    /vignettes/articles/*.docx
    /vignettes/articles/*_files/
    ```

  - `pkgdown/extra.css`: append

    ```css

    /* flextable output on a page of its own: the tables set their text in
       black, so in the dark theme they need the white of the page they are
       printed on. */
    .flextable-shadow-host {
      background-color: #fff;
      color: #000;
      padding: 0.5rem;
    }
    ```

- [ ] **Step 3: Build the article; it fails until Tasks 1 to 3 are installed, then passes.**
  The article reads the installed package, so install the branch into a private library
  first (concurrent sessions overwrite the user library):

```bash
LIB=$(mktemp -d) && R CMD INSTALL -l "$LIB" . && \
  R_LIBS="$LIB" Rscript -e 'pkgdown::build_article("articles/table-styles", new_process = FALSE)'
```

  Expected: `Writing 'articles/table-styles.html'` and three `Copying
  articles/table-styles-*.docx` lines. Against an install without `.style_matrix()` it exits
  1 with a Quarto error, which is the gate CI applies.

- [ ] **Step 4: Check the index and the tarball.**

```bash
R_LIBS="$LIB" Rscript -e 'pkgdown::check_pkgdown()'
R CMD build . && tar -tzf hvtiRtables_*.tar.gz | grep -c "vignettes/articles"
```

  Expected: `No problems found.` and `0`. Delete the tarball afterwards. `git status` shows
  no `.docx` and no `_files/` under `vignettes/articles/`.

- [ ] **Step 5: Mutation.** Remove `- articles/table-styles` from `_pkgdown.yml`:
  `check_pkgdown()` reports the article missing from the index. Revert.

- [ ] **Step 6: Commit**

```bash
git add vignettes/articles/table-styles.qmd _pkgdown.yml .Rbuildignore .gitignore pkgdown/extra.css
git commit -m "docs: the Table styles article, with the matrix generated from hv_table_style()"
```

### Task 5: Links, news, gates, the dependent

**Files:**
- Modify: `R/hv-man-table.R`, `R/hv-table-style.R` (roxygen); `man/hv_man_table.Rd`,
  `man/hv_table_style.Rd` (regenerated); `README.md`
- Create: `news/feat-table-styles-article.md`

- [ ] **Step 1: Roxygen (decision 15).** In `R/hv-man-table.R`, replace

```r
#' for it. See [hv_table_style()] for the properties of each style.
```

  with

```r
#' for it. See [hv_table_style()] for the properties of each style, and
#' the [Table styles](
#' https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
#' article, which draws one table in each style and layout beside the
#' matrix of their properties and says which house rules each style
#' keeps.
```

  In `R/hv-table-style.R`, replace

```r
#' @seealso [hv_man_table()], which draws a table in a style.
```

  with

```r
#' @seealso [hv_man_table()], which draws a table in a style. The
#'   [Table styles](
#'   https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
#'   article prints every style's properties, read from this object.
```

  Then `Rscript -e 'devtools::document()'`. Expected: `hv_man_table.Rd` and
  `hv_table_style.Rd` rewritten, each carrying one `\href{https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html}{Table
  styles}` (the first inside `\details{}`).

- [ ] **Step 2: README.** After the paragraph that ends "for cohorts or repeated measures it
  describes side by side.", add:

```markdown
The [Table styles](https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html)
article draws one table in each and lists what differs.
```

- [ ] **Step 3: News fragment** `news/feat-table-styles-article.md`:

```markdown
* The package site gains a "Table styles" article: one synthetic table drawn in each style and
  layout (report; manuscript, compare; manuscript, describe), beside the matrix of their
  properties, and a table of the house rules saying which are content rules, binding every
  style, and which are hand-edit rules, and which styles keep each. The matrix is written from
  `hv_table_style()` when the site is built, so it cannot drift from the package. Each table's
  saved `.docx` is a download on the page. `?hv_man_table` and `?hv_table_style` link to it.
* `hv_man_table_display()` shows a manuscript table in the page's font and size. The manuscript
  style sets no font, and in HTML its table fell back to the browser's default font, a serif,
  so it looked set in the report's Times New Roman, while its notes were in Helvetica.
```

- [ ] **Step 4: Gates.**

```bash
NOT_CRAN=true Rscript -e 'devtools::test()'
LIB=$(mktemp -d) && R CMD INSTALL -l "$LIB" . && R_LIBS="$LIB" Rscript -e 'lintr::lint_package()'
Rscript -e 'print(tools:::.check_package_ASCII_code("."))'
EXP=$(mktemp -d) && git archive HEAD | tar -x -C "$EXP" && (cd "$EXP" && Rscript -e 'devtools::check()')
R_LIBS="$LIB" Rscript -e 'pkgdown::check_pkgdown()'
SITE=$(mktemp -d) && git archive HEAD | tar -x -C "$SITE" && \
  (cd "$SITE" && R_LIBS="$LIB" Rscript -e 'pkgdown::build_site(new_process = FALSE, install = FALSE)')
```

  Expected: `FAIL 0 | WARN 0 | SKIP 0 | PASS 1413`; 0 lints; `character(0)`; 0/0/0 with the
  manual and vignettes (apart from CRAN's "New submission" NOTE if the incoming checks run);
  `No problems found.`; the site builds with `Writing 'articles/table-styles.html'` and the
  three `.docx` copied. Then serve `"$SITE"/docs` and open `articles/table-styles.html` in a
  browser: the report table in Times New Roman with rules only; the two manuscript tables in
  the page's font with a full grid and spanning shaded sections; the matrix and the
  house-rules table; and, with the theme switched to dark, every table on white. Open one
  saved `.docx` from the page's link.

  The help pages' link answers 404 until the merge deploys the site. Run
  `urlchecker::url_check()` after that deploy, before the next release, not on the PR.

- [ ] **Step 5: The dependent.** As in Global Constraints. `dc-tables` draws report tables and
  displays them; the display change touches only fontless styles, so it should pass
  unchanged. Report the count and SKIP in the PR.

- [ ] **Step 6: Commit, run `/code-review` locally, open the PR**

```bash
git add R/hv-man-table.R R/hv-table-style.R man/hv_man_table.Rd man/hv_table_style.Rd README.md news/feat-table-styles-article.md
git commit -m "docs: hv_man_table() and hv_table_style() link the Table styles article; news"
```

  The PR body lists the decisions above for John, says that rules 2, 8 and 14's texts are
  paraphrased and asks him to check them against the memo, asks where label superscripts go
  (decision 12) and whether house rule 14 wants `A=...` (decision 7), gives the dependent's
  count, and says whether the local review stood in for Copilot.

---

## Suggested allocation for subagent-driven execution

| task | implementer | why |
|---|---|---|
| 0 | haiku, low | three text edits |
| 1, 2 | sonnet, medium | complete code and tests, verified on a scratch build; watch the escapes |
| 3 | sonnet, medium | one helper and two tests, verified in a browser |
| 4 | sonnet, medium | the article as written, plus four small config edits; the site build is the check |
| 5 | sonnet, medium | docs and gates, including the browser look |

Task reviewers on haiku at low effort, escalating to sonnet on a flag; the whole-branch review
on the most capable model.

## Self-review

- **Spec coverage.** D6: the article (Task 4) renders one synthetic table in each style and
  layout, report, compare and describe; the matrix beside them is generated from
  `hv_table_style()` (Task 1) so the two cannot drift, held by Task 1's tests; the house-rules
  table states content or hand edit and which styles keep each (Task 2, Task 4); the
  `@details` of `hv_man_table()` link to the article (Task 5). Section 5: the nineteen rows
  plus 5.1's columns row (Task 1). 5.1: describe's differences as the third column (Task 1).
  5.2: the rows the same in every style stated once (Task 1's `shared`, Task 4). Section 6:
  rules 2, 3, 5, 8, 13, 14, the hidden-column and layer bans, and the three content rules
  (Task 2). Decision 8 of the design, the standard rendered from the style object (Tasks 1
  and 4). D2, the display following the style (Task 3). Section 9's matrix-as-fixture spirit:
  the matrix's note and key cells checked against a saved `.docx` (Task 1).
- **Not covered, by design:** D7 (Phase 5); label superscripts (decision 12, in no phase).
- **Placeholders.** None: every code step carries its code, every command its expected
  output.
- **Names used across tasks:** `.style_matrix()`, `.matrix_reads()`, `.mrow()`,
  `.matrix_rows()` (Task 1); `.house_rules()`, `.hrule()`, `.rule_rows()` (Task 2);
  `.document_font_html()`, the class `hv-document-font` (Task 3); the article path
  `vignettes/articles/table-styles.qmd`, its index name `articles/table-styles`, its URL
  `https://ehrlinger.github.io/hvtiRtables/articles/table-styles.html` (Tasks 4 and 5), spelled
  the same in every task. The result columns `property`, `report`, `compare`, `describe`,
  `shared` and `rule`, `says`, `kind`, `report`, `manuscript`, `checked` are those the
  article reads.
