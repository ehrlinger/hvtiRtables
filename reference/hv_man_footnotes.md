# The house-standard manuscript table footnotes

The house footnote block the macro emitted under `PRINTFN=1`.

## Usage

``` r
hv_man_footnotes()
```

## Value

A named list with elements `` `*` `` and `` `†` ``, in the format
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)'s
`footnotes` parameter expects.

## Details

Two footnotes are universal to the HVTI CORR "Table Construction for
Manuscripts" rules, not specific to any one study, so you don't have to
re-type them at every
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
call site: a `*` for the non-missing-value count (house rule 8, exact
wording required) and a `†` explaining the `{median} ({p15}, {p85})`
format used for continuous variables throughout these tables. You don't
need a footnote for the categorical `n (%)` format; the column header
text already covers it (house rules 10/12).

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)'s
`footnotes` parameter defaults to calling this function, so every table
gets both automatically. The dagger text hardcodes "15th, 85th
percentile" –
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
own default – so if you called it with `percentiles =` set to anything
else (e.g. `c(16, 84)`), this default footnote will misreport what the
table actually shows. Override it in that case; see below. Override with
ordinary list operations, no special sentinel values needed:

- Suppress both: `footnotes = NULL`

- Change one: `modifyList(hv_man_footnotes(), list(...))` with `` `†` ``
  = "custom text"

- Add a study-specific one alongside: `c(hv_man_footnotes(), list(...))`
  with `` `‡` `` = "extra note"

## Common mistakes

**Passing the result to the JTCVS saver.** These footnotes are
CORR-shaped, keyed by symbol, and belong to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
takes an unrelated type keyed by row and column, and rejects this one.
Its equivalent is
[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md).

**Letting the dagger go stale.** The text hardcodes "15th, 85th
percentile", which is
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
default rather than a promise about your table. Call that function with
`percentiles = c(16, 84)` and the table and its footnote disagree,
silently – nothing checks that the two still match. Override the dagger
whenever you move the pair.

## See also

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)

## Examples

``` r
hv_man_footnotes()
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "Median (15th, 85th percentile)."
#> 
modifyList(hv_man_footnotes(), list(`†` = "custom text"))
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "custom text"
#> 
```
