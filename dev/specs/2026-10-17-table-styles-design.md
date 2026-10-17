# Table styles: one renderer, three named styles (design)

Date: 2026-10-17
Status: draft for John's review. Decisions taken on 2026-10-17 are in section 2; the open
questions in section 10 need an answer before an implementation plan.

This note is self-contained. It assumes no memory of the session that produced it.

## 1. Problem

The goal is that **nobody ever hand-edits a manuscript table**. A table that leaves the
package must already be the table the journal gets.

There are three table looks in use today, and the package names two of them after their
first users rather than after what they look like:

- `hv_man_table()` and `hv_man_table_save()`: the CORR look, used for analysis reports.
- `hv_man_table_jtcvs()` and `hv_man_table_save_jtcvs()`: the JTCVS look.
- The look of the tables in the AVSD morphology manuscript (ms.1264, submitted to
  *Circulation* in October 2026), which no function produces. Its tables were finished by
  hand, and two hand-edit inconsistencies survive in the submitted file (section 4).

Naming each look after a journal does not scale: a second journal that wants the JTCVS
look would need a third copy of it, and a journal that changes its rules would rename a
look that has not changed.

## 2. Decisions taken, 2026-10-17

1. **Three named styles**, named for what they look like, not for a journal. A journal is
   a choice of style. The JTCVS functions are a temporary name for one of them.
2. **Reports keep the CORR look, with the Variable column.** Manuscript exports use a
   manuscript style and **never** carry variable names (the savers drop the column; see
   hvtiRtables `feat/savers-drop-variable`, in progress).
3. **The ms.1264 look becomes a named style** beside the other two.
4. **Section-row shading goes into all three styles.**
5. **The differences are documented clearly.** The matrix in section 5 is the definition
   of the styles, and the package gains an article that renders one table in each style
   beside it (section 8, D6).
6. **Some house rules exist because tables were edited by hand,** to make a hand-edited
   table look right, not because of their content. Once tables are generated, those rules
   are open to change style by style (section 6).

## 3. The three styles

Working names, chosen for the look (question 1 in section 10):

| style | today | used for | defining trait |
|---|---|---|---|
| `"report"` | `hv_man_table()` | analysis reports | horizontal rules only, one flat header row, a count column per group, the Variable column |
| `"spanned"` | `hv_man_table_jtcvs()` | JTCVS submissions | each group spans its own (n, statistic) pair, lettered notes, statistic named in the header |
| `"grid"` | none | ms.1264; manuscripts in that look | full grid, one overall `n*` column, `GROUP†` spanning the groups, bracketed percentiles |

## 4. Evidence

Measured on 2026-10-17 from the Word XML of three files: Table 1 of
`ms.1264.avsd_morphology.circulation.complete.final20261016.docx` (Tables 2, S2 and S6
share its layout); and the same synthetic table saved with hvtiRtables 1.0.7's
`hv_man_table_save()` and `hv_man_table_save_jtcvs()`. The manuscript is unpublished and
is **not** committed; this note records its properties only.

Two inconsistencies in the submitted manuscript show hand editing: the header reads
`B (N = 94)` beside `F(N=114)`, and the cells read `30(42)` under a note that says
`No. (%)`. A generated table would carry one form throughout.

## 5. The style matrix

This table **is** the specification. Each row is a property the renderer sets, and every
style has a value. Rows marked † change what an existing style produces today.

