# Check a .docx for structural patterns the house rules forbid

Read-only inspection of any Word document, whether written by this
package or received from elsewhere. Reports the three structural failure
patterns the canonical "Table Construction for Manuscripts" memo names,
and never modifies the file.

## Usage

``` r
hv_check_docx(path)
```

## Arguments

- path:

  Path to a `.docx` file.

## Value

A `data.frame` with one row per finding and columns `type`, `table`
(1-indexed table number, `NA` when document-level), `location`
(row/column detail where applicable, `NA` otherwise), and `detail`
(human-readable description). Zero rows means clean.

## Details

Three detectors run:

- `"layer"` (structural, high confidence): paragraphs positioned with
  `w:framePr`, or floating text boxes (`w:txbxContent`). Table content
  belongs in the table, not in a floating layer over it.

- `"hidden_column"` (structural, high confidence): a table column that
  is both entirely empty **and** strictly narrower than 0.1 inch (a
  `w:gridCol` width below 144 dxa; exactly 144 does not count). Both
  conditions are required. The house's own JTCVS templates contain
  all-empty 0.5-inch gutter columns between group pairs, which are
  deliberate; width alone or emptiness alone would flag them. A cell
  spanning several columns counts as filling every column it covers, so
  a merged header never makes the columns beneath it look empty.

- `"embedded_footnote"` (heuristic, lower confidence): a cell in a
  table's last row whose text starts with a footnote marker (`*`, a
  dagger or double dagger, a section or pilcrow sign, a lettered
  `a.`/`b.` marker, or `Key:`), the pattern
  [`flextable::footnote()`](https://davidgohel.github.io/flextable/reference/footnote.html)
  produces when misused. This detector is pattern-based rather than a
  guaranteed structural signature, so treat its findings as prompts to
  look, not proof.

## Common mistakes

**"`path` must be a single non-empty string."** The argument is a file
path, not a `flextable` or an `officer` document. Neither saver runs
this on its own output, so call it on the written `.docx` afterwards.

**Reading a `hidden_column` finding as a gutter column.** It is not one.
The detector requires empty **and** narrower than 0.1 inch, precisely so
the deliberate half-inch gutter columns in the house JTCVS templates do
not trip it. A finding here is a real spacer.

**Treating `embedded_footnote` as proof.** It is the one heuristic
detector of the three: it matches a marker character opening a cell in a
table's last row, and a legitimate last row that happens to start that
way matches it too. Read it as a prompt to look, not a verdict.

**Expecting a repair.** This is read-only and never modifies the file.
Fix what it reports in Word, or rebuild the table through
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
or
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md).

## See also

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
and
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md),
which write the files this checks. Neither runs the check on its own
output, so call this on the path afterwards when you want it.

## Examples

``` r
# \donttest{}: the example writes a .docx and reads it back, which is
# I/O-bound enough to trip CRAN's 5s example budget (12.7s elapsed at
# 1.0.0). It runs, and is meant to -- it is not \dontrun{}.
# \donttest{
library(gtsummary)
tbl <- trial |>
  tbl_summary(
    by = trt,
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    include = age,
    missing = "no"
  )
ft <- hv_man_table_jtcvs(tbl, groups = c(stat_1 = "A", stat_2 = "B"))
out <- tempfile(fileext = ".docx")
hv_man_table_save_jtcvs(ft, out, caption = "Table 1. X")
hv_check_docx(out)
#> [1] type     table    location detail  
#> <0 rows> (or 0-length row.names)
# }
```
