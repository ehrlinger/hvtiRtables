# Label superscripts and subscripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render `^…^` as a superscript and `~…~` as a subscript in every piece of
study-supplied text a table carries: labels, levels, `by` levels, section names, notes, the
abbreviation key and the caption. Add a check in `hv_check_docx()` that fails a saved file
still holding the markup.

**Architecture:** One parser, `.markup_pieces()`, in a new file `R/hv-markup.R`, serves three
seams:
1. **Table cells.** `.apply_markup(ft)` splits flextable chunks. It is the last step of each
   table builder: the report path of `hv_man_table()`, `.man_table_compare()` and
   `.man_table_describe()`.
2. **Notes and the abbreviation key.** `.expand_markup(runs)` splits runs, and is called first
   by `.runs_fpar()` and `.runs_paragraph()`.
3. **The caption.** It goes through `.runs_fpar()`.

The check is `.detect_markup()` in `hv_check_docx()`. The spec is
[2026-10-21-label-markup-design.md](2026-10-21-label-markup-design.md).

**Tech Stack:** R (>= 4.4), flextable 0.10.0, officer 0.7.6, xml2, gtsummary, testthat 3.

## Global Constraints

- Every string literal under `R/` is ASCII. A non-ASCII character is written as a `\u`
  escape. Tests may use `\u` escapes too.
- Lines are at most 80 characters (`.lintr` uses the default width). `lintr::lint_package()`
  must report 0.
- Lint against an installed copy of the branch: run `R CMD INSTALL -l <lib> .`, then
  `R_LIBS=<lib> Rscript -e 'lintr::lint_package()'`.
- Roxygen here is markdown (`Roxygen: list(markdown = TRUE)`). Write markup examples in code
  spans, such as `` `"BSA (m^2^)"` ``.
- The pair rule, verbatim from the spec: `([\^~])([^\s\^~]+)\1`, applied left to right. Pairs
  do not nest. There is no escape syntax.
- Text without markup renders exactly as before. Existing tests must pass unchanged.
- The PR does not touch `Version:` or `NEWS.md`. Its entry goes in `news/feat-label-markup.md`.
  The release (1.0.10) is a separate bump, made when John names it.
- Never `git add -A`. After a failing test run, delete `tests/testthat/_problems/` and
  `tests/testthat/testthat-problems.rds`.
- Do not use em dashes. Use US spelling.
- Every task's code below was prototyped and run against hvtiRtables 1.0.9 (main at
  `633db3e`) on 2026-10-21. The full suite passed, lint read 0, and mutations M1 to M12 in
  Task 4 each turned a test red.

## Files

| file | change | task |
|---|---|---|
| `R/hv-markup.R` | new: the pattern, `.markup_pieces()`, `.split_chunks()`, `.apply_markup()`, `.expand_markup()` | 1, 2 |
| `R/hv-man-table.R` | the report path ends in `.apply_markup(ft)`; a paragraph on markup in the docs | 1, 4 |
| `R/hv-man-table-compare.R` | `.man_table_compare()` ends in `.apply_markup(ft)` | 1 |
| `R/hv-man-table-describe.R` | `.man_table_describe()` ends in `.apply_markup(ft)` | 1 |
| `R/hv-man-table-save.R` | `.runs_fpar()`, `.runs_paragraph()`, the caption; param docs | 2, 4 |
| `R/hv-man-table-display.R` | param docs | 4 |
| `R/hv-check-docx.R` | `.detect_markup()` and its docs | 3 |
| `tests/testthat/helper-word.R` | `wx_runs()` | 1 |
| `tests/testthat/test-hv-markup.R` | new | 1, 2 |
| `tests/testthat/test-hv-check-docx.R` | the check's test | 3 |
| `vignettes/articles/table-styles.qmd` | a "Units in labels" section | 4 |
| `news/feat-label-markup.md` | new | 4 |

**Why the call goes at the end of each builder:** `hv_man_table_jtcvs()`, which is deprecated,
calls `.man_table_describe()` directly, not `hv_man_table()`. A call placed in the builders
therefore reaches it too.

**`.mark_compare()` is the wrong place.** Both manuscript layouts call it, so a call there
makes the describe builder's own call redundant, and mutation M4 cannot catch its removal.
The prototype measured exactly that.

**The header † needs no special handling.** `.mark_header()` adds it in the saver, after the
markup pass, so the two never meet in a cell. Task 2's Word test asserts that both stay
raised.

---

### Task 0: Re-measure, branch, private library

**Files:** none.

