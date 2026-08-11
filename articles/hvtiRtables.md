# Building a manuscript table end to end

``` r

library(hvtiRtables)
```

This walks one complete JTCVS submission table, from a data frame to a
checked `.docx`. The CORR house-style path is shorter and covered in
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

The result carries two attributes the renderer wants: the
percentile-aware sub-header text, and a ready-made `trailing` argument
for the comparison column.

``` r

attr(tbl, "hv_stat_label")
#> [1] "No. (%) or Median (15th, 85th percentile)"
attr(tbl, "hv_trailing")
#> hv_compare_col 
#>            "P"
```

## 2. Render the JTCVS shape

``` r

ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)"),
  stat_label = attr(tbl, "hv_stat_label"),
  trailing = attr(tbl, "hv_trailing")
)
```

`groups` names are the `stat_<k>` columns `gtsummary` built, one per
level of `trt`. The labels are yours, including each arm’s N.

## 3. Build the test footnotes

[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md)
reads which test produced each p-value and returns footnotes in the
shape the saver expects, with the body-row indices already computed.

``` r

notes <- hv_test_footnotes_jtcvs(tbl)
length(notes)
#> [1] 2
notes[[1]]$text
#> [1] "Wilcoxon rank-sum test."
```

## 4. Save and check

``` r

out <- tempfile(fileext = ".docx")
hv_man_table_save_jtcvs(
  ft, out,
  caption = "Table 1. Baseline Characteristics",
  footnotes = notes,
  abbreviations = c(SMD = "standardized mean difference")
)
```

Neither saver checks its own output, so run
[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
on the path. Zero rows means clean.

``` r

hv_check_docx(out)
#> [1] type     table    location detail  
#> <0 rows> (or 0-length row.names)
```

## What the package refuses

Every public function rejects out-of-spec input with a message naming
the fix, rather than letting it reach `gtsummary` or `flextable`.

``` r

hv_man_table_jtcvs(
  gtsummary::tbl_summary(gtsummary::trial, by = "trt", include = "age"),
  groups = c(stat_1 = "A", stat_2 = "B")
)
#> Error:
#> ! `tbl` was not built with the "{N_obs} ||| {stat}" convention hv_man_table_jtcvs() requires, so column `stat_1` cannot be split into its N and statistic parts. Build it with hv_tbl_summary(), or pass statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"). First unparseable value: "46 (37, 60)".
```

``` r

hv_tbl_summary(
  gtsummary::trial, groups = list(D = "age"),
  continuous = "age", binary = "age"
)
#> Error:
#> ! `age` appears in more than one of `continuous`, `binary`, and `categorical`. Every variable must be classified exactly once. Overlapping: age (continuous, binary).
```
