# The house-standard manuscript table footnotes

The house footnote block the macro emitted under `PRINTFN=1`.

## Usage

``` r
hv_man_footnotes(
  continuous_stat = c("median", "mean", "both"),
  percentiles = c(15, 85)
)
```

## Arguments

- continuous_stat:

  One of `"median"` (default), `"mean"`, or `"both"`. Controls whether
  the dagger reads as median and percentiles, mean +/- SD, or both.

- percentiles:

  Numeric vector of length 2, the increasing whole-number percentile
  pair named by the dagger. Default `c(15, 85)`. Used for
  `continuous_stat = "median"` and `"both"`; validated but not printed
  for `"mean"`, so the arguments share
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
  contract.

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
wording required) and a `†` explaining the continuous statistic. You
don't need a footnote for the categorical `n (%)` format; the column
header text already covers it (house rules 10/12).

[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)'s
`footnotes` parameter defaults to calling this function, so every table
gets both automatically. A table built by
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
and
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
carries its `continuous_stat` and `percentiles` choices through to the
saver, so its default dagger follows what the table shows. Call this
function directly with the same arguments when composing footnotes
yourself. Override with ordinary list operations, no special sentinel
values needed:

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

**Calling this helper with settings different from the table.** The
automatic
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
-\>
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
-\>
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
path stays synchronized. If you call this helper yourself, pass the same
`continuous_stat` and `percentiles` used to build the table, or override
the dagger explicitly.

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
hv_man_footnotes(continuous_stat = "mean")
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "Mean±SD."
#> 
hv_man_footnotes(continuous_stat = "both", percentiles = c(16, 84))
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "Mean±SD; Median (16th, 84th percentile)."
#> 
modifyList(hv_man_footnotes(), list(`†` = "custom text"))
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "custom text"
#> 
```
