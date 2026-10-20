# The house-standard manuscript table footnotes

The house footnote block the macro emitted under `PRINTFN=1`.

## Usage

``` r
hv_man_footnotes(
  continuous_stat = c("median", "mean", "both"),
  percentiles = c(15, 85),
  style = "report"
)
```

## Arguments

- continuous_stat:

  One of `"median"` (default), `"mean"`, or `"both"`. Controls whether
  the dagger's continuous half reads as median and percentiles or mean
  +/- SD. Under `"both"` it reads as mean +/- SD, because
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  puts the medians in columns of their own whose headers name them.

- percentiles:

  Numeric vector of length 2, the increasing whole-number percentile
  pair named by the dagger. Default `c(15, 85)`. Used for
  `continuous_stat = "median"` and `"both"`; validated but not printed
  for `"mean"`, so the arguments share
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)'s
  contract.

- style:

  `"report"` (default) or `"manuscript"`, or a style from
  [`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md).
  The manuscript writes the notes in the words of the submissions:
  `"Patients with non-missing data."` and
  `"Values are No. (%) or median [15th, 85th percentiles]."`.

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
wording required) and a `†` explaining the statistic in each group
column, e.g. `"No. (%) or Median [15th, 85th percentiles]."` The
categorical half is part of it because the cells print `12 (39)` with no
`%` sign (house rules 10/12), and the flat CORR header names only the
group.

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
  with `` `||` `` = "extra note". Avoid `‡`, `§` and `¶` on a table from
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md):
  `‡` marks Fisher exact p-values there, and `§` and `¶` mark the
  minority statistic when a table mixes mean and median.

## Common mistakes

**Passing the result to the JTCVS saver.** These footnotes are
CORR-shaped, keyed by symbol, and belong to
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md).
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
takes an unrelated type keyed by row and column, and rejects this one.
Its equivalent,
[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md),
is deprecated along with that saver: the describe layout of
`hv_man_table(style = "manuscript")` names its tests in its own notes,
which
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
writes.

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
#> [1] "No. (%) or Median [15th, 85th percentiles]."
#> 
hv_man_footnotes(continuous_stat = "mean")
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "No. (%) or Mean±SD."
#> 
hv_man_footnotes(continuous_stat = "both", percentiles = c(16, 84))
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "No. (%) or Mean±SD."
#> 
modifyList(hv_man_footnotes(), list(`†` = "custom text"))
#> $`*`
#> [1] "Number of non-missing values."
#> 
#> $`†`
#> [1] "custom text"
#> 
```