| # | property | `"report"` (CORR) | `"spanned"` (JTCVS) | `"grid"` (ms.1264) |
|---|---|---|---|---|
| 1 | Section row | label in the first cell, bold, left; **fill #CAEDFB on every cell of the row**, unmerged † | spans the full width, bold, left; **fill #CAEDFB** † | spans the full width, bold, centered; fill #CAEDFB |
| 2 | Borders | horizontal rules only | horizontal rules only | full grid: box plus all inner lines, single 0.5 pt |
| 3 | Header | one row; `No.*`, then `<group> N = n†` per group | two rows; each group spans its (n, statistic) pair; row 2 names the statistic | two rows; `Characteristic` and `n*` merged down; `GROUP†` spans the groups; row 2 `<group> (N = n)` |
| 4 | Non-missing count | one column per group | one column per group | **one overall `n*` column** (needs `hv_tbl_summary()`, section 7) |
| 5 | Group header text | `A N = 44†` | `A (n = 44)` | `A (N = 44)` |
| 6 | Continuous values | `10.35 (8.11, 12.74)`: parentheses, 2 decimals | as `"report"` | `9.9 [8.5, 11]`: square brackets, each number to 2 significant digits (section 7) |
| 7 | Categorical values | `3 (6.8)` | `3 (6.8)` | `30 (42)`; the manuscript's `30(42)` is a hand edit (section 4) |
| 8 | Note markers | `*`, `†`, `‡` superscript | lettered `a.`, `b.` | `*`, `†` at the start of the note, not superscript |
| 9 | Count note | `Number of non-missing values.` (house rule 8) | `Patients with data available.` | `Patients with non-missing data.` (question 3) |
| 10 | Statistic note | `No. (%) or Median (15th, 85th percentile).` | named in the header row | `Values are No. (%) or median [15th, 85th percentiles].` |
| 11 | Abbreviations | `Key: A=…; B=…` (house rule 14) | its own key | `Key: A=…; B=…` |
| 12 | Font | Times New Roman 12 pt (house rule 5) | Times New Roman 12 pt | the document's body font, 11 pt (question 5) |
| 13 | Caption | none | above the table, plain | `Table 1. …`, bold, above the table |
| 14 | Alignment and weight | header bold; first column left, others centered | everything left; header plain | first column left, others centered; only `GROUP†` bold |
| 15 | Row height | auto, about 600 twips | 360 twips | 300 twips, rows kept on one page |
| 16 | Header repeated on a new page | yes | yes | yes (the manuscript lacks it; the generated style adds it) |
| 17 | Page | A4 landscape † | A4 landscape † | **US Letter** landscape, 1 in margins (question 4) |
| 18 | Variable column | shown (`show_variable = TRUE`) | never | never |
| 19 | Merged cells | none (house rule 3) | header and section rows | header and section rows (sections 6 and 10, question 2) |

## 6. Which house rules still bind

The house rules (`Table Construction for Manuscripts.docx`, 7/14/2026) mix two kinds of
rule. Generating tables removes the reason for one kind and not the other.

**Rules about content.** These say what a reader is told, so they bind every style:

- Rule 8: the count column and its exact note wording.
- Rule 14: the abbreviation key, sorted, with its separators.
- The notes say which statistic each cell holds, and every mark in the table is explained.

**Rules that exist because tables were edited by hand.** These keep a hand-edited table
manageable or make it *look* right after editing, not what it says:

- Rule 3: no merged cells. Merged cells are hard to edit and break when a row is added by
  hand. A generated table is never edited, and `"spanned"` already merges.
- Rule 2: where a table is pasted into the manuscript, a concern of the paste-in workflow.
- No hidden spacing columns, floating layers, or footnotes inside the table: constructs
  that SAS RTF output used to reach a look, and that an editor could not see or reach.
- Possibly rule 5 (Times New Roman 11 or 12 pt): to confirm (question 5).

Proposal: content rules hold in every style. Hand-edit rules hold in `"report"`, which is
read and sometimes edited as a working document, and each manuscript style may set them
aside where the journal's look needs it. `hv_check_docx()` keeps checking the constructs
that hide content (layers, hidden columns, embedded footnotes) in every style, since those
are content problems for a reader whatever produced the table. John to confirm which rules
are which (question 2).

## 7. Changes outside the renderer

Three rows of the matrix cannot be met by a renderer alone:

- **Overall non-missing count (row 4).** `hv_tbl_summary()` computes one count per group;
  `"grid"` shows one across all groups. Proposal: `hv_tbl_summary()` always carries both
  counts in its table body, and the style picks which to show.
- **Significant-digit rounding (row 6).** Each median and percentile is shown to 2
  significant digits (`0.31 [0.21, 0.39]`, `11 [9.3, 12]`, `3.0 [2.1, 4.4]`). The EHB
  paired rule covers mean ± SD only. Formatting happens in `hv_tbl_summary()` today, so a
  style property for digits means re-formatting from the raw statistics at render time.
  gtsummary keeps those in the table's cards, so that is possible. A design question for
  the plan, not for this note.
