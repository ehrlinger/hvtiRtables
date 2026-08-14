# Write an hv_man_table_jtcvs() table to a compliant .docx

Stage 3 of the `%summarytable` split: writes the document. Replaces the
macro's `RTFFILE=`/`PDFFILE=` output block.

## Usage

``` r
hv_man_table_save_jtcvs(
  ft,
  file,
  caption,
  footnotes = NULL,
  abbreviations = NULL,
  ...
)
```

## Arguments

- ft:

  A `flextable`, from
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).

- file:

  Output `.docx` path. The output directory (`dirname(file)`) must
  already exist; this function does not create it. (`%summarytable`
  `RTFFILE=`/`PDFFILE=` equivalent; output here is always `.docx`).

- caption:

  Full caption text, e.g. `"Table 1. Baseline Characteristics"`,
  rendered bold above the table. This function does not auto-number
  tables for you; include the number yourself. (`%summarytable`
  `TBLTITLE=` equivalent).

- footnotes:

  Optional list of `list(row =, col =, text =)`, one per footnote, in
  the order letters should be assigned (`a`, `b`, ...). `col` is a
  single `col_keys` name. `row` may be a vector, in which case the one
  letter marks every row named, which is how several rows share a
  footnote. `row` indexes `ft`'s body rows as shown: for a sectioned
  table (built with `groupname_col`), that includes the section-header
  rows
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  interleaves into the body, so count those too.
  [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
  computes these indices for you when the footnotes mark statistical
  tests. (`%summarytable` `ADDFN=` equivalent. `PRINTFN=1`'s house block
  is
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md),
  which is CORR-shaped and cannot be passed here: build the equivalent
  entries in this function's `list(row =, col =, text =)` shape
  instead.)

- abbreviations:

  Optional named character vector, same as
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
  rendered via the shared `Key:` helper.

- ...:

  Not used. Present so that `%summarytable` parameter names produce an
  error naming the argument to use instead.

## Value

Invisibly, the `file` path.

## Details

JTCVS counterpart to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md):
it adds a bold `Table N. Caption` paragraph before the table, and
renders footnotes as lettered (`a.`, `b.`, ...) markers attached to
specific body cells rather than the fixed symbol set
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
uses on the header row, matching the JTCVS template convention.

## Common mistakes

**"`footnotes\[\[k\]\]$text` must be a single non-empty string."** Every
footnote needs all three of `row`, `col`, and `text`, and `text` must be
one non-empty string. Before this check existed, an entry missing `text`
wrote a document with a dangling superscript marker and an empty
footnote line.

**"`footnotes[[k]]` must be a list of the form list(row =, col =, text
=)."** `footnotes` is a list *of* footnotes, so a single one is
`list(list(row = 1, col = "n_stat_1", text = "..."))`. Dropping the
outer [`list()`](https://rdrr.io/r/base/list.html) previously failed
with `$ operator is invalid for atomic vectors`.

**"`footnotes[[k]]$row` must be whole numbers ..."** Row indices count
the section-header rows
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
interleaves into the body.
[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
computes them for you.

**"`file` must be a single non-empty file path."** Check the argument
order: it is `(ft, file, caption)`.

**"Output directory does not exist: ..."** The directory part of `file`
(its [`dirname()`](https://rdrr.io/r/base/basename.html)) is not created
for you; create it first with
`dir.create(dirname(file), recursive = TRUE)`.

## See also

[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
to build a compliant `flextable` first.

## Examples

``` r
library(gtsummary)
tbl <- trial |>
  tbl_summary(
    by = trt,
    statistic = list(
      all_continuous() ~ "{N_obs} ||| {mean} ± {sd}",
      all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
    ),
    include = c(age, grade),
    missing = "no"
  )
ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
)
out <- tempfile(fileext = ".docx")
hv_man_table_save_jtcvs(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  footnotes = list(list(
    row = 1, col = "n_stat_1", text = "Patients with data available."
  ))
)
```
