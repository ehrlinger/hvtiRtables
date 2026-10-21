# Superscripts and subscripts in study-supplied text

Status: design, approved by John on 2026-10-21. It is not yet planned or built.

## 1. Why

The table styles design ([2026-10-17](2026-10-17-table-styles-design.md), section 7, third
bullet) says the renderer turns `^2^` in a label into a superscript. A study can then write
`LAVV area (cm^2^/m^2^)` as plain text in its `vars()` or data build, and the manuscript table
shows it set properly. Both submissions the design was measured on carry such labels: 18 in
ms.1264 Table 1 and 13 in BVR rv3 Table 1. No phase of the table styles work built it. Today
the markup prints as typed, so someone fixes it by hand in Word, and that is the hand edit
this work exists to remove.

## 2. Decisions (John, 2026-10-21)

1. **Both superscript and subscript.** `^text^` raises, `~text~` lowers, as in Pandoc and
   Quarto. Clinical labels need subscripts about as often as superscripts: PaO~2~, VO~2~ max,
   HbA~1c~, CO~2~.
2. **All study-supplied text.** That means:
   - the label column: variable, level and section rows;
   - header cells: group levels and the `by` label;
   - the notes, the abbreviation key and the caption.
   A study writes `c(BSA = "body surface area (m^2^)")` in `abbreviations` and gets the same
   result as in a label.
3. **Approach A: split runs at render time.** The gtsummary object keeps its text as typed.
   The renderer splits a run holding markup into plain, raised and lowered runs, and each new
   run inherits the original run's font, size, bold, italic and color. Unicode substitution
   (`^2^` to the superscript-two character) was rejected: Unicode has no subscript "c" for
   HbA~1c~, fonts draw those glyphs unevenly, and typesetters expect real raised runs.
   gtsummary's markdown labels were rejected because they reach gt output only, and
   `as_flex_table()` drops them.
4. **A guard in `hv_check_docx()`.** A saved table containing an unrendered pair fails the
   check, so markup that reaches Word by a path the renderer does not cover is caught rather
   than submitted.

## 3. The rule

A pair is an opening marker, one or more characters with no whitespace, and the same marker
closing it. This is Pandoc's rule, and it is the whole grammar:

| text | renders as |
|---|---|
| `cm^2^/m^2^` | cm, raised 2, /m, raised 2 |
| `HbA~1c~` | HbA, lowered 1c |
| `PaO~2~ (mm Hg)` | PaO, lowered 2, (mm Hg) |
| `~5 years` | as typed: no closing marker |
| `x ^ y ^ z` | as typed: whitespace inside |
| `a^^b` | as typed: an empty pair is not a pair |
| `m^2^~a~` | m, raised 2, lowered a |

- Pairs do not nest. `^` inside a `~` pair is plain text, and vice versa.
- There is no escape syntax. A literal `^x^` in a label is not a real need, and adding an
  escape later breaks nothing (YAGNI).
- In a regular expression: `([\^~])([^\s\^~]+)\1`, applied left to right.

## 4. Where it applies: three seams

All study text reaches output through one of three places, so the change is made in those
three places and nowhere else.

1. **Table cells.** `hv_man_table()` builds every flextable, in the report style, the compare
   layout (`.man_table_compare()`) and the describe layout. A new internal
   `.apply_markup(ft)` runs as the last step of each path. For the header, body and footer
   parts it rewrites flextable's chunk data: each chunk whose `txt` holds a pair is replaced
   by one chunk per piece. Every piece copies the original chunk's row, so font, size, bold,
   italic, color and shading come along, and its `vertical.align` is set to `"superscript"`
   or `"subscript"` for the raised and lowered pieces.
   - Chunks that are already raised, such as the † and ‡ marks on the header and the § and ¶
     minority marks, contain no pair and are left alone.
   - `hv_man_table_display()` and `hv_man_table_save()` take a table `hv_man_table()` made, so
     they inherit this.
2. **Notes and the abbreviation key.** These are runs data frames (`.note_runs()`,
   `.key_runs()`), drawn by `.runs_paragraph()` for display and by `.runs_fpar()` for Word. A
   new internal `.expand_markup(runs)` splits each run's `text` the same way. It adds a `sub`
   column beside the existing `sup` column and keeps `italic`, and both drawers call it first.
   `.runs_fpar()` maps `sub` to `.note_prop(font, "subscript")`; `.runs_paragraph()` maps it
   to `flextable::as_sub()`.
3. **The caption.** `.write_man_docx()` writes the caption as one bold `ftext`. It becomes
   `.runs_fpar()` over the expanded caption, with bold carried on each run.

One parser, `.markup_pieces(txt)`, serves all three seams. It returns a data frame of `text`
and `align` (`"baseline"`, `"superscript"` or `"subscript"`), and gives back the input as a
single baseline piece when there is no pair. Text without markup therefore takes the same
path, and comes out unchanged.

**Not covered: the deprecated JTCVS savers.** `hv_man_table_jtcvs()` already goes through the
describe layout, so its cells get the markup. `hv_man_table_save_jtcvs()` writes its notes its
own way and is deprecated; it is left as it is. Its docs say to move to `hv_man_table_save()`,
and the guard in section 5 catches any leftover pair.

## 5. The guard

`hv_check_docx()` gains `.detect_markup(doc)`. It reports any `w:t` text in the document body,
captions and notes included, that still matches the rule in section 3. Its finding names the
text, like the other detectors, and its message says the renderer did not reach that text.
The rule applies whatever `style =` is given: unrendered markup is wrong in both styles.

## 6. Tests

Each test carries a mutation it must catch, written beside it in the plan.

- **The parser** (`.markup_pieces()`): every row of the table in section 3, plus the
  no-markup case returning one baseline piece unchanged.
- **Cells, one case per part:**
  - a variable label with `^2^`;
  - a level with `~2~`;
  - a `by` label (header) with markup;
  - a section row: bold and shading survive the split;
  - a header † mark still raised beside a raised label piece.
  Each asserts `vertical.align` on the right chunks and that `font.family` and `bold` match
  the original chunk. Cases run in both styles and both manuscript layouts.
- **Runs:** a note and an abbreviation definition with markup through `.runs_fpar()` (the
  docx XML carries `w:vertAlign w:val="superscript"` and `"subscript"`) and through
  `.runs_paragraph()` (the display footer's chunks).
- **Caption:** a saved docx whose caption carries markup has bold raised runs.
- **Guard:** `hv_check_docx()` fires on a hand-built docx that holds `m^2^` as plain text, and
  is silent on a table `hv_man_table_save()` wrote with markup.
- **No change without markup:** an existing table, snapshot or XML comparison, is identical
  before and after.

## 7. Docs and release

- The Table styles article (`vignettes/articles/table-styles.qmd`) gains a Notation bullet with
  an example label, and shows it rendered.
- `@details` on `hv_man_table()`, and the `abbreviations` parameter docs of
  `hv_man_table_save()` and `hv_man_table_display()`, say that the markup applies. Roxygen
  here is markdown (`Roxygen: list(markdown = TRUE)`), so the examples go in code spans,
  `` `cm^2^` ``, where `^` and `~` reach the Rd as typed.
- A news fragment. A patch release, 1.0.10, when John names one. Tables without markup do not
  change.

## 8. Out of scope

- hvtiRtemplates. Labels come from the study, so templates need no change. A template example
  label using the markup could follow once 1.0.10 is the floor.
- Markup in data values: statistics and P values never carry it.
- An escape syntax, nesting, and other inline markup (bold, italics).
