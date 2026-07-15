# JTCVS manuscript table format + table repair — design

Date: 2026-07-15
Status: approved, pending implementation plan

## Problem

Penny's manuscript tables are hand copy-pasted into Word templates rather than
generated from analysis output. Others use a SAS table macro instead, which
creates downstream problems for editorial staff (Tess/Ingrid). `hvtiRtables`
already has a CORR-house-rule table generator (`manuscript_flextable()`,
flat/non-merged headers) but that does not match the format editorial
actually needs for JTCVS submission, which was previously unverified.

Reference material obtained this session: `template_jtcvs_consolidated.docx`
(Tess's JTCVS template, consolidated with real worked example tables from
published papers — mitral valve re-replacement and Trifecta/PERIMOUNT
comparison tables).

## Finding: header format diverges from current package behavior

`manuscript_flextable()` deliberately flattens headers per the CORR "Table
Construction for Manuscripts" rule (see roxygen doc in
`R/manuscript-flextable.R`): single non-merged header row, via
`flextable::merge_none()`.

Tess's actual JTCVS example tables use **2-row merged spanning headers**:
a group-name row that spans multiple sub-columns (e.g. `Non-Isolated
Re-Replacement (n=392)` spanning 2 columns), over a sub-header row (`na` /
`No. (%) or Mean ± SD`, or `P` / `Std. Diff.` for a trailing comparison
column).

Decision: build for what actually gets published. The JTCVS format is a
**separate mode**, not a replacement of the existing flat-header behavior —
`manuscript_flextable()` may still be the right shape for internal CORR
review tables; that usage is not being touched.

## Component 1 — JTCVS merged-header table function

- New exported function (name TBD, e.g. `jtcvs_flextable()`), added
  alongside `manuscript_flextable()` in `hvtiRtables`. Existing function and
  its callers are unchanged.
- Input: a `gtsummary` table object, plus a way to declare the grouping
  structure needed to build the spanning header (exact signature TBD at
  planning time — needs to be worked out against how `gtsummary::tbl_merge()`
  / comparison tables expose group boundaries).
- Header structure is **hard-coded to match the template**, not derived by
  parsing the template `.docx` at runtime. Rationale: gtsummary input shapes
  vary (2 groups vs. more, with/without a trailing Std. Diff./P column), and
  the template only shows a fixed handful of examples — runtime parsing would
  be fragile for shapes the template doesn't demonstrate.
- Body formatting to match the template:
  - Bold-italic section-header rows spanning the row (e.g. "Demographics",
    "Mitral valve pathology"), blank stat cells.
  - Indented sub-category rows under a category header (e.g. "Severity" →
    "Trace/None"/"Mild"/"Moderate").
  - Bold `Table N. Caption in Title Case` above the table.
  - Lettered footnotes (`a.`, `b.`, ...) below the table — **not** the
    numbered convention `standard_footnotes()` currently produces. Check how
    tightly footnote-marker generation is coupled to numbering before
    deciding whether to extend `standard_footnotes()` or fork a
    lettered-footnote variant.
  - `Key:` line below footnotes, abbreviation terms italicized, alphabetical.

## Component 2 — table structural repair function

- New function (e.g. `repair_table_structure()`), same package.
- Purpose: given a `.docx` path, fix a table's **row/cell XML structure**
  when it has been corrupted — either by hand-editing or by originating
  outside the normal pipeline. Explicitly narrower than Component 1: this
  does *not* reformat fonts, headers, or footnotes; it only repairs
  structure. A caller who wants full JTCVS formatting runs the result
  through Component 1 separately.
- Known corruption patterns to detect and fix (both called out by warnings
  already present in the template itself):
  1. Fake rows: paragraph/line breaks inside a single cell used to simulate
     a new row, instead of a real `<w:tr>`.
  2. Cell structure mismatches: `gridSpan`/`vMerge` values that don't
     resolve to a clean rectangular grid.
- **Open risk, unresolved at spec time:** distinguishing "structurally
  broken" from "legitimately unusual but valid" is not fully defined.
  Decision: default to **flag-and-report** suspected issues for human
  confirmation rather than silently auto-fixing, to avoid corrupting a
  table that was fine. Auto-fix behavior (if any) is a planning-time
  decision, gated on this default.

## Testing

Both functions get characterization tests using the tables extracted from
`template_jtcvs_consolidated.docx` this session as fixtures, so output can
be checked directly against Tess's real examples rather than only "does it
run without erroring."

## Explicitly deferred (not in this spec)

- **Delivery mechanism.** Who actually runs `repair_table_structure()` —
  biostatisticians (who already have R via `hvtiRtables`) or editorial staff
  (Tess/Ingrid, who likely do not run R) — is unresolved. This determines
  whether an R function is sufficient or a Word-native macro/add-in or
  zero-setup tool is needed. Follow-up question once the transform logic
  exists, not before.
- Exact function signatures (parameter names/types for both new functions).
- Whether `standard_footnotes()` is extended or forked for lettered
  footnotes.
