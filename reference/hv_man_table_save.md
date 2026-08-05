# Write an hv_man_table() table to a compliant .docx

You hand this a `flextable` (typically from
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)),
and it writes a Word document with footnotes and an abbreviation key
rendered as text below the table rather than embedded within it (house
rules 13-14).
[`flextable::footnote()`](https://davidgohel.github.io/flextable/reference/footnote.html)
cannot do this for you: it renders footnote text as an extra row inside
the table's own `<w:tbl>` block (a "footer" table part), which is
exactly the compliance violation this function exists to avoid. Instead,
a superscript reference symbol is appended to the target header cell (a
normal, compliant reference mark), and the footnote text itself is
written as a genuine document paragraph after the table via
[`officer::body_add_fpar()`](https://davidgohel.github.io/officer/reference/body_add_fpar.html).
The table itself is inserted directly (no leading blank paragraph),
which keeps vertical cell alignment controllable if you later reformat
the surrounding document to 1.5- or double-spacing. House rule 2
concerns the *insertion point* in the destination document, not this
function's output; see the package README for the paste-in workflow.

## Usage

``` r
hv_man_table_save(
  ft,
  file,
  footnotes = hv_man_footnotes(),
  abbreviations = NULL
)
```

## Arguments

- ft:

  A `flextable` object, typically from
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md).

- file:

  Output `.docx` path.

- footnotes:

  Optional named list, symbol -\> footnote text. Defaults to
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  (the house-universal N and median/percentile footnotes). Pass `NULL`
  to suppress both, or compose with
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  to override or extend (see its documentation). Symbols must be drawn
  from `c("*", "†", "‡", "§", "¶", "||")`. Each symbol is appended as a
  superscript reference mark to the table's `N` column header cell (or
  the first column if no `N` column is present), and its text is
  rendered as its own paragraph below the table, in the order given.
  Every element must be named (unnamed or blank-named entries raise an
  error); an empty list is a no-op, same as `NULL`.

- abbreviations:

  Optional named character vector, `c(ABBR = "expansion", ...)`.
  Rendered as one `Key:` paragraph below any footnotes, sorted
  alphabetically by abbreviation, abbreviation italicized, pairs
  separated by `"; "` (house rule 14). Every element must be named
  (unnamed or blank-named entries raise an error); an empty or `NULL`
  vector is a no-op.

## Value

Invisibly, the `file` path.

## See also

[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
to build a compliant `flextable` first.
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
for details on the default footnotes.

## Examples

``` r
library(gtsummary)
tbl <- tbl_summary(trial, by = trt, include = c(age, grade))
ft <- hv_man_table(tbl)
out <- tempfile(fileext = ".docx")
hv_man_table_save(ft, out, abbreviations = c(N = "sample size"))
```