- [ ] **Step 1: Re-measure.** `git fetch origin` in `~/Documents/GitHub/hvtiRtables`. Confirm
  that `origin/main` carries this plan and that `DESCRIPTION` reads `Version: 1.0.9` or later.
  If someone has added markup handling since, stop and report.
- [ ] **Step 2: Branch.**
  `git worktree add ../hvtiRtables-markup -b feat/label-markup origin/main`. Work only there.
- [ ] **Step 3: Private library.**
  `mkdir -p <scratch>/lib && R CMD INSTALL -l <scratch>/lib .`. Use this library for every
  lint run.
- [ ] **Step 4: Baseline.**
  `NOT_CRAN=true Rscript -e 'r <- as.data.frame(devtools::test(reporter = "silent")); cat(sum(r$failed), sum(r$skipped), sum(r$passed))'`.
  Record the numbers in the ledger. Expected: 0 failures, 0 skips.

---

### Task 1: The parser and table cells

**Files:**
- Create: `R/hv-markup.R`
- Modify: `R/hv-man-table.R` (the last line of `hv_man_table()`)
- Modify: `R/hv-man-table-compare.R` (the last line of `.man_table_compare()`)
- Modify: `R/hv-man-table-describe.R` (the last line of `.man_table_describe()`)
- Modify: `tests/testthat/helper-word.R`
- Create: `tests/testthat/test-hv-markup.R`

**Interfaces:**
- Produces:
  - `.markup_pattern`, a character(1);
  - `.markup_pieces(txt)`, taking a character(1) and returning `data.frame(text, align)`, with
    `align` one of `"baseline"`, `"superscript"` or `"subscript"`;
  - `.apply_markup(ft)`, taking a flextable and returning a flextable with its attributes
    kept;
  - `wx_runs(path, has)`, a test helper.
- Task 2 adds `.expand_markup()` to the same file.

- [ ] **Step 1: Write the test helper.** Append to `tests/testthat/helper-word.R`:

```r

# The runs of the first Word paragraph whose text contains `has`, each as
# list(text, align, bold, italic). A w:b or w:i written off
# (w:val="0" or "false") is not bold or italic.
wx_runs <- function(path, has) {
  doc <- wx_doc(path)
  p <- xml2::xml_find_first(
    doc, sprintf("//w:p[contains(string(.), '%s')]", has), wx_ns
  )
  on <- function(r, tag) {
    node <- xml2::xml_find_first(r, sprintf(".//w:rPr/w:%s", tag), wx_ns)
    !inherits(node, "xml_missing") &&
      !xml2::xml_attr(node, "val") %in% c("0", "false")
  }
  lapply(xml2::xml_find_all(p, ".//w:r", wx_ns), function(r) {
    va <- xml2::xml_find_first(r, ".//w:vertAlign", wx_ns)
    list(text = xml2::xml_text(r),
         align = if (inherits(va, "xml_missing")) "baseline" else
           xml2::xml_attr(va, "val"),
         bold = on(r, "b"), italic = on(r, "i"))
  })
}
```

  It lives in the helper because `wx_ns` is defined there. A function in a test file that
  uses `wx_ns` trips `object_usage_linter`. **Read the `w:val` attribute, not just whether the
  element exists:** in the prototype a split that wrote `bold = FALSE` produced
  `<w:b w:val="false"/>`, and a presence-only check passed it.

- [ ] **Step 2: Write the failing tests.** Create `tests/testthat/test-hv-markup.R`:

