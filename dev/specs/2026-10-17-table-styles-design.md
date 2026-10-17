# Table styles: one renderer, styles named by role (design)

Date: 2026-10-17
Status: draft for John's review. Decisions taken on 2026-10-17 are in section 2; question 4 in
section 10 needs an answer before an implementation plan.

This note is self-contained. It assumes no memory of the session that produced it.

## 1. Problem

The goal is that **nobody ever hand-edits a manuscript table**. A table that leaves the
package must already be the table the journal gets.

The package has two renderers today, named after their first users rather than their role:

- `hv_man_table()` and `hv_man_table_save()`: the CORR look, used for analysis reports.
- `hv_man_table_jtcvs()` and `hv_man_table_save_jtcvs()`: a JTCVS look, built in July 2026
  from a JTCVS template document.

Neither produces the tables the group actually submits. Two submissions measured on
2026-10-17, to two journals, share one look that no function produces (section 4). Both were
finished by hand, and both carry hand-edit errors as a result.

## 2. Decisions taken, 2026-10-17

1. **Styles are named by role,** not by journal and not by look. A journal is a choice of
   style, and a style's properties can vary where journals differ (the fill color does,
   section 4).
2. **Reports keep the CORR look, with the Variable column on screen.** Every saved `.docx`
   drops the Variable column (hvtiRtables#82), so a manuscript export never carries variable
   names.
3. **The submitted look becomes the `"manuscript"` style.**
4. **Section-row shading goes into every style.**
5. **The differences are documented clearly.** The matrix in section 5 is the definition of
   the styles, and the package gains an article that renders one table in each style beside
   it (section 8, D6).
6. **`hv_man_table_jtcvs()` and `hv_man_table_save_jtcvs()` are deprecated in favor of
   `"manuscript"`.** Neither submission uses their look, including the JTCVS one.
7. **The house rules were built for editing tables by hand for submission.** A generated
   table meets their purpose by construction, so each becomes a style property; what binds
   every style is the content beneath them (section 6).

## 3. The styles

| style | role | today | defining trait |
|---|---|---|---|
| `"report"` | the analysis report, read on screen | `hv_man_table()` | horizontal rules only, one flat header row, a count column per group, the Variable column on screen |
| `"manuscript"` | tables a journal receives, main text and supplement | none | full grid, one overall `n*` column, the grouping spanning its levels, full-width shaded section rows, bracketed percentiles |
| *(the JTCVS renderer's look)* | none: **deprecated** 2026-10-17 | `hv_man_table_jtcvs()` | each group spans its own (n, statistic) pair, lettered notes. Neither submission uses it |

## 4. Evidence

Measured on 2026-10-17 from the Word XML of four files:

- **ms.1264**, `ms.1264.avsd_morphology.circulation.complete.final20261016.docx`, to be
  submitted to *Circulation*: Tables 1, 2, S2 and S6 (characteristics by group).
- **BVR rv3**, `ms.rv3.jtcvs.biventricular_repair.current.docx`, a JTCVS revision: Tables 1
  and E4 (characteristics by cluster), and Tables 2 and 3 (risk factors).
- The same synthetic table saved with hvtiRtables 1.0.7's `hv_man_table_save()` and
  `hv_man_table_save_jtcvs()`.

- **CAA proof**, `ViewPageProof_YMTC_20718.pdf`, the JTCVS page proof of the coronary artery
  aneurysm paper (Alshneikat et al., 16 October 2026): Tables 1 to 4 as the journal typeset
  them.

Neither manuscript is published, and none of the files is committed; this note records their
measured properties only.

**A typesetting journal discards the submitted styling.** JTCVS re-set every table in its own
style: horizontal rules, no grid, its own font, and **whole section blocks** (the heading and
its rows) shaded in alternating bands, not only the heading row. So for a journal that
typesets, borders, fills and fonts in the submitted file do not reach the reader; content and
structure do. What survived typesetting in the proof:

- one `N*` column (patients with data available), an Overall column beside the groups, and a
  `P†` column with no leading zero (`.013`, `<.001`, `>.9`);
- mean ± SD by default, with skewed variables shown as `102 [63, 170]‡`, the median marked per
  cell (hvtiRtables' `mean_sd` plus a mark);
- the notes, as the authors wrote them (JTCVS kept the wording): `Data: n (%) or mean ± SD.`, the abbreviations, `*Patients with data
  available.`, `†Wilcoxon rank sum; Pearson's chi-square; Fisher exact.`, `‡Median [15th, 85th
  percentiles].`

The proof is itself inconsistent: Table 1 writes percentiles in brackets and Tables 3 and 4 in
parentheses, so a journal does not repair hand-made tables either.

**What this means for `"manuscript"`.** Its first job is content and structure: the overall
`N*` column, the Overall column, the P column and its format, the per-cell mark for medians,
and notes that name the statistics and tests. Those survive any journal. Its visual
properties (grid, fill, font) matter for journals that print the submitted table, for
reviewers, and for co-authors reading the draft, and are properties a journal's choice can
set.

**The two submissions share one look across two journals.** Both have a full single-line
grid; a two-row header with `Characteristic` and `n*` merged down and the grouping
(`GROUP†`, `Cluster†`) spanning its levels; full-width shaded section rows; one overall `n*`
column; `median [P15, P85]`; US Letter pages; and the document's 11 pt body font. **What
differs between them is the fill color** (`#CAEDFB` in ms.1264, `#A5C9EB` in BVR rv3) and
details that are hand edits.

**Hand-edit errors in the submitted files.** These are what a generated table removes:

- BVR rv3 Table 1's note reads "median [15th, **18th** percentiles]", a typo for 85th.
- The bracket spacing differs between the papers: `9.9 [8.5, 11]` in ms.1264 against
  `8.6[7.7, 9.3]` in BVR rv3.
- The count-in-percent spacing differs too: `30(42)` in ms.1264 under a note saying
  `No. (%)`, and `65 (49)` in BVR rv3.
- ms.1264's header reads `B (N = 94)` beside `F(N=114)` in one row.
- The count note differs: "Patients with non-missing data." (ms.1264) against "Patients with
  data available." (BVR rv3).

## 5. The style matrix

This table **is** the specification. Each row is a property the renderer sets. Rows
marked † change what an existing renderer produces today. The JTCVS column records today's
renderer, which is deprecated (D3); it is kept here so the article can show what changes.

| # | property | `"report"` | `"manuscript"` | JTCVS renderer today |
|---|---|---|---|---|
| 1 | Section row | label in the first cell, bold, left; **fill on every cell of the row**, unmerged † | spans the full width, bold; fill | spans the full width, bold, left; no fill |
| 2 | Fill color | `#CAEDFB` by default | **a property:** `#CAEDFB` (ms.1264), `#A5C9EB` (BVR rv3) | none |
| 3 | Borders | horizontal rules only | full grid: box plus all inner lines, single 0.5 pt | horizontal rules only |
| 4 | Header | one row; `No.*`, then `<group> N = n†` per group | two rows: `Characteristic` and `n*` merged down, the grouping label with † spanning its levels; row 2 `<level> (N = n)` | two rows; each group spans its (n, statistic) pair |
| 5 | Non-missing count | one column per group | **one overall `n*` column** (needs `hv_tbl_summary()`, section 7) | one column per group |
| 6 | Continuous values | `10.35 (8.11, 12.74)`: parentheses, 2 decimals | `9.9 [8.5, 11]`: brackets, a space before them, each number to 2 significant digits (section 7) | as `"report"` |
| 7 | Categorical values | `3 (6.8)` | `30 (42)` | `3 (6.8)` |
| 8 | Note markers | `*`, `†`, `‡` superscript | `*`, `†` at the start of the note, not superscript | lettered `a.`, `b.` |
| 9 | Count note | `Number of non-missing values.` (house rule 8) | `Patients with non-missing data.` | `Patients with data available.` |
| 10 | Statistic note | `No. (%) or Median (15th, 85th percentile).` | `Values are No. (%) or median [15th, 85th percentiles].` | named in the header row |
| 11 | Abbreviations | `Key: A=…; B=…` (house rule 14) | `Key: A=…; B=…` | its own key |
| 12 | Font | Times New Roman 12 pt (house rule 5) | none set: the document's body font (11 pt in the submissions) | Times New Roman 12 pt |
| 13 | Caption | none | `Table 1. …`, bold, above the table | above the table, plain |
| 14 | Alignment and weight | header bold; first column left, others centered | first column left, others centered | everything left; header plain |
| 15 | Row height | auto, about 600 twips | 300 twips, rows kept on one page | 360 twips |
| 16 | Header repeated on a new page | yes | yes (neither submission has it; the generated style adds it) | yes |
| 17 | Page | A4 landscape † | **US Letter**, landscape when wide, else portrait (question 4) | A4 landscape |
| 18 | Variable column | on screen only; every saved `.docx` drops it (hvtiRtables#82) | never | never |
| 19 | Merged cells | none (house rule 3) | header and section rows (section 6) | header and section rows |

## 6. Which house rules still bind

**Answered 2026-10-17: the house rules (`Table Construction for Manuscripts.docx`, 7/14/2026)
were, in general, built because of problems editing tables for submission.** No merged cells
(rule 3), where a table is pasted (rule 2), the font (rule 5), the exact count wording
(rule 8), the abbreviation key's format (rule 14), and the bans on hidden spacing columns,
floating layers and footnotes inside the table all exist so that a table someone edits by hand
stays editable and comes out looking right.

A generated table is never edited by hand, so it meets the purpose of those rules by
construction, and each rule becomes a style property rather than a constraint on every style.
`"report"` keeps today's values, since it is read and sometimes edited as a working document.
`"manuscript"` takes the values the submissions use where they differ (merged header and
section cells, the document's body font, Letter pages).

**What still binds every style is the content beneath the rules**, which a reader needs
whoever made the table:

- the non-missing count is shown, and its note says what it counts;
- every cell's statistic is named, and every mark in the table is explained;
- abbreviations used in the table are defined.

`hv_check_docx()` keeps checking, in every style, the constructs that hide content from a
reader (floating layers, hidden columns, footnotes inside the table), since those are content
problems whatever produced the file.

## 7. Changes outside the renderer

Three rows of the matrix cannot be met by a renderer alone:

- **Overall non-missing count (row 5).** `hv_tbl_summary()` computes one count per group;
  `"manuscript"` shows one across all groups. Proposal: `hv_tbl_summary()` always carries
  both counts in its table body, and the style picks which to show.
- **Significant-digit rounding (row 6).** Each median and percentile is shown to 2
  significant digits (`0.31 [0.21, 0.39]`, `11 [9.3, 12]`, `8.6 [7.7, 9.3]`). The EHB paired
  rule covers mean ± SD only. Formatting happens in `hv_tbl_summary()` today, so a style
  property for digits means re-formatting from the raw statistics at render time. gtsummary
  keeps those in the table's cards, so that is possible. A design question for the plan.
- **Labels with units and superscripts.** `LAVV area (cm²/m²)` comes from the variable's
  label, which the study sets (its `vars()` or the data build). The renderer will turn a
  `^2^` markup in a label into a superscript, so a label can carry it as plain text. Both
  submissions have them (18 in ms.1264 Table 1, 13 in BVR rv3 Table 1).

## 8. Deliverables

- **D1. A style object.** `hv_table_style(name, ...)` returns the properties of section 5
  for a role, with overrides for the properties journals vary (the fill color first).
- **D2. One renderer and one saver.** `hv_man_table(tbl, style = "report")` and
  `hv_man_table_save(ft, file, ...)`. The flextable carries its style, so the saver writes
  that style's notes, caption and page without being told again.
  `hv_man_table_display()` follows the style too.
- **D3. Deprecate the JTCVS functions.** `hv_man_table_jtcvs()`,
  `hv_man_table_save_jtcvs()` and `hv_test_footnotes_jtcvs()` keep working for one release
  with a deprecation message naming `hv_man_table(style = "manuscript")`, then go. No other
  hvtiR package calls them (checked 2026-10-17 across hvtiRtemplates, hvtiRutilities and
  hvtiPlotR). Their tests move to the `"manuscript"` style where a behavior carries over
  (multiple trailing columns, letters only on the p-value column) and are retired where it
  does not (lettered notes).
- **D4. Section shading in every style.** In `"report"` the fill goes on every cell of the
  section row and nothing is merged, so rule 3 holds there. In `"manuscript"` the spanned
  cell is filled.
- **D5. `hv_tbl_summary()`**: the overall count beside the per-group ones, and whatever the
  rounding design needs (section 7).
- **D6. Documentation of the differences.** A pkgdown article, "Table styles", renders one
  synthetic table in each style beside the matrix of section 5, so a reader sees each
  difference. The article's matrix is generated from `hv_table_style()`, not written by
  hand, so the two cannot drift. It also states, for each house rule, whether it is a
  content rule or a hand-edit rule and which styles keep it (section 6). The `@details` of
  `hv_man_table()` link to the article.
- **D7. hvtiRtemplates.** `dc-tables`' report stays `"report"`, with the Variable column on
  screen. Its Word export takes `"manuscript"`, with the fill color as a study choice. A
  later PR, after the hvtiRtables release.

## 9. Testing

- For each style, a structural test reads the saved `.docx` XML and asserts every row of the
  matrix: fills, spans, borders, header rows, the count column, cell text patterns, notes,
  font, caption, row height, header repeat and page size. The matrix is the fixture.
- Synthetic replicas of ms.1264 Table 1 and BVR rv3 Table 1 (their shapes, not their data),
  saved in `"manuscript"` with each paper's fill color, must match the measured properties
  in sections 4 and 5, apart from the hand-edit errors listed in section 4.
- `hv_check_docx()` passes on every style, with its merged-cell expectation set per style
  (section 6).
- Existing CORR and JTCVS tests keep passing, apart from rows marked † in section 5, whose
  expectations change on purpose and are listed in the PR.

## 10. Questions

All answered on 2026-10-17 except question 4.

1. **Names.** By role. The JTCVS renderer, whose look neither submission uses, is deprecated
   in favor of `"manuscript"` (decision 6, D3).
2. **Which house rules exist only for hand editing.** In general, all of them were built
   because of problems editing tables for submission (section 6). They become style
   properties; the content beneath them binds every style.
3. **Count-note wording for `"manuscript"`.** "Patients with non-missing data." The documents
   disagreed (ms.1264 said this; BVR rv3 and the CAA paper said "Patients with data
   available."), and those were authors' choices, not journal requirements. `"report"` keeps
   rule 8's "Number of non-missing values."
4. **Page size. Open.** US Letter for every style, or only `"manuscript"`? Both savers write
   A4 today; every submission measured is on Letter.
5. **Font for `"manuscript"`.** Follow the document's body font: `"manuscript"` sets no font
   on the table, so it takes the font and size of the document it is saved into, as the
   submissions do.
6. **Shading color.** A style property, since the submissions differ (`#CAEDFB`, `#A5C9EB`).
   Default `#CAEDFB`.
7. **Shading section rows or section blocks.** The heading rows. A journal that typesets
   applies its own shading (JTCVS shaded whole sections in alternating bands), and the package
   does not imitate it.
8. **Mixed statistics in one table.** Add the per-cell mark. In `"manuscript"`, when a table
   shows mean ± SD by default and some variables as medians (`hv_tbl_summary(mean_sd =)`),
   each median cell carries a mark, `102 [63, 170]‡`, and the notes gain `‡Median [15th, 85th
   percentiles].`, with the percentiles the table uses. The default statistic is named once,
   in a `Data:` note.

## 11. Out of scope

Other general table shapes that appear in **both** submissions, each a template of its own
later:

- **Risk-factor tables** from a hazard model (BVR rv3 Tables 2 and 3): sections per stratum,
  phase sub-headings (early, late hazard phase), `Coefficient±SE`, `P` without a leading
  zero, and bootstrap reliability (%), with notes for transformations ("After inverse squared
  transformation."). The natural home is the `hm` and `bh` templates.
- **Cross-tabulations** with a two- or three-row header (ms.1264 S5, BVR rv3 E5).
- **Sectioned single-column lists** of observations and measurements (ms.1264 S3 and S4, BVR
  rv3 E2 and E3), and **banded lists** (ms.1264 S1 and BVR rv3 E1, participating
  institutions, alternating `#A5C9EB` and `#DAE9F7` in BVR rv3).
- Weighted summaries (hvtiRtables#76, parked).

## 12. Versioning

The work lands as patch bumps. Consolidating it into a minor release is John's call; a
renderer API built around styles would be a natural point for one.
