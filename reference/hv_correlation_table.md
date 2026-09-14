# Pairwise correlations with Fisher confidence intervals

The table half of the SAS correlation job
`proc corr nosimple spearman pearson fisher(biasadj=no alpha=.32)`, with
the `SpearmanCorr`, `FisherSpearmanCorr`, `PearsonCorr` and
`FisherPearsonCorr` ODS tables folded into one data frame. The
scatter-plot matrix (`plots=matrix`) is
`hvtiPlotR::hv_correlation_matrix()`.

## Usage

``` r
hv_correlation_table(
  data,
  vars,
  with = NULL,
  by = NULL,
  method = c("spearman", "pearson"),
  conf_level = 0.68,
  digits = 2
)
```

## Arguments

- data:

  A data frame.

- vars:

  Character vector of numeric columns (`VAR` statement).

- with:

  Character vector of numeric columns to correlate each of `vars`
  against (`WITH` statement). `NULL` (default) correlates every
  unordered pair within `vars`.

- by:

  Optional single column name to stratify on (`BY` statement). Each
  level gets its own rows; the column is carried first in the output.

- method:

  One or both of `"spearman"` and `"pearson"`.

- conf_level:

  Confidence level for the Fisher interval, strictly between 0 and 1.
  Default `0.68`.

- digits:

  Decimal places in `display`. Default `2`, the SAS `6.2` format.

## Value

A data frame, one row per stratum, pair and method, with columns `by`
(when given), `variable`, `label`, `with`, `method`, `n`, `estimate`,
`conf.low`, `conf.high`, `p.value` and `display` (`"r (lcl, ucl)"`).
`label` describes `variable` only, not the pair. `display` is `NA`
whenever the interval is undefined: n \<= 3, a zero-variance column, or
an empty stratum. The level used is stored as `attr(x, "conf_level")`.

## Details

The interval is Fisher's z without bias adjustment, SAS's `biasadj=no`:
`z = atanh(r)`, `se = 1 / sqrt(n - 3)`, back-transformed with
[`tanh()`](https://rdrr.io/r/base/Hyperbolic.html). The same transform
is applied to Spearman's coefficient, as SAS does. The p-value tests rho
= 0 on the same z scale, so it is the Fisher p-value SAS reports
alongside the interval, not the t-test p-value of
[`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html). The
interval, by contrast, is identical to
[`cor.test()`](https://rdrr.io/r/stats/cor.test.html)'s for Pearson.

`conf_level` defaults to 0.68, the exemplar's `alpha=.32`: the house
one-standard-error convention, the same logic as the 15th and 85th
percentiles in
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md).
Pass `0.95` for a conventional interval.

Missing values are deleted pairwise, per pair and per stratum, which is
`proc corr`'s default. Rows with a missing `by` value are dropped, where
SAS's `BY` would keep them as their own group.

## See also

`hvtiPlotR::hv_correlation_matrix()` for the plot.

## Examples

``` r
hv_correlation_table(
  datasets::mtcars, vars = c("hp", "wt", "qsec"), with = "mpg",
  by = "am"
)
#>    am variable label with   method  n   estimate   conf.low  conf.high
#> 1   0       hp    hp  mpg spearman 19 -0.8739554 -0.9213971 -0.8008475
#> 2   0       hp    hp  mpg  pearson 19 -0.8315065 -0.8940220 -0.7372300
#> 3   0       wt    wt  mpg spearman 19 -0.7743072 -0.8563809 -0.6540710
#> 4   0       wt    wt  mpg  pearson 19 -0.7676554 -0.8519462 -0.6445855
#> 5   0     qsec  qsec  mpg spearman 19  0.5876158  0.4014717  0.7271397
#> 6   0     qsec  qsec  mpg  pearson 19  0.6571077  0.4923002  0.7764310
#> 7   1       hp    hp  mpg spearman 13 -0.8370166 -0.9096686 -0.7146626
#> 8   1       hp    hp  mpg  pearson 13 -0.8006683 -0.8885400 -0.6561350
#> 9   1       wt    wt  mpg spearman 13 -0.8815460 -0.9350503 -0.7887773
#> 10  1       wt    wt  mpg  pearson 13 -0.9089148 -0.9503829 -0.8357086
#> 11  1     qsec  qsec  mpg spearman 13  0.8181849  0.6841246  0.8987688
#> 12  1     qsec  qsec  mpg  pearson 13  0.8022104  0.6585831  0.8894440
#>         p.value              display
#> 1  6.725964e-08 -0.87 (-0.92, -0.80)
#> 2  1.824110e-06 -0.83 (-0.89, -0.74)
#> 3  3.723802e-05 -0.77 (-0.86, -0.65)
#> 4  4.941525e-05 -0.77 (-0.85, -0.64)
#> 5  7.016367e-03    0.59 (0.40, 0.73)
#> 6  1.628098e-03    0.66 (0.49, 0.78)
#> 7  1.281886e-04 -0.84 (-0.91, -0.71)
#> 8  5.014206e-04 -0.80 (-0.89, -0.66)
#> 9  1.229093e-05 -0.88 (-0.94, -0.79)
#> 10 1.504730e-06 -0.91 (-0.95, -0.84)
#> 11 2.718594e-04    0.82 (0.68, 0.90)
#> 12 4.765023e-04    0.80 (0.66, 0.89)
```
