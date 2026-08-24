# Write an hv_man_table() table to a compliant .docx

Stage 3 of the `%summarytable` split: writes the document. Replaces the
macro's `RTFFILE=`/`PDFFILE=` output block.

## Usage

``` r
hv_man_table_save(
  ft,
  file,
  footnotes = hv_man_footnotes(),
  abbreviations = NULL,
  ...
)
```

## Arguments

- ft:

  A `flextable` object, typically from
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md).

- file:

  Output `.docx` path. The output directory (`dirname(file)`) must
  already exist; this function does not create it. (`%summarytable`
  `RTFFILE=`/`PDFFILE=` equivalent; output here is always `.docx`).

- footnotes:

  Optional named list, symbol -\> footnote text. Defaults to
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  (the house-universal N and median/percentile footnotes). That default
  text hardcodes the 15th/85th percentile pair; if the table was built
  with
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
  `percentiles =` set to anything else, override it (see below) or the
  footnote will misstate what the table shows. Pass `NULL` to suppress
  both, or compose with
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  to override or extend (see its documentation). Symbols must be drawn
  from `c("*", "†", "‡", "§", "¶", "||")`. Each symbol is appended as a
  superscript reference mark to the table's count-column header cell — a
  column named `n`, else the first `n_stat_<k>` column
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  creates when it splits an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  table, else the first column — and its text is rendered as its own
  paragraph below the table, in the order given. Every element must be
  named (unnamed or blank-named entries raise an error) and every text
  must be a single non-empty string (`NULL`, `NA`, a number, or a
  multi-element vector raise an error, since each writes a dangling
  marker); an empty list is a no-op, same as `NULL`. (`%summarytable`
  `ADDFN=` equivalent; `PRINTFN=1`'s house block is
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)).

- abbreviations:

  Optional named character vector, `c(ABBR = "expansion", ...)`.
  Rendered as one `Key:` paragraph below any footnotes, sorted
  alphabetically by abbreviation, abbreviation italicized, pairs
  separated by `"; "` (house rule 14). Every element must be named
  (unnamed or blank-named entries raise an error); an empty or `NULL`
  vector is a no-op.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

Invisibly, the `file` path.

## Details

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

## Common mistakes

**"unused argument (caption)"** The CORR saver writes no caption. Only
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
takes one; here the table title goes in the manuscript, above the pasted
table.

**"`footnotes` must be a named list (symbol -\> footnote text) ..."**
You passed the JTCVS shape. The two savers' `footnotes` arguments are
unrelated types: this one is keyed by symbol, `` list(`*` = "text") ``,
and
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)'s
is keyed by position, `list(list(row =, col =, text =))`. So
[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)'s
output does not belong here;
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)'s
does.

**"Invalid footnote symbol(s): ..."** Symbols are drawn from the house
set `* † ‡ § ¶ ||`. A letter or a digit is not one of them; lettered
markers are the JTCVS renderer's convention.

**"Output directory does not exist: ..."** The
[`dirname()`](https://rdrr.io/r/base/basename.html) of `file` is not
created for you. Run `dir.create(dirname(file), recursive = TRUE)`
first.

**A footnote that misstates the table.** Nothing errors here.
`footnotes` defaults to
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md),
whose dagger text hardcodes the 15th and 85th percentiles; build the
table with
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
`percentiles =` set to any other pair and the table shows one pair while
the footnote below it names another. Override the dagger whenever you
move the pair.

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
