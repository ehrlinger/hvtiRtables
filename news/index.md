# Changelog

## hvtiRtables 1.0.9

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  no longer fails when the calling session defines an object named `sd`
  or `median`. gtsummary turns each statistic in `{mean}±{sd}` or
  `{median} [{p15}, {p85}]` into a function by looking its name up from
  where
  [`tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
  was called, and from inside a package that lookup reaches the global
  environment before `package:stats`, so a study whose `R/` folder
  defined `sd` (as hvtiRtemplates jobs source it into the global
  environment) got “Value must be a named list of functions” whenever a
  row showed mean±SD or a median. The call now runs from an environment
  holding [`stats::sd`](https://rdrr.io/r/stats/sd.html) and
  [`stats::median`](https://rdrr.io/r/stats/median.html) and then only
  base, so nothing a user defines can shadow a statistic. Present in
  1.0.7 and 1.0.8.

## hvtiRtables 1.0.8

- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  always drop the “Variable” column
  `hv_tbl_summary(show_variable = TRUE)` adds, before fitting the page,
  so a saved table is always a manuscript table and its width and
  orientation are the manuscript table’s.
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
  keep it for the report view; `show_variable` stays `TRUE` by default
  and no longer needs setting to `FALSE` for a manuscript.
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
  whose table is always a manuscript table, no longer shows it.

- Tables follow the house notation standard
  (dev/specs/2026-10-17-table-styles-design.md, section 5.2). **Existing
  tables change:**

  - Medians are shown in brackets, each number to 2 significant digits
    and a value of 10 or more to the units place: `102 [63, 170]`,
    `0.31 [0.21, 0.39]`. The statistic note reads “Median \[15th, 85th
    percentiles\]”.
  - P values drop the leading zero: `.013`, `<.001`, `>.9`.
  - A table mixing medians and means marks the cells of whichever
    statistic fewer rows use, a section sign on medians and a pilcrow on
    means, with a note for each; the row-label suffixes (“Age, Mean±SD”)
    and the “No. (%) or as labeled” note are gone.
  - Mean ± SD is unchanged: `63±13`, unspaced, EHB paired rounding.
  - Exact ties in a median or percentile round to even, as for mean +/-
    SD: 62.5 shows as 62, where gtsummary and SAS showed 63.
  - In
    [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
    the mark is a lettered superscript `b` with its own note, so the
    test footnotes letter from `c` (they were `b`, `c`).
  - Passing `footnotes = hv_man_footnotes()` explicitly on a mixed table
    now errors unless the footnotes carry the mark’s note. `§` and `¶`
    are reserved on mixed tables; use `||` for a study note.

- Tables are drawn in a style named by its role
  (dev/specs/2026-10-17-table-styles-design.md).
  [`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
  holds a style’s properties; `hv_man_table(style =)` takes `"report"`
  (the default, today’s table) or `"manuscript"`.

  - The manuscript style lays out a comparison table as the submissions
    did: a full grid, a two-row header with the grouping spanning its
    levels, one overall `n` column, shaded section rows spanning the
    table, a bold header and caption, 300-twip rows kept whole, and no
    font of its own, so it takes the document’s body font. Its notes
    begin with the plain symbol: `*Patients with non-missing data.`,
    `†Values are No. (%) or median [15th, 85th percentiles].`
  - [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
    takes `caption`, written bold above the table: the manuscript style
    requires it, and a report may give one.
  - [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
    carries each variable’s overall non-missing count and the grouping’s
    name for the manuscript header.
  - [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
    shows the notes in the table’s style, so a manuscript table’s notes
    begin with the plain symbol there as they do in the saved file.
  - The SAS glossary maps `STYLE=` to `style =` (CORR family only) and
    `TBLTITLE=` to `caption =`.
  - The manuscript style refuses what it cannot lay out, each with an
    error that says what to do instead: `font` and `font_size` (it sets
    no font), `continuous_stat = "both"` in the compare layout (one
    statistic per group; the describe layout draws it), and a table not
    built by
    [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
    (it reads the overall count and the grouping’s name that function
    records).
  - The manuscript’s label column is 2.0 in wide, so a Table 1 with
    Overall, two groups and a P value is 6.5 in and stays on a portrait
    Letter page.
  - [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
    checks merged cells: by default merges only in header rows and in
    section rows that span the table, and none at all with
    `style = "report"`.
  - [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
    section rows now span the table in one cell; they were a label
    beside one merged blank cell.
  - **Existing tables change:** the report shades its section rows
    (`#CAEDFB` by default, every cell, unmerged), its header is now bold
    throughout (the `N = n` lines and the marks were not), and both
    savers write US Letter pages instead of A4, so a wide table now fits
    a 9.0 in landscape text block instead of 9.7 in.

- [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  no longer carries gtsummary’s own footnotes inside the table. A saved
  table with `compare = "pvalue"` (or `"smd"` or `"both"`) ended in a
  footer row reading “1Wilcoxon rank sum test; Pearson’s Chi-squared
  test”, with a raised digit on the p-value header, and
  `compare = "both"` added an “Abbreviation: CI = Confidence Interval”
  row: house rule 13 puts notes below the table. **Existing tables
  change:**

  - The dagger note now names the tests behind the p-values (“… Median
    \[15th, 85th percentiles\]; P values from the Wilcoxon rank sum test
    and Pearson’s chi-square test.”), and the dagger marks the p-value
    header as well as the statistic headers. Fisher’s exact test keeps
    its own double dagger and is not repeated. A table with no p-values
    has no test sentence. The manuscript style says it in its own words,
    “Values are … median \[15th, 85th percentiles\]; P values from the
    …”, and marks its comparison header the same way.
  - `compare = "smd"` and `"both"` head the difference column “Std.
    Diff.” (gtsummary’s “Difference” was explained only by the footnote
    now gone), and the dagger note says “Std. Diff. is the standardized
    mean difference, with its 95% CI.” (the manuscript style: “Std.
    Diff.” or, under `"both"`, “SMD”, without the CI it does not show).
    The dagger marks that header.
  - A table showing a confidence interval (`compare = "both"`) defines
    `CI` in the key, beside any `abbreviations` you pass (your own
    definition of `CI` wins).

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  flags a last-row cell that opens with a superscript number, the form
  gtsummary writes a footnote in, and one that starts “Abbreviation:”.
  It returned no findings for the tables above.

- The manuscript style gains its second layout, `"describe"`, for tables
  that describe cohorts or repeated measures side by side
  (dev/specs/2026-10-17-table-styles-design.md, section 5.1):
  `hv_man_table(tbl, style = "manuscript", layout = "describe")`. Each
  group spans its own count and statistic, so every group has its count,
  and an Overall column and comparison columns appear when the table
  carries them. Everything else is the comparison layout’s: the full
  grid, shaded section rows spanning the table, a bold header, notes
  that begin with the plain symbol, no font of its own, and US Letter
  pages. The describe layout draws `continuous_stat = "both"`, which the
  compare layout refuses. `layout = "compare"` is the default, and the
  report style takes no `layout`.

  - [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)’s
    `layout` argument follows `style`, so a call passing every argument
    by position reaches `...` at the seventh, not the sixth. A named SAS
    argument such as `%summarytable`’s `STYLE=` is caught by its name at
    any position; only an unnamed extra argument is reported at position
    7.
  - Describe’s marks follow the notation standard: `*` on each group’s
    `n` and `†` on each statistic, with
    `*Patients with non-missing data.` and the dagger note below the
    table, and `hv_man_table_save(ft, file, caption = )` writes the
    caption above it.
  - [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
    shows a describe table; it refused one before.

- **Deprecated:**
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  and
  [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  warn on every call and go in the next release. Until then their
  arguments keep their meaning: `groups` and `trailing` choose the same
  columns, and `stat_label` names the statistic.

  - **Their output changes:** the table is drawn in the describe layout,
    with the same columns as before but the manuscript’s grid, shading,
    notes (`*Patients with non-missing data.` for
    `a. Patients with data available.`) and the document’s font.
  - [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
    writes `caption` above the table and the table’s own notes below it,
    as
    [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
    does, and keeps `abbreviations`. It drops a test footnote that
    [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
    wrote when the table already names that test, as an
    [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
    table does in its dagger note and with Fisher’s mark on its P
    values. Every other positional `footnotes` entry keeps a lettered
    superscript on its cells, lettered from `a`, with its line after the
    table’s own notes; the unnamed test notes of a plain gtsummary table
    stay lettered the same way.
  - Given a flextable that is not a describe table,
    [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
    now writes that table’s default notes and header marks; it used to
    write only the lettered notes.
  - Move to
    `hv_man_table(tbl, style = "manuscript", layout = "describe")` and
    `hv_man_table_save(ft, file, caption = )`; the test notes then come
    from the table.

- The package site gains a “Table styles” article: one synthetic table
  drawn in each style and layout (report; manuscript, compare;
  manuscript, describe), beside the matrix of their properties, and a
  table of the house rules saying which are content rules, binding every
  style, and which are hand-edit rules, and which styles keep each. The
  matrix is written from
  [`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
  when the site is built, so it is read from the style objects, not
  copied by hand. Each table’s saved `.docx` is a download on the page.
  [`?hv_man_table`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`?hv_table_style`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
  link to it.

- The site keeps flextable tables on white in its dark theme
  (`pkgdown/extra.css`), as they appear in Word, reference examples
  included.

- [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
  shows a manuscript table in the page’s font and size. The manuscript
  style sets no font, and in HTML its table fell back to the browser’s
  default font, a serif, so it looked set in the report’s Times New
  Roman, while its notes were in Helvetica.

## hvtiRtables 1.0.7

- New
  [`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)
  adds to a flextable from
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  what
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  writes around it in Word, so a report shows the same table in HTML:
  the asterisk and dagger header marks, the footnotes and the
  abbreviation key, the last two as footer lines. It shares that code
  with the saver, so the two cannot disagree. Both savers refuse its
  result, whose notes are rows inside the table.

## hvtiRtables 1.0.6

- The README’s Installation section now leads with `hvtiR::install()`,
  which installs the whole HVTI R family in one call, and then gives
  `pak::pak("ehrlinger/hvtiRtables")` for this package alone.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  gains `mean_sd`, the continuous variables to *show* as mean±SD while
  keeping the Wilcoxon or Kruskal-Wallis test. `normal` still couples
  mean±SD to one-way ANOVA and is unchanged.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  gains `show_variable`, on by default: a “Variable” column beside the
  label holds each variable’s column name, as `%summarytable`’s report
  did.
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  both show it. **Existing tables gain this column**; pass
  `show_variable = FALSE` for a manuscript.

- New
  [`hv_tbl_compare()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_compare.md)
  adds a comparison column you computed yourself, one value on each
  variable’s first row, rightmost in the table. It is how
  `hvtiRpropensity::ps_stddiff()`’s `%stddiff` standardized difference
  reaches a table, beside `compare = "pvalue"`, without hvtiRtables
  depending on hvtiRpropensity. `compare = "smd"` is unchanged; its help
  now says it is gtsummary’s generic SMD, not `%stddiff`’s.

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)’s
  `trailing` now takes several columns, laid out in order. Its error for
  a malformed `trailing` no longer says “of length 1”.

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  gains `cutexact`. The default, `"any"`, keeps the rule used until now:
  Fisher’s exact test when any cell expects fewer than 5, so categorical
  p-values are unchanged. A number opts in to `%summarytable`’s
  `CUTEXACT=` rule to reproduce a SAS table (`cutexact = 50` is the
  macro’s default). In the CORR table each Fisher p-value now carries a
  superscript double dagger, footnoted “Fisher exact test.”;
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  stops if given `footnotes` that leave that mark unexplained or file
  another note under it.

- `continuous_stat = "both"` now shows mean±SD and the median side by
  side, in a median column beside each group’s statistic column, instead
  of stacked sub-rows. Both renderers lay it out the same way. **This
  changes existing “both” tables**: the statistic columns and their
  dagger now read “No. (%) or Mean±SD”, the median column names itself
  in its header, and a two-group “both” table now saves in landscape.

- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  save a table wider than a portrait page on a landscape page, and
  narrow its columns in proportion when it is wider than landscape too,
  so the label and rightmost columns are never clipped. A two-group
  “both” CORR table with an Overall column measured 13 inches and lost
  both on a landscape page.

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  gains a fourth detector, `"wide_table"`: a table wider than its page’s
  text block, which Word clips.

- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  letters only the p-value column
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  writes. It no longer falls back to another trailing column, which
  footnoted a joined standardized difference “Fisher exact test.”

## hvtiRtables 1.0.5

- The Word tables from
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now match the SAS `%summarytable` layout, after a review of two
  commented example tables:
  - [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
    writes categorical cells as `12 (39)`, without the `%` sign. The
    `(%)` is stated once, in the JTCVS sub-header or the CORR dagger
    footnote.
  - [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
    puts each section (“Demography”) on its own bold row in the
    Characteristic column, above its first variable. Before, the
    sections filled an extra column headed `groupname_col`. The
    Characteristic column is now left-justified.
  - The CORR dagger now marks each statistic column instead of the first
    `No.` column. Its text now covers both kinds of row, for example
    “No. (%) or Median (15th, 85th percentile).”
    [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
    returns the same wording.
  - [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
    takes its statistic sub-header from the table (`stat_label = NULL`).
    The fixed `"No. (%) or Mean±SD"` default labeled median tables as
    mean and SD.
  - In the JTCVS table, “Characteristic” spans both header rows instead
    of printing twice, and the section rows are no longer shaded blue.
    Each `n` sub-header carries a superscript `a`, which
    [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
    explains first with “a. Patients with data available.” The `a` used
    to print as plain text, `na`. Footnotes you pass now start at `b`.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  has a `normal` argument, the macro’s `CON1=`: list continuous
  variables in it as well as in `continuous`, and each is shown as
  mean±SD and tested with one-way ANOVA. Every other continuous variable
  keeps the `continuous_stat` summary and its non-parametric test. When
  one table shows both mean and median rows, each continuous row names
  its own statistic (“Age, Mean±SD”), as the macro’s `DESCLABEL=1` did.
  The header and the dagger then read “No. (%) or as labeled”.
  [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  footnotes the ANOVA as “One-way analysis of variance.”
- [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  writes a table with three or more statistic columns, such as an
  Overall column and two groups, on a landscape page. In portrait, Word
  clipped its right edge.
- The footnotes and `Key:` line under a table, and the JTCVS caption
  above it, are now set in the table’s own font (Times New Roman by
  default). They used the Word template’s default font.

## hvtiRtables 1.0.4

- The vignettes are Quarto documents now, not R Markdown, like the rest
  of the HVTI family. `VignetteBuilder` is `quarto`, and building them
  needs the Quarto CLI. The text and code are unchanged.

- The pkgdown site’s articles put the table of contents on the left and
  use the full width of the window, through `pkgdown/extra.css`.

- Now requires R 4.4.0 or newer, up from 4.1.0, to match the rest of the
  HVTI family. `hvtiR::install()` installs the members together, and
  several already required 4.4.0, so on an older R the install failed
  whatever this package declared.

- `DESCRIPTION` now declares the Quarto command line tool in
  `SystemRequirements`. The vignettes have always needed it to build;
  the field makes that visible to installers and to `R CMD check`.

- **`hv_tbl_summary(compare = "pvalue")` and `compare = "both"` now stop
  with an error when ‘broom’ is not installed**, instead of returning a
  table with every p-value blank.
  [`gtsummary::add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)
  runs its Wilcoxon test through ‘cardx’, which needs ‘broom’; without
  it gtsummary only warned, and
  [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  then returned [`list()`](https://rdrr.io/r/base/list.html) because no
  test was recorded. The HVTI Recipes book published blank p-values for
  a week this way. ‘broom’ stays in `Suggests`, so `compare = "smd"` and
  `"none"` still work without it.

- `testthat` in `Suggests` is now `>= 3.1.7`, the first release with
  `local_mocked_bindings()`, which the test for the ‘broom’ guard uses.

## hvtiRtables 1.0.3

- **The em dashes in `R/` documentation are gone.** Six sat in roxygen
  blocks, and `man/` is generated from those blocks, so they reached
  readers in the rendered help pages. A seventh sat in an ordinary code
  comment. Replacements vary by sentence: parentheses around an aside, a
  period between two independent clauses, and a verb where the dash
  stood in for one. The released headings below are left as written. No
  behavior changed.

## hvtiRtables 1.0.2

- **[`hv_correlation_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_correlation_table.md)
  now de-duplicates repeated `method` values.** Each stratum/pair/method
  combination appears once, while the caller’s method order is
  preserved.

## hvtiRtables 1.0.1

- **New
  [`hv_correlation_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_correlation_table.md)**
  ports the SAS correlation job
  (`proc corr spearman pearson fisher(biasadj=no alpha=.32)`): pairwise
  coefficients with Fisher intervals, a 68% interval by default,
  pairwise deletion, and a `by` stratum. It backs the `dc-tables` job
  template.
- **Mean±SD cells now enforce EHB/Blackstone paired rounding.**
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  rounds each mean to the SD’s first-significant-digit place and the SD
  one place finer, retaining an extra place in both when the SD begins
  with 1. Exact ties round to even. The rule applies to grouped and
  Overall columns under `continuous_stat = "mean"` and to the mean row
  under `"both"`; median/percentile rows are unchanged.
- **The JTCVS renderer’s default mean label now follows house spacing.**
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  writes `"No. (%) or Mean±SD"`, matching
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  and the CORR footnote text.
- **CORR footnotes now follow the continuous statistic automatically.**
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  accepts `continuous_stat` and `percentiles`, and an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  table carries the matching footnote through
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  into
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)’s
  default. Mean tables no longer receive a median dagger, `"both"` names
  both statistics, and custom percentile pairs no longer leave the
  default footnote stale. Custom values use correct ordinal suffixes,
  including the 11th-13th exceptions. Hand-built flextables retain the
  median/15th-85th house default.
- **[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)’s
  N column now counts non-missing values.** It was built from
  gtsummary’s `{N_obs}`, which counts every row, so any variable with
  missing data reported the full row count under a footnote reading
  “Number of non-missing values.” It now uses `{N_nonmiss}`, matching
  the house rule and the `%summarytable` tables it replaces. Tables
  built with earlier versions overstate n wherever a variable has
  missing values and should be rebuilt. The `{N_obs} ||| {stat}`
  examples in the renderer documentation, the README, and the convention
  error message now use `{N_nonmiss}` too.
- **[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  gains `continuous_stat`.** `"median"` (default) keeps
  `median (P<low>, P<high>)`; `"mean"` gives mean +/- SD, written
  `64±12` without spaces per the house table rules; `"both"` puts the
  two on sub-rows under each continuous variable, with n shown once, so
  the choice for the manuscript is a deleted row. The test is the same
  non-parametric one whichever is shown. `hv_stat_label` follows the
  choice. Defaults taken from Rajes’s `%summarytable` tables.
- **[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)’s
  `overall` now defaults to `TRUE`**, matching the macro’s `TOTALCOL=1`
  and the stratified tables it replaces. With `by = NULL` it is ignored
  rather than an error.
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  shows the new Overall column automatically;
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  shows it only when `groups` names `stat_0`, so existing JTCVS calls
  render as before until you add it. Pass `overall = FALSE` for the old
  layout.

## hvtiRtables 1.0.0

First supported release. The package is now the HVTI CORR group’s table
interface rather than a working draft: the two manuscript renderers, the
`%summarytable` migration path, and the checks that keep a written
`.docx` inside house rules are all in place and covered.

What the 1.0.0 claim means in practice:

- **Both house styles are complete and symmetric where they should be.**
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  both consume
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  output, and the places the two families genuinely differ - `caption`
  on the JTCVS saver only, the two footnote shapes - are documented as
  differences rather than papered over.
- **The SAS interface is documented from the macro side.**
  [`vignette("sas-migration")`](https://ehrlinger.github.io/hvtiRtables/articles/sas-migration.md)
  ports a `%summarytable` program end to end, including the defaults
  that differ and the `QNTLDEF=5` / `quantile(type = 2)` trap.
- **Macro parameter names teach.** Passing `class=`, `con1=` or
  `tbltitle=` to any public function errors with the R argument and the
  function that takes it, resolved against the caller’s CORR/JTCVS
  family.
- **The `dc` prefix formally belongs here.** `hvtiRtemplates`’
  allocation map assigns the `dc.*` descriptive-table macro family to
  this package, so the `%summarytable` port has a governing decision
  behind it rather than a precedent.

No API changes since 0.9.7. This release is the claim of support, not
new behavior.

## hvtiRtables 0.9.7

### New features

- [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  now accepts an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  table. It splits each `"{N_obs} ||| {stat}"` cell into a flat `No.`
  column immediately before the statistic it counts — the same two
  values the JTCVS renderer puts under a merged spanning header, without
  the merge. Previously the separator rendered literally into the Word
  table (`98 ||| 46 (32, 63)`), so the SAS-macro interface was usable
  only in JTCVS mode. The count is kept rather than discarded because
  house rule 8 requires it and
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  ships a `*` footnote describing it. A plain
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
  table carries no such convention and passes through unchanged.
- A table where only *some* cells carry the convention is now rejected,
  through the same assertion the JTCVS renderer uses. Splitting it would
  have left the rest blank.

### Bug fixes

- The house footnote symbols now attach to the count column when the
  table has one. With the split above, a sectioned table’s first column
  is `groupname_col`, so the marker would otherwise have landed on the
  section-label column.
- A CORR table missing the `"{N_obs} ||| {stat}"` convention now raises
  an error naming
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md),
  not
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).
  The internal assertion the two renderers share previously hardcoded
  the JTCVS renderer’s name in its message.

## hvtiRtables 0.9.6

### New features

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  gains `overall =`, the `%summarytable` `TOTALCOL=` equivalent, adding
  an Overall column across all groups. Defaults to `FALSE`; the macro’s
  own default is `TOTALCOL=1`.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md),
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now error on a `%summarytable` parameter name, naming the R argument
  and the function that takes it, rather than silently ignoring it.
- New vignette, “Porting a `%summarytable` program to R”.

### Documentation

- The README’s migration table stated that `CON1=` maps to `continuous`.
  It does not: `CON1=` was mean +/- SD with ANOVA, and `continuous`
  reproduces `CON3=`. Corrected.

### Bug fixes

- `binary` variables now pass an explicit event value to `gtsummary`
  instead of letting it infer one. Its inference is type-sensitive in a
  way that hit the SAS import path: a `haven_labelled` column over a
  *double* base type – what
  [`haven::read_sas()`](https://haven.tidyverse.org/reference/read_sas.html)
  produces, since every SAS numeric is an 8-byte float – failed with
  `Summary type is "dichotomous" but no summary value has been assigned.`,
  while the otherwise-identical integer-backed column worked. The event
  is the `TRUE`, `1`, or `Yes` side in every accepted encoding.

## hvtiRtables 0.9.5

### Breaking changes

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now enforces `font_size` of 11 or 12, the same house rule
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  has always enforced. Calls passing any other value, or a vector, now
  error.
- `abbreviations` must be a character vector, as documented. A list
  previously worked by accident.

### Bug fixes

- `abbreviations` and `footnotes` are now type-checked before the
  empty-value shortcut. An empty value previously skipped the type check
  entirely, so `abbreviations = list()` was accepted while
  `abbreviations = list(N = "x")` errored. `NULL` and `character(0)`
  remain no-ops for `abbreviations`; `NULL` and
  [`list()`](https://rdrr.io/r/base/list.html) for `footnotes`.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now errors when `tbl` was not built with the `{N_obs} ||| {stat}`
  statistic convention. It previously rendered a complete, correctly
  styled, entirely empty table.
- Both savers now enforce one footnote-text contract, through shared
  code.
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  errors when a footnote entry has no `text`;
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  now does the same for its `symbol -> text` list, which previously
  *wrote* the `.docx` for `list("*" = NULL)` (header marked
  `Characteristic*`, a footnote paragraph of `"* "`), and equally for
  `NA` (`"* NA"`), a number (`"* 1"`), and a length-2 vector
  (`"* a* b"`). The two savers’ messages share the contract sentence but
  no longer share one fixed label or fix: each names the bad entry the
  way its own caller would look for it (`footnotes[["*"]]` for
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
  `footnotes[[k]]$text` for
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md))
  instead of a shared, list-position label that made a CORR caller count
  entries to find their symbol.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now enforces its documented “exactly one type bucket” contract instead
  of failing inside `gtsummary`.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now checks each variable’s data against the bucket it was put in, not
  just that the buckets don’t overlap. A non-numeric variable in
  `continuous` previously produced `"{N} ||| NA (NA, NA)"` cells, which
  satisfy the `|||` convention check because the convention genuinely is
  applied and only the statistic is `NA` — so the table rendered and
  saved as a complete, correctly styled, all-`NA` manuscript table off
  nothing but `gtsummary` *messages*. `binary` now requires at most two
  distinct non-missing values AND a form `gtsummary` can dichotomize
  (logical, `0`/`1`, `Yes`/`No`), which is what removes the leaked
  “Summary type is "dichotomous" but no summary value has been
  assigned.” error. A column with no non-missing values is rejected in
  any bucket. `categorical` keeps no type rule.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  validates `groups` names against `tbl$table_body`, replacing a base-R
  `non-character argument` error.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now rejects a `groups` name given twice, replacing `flextable`’s
  `duplicated col_keys: n_stat_1, disp_stat_1` — internal column names
  the caller never wrote.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now rejects a `groups` section holding no variables
  (e.g. `list(Demo = character(0))`, plausible when `groups` is built
  from a filter that returns nothing).
  [`list()`](https://rdrr.io/r/base/list.html) was already caught; a
  named-but-empty section leaked the base-R “`names` must be `NULL` or a
  character vector, not an empty integer vector.”.
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  validates `file`, replacing a base-R
  `a character vector argument expected` error.
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now checks each `footnotes` entry is a list before reading its fields.
  Dropping the outer nesting (`footnotes = list(row =, col =, text =)`),
  or passing a bare string, leaked
  `$ operator is invalid for atomic vectors`.
- A footnote entry with no `col` now reports what arrived and lists
  `ft`’s columns. The message previously ended at a bare colon with
  nothing after it.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  validates `by` in the package’s own vocabulary.
- Every validation message’s `Received:` clause now names the class even
  when the value is not length 1. The clause exists for the
  argument-order slip, where the class mismatch is the tell, but it
  reported a bare `a vector of length 8` for a 200-row data frame (8
  columns) and `a vector of length 5` for a `gtsummary` table — losing
  exactly the diagnostic it was written for. Those now read
  `tbl_df of length 8` and `tbl_summary of length 5`.
- The `binary` bucket error no longer always says “Recode to 0/1”, which
  was impossible advice for a constant column (already 0/1, with no
  event to recode — the fix is moving it to `categorical`) and for a
  factor whose only problem is an unused level (the fix is
  [`droplevels()`](https://rdrr.io/r/base/droplevels.html)). Every other
  case keeps the “Recode to 0/1” fix.

### Documentation

- New
  [`?hvtiRtables`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  package topic explaining which rendering mode to use, with both
  pipelines end to end.
- New vignette walking a complete JTCVS table from data frame to checked
  `.docx`.
- Every function’s help now states its arguments’ accepted values
  exhaustively and carries a “Common mistakes” section.

## hvtiRtables 0.9.4

### New features

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  reads a written `.docx` and reports the three constructs the CORR
  manuscript table rules prohibit, returning one row per finding and
  zero rows when the file is clean: floating layers (`w:framePr`
  paragraphs, `w:txbxContent` text boxes), hidden spacer columns (a
  column both entirely empty and under 0.1 inch wide), and footnotes
  written as a row inside the table rather than as text below it. The
  first two are structural and high confidence; the third is a
  marker-prefix heuristic, so read it as a prompt to look rather than as
  proof. It reads the file rather than the object that produced it, so
  it catches violations introduced anywhere in the pipeline, including
  by a hand edit after the fact.
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  do not call it — run it on the path yourself when you want the check.

### Bug fixes

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now checks up front that `compare = "smd"` or `"both"` is used with
  exactly two groups, and errors naming `by` and the group count if not.
  [`gtsummary::add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  requires two groups and previously failed three different ways, none
  naming anything the caller wrote: it threw an internal message about
  `tbl_summary(by)` for a genuine 3+ group variable and for a single
  group, and, when `by` was a factor carrying an unused level, did not
  error at all but returned `estimate` as `NA`, silently rendering an
  empty comparison column. That last case now errors too, with a hint
  pointing at [`droplevels()`](https://rdrr.io/r/base/droplevels.html).
  `compare = "pvalue"` and `"none"` are unaffected and still work at any
  number of groups.

## hvtiRtables 0.9.3

### New features

- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md):
  builds the lettered p-value footnotes the SAS `%summarytable` macro
  emits, reading `gtsummary`’s `test_name` column off an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  result and returning the list
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  already accepts. Letters follow a fixed order (Wilcoxon,
  Kruskal-Wallis, chi-square, Fisher), filtered to the tests used, so
  two tables using the same tests agree. ANOVA never appears, since this
  package tests continuous variables non-parametrically throughout.

### Bug fixes

- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now validates each footnote’s `row` and `col` against the table being
  rendered. A row index computed against a different object previously
  marked the wrong cell silently.

## hvtiRtables 0.9.2

### Bug fixes

- `hv_tbl_summary(compare = "both")` reported a wrong standardized mean
  difference.
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  ran after
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html),
  and in that order `gtsummary` overwrites the `estimate` column with a
  raw mean difference for continuous variables and leaves it `NA` for
  binary and categorical ones. A table could render `0.7 (SMD -1.0)`
  where the true SMD was -0.03, under a column header saying SMD, and
  categorical variables showed no SMD at all. The two calls are now
  ordered
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  then
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html),
  which reproduces
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)’s
  own output exactly for continuous, binary, and categorical variables
  alike. `compare = "pvalue"`, `"smd"`, and `"none"` are unaffected,
  since none of them runs both calls.

  The same reordering preserves
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)’s
  `test_name` column, which
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  had been overwriting with `"smd"`.

## hvtiRtables 0.9.1

### New features

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md):
  a thin wrapper over
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
  /
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)
  /
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  modeled on the interface biostats team members already know from the
  `%summarytable` SAS macro — a grouped, ordered variable list and
  variable-type buckets (`continuous`/`binary`/`categorical`), rather
  than gtsummary’s own tidyselect interface. Always uses a blanket
  non-parametric test for continuous variables (no per-variable Gaussian
  classification) and reports `median (P15, P85)` by default, matching
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)’s
  house convention. `compare` adds a p-value, standardized mean
  difference, or both, as a trailing column. Returns a plain `gtsummary`
  object ready for
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).
  See the README’s “Migrating from the `%summarytable` SAS macro”
  section for a parameter-mapping table and worked example.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  gains a `stat_label` parameter so callers whose statistic is a median,
  not a mean, can set an accurate sub-header —
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  sets this automatically.

## hvtiRtables 0.9.0

### New features

- Initial release.
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  converts a `gtsummary` table object into a flextable complying with
  HVTI CORR’s “Table Construction for Manuscripts” rules (flat header,
  no merged cells, house font/rounding rules).
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  writes it to a `.docx` with footnotes and an abbreviation key as text
  below the table.
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  supplies the house-universal N and median/percentile footnotes used as
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)’s
  default.
- JTCVS submission mode:
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  builds a merged-header `flextable` (spanning group headers,
  N/statistic column pairs) matching the JTCVS journal submission
  template, and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  writes it to a `.docx` with a bold `Table N. Caption` paragraph and
  lettered (`a.`, `b.`, …) footnotes targeted to specific body cells.
  Section-header rows are bold with `#CAEDFB` shading and column widths
  are set explicitly, matching the canonical “Table Construction for
  Manuscripts” house example and avoiding the header/number wrapping
  `flextable`’s default column sizing produced.

### Bug fixes

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)’s
  `trailing` argument is now validated: a name absent from
  `tbl$table_body`, an unnamed value, or a value of length other than 1
  now raises a clear error instead of either silently dropping the
  column or failing later with an unrelated internal error.