```r
# Superscripts and subscripts in study-supplied text (design
# dev/specs/2026-10-21-label-markup-design.md).

# A table whose label, level, `by` levels and section carry markup.
mk_markup_tbl <- function() {
  d <- gtsummary::trial
  attr(d$age, "label") <- "BSA (m^2^)"
  levels(d$grade)[1] <- "HbA~1c~"
  d$trt <- factor(d$trt, labels = c("Arm^a^", "Arm^b^"))
  hv_tbl_summary(d, by = "trt", groups = list("Size m^2^" = c("age", "grade")),
                 continuous = "age", categorical = "grade", compare = "p")
}

# Every chunk of a part as "text:alignment".
chunk_aligns <- function(ft, part) {
  unlist(lapply(ft[[part]]$content$data, function(ch) {
    paste0(ch$txt, ":", ifelse(is.na(ch$vertical.align), "baseline",
                               ch$vertical.align))
  }))
}

test_that(".markup_pieces() follows the pair rule", {
  pieces <- function(x) {
    p <- .markup_pieces(x)
    paste0(p$text, ":", p$align)
  }
  expect_identical(pieces("cm^2^/m^2^"),
                   c("cm:baseline", "2:superscript", "/m:baseline",
                     "2:superscript"))
  expect_identical(pieces("HbA~1c~"), c("HbA:baseline", "1c:subscript"))
  expect_identical(pieces("PaO~2~ (mm Hg)"),
                   c("PaO:baseline", "2:subscript", " (mm Hg):baseline"))
  expect_identical(pieces("m^2^~a~"),
                   c("m:baseline", "2:superscript", "a:subscript"))
  # As typed: no closing marker, whitespace inside, an empty pair.
  expect_identical(pieces("~5 years"), "~5 years:baseline")
  expect_identical(pieces("x ^ y ^ z"), "x ^ y ^ z:baseline")
  expect_identical(pieces("a^^b"), "a^^b:baseline")
  expect_identical(pieces("plain"), "plain:baseline")
  expect_identical(pieces(NA_character_), "NA:baseline")
})

test_that("each table path raises and lowers label, level and header text", {
  tbl <- mk_markup_tbl()
  paths <- list(
    report = hv_man_table(tbl),
    compare = hv_man_table(tbl, style = "manuscript"),
    describe = hv_man_table(tbl, style = "manuscript", layout = "describe")
  )
  for (name in names(paths)) {
    body <- chunk_aligns(paths[[name]], "body")
    header <- chunk_aligns(paths[[name]], "header")
    expect_true("2:superscript" %in% body, info = name)
    expect_true("1c:subscript" %in% body, info = name)
    expect_true(all(c("a:superscript", "b:superscript") %in% header),
                info = name)
    expect_false(any(grepl("\\^|~", c(body, header))), info = name)
  }
})

test_that("the deprecated JTCVS table renders markup too", {
  ft <- jtcvs_quiet(hv_man_table_jtcvs(
    mk_markup_tbl(), groups = c(stat_1 = "Arm a", stat_2 = "Arm b")
  ))
  expect_true("2:superscript" %in% chunk_aligns(ft, "body"))
})

test_that("a split label keeps its row's bold in Word", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  hv_man_table_save(hv_man_table(mk_markup_tbl()), out)
  runs <- wx_runs(out, "Size m")
  expect_identical(vapply(runs, `[[`, "", "text"), c("Size m", "2"))
  expect_identical(vapply(runs, `[[`, "", "align"),
                   c("baseline", "superscript"))
  expect_true(all(vapply(runs, `[[`, TRUE, "bold")))
})

test_that("a table without markup is unchanged", {
  ft <- hv_man_table(fx_hv_tbl())
  expect_identical(.apply_markup(ft), ft)
})
```

- [ ] **Step 3: Run and see it fail.**
  `NOT_CRAN=true Rscript -e 'devtools::test(filter = "markup")'`. Expected: errors, because
  the function `.markup_pieces` could not be found.

- [ ] **Step 4: Write `R/hv-markup.R`:**

```r
# Superscripts and subscripts in study-supplied text (design
# dev/specs/2026-10-21-label-markup-design.md). A study writes
# "BSA (m^2^)" or "HbA~1c~" as plain text in a label, a level, a `by`
# level, a note, the abbreviation key or the caption, and the renderer
# raises or lowers the marked piece, as Pandoc and Quarto do.

# A pair is a marker, one or more characters with no whitespace and no
# marker, and the same marker again. Anything else prints as typed:
# "~5 years" has no closing marker, "x ^ y ^ z" has whitespace inside,
# and "a^^b" is an empty pair.
.markup_pattern <- "([\\^~])([^\\s\\^~]+)\\1"

# `txt` split into pieces: a data frame of `text` and `align`
# ("baseline", "superscript" or "subscript"), in order. Text without a
# pair comes back as one baseline piece, unchanged.
.markup_pieces <- function(txt) {
  if (is.na(txt) || !grepl(.markup_pattern, txt, perl = TRUE))
    return(data.frame(text = txt, align = "baseline",
                      stringsAsFactors = FALSE))
  m <- gregexpr(.markup_pattern, txt, perl = TRUE)[[1L]]
  starts <- as.integer(m)
  ends <- starts + attr(m, "match.length") - 1L
  text <- character(0)
  align <- character(0)
  at <- 1L
  for (k in seq_along(starts)) {
    if (starts[k] > at) {
      text <- c(text, substr(txt, at, starts[k] - 1L))
      align <- c(align, "baseline")
    }
    text <- c(text, substr(txt, starts[k] + 1L, ends[k] - 1L))
    raise <- substr(txt, starts[k], starts[k]) == "^"
    align <- c(align, if (raise) "superscript" else "subscript")
    at <- ends[k] + 1L
  }
  if (at <= nchar(txt)) {
    text <- c(text, substr(txt, at, nchar(txt)))
    align <- c(align, "baseline")
  }
  data.frame(text = text, align = align, stringsAsFactors = FALSE)
}

# One cell's flextable chunks, each chunk holding a pair split into one
# chunk per piece. A piece copies its chunk's row, so whatever the chunk
# carried (and the NA it leaves for the cell's own font, size, bold and
# color) comes along; only the text and the raised or lowered alignment
# change. Chunks already raised, such as the minority marks, hold no
# pair and are kept as they are.
.split_chunks <- function(chunks) {
  if (!any(grepl(.markup_pattern, chunks$txt, perl = TRUE))) return(chunks)
  out <- lapply(seq_len(nrow(chunks)), function(k) {
    row <- chunks[k, , drop = FALSE]
    pieces <- .markup_pieces(row$txt)
    if (nrow(pieces) == 1L) return(row)
    rows <- row[rep(1L, nrow(pieces)), , drop = FALSE]
    rows$txt <- pieces$text
    moved <- pieces$align != "baseline"
    rows$vertical.align[moved] <- pieces$align[moved]
    rows
  })
  out <- do.call(rbind, out)
  out$.chunk_index <- seq_len(nrow(out))
  rownames(out) <- NULL
  out
}

# Every cell of a flextable's header, body and footer, its markup
# rendered. The last step of each table hv_man_table() builds.
.apply_markup <- function(ft) {
  for (part in c("header", "body", "footer")) {
    data <- ft[[part]]$content$data
    if (length(data) == 0L) next
    for (cell in seq_along(data)) data[[cell]] <- .split_chunks(data[[cell]])
    ft[[part]]$content$data <- data
  }
  ft
}
```

  In flextable 0.10.0, `ft[[part]]$content$data` is a list-matrix with one chunk data frame
  per cell. A chunk leaves `font.family`, `bold` and similar as `NA` when the cell's text
  style governs them, which is why copying the row keeps the cell's formatting.

- [ ] **Step 5: Wire it into the three builders.** In each, replace the final line `ft` of the
  function with `.apply_markup(ft)`:
  - `R/hv-man-table.R`, the report path of `hv_man_table()`, just after
    `attr(ft, "hv_style") <- style`;
  - `R/hv-man-table-compare.R`, `.man_table_compare()`, just after
    `attr(ft, "hv_layout") <- "compare"`. **Not** at the end of `.mark_compare()`;
  - `R/hv-man-table-describe.R`, `.man_table_describe()`, just after
    `attr(ft, "hv_pairs") <- list(n = n_cols, stat = disp)`.

- [ ] **Step 6: Run the tests.** `NOT_CRAN=true Rscript -e 'devtools::test(filter = "markup")'`
  should pass. Then run the full suite: it should give 0 failures, with PASS equal to the Task 0
  baseline plus the new expectations.

- [ ] **Step 7: Lint.** Reinstall into the private library and run `lintr::lint_package()`
  with `R_LIBS` pointing at it. Expected: 0.

- [ ] **Step 8: Commit.**

```bash
git add R/hv-markup.R R/hv-man-table.R R/hv-man-table-compare.R R/hv-man-table-describe.R \
  tests/testthat/helper-word.R tests/testthat/test-hv-markup.R
git commit -m "feat(markup): ^...^ and ~...~ in table cells raise and lower"
```

---

### Task 2: Notes, the abbreviation key and the caption

**Files:**
- Modify: `R/hv-markup.R` (append `.expand_markup()`)
- Modify: `R/hv-man-table-save.R` (`.runs_fpar()`, `.runs_paragraph()`, and the caption in
  `.write_man_docx()`)
- Modify: `tests/testthat/test-hv-markup.R` (append)

**Interfaces:**
- Consumes `.markup_pieces()` from Task 1.
- Produces `.expand_markup(runs)`. It takes a runs data frame with columns `text`, `sup`,
  `italic` and an optional `bold`, and returns the same columns plus `sub` (logical).

- [ ] **Step 1: Write the failing tests.** Append to `tests/testthat/test-hv-markup.R`:

```r

test_that("runs without markup are unchanged", {
  runs <- .key_runs(c(SD = "standard deviation"))
  expect_identical(.expand_markup(runs)[names(runs)], runs)
})

test_that("the abbreviation key and the caption render markup in Word", {
  out <- tempfile(fileext = ".docx")
  on.exit(unlink(out), add = TRUE)
  hv_man_table_save(
    hv_man_table(mk_markup_tbl(), style = "manuscript"), out,
    abbreviations = c(BSA = "body surface area (m^2^)", "SpO~2~" = "oxygen"),
    caption = "Table 1. Size (m^2^)"
  )
  key <- wx_runs(out, "Key:")
  texts <- vapply(key, `[[`, "", "text")
  aligns <- vapply(key, `[[`, "", "align")
  expect_identical(aligns[texts == "2"], c("superscript", "subscript"))
  expect_true(key[[which(texts == "SpO")]]$italic)
  expect_true(key[[which(texts == "2" & aligns == "subscript")]]$italic)
  cap <- wx_runs(out, "Table 1.")
  expect_identical(vapply(cap, `[[`, "", "align"),
                   c("baseline", "superscript", "baseline"))
  expect_true(all(vapply(cap, `[[`, TRUE, "bold")))
  # The saver's header marks are added after the markup, and both stay
  # raised: the dagger on P, the letters on the group levels.
  header_sup <- unlist(lapply(wx_rows(wx_doc(out))[1:2], function(row) {
    vapply(row, `[[`, "", "sup")
  }))
  expect_true(any(grepl("†", header_sup)))
  expect_true(all(c("a", "b") %in% header_sup))
  expect_identical(nrow(hv_check_docx(out, style = "manuscript")), 0L)
})

test_that("the display's notes and key render markup", {
  ft <- hv_man_table_display(
    hv_man_table(mk_markup_tbl()),
    abbreviations = c(BSA = "body surface area (m^2^)",
                      "SpO~2~" = "saturation of O~2~")
  )
  footer <- chunk_aligns(ft, "footer")
  # One raised 2 (m^2^); two lowered, the italic SpO~2~ and the plain O~2~.
  expect_identical(sum(footer == "2:superscript"), 1L)
  expect_identical(sum(footer == "2:subscript"), 2L)
  expect_false(any(grepl("\\^2\\^|~2~", footer)))
})
```

  The display test needs a plain subscript as well as the italic one. With only `SpO~2~`, the
  only lowered run takes the italic branch, and mutation M11 (drawing `sub` as `as_sup`)
  survives. The prototype measured this.

- [ ] **Step 2: Run and see it fail.** Expected: `.expand_markup` not found, and the Word
  runs still hold `m^2^`.

- [ ] **Step 3: Append `.expand_markup()` to `R/hv-markup.R`:**

```r

# Note, key and caption runs (a data frame of `text`, `sup`, `italic`
# and, for the caption, `bold`), each run holding a pair split into one
# run per piece. Adds `sub`; every other column is copied from the run.
.expand_markup <- function(runs) {
  if (is.null(runs) || nrow(runs) == 0L) return(runs)
  if (is.null(runs$sub)) runs$sub <- FALSE
  out <- lapply(seq_len(nrow(runs)), function(k) {
    pieces <- .markup_pieces(runs$text[k])
    rows <- runs[rep(k, nrow(pieces)), , drop = FALSE]
    rows$text <- pieces$text
    rows$sup <- rows$sup | pieces$align == "superscript"
    rows$sub <- rows$sub | pieces$align == "subscript"
    rows
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}
```

- [ ] **Step 4: Replace `.runs_fpar()` and `.runs_paragraph()` in `R/hv-man-table-save.R`**
  with these two definitions:

```r
# Runs as a Word paragraph, in the table's font, their markup rendered.
.runs_fpar <- function(runs, font) {
  runs <- .expand_markup(runs)
  bold <- if (is.null(runs$bold)) rep(FALSE, nrow(runs)) else runs$bold
  do.call(officer::fpar, lapply(seq_len(nrow(runs)), function(k) {
    align <- if (runs$sup[k]) {
      "superscript"
    } else if (runs$sub[k]) {
      "subscript"
    } else {
      "baseline"
    }
    args <- list(font, align)
    if (runs$italic[k]) args$italic <- TRUE
    if (bold[k]) args$bold <- TRUE
    officer::ftext(runs$text[k], prop = do.call(.note_prop, args))
  }))
}

# Runs as a flextable paragraph, for a footer line, their markup
# rendered.
.runs_paragraph <- function(runs) {
  runs <- .expand_markup(runs)
  do.call(flextable::as_paragraph, lapply(seq_len(nrow(runs)), function(k) {
    if (runs$italic[k] && (runs$sup[k] || runs$sub[k])) {
      align <- if (runs$sup[k]) "superscript" else "subscript"
      flextable::as_chunk(runs$text[k], props = officer::fp_text_lite(
        italic = TRUE, vertical.align = align
      ))
    } else if (runs$sup[k]) {
      flextable::as_sup(runs$text[k])
    } else if (runs$sub[k]) {
      flextable::as_sub(runs$text[k])
    } else if (runs$italic[k]) {
      flextable::as_i(runs$text[k])
    } else {
      flextable::as_chunk(runs$text[k])
    }
  }))
}
```

  `.runs_fpar()` passes `italic` and `bold` only when they are TRUE. A run that is neither
  therefore gets the same `.note_prop()` call as before, and its XML does not change.

- [ ] **Step 5: Send the caption through the runs.** In `.write_man_docx()`, replace

```r
  if (!is.null(caption))
    doc <- officer::body_add_fpar(doc, officer::fpar(officer::ftext(
      caption, prop = .note_prop(font, bold = TRUE)
    )), style = "Normal")
```

  with

```r
  if (!is.null(caption))
    doc <- officer::body_add_fpar(doc, .runs_fpar(data.frame(
      text = caption, sup = FALSE, italic = FALSE, bold = TRUE,
      stringsAsFactors = FALSE
    ), font), style = "Normal")
```

- [ ] **Step 6: Run the tests.** The markup tests should pass. The full suite should give 0
  failures; the existing note and key tests must pass unchanged.
- [ ] **Step 7: Lint.** Reinstall and run lint; expected 0.
- [ ] **Step 8: Commit.**

```bash
git add R/hv-markup.R R/hv-man-table-save.R tests/testthat/test-hv-markup.R
git commit -m "feat(markup): notes, the abbreviation key and the caption render markup"
```

---

### Task 3: The `hv_check_docx()` guard

**Files:**
- Modify: `R/hv-check-docx.R` (`hv_check_docx()`, a new `.detect_markup()`, and the roxygen)
- Modify: `tests/testthat/test-hv-check-docx.R` (append)

**Interfaces:**
- Consumes `.markup_pattern` from Task 1.
- Produces a new finding type, `"markup"`.

- [ ] **Step 1: Write the failing test.** Append to `tests/testthat/test-hv-check-docx.R`,
  which already defines `mk_clean_docx()` and `splice_docx_xml()`:

```r

test_that("hv_check_docx detects markup left as plain text", {
  clean <- tempfile(fileext = ".docx")
  dirty <- tempfile(fileext = ".docx")
  on.exit(unlink(c(clean, dirty)), add = TRUE)
  mk_clean_docx(clean)
  expect_false("markup" %in% hv_check_docx(clean)$type)
  splice_docx_xml(clean, dirty, function(xml) {
    sub("<w:body>",
        "<w:body><w:p><w:r><w:t>BSA (m^2^)</w:t></w:r></w:p>",
        xml, fixed = TRUE)
  })
  report <- hv_check_docx(dirty)
  expect_true("markup" %in% report$type)
  expect_match(report$detail[report$type == "markup"], "BSA (m^2^)",
               fixed = TRUE)
  # Whatever the style: unrendered markup is wrong in both.
  expect_true("markup" %in% hv_check_docx(dirty, style = "report")$type)
})
```

- [ ] **Step 2: Run and see it fail.** Use `filter = "check-docx"`. Expected: "markup" is not
  among the reported types.

- [ ] **Step 3: Add the detector.** In `hv_check_docx()`, change the last two lines of the
  `rbind(` call from

```r
    .detect_merged_cell(doc, strict)
  )
```

  to

```r
    .detect_merged_cell(doc, strict),
    .detect_markup(doc)
  )
```

  and add this after the function:

```r

# The renderer turns "m^2^" and "HbA~1c~" into raised and lowered runs
# (design dev/specs/2026-10-21-label-markup-design.md). A pair still in
# the text reached Word by a path the renderer does not cover, and would
# print as typed.
.detect_markup <- function(doc) {
  paras <- xml2::xml_find_all(doc, "//w:p")
  txt <- vapply(paras, function(p) {
    paste(xml2::xml_text(xml2::xml_find_all(p, ".//w:t")), collapse = "")
  }, character(1))
  hit <- txt[grepl(.markup_pattern, txt, perl = TRUE)]
  if (length(hit) == 0L) return(.empty_report())
  .finding(
    "markup", NA_integer_, NA_character_,
    sprintf(
      paste0("%d paragraph(s) carry ^...^ or ~...~ markup as plain text ",
             "(first: \"%s\"). hv_man_table() and hv_man_table_save() ",
             "render it as a superscript or subscript; this text reached ",
             "Word another way."),
      length(hit), hit[[1L]]
    )
  )
}
```

  It reads a paragraph's text joined across its runs, so a pair that Word split over two runs
  is still found.

- [ ] **Step 4: Update the roxygen of `hv_check_docx()`.**
  - Change `#' Five detectors run:` to `#' Six detectors run:`.
  - Change `detector of the five:` (in Common mistakes) to `detector of the six:`.
  - Add this bullet after the `"merged_cell"` bullet:

```r
#' * `"markup"` (structural, high confidence): a paragraph whose text
#'   still holds `^...^` or `~...~` markup, such as `"BSA (m^2^)"`.
#'   [hv_man_table()] and [hv_man_table_save()] render it as a superscript
#'   or subscript, so markup left in the text reached Word another way,
#'   and would print as typed. Checked whatever `style` is given.
```

- [ ] **Step 5: Run `devtools::document()`,** then the tests (`filter = "check-docx|markup"`)
  and the full suite. Lint should be 0.
- [ ] **Step 6: Commit.**

```bash
git add R/hv-check-docx.R man/hv_check_docx.Rd tests/testthat/test-hv-check-docx.R
git commit -m "feat(hv_check_docx): markup left as plain text is a finding"
```

---

### Task 4: Docs, the article and the news fragment

**Files:**
- Modify: `R/hv-man-table.R`, `R/hv-man-table-save.R` and `R/hv-man-table-display.R`
  (roxygen only)
- Modify: `vignettes/articles/table-styles.qmd`
- Create: `news/feat-label-markup.md`

- [ ] **Step 1: `hv_man_table()`.** Insert this paragraph just before `#' @section Common
  mistakes:` in `R/hv-man-table.R`:

```r
#' Superscripts and subscripts are written into the text as in Pandoc:
#' a label `"BSA (m^2^)"` raises the 2 and `"HbA~1c~"` lowers the 1c, in
#' labels, levels, the `by` levels and section names alike. A pair holds no
#' whitespace, so `"~5 years"` and `"x ^ y"` print as typed. The notes, the
#' abbreviation key and the caption [hv_man_table_save()] writes take the
#' same markup.
#'
```

- [ ] **Step 2: The `abbreviations` parameter of `hv_man_table_save()`.** The paragraph ends
  `#'   empty or \`NULL\` vector is a no-op.`. Append one line to it:

```r
#'   A name or definition may carry `^2^` or `~2~` markup, as a label does.
```

  In `@param caption`, after `given and writes none otherwise.`, append:

```r
#'   It may carry `^2^` or `~2~` markup, as a label does.
```

- [ ] **Step 3: The `abbreviations` parameter of `hv_man_table_display()`.** After
  `#'   interval adds \`CI\` unless you define it.`, append:

```r
#'   A name or definition may carry `^2^` or `~2~` markup, as a label does.
```

- [ ] **Step 4: The article.** In `vignettes/articles/table-styles.qmd`, insert this section
  just before `## What a web page cannot show`:

````markdown
## Units in labels

A label, a level, a note or the caption can carry a superscript or a
subscript, written as in Pandoc: `^2^` raises the 2 and `~2~` lowers it.
The study writes plain text, in its `vars()` or its data build, and every
style sets it. A pair holds no whitespace, so `~5 years` prints as typed.

```{r}
units <- gtsummary::trial
units$bsa <- 1.6 + (units$age %% 10) / 20
attr(units$bsa, "label") <- "BSA (m^2^)"
bsa <- hv_tbl_summary(units, by = "trt", groups = list(Size = "bsa"),
                      continuous = "bsa", show_variable = FALSE)
```

```{r, echo = FALSE}
hv_man_table_display(hv_man_table(bsa, style = "manuscript"),
                     abbreviations = c(BSA = "body surface area"))
```
````

  `units$bsa` is derived from age, not drawn at random, so the article needs no
  `set.seed()`.

- [ ] **Step 5: The news fragment.** Create `news/feat-label-markup.md`:

```markdown
* Study-supplied text can carry superscripts and subscripts, written as in
  Pandoc: a label `"BSA (m^2^)"` raises the 2 and `"HbA~1c~"` lowers the 1c.
  It applies to labels, levels, the `by` levels and section names in every
  style and layout, and to the notes, the abbreviation key and the caption
  `hv_man_table_save()` writes. A pair holds no whitespace, so `"~5 years"`
  prints as typed, and text without markup is unchanged.
  `hv_check_docx()` reports any markup a saved file still holds as plain
  text, as a `"markup"` finding.
```

- [ ] **Step 6: Run `devtools::document()`.** Only `man/hv_man_table.Rd`,
  `man/hv_man_table_save.Rd` and `man/hv_man_table_display.Rd` should change, plus
  `man/hv_check_docx.Rd` if Task 3's change was not yet documented.
- [ ] **Step 7: Build the article.**
  `Rscript -e 'pkgdown::build_article("articles/table-styles", new_process = FALSE)'`, run
  with `R_LIBS` pointing at a fresh install of the branch. Open the HTML and confirm the "Units
  in labels" table shows "BSA (m²)" with a raised 2 and the key reads "BSA, body surface area".
  Do not commit `docs/`.
- [ ] **Step 8: Commit.**

```bash
git add R/hv-man-table.R R/hv-man-table-save.R R/hv-man-table-display.R man/ \
  vignettes/articles/table-styles.qmd news/feat-label-markup.md
git commit -m "docs(markup): the markup in hv_man_table, the savers and the Table styles article"
```

---

### Task 5: Gates, mutations and review

**Files:** none, unless a gate needs a fix. A fix is its own commit.

- [ ] **Step 1: Full suite** with `NOT_CRAN=true`. Expected: 0 failures, 0 skips and 0
  warnings, with PASS above the Task 0 baseline.
- [ ] **Step 2: Lint** against a fresh private install. Expected: 0.
- [ ] **Step 3: `R CMD check --as-cran`, built with the manual.** Build from a clean export:
  `git archive HEAD | tar -x -C <scratch>/src`, then `R CMD build`, then
  `R CMD check --as-cran` (no `--no-manual`).
  - Expected: 0 errors, 0 warnings and only the expected "New submission" NOTE.
  - The manual build is the gate for Rd: `^` and `~` sit in code spans, and nothing in Rd may
    be raw non-ASCII.
  - The overall check time must stay under 10 minutes.
- [ ] **Step 4: Mutations.** Apply each, run `devtools::test(filter = "markup|check-docx")`,
  confirm at least one failure, then revert. Each one was measured on the prototype:

| id | mutation | turned red on the prototype |
|---|---|---|
| M1 | pattern `[^\\s\\^~]+` becomes `[^\\^~]+` (whitespace allowed) | parser test |
| M2 | report path ends in `ft`, not `.apply_markup(ft)` | the three-path test |
| M3 | `.man_table_compare()` ends in `ft` | the three-path test |
| M4 | `.man_table_describe()` ends in `ft` | the three-path and JTCVS tests |
| M5 | `.split_chunks()` adds `rows$bold <- FALSE` | the bold-in-Word test |
| M6 | `.runs_fpar()` skips `.expand_markup()` (sets `runs$sub <- FALSE`) | the key and caption test |
| M7 | `.runs_paragraph()` skips `.expand_markup()` | the display test |
| M8 | the caption's `bold = TRUE` becomes `FALSE` | the key and caption test |
| M9 | `.detect_markup(doc)` is dropped from the `rbind()` | the check-docx test |
| M10 | `raise` compares to `"~"`, not `"^"` | the parser and three-path tests |
| M11 | `.runs_paragraph()` draws `sub` with `as_sup()` | the display test |
| M12 | `.expand_markup()` adds `rows$italic <- FALSE` | the key and caption test |

- [ ] **Step 5: Look at the output.** Save one manuscript table with markup in a label, a
  level, a group level, a definition and the caption. Convert it with
  `soffice --headless --convert-to pdf` and look at the page, checking that each piece is
  raised or lowered and the grid is unchanged.
- [ ] **Step 6: Final review.** Run a whole-branch review: the Opus final reviewer, or
  `/code-review` when run inline. Fix its findings in one commit.
- [ ] **Step 7: Open the PR** against `main`, with Auto-fix on. The body should state:
  - the decisions (spec section 2);
  - the gate results;
  - the mutation table;
  - that a local review stood in for Copilot if its quota notice appears.

## Self-review

- **Spec coverage.**
  - Section 3, the rule: Task 1 parser test.
  - Section 4.1, cells: Task 1, every path, JTCVS included.
  - Section 4.2, runs: Task 2.
  - Section 4.3, caption: Task 2.
  - Section 5, guard: Task 3.
  - Section 6, tests: Tasks 1 to 3, plus the no-change tests in Tasks 1 and 2.
  - Section 7, docs and release: Task 4. The release is not part of this PR.
- **Departure from the spec.** Section 6 lists "a header † mark still raised beside a raised
  label piece" as a cell test. In the code the † is added by the saver, after the markup
  pass, so they never share a cell at `hv_man_table()` time. The check moved to the saved
  file, in Task 2's Word test.
- **Departure from the spec.** Section 4.1 says `.apply_markup()` runs "as the last step of
  each path" in `hv_man_table()`. It runs at the end of each builder instead, which is what
  covers `hv_man_table_jtcvs()`.
