# Building a manuscript table end to end

``` r

library(hvtiRtables)
```

This walks one complete manuscript table, from a data frame to a checked
`.docx`, and then lays the same table out to describe its groups side by
side. The report path is shorter and covered in
[`?hv_man_table`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md).

## 1. Summarize the data

[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
takes a grouped, ordered variable list and type buckets, the way the SAS
`%summarytable` macro does. Every variable in `groups` appears in
exactly one of `continuous`, `binary`, or `categorical`.

``` r

tbl <- hv_tbl_summary(
  gtsummary::trial,
  by = "trt",
  groups = list(
    Demography = c("age", "marker"),
    Disease = c("stage", "grade")
  ),
  continuous = c("age", "marker"),
  categorical = c("stage", "grade"),
  compare = "pvalue"
)
```

The result records what the manuscript style reads: the statistic it
shows and the comparison column.

``` r

attr(tbl, "hv_stat_label")
#> [1] "No. (%) or Median [15th, 85th percentiles]"
attr(tbl, "hv_trailing")
#> hv_compare_col 
#>            "P"
```

## 2. Shape the manuscript table

``` r

ft <- hv_man_table(tbl, style = "manuscript")
```

The `"compare"` layout, the default, for groups the table compares: one
overall `n` column, the grouping spanning its levels, and the P column.

## 3. Or describe the groups side by side

``` r

ft2 <- hv_man_table(tbl, style = "manuscript", layout = "describe")
```

The `"describe"` layout gives each group its own count, for separate
cohorts or repeated measures. The P column stays, because the table
carries it. Either layout names the tests behind the p-values in its
dagger note, so there is no separate step for test footnotes.

## 4. Save and check

``` r

out <- tempfile(fileext = ".docx")
hv_man_table_save(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  abbreviations = c(SMD = "standardized mean difference")
)
```

Neither saver checks its own output, so run
[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
on the path, as the style that wrote it. Zero rows means clean.

``` r

hv_check_docx(out, style = "manuscript")
#> [1] type     table    location detail  
#> <0 rows> (or 0-length row.names)
```

## What the package refuses

Every public function rejects out-of-spec input with a message naming
the fix, rather than letting it reach `gtsummary` or `flextable`.

``` r

hv_man_table(
  gtsummary::tbl_summary(gtsummary::trial, by = "trt", include = "age"),
  style = "manuscript"
)
#> Error:
#> ! style = "manuscript" needs a table from hv_tbl_summary(), which carries each variable's overall count for the n column.
```

``` r

hv_tbl_summary(
  gtsummary::trial, groups = list(D = "age"),
  continuous = "age", binary = "age"
)
#> Error:
#> ! `age` appears in more than one of `continuous`, `binary`, and `categorical`. Every variable must be classified exactly once. Overlapping: age (continuous, binary).
```