- **Labels with units and superscripts.** `LAVV area (cm²/m²)` comes from the variable's
  label, which the study sets (its `vars()` or the data build). The renderer will turn a
  `^2^` markup in a label into a superscript, so a label can carry it as plain text.

## 8. Deliverables

- **D1. A style object.** `hv_table_style(name)` returns the properties of section 5 for
  one of the three names. A future journal is a new name or a variant of an existing one,
  not a new function.
- **D2. One renderer and one saver.** `hv_man_table(tbl, style = "report")` and
  `hv_man_table_save(ft, file, ...)`. The flextable carries its style, so the saver writes
  that style's notes, caption and page without being told again.
  `hv_man_table_display()` follows the style too.
- **D3. The JTCVS functions become wrappers** for `style = "spanned"`, deprecated over one
  release with a message naming the replacement. No other hvtiR package calls them
  (checked 2026-10-17 across hvtiRtemplates, hvtiRutilities and hvtiPlotR).
- **D4. Section shading in all three styles.** In `"report"` the fill goes on every cell
  of the section row and nothing is merged, so rule 3 holds there. In the two styles that
  span, the spanned cell is filled.
- **D5. `hv_tbl_summary()`**: the overall count beside the per-group ones, and whatever
  the rounding design needs (section 7).
- **D6. Documentation of the differences.** A pkgdown article, "Table styles", renders one
  synthetic table in each of the three styles beside the matrix of section 5, so a reader
  sees each difference. The article's matrix is generated from `hv_table_style()`, not
  written by hand, so the two cannot drift. It also states, for each house rule, whether it
  is a content rule or a hand-edit rule and which styles keep it (section 6). The
  `@details` of `hv_man_table()` link to the article.
- **D7. hvtiRtemplates.** `dc-tables`' report stays `"report"` with the Variable column. Its
  Word export takes a `MANUSCRIPT_STYLE` study choice (`"grid"` or `"spanned"`). A later
  PR, after the hvtiRtables release.

## 9. Testing

- For each style, a structural test reads the saved `.docx` XML and asserts every row of
  the matrix: fills, spans, borders, header rows, the count column, cell text patterns,
  notes, font, caption, row height, header repeat and page size. The matrix is the
  fixture.
- A synthetic replica of ms.1264 Table 1's shape (five groups, four sections, continuous
  and binary rows, missing values), saved in `"grid"`, must match the manuscript's measured
  properties in section 5, apart from the two hand-edit inconsistencies.
- `hv_check_docx()` passes on all three, with its merged-cell expectation set per style
  (section 6).
- Existing CORR and JTCVS tests keep passing through the wrappers, apart from rows marked
  † in section 5, whose expectations change on purpose and are listed in the PR.

## 10. Open questions

1. **Names.** `"report"`, `"spanned"` and `"grid"` describe the look. The alternative,
   naming by role (`"report"`, `"journal"`, …), breaks as soon as two journals differ.
2. **Which house rules are hand-edit rules.** Section 6 sorts rules 2 and 3 and the hidden
   constructs as hand-edit rules, and rules 8 and 14 as content. Is that right, and is
   anything else in the house rules document a hand-edit rule?
3. **Count-note wording.** `"grid"` uses the manuscript's `Patients with non-missing data.`
   while `"report"` keeps rule 8's `Number of non-missing values.`? Or one wording for all?
4. **Page size.** US Letter for every style, or only `"grid"`? Both savers write A4 today.
5. **Font.** Is rule 5 (Times New Roman, 11 or 12 pt) a content rule or a look? `"grid"`
   follows the document's body font at 11 pt, as the manuscript does.
6. **Shading color.** `#CAEDFB` for every style, or a property each style can set?

## 11. Out of scope

- The other general shapes in ms.1264: the cross-tabulation with a two-level header (S5),
  and the sectioned or banded lists (S1, S3, S4). Each is a template of its own, later.
- Weighted summaries (hvtiRtables#76, parked).

## 12. Versioning

The work lands as patch bumps. Consolidating it into a minor release is John's call; a
renderer API built around styles would be a natural point for one.
