# hv_check_docx() — hidden-layer / hidden-column / embedded-footnote detector — design

Date: 2026-07-16
Status: approved, pending implementation plan

## Problem

The canonical house rules document (`Table Construction for Manuscripts.docx`,
7/14/2026) names the root cause of the whole manuscript-table bottleneck this
project exists to fix, in its opening paragraph:

> "it embeds 'layers' that we don't know how to reach, hidden columns for
> spacing that are not allowed by any of the journals to which we commonly
> submit, footnotes (with material sometimes inapplicable) within the table,
> non-vertical columns that are difficult to control."

This describes SAS-macro-generated `.docx` tables using three distinct
constructs that make content structurally present but practically invisible
or unreachable to an editor working in normal Word view:

1. **Floating layers** — text boxes or frames anchored outside the normal
   document text flow (Word's "Show text boxes, drawings, and WordArt on
   screen" display option controls whether this layer even renders; when
   off, the content is there but invisible).
2. **Hidden columns** — table columns shrunk to near-zero width purely to
   create spacing, structurally present but visually unreadable.
3. **Embedded footnotes** — footnote text placed as an extra row inside the
   table's own `<w:tbl>` block rather than as document text below the table
   (this is the exact regression [flextable::footnote()] would introduce,
   already called out in `hv_man_table_save()`'s own roxygen and covered by
   a dedicated test per Copilot review finding C4 on PR #1).

Neither of the two reference documents examined this session
(`Table Construction for Manuscripts.docx`,
`ms.template_jtcvs_consolidated.current.docx`) contains any of these
patterns — manually verified via raw OOXML inspection. `hvtiRtables`'
own output is also structurally immune by construction (built via
`officer`/`flextable`, never via SAS RTF export or manual frame
positioning). But there is currently no automated, reusable way to check
an arbitrary incoming `.docx` — one from outside the package, or a
existing template someone may have hand-edited — for these patterns
before trusting it. This spec adds that check.

**Distinct from `repair_table_structure()`** (Component 2 of
`2026-07-15-jtcvs-table-format-design.md`, never built): that idea was
about repairing corrupted row/cell XML (fake rows from Enter-key presses,
bad cell merges). This is a different, narrower problem — detecting the
three specific constructs named above — and does not attempt to fix
anything.

## Component — `hv_check_docx(path)`

- New exported function, read-only: takes a `.docx` path (any document —
  package output or external) and returns a report of what it finds.
  Never modifies the file.
- **Report structure**: a plain `data.frame`, one row per finding, columns
  `type` (`"layer"` / `"hidden_column"` / `"embedded_footnote"`), `table`
  (1-indexed table number the finding is in), `location` (row/column index
  where applicable, `NA` otherwise), `detail` (human-readable description).
  Zero rows means clean. No new S3 class or print method — a data frame is
  sufficient to inspect, filter, or act on programmatically.
- **Error handling**: `stop()` (matching existing package style, `call. =
  FALSE`) if `path` doesn't exist or isn't a valid `.docx`/zip archive.

### Detector 1 — floating layers (structural, high-confidence)

Scans the document XML for either:
- `w:framePr` on any paragraph (legacy Word frame positioning), or
- `wp:anchor` combined with `w:txbxContent` (floating text box via
  DrawingML, the modern equivalent).

### Detector 2 — hidden spacer columns (structural, high-confidence when combined)

A table column is flagged only when **both** conditions hold, to avoid
false-positiving on legitimately narrow columns (e.g. a 1-2 digit N
count):
- every cell in that column is empty or whitespace-only, **and**
- the column's width is below a threshold tuned to be narrower than any
  real content could need (exact dxa threshold to be pinned during
  implementation against real narrow-but-legitimate columns from the
  reference documents, so the threshold is evidence-based, not guessed).

### Detector 3 — embedded footnotes (heuristic, lower-confidence)

Checks whether the **last row** of a table contains small-font text or
text prefixed with a footnote marker (`*`, `†`, `‡`, `§`, `¶`, a lettered
marker like `a.`/`b.`, or the literal text `"Key:"`) — the pattern
`flextable::footnote()` produces when misused. This detector is
explicitly heuristic (pattern-based, not a guaranteed structural
signature) and is documented as such in the function's roxygen.

## Integration into `hv_man_table_save()` / `hv_man_table_save_jtcvs()`

Both functions call `hv_check_docx()` on the file they just wrote, after
writing, as an automatic defense-in-depth check (should essentially never
fire on our own output, but catches a future regression instead of
shipping it silently). If the report is non-empty, `warning()` with a
one-line summary (count and types found) pointing the caller to
`hv_check_docx()` for details. Return value of both save functions is
unchanged (`invisible(file)`); a normal call with a clean result is
silent, matching current behavior exactly.

## Testing

- **Negative-case regression fixtures** (already manually verified this
  session to report zero findings): `Table Construction for
  Manuscripts.docx` and `ms.template_jtcvs_consolidated.current.docx`.
  These are external files (outside the repo, on OneDrive/Downloads) —
  the test suite copies the specific check assertions, not the files
  themselves, since committing a copy of a live team document into the
  package repo is out of scope and inappropriate; if a stable local copy
  is needed for CI, that's an implementation-time decision (e.g. a
  minimal synthetic fixture built to match the same structural shape,
  documented as standing in for the real reference document).
- **Positive-case fixtures** (one per detector): `officer`/`flextable`
  don't expose APIs for building floating text boxes, hidden columns, or
  embedded footnotes — building a table that violates the rules isn't
  something the tools that enforce the rules can do. Each positive test
  therefore constructs a minimal `.docx` and splices in the offending raw
  XML directly (a `w:framePr`, a column that's all-blank with a near-zero
  width, a last row with footnote-marker-prefixed text), proving each
  detector actually fires rather than assuming it does.
- **Integration test**: `hv_man_table_save()`'s own clean output produces
  zero findings when passed through `hv_check_docx()`, confirming the
  auto-check integration doesn't false-positive on normal usage.

## Explicitly deferred (not in this spec)

- Auto-repair of any detected issue — this tool only reports, per the
  established "flag and report, don't silently auto-fix" decision from
  the original design spec.
- `repair_table_structure()` (structural row/cell repair) — a separate,
  distinct piece of work, not built here.
- Exact hidden-column width threshold — pinned during implementation
  against real evidence, not specified as a magic number here.
