# Weighted summaries for `hv_tbl_summary()`: design

**Date:** 2026-10-16
**Status:** design with measurements, not an implementation. It feeds the `dc-summary`
template in hvtiRtemplates, whose weighted panel may be dropped at the 2026-10-16 meeting. If
it is, this note records what was measured and stops there.
**Reads with:** `2026-07-17-hv-tbl-summary-sas-migration-design.md`, which deferred `WEIGHT=`
and `PROPENMT=` on purpose; hvtiRtemplates `dev/specs/2026-10-16-dc-summary-design.md`
(branch `spec/dc-summary`, section 3), which found that hvtiRtables has no weight support.
**Measured with:** hvtiRtables 1.0.5, gtsummary 2.5.1, survey 4.5, cardx 0.3.4,
hvtiRpropensity 0.2.1. The script is `2026-10-16-weighted-summary-parity.R` beside this note.

⚠️ Synthetic data only. No study, variable value or patient identifier appears here.

## 1. The question

`%summarytable` draws a baseline table under a matching weight: weighted n (%), weighted
mean ± SD, weighted median and percentiles, a weighted standardized difference and a bootstrap
p-value. `hv_tbl_summary()` has no weight. Three things decide the design:

1. which R engine computes the weighted summaries, and whether its numbers are SAS's;
2. how a non-integer count is printed;
3. where the weighted comparison columns come from, given that the two functions that compute
   them live in hvtiRpropensity, a package hvtiRtables must not import.

## 2. What `%summarytable` does under `WEIGHT=`

Read from `~/Documents/macro.library/summarytable.sas` (4,097 lines, last modified 2021).

- **Counts and percentages** come from `proc freq` with a `weight` statement: the weighted n
  is the sum of weights in the level, the percentage that over the sum of weights in the
  column.
- **The N column becomes a sum of weights.** For each continuous variable the macro builds a
  shadow variable equal to the weight wherever the value is non-missing, sums it by class,
  and substitutes that sum for the raw N (lines 1697–1734).
- **Mean, SD and percentiles** come from `proc univariate` with `WEIGHT` and `VARDEF=WDF`
  (lines 1711 and 1746; the change log dates `VARDEF=WDF` to 2021-07-15, "to adjust the degrees
  of freedom to reflect the weighted Ns"). Under `VARDEF=WDF` the variance divisor is
  **Σw − 1**. Under a `WEIGHT` statement `proc univariate` ignores `PCTLDEF=` and uses the
  weighted empirical distribution with averaging, the weighted analogue of `PCTLDEF=5`. With
  W = Σw and cumulative weights cᵢ over the sorted values:
  x₍ᵢ₊₁₎ when cᵢ < pW < cᵢ₊₁, and (x₍ᵢ₎ + x₍ᵢ₊₁₎)/2 when cᵢ = pW exactly.
- **Weighted counts are printed with `__WCountf.`** (lines 757–763), a rounding picture
  format: `0` as `0`; below 0.001 as `<0.001`; 0.001–0.1 to 3 places; 0.1–1 to 2 places;
  1 and above to 1 place.
- **The default percentiles are 16 and 84** (`PP=16 84`). `hv_tbl_summary()` defaults to
  15 and 85, the house convention. A parity run must pass `percentiles = c(16, 84)`.

## 3. Measurement

The script builds a synthetic cohort of 400 (two groups of 219 and 181, matching weights from
a synthetic propensity score, sums of weights 160.6 and 156.2, 12 missing values in one
variable) and three continuous variables chosen to stress ties: integer ages, a skewed
variable at one decimal, and a variable with no ties. It runs three weight regimes: the
matching weights, unit weights, and the matching weights halved.

**No SAS was run.** The SAS column is the documented SAS definition implemented in R. As a
check, the percentile rule was run with unit weights on 500 random draws with ties, where it
must equal `PCTLDEF=5`, which is R's `quantile(type = 2)`; all 500 agreed. A run on the SAS
server would confirm it outright; see open question 3.

### 3.1 The results

| statistic | SAS definition | `tbl_svysummary()` gives | measured difference | verdict |
|---|---|---|---|---|
| weighted N (non-missing) | Σw over non-missing | `{N_nonmiss}` | 0 | identical |
| weighted n per level | `proc freq` + `weight` | `{n}` | 0 | identical |
| weighted % | n / Σw | `{p}` | ≤ 2.2 × 10⁻¹⁶ | identical |
| mean | Σwx / Σw | `svymean()` | ≤ 7 × 10⁻¹⁴ | identical |
| **SD** | Σw(x − x̄)² / **(Σw − 1)** | √`svyvar()` = Σw(x − x̄)²/Σw · **n/(n − 1)** | ratio 0.99916–0.99956 (matching); 0.9959–0.9963 (halved); 1 (unit) | **differs** |
| **percentiles** | weighted EDF, average on an exact hit | `svyquantile(qrule = "math")`: the lower value on an exact hit | 0 in all 54 synthetic cells; differs on every exact hit | **differs at exact hits** |

`tbl_svysummary()` and a direct `survey` call agree to the last digit (maximum difference
0). That is by construction: cardx 0.3.4 computes `sd` as `sqrt(survey::svyvar())` and every
percentile with `survey::svyquantile()`, passing no `qrule`, so the default `"math"` applies.
`tbl_svysummary()` has no argument that reaches `qrule`.

**The SD.** The ratio of survey's SD to SAS's is √[n(W − 1) / ((n − 1)W)], where n counts
the observations and W sums their weights. Survey's estimator does not change when every
weight is rescaled, and SAS's does. With matching weights W is close to the matched sample
size, so the two agree to within 0.1%. Halve the weights and the gap grows to 0.4%. Normalize
the weights to sum to 1 and `VARDEF=WDF` divides by zero.

The per-cell SDs under matching weights:

| group | variable | SAS (WDF) | gtsummary | difference |
|---|---|---|---|---|
| 0 | age | 9.95478 | 9.94647 | −0.00831 |
| 1 | age | 9.90222 | 9.89784 | −0.00437 |
| 0 | skewed | 0.669216 | 0.668654 | −0.00056 |
| 1 | skewed | 0.730577 | 0.730241 | −0.00034 |
| 0 | no ties | 9.64202 | 9.63397 | −0.00805 |
| 1 | no ties | 8.58513 | 8.58134 | −0.00379 |

**Small, and still visible.** `hv_tbl_summary()` prints mean ± SD under EHB/Blackstone paired
rounding, which takes its precision from the SD. Of 18 printed cells across the three regimes,
**3 differ**: `67±10.0` (SAS) against `67±9.9` (gtsummary) for age in group 0 under the
matching weights, the same cell under the halved weights, and `54±9.7` against `54±9.6` under
the halved weights. An SD sitting just under 10 is the worst case, because the leading digit,
and with it the printed precision, changes.

**The percentiles.** SAS's rule is survey's `qrule = "school"`. The code of
`survey:::qrule_school` is the SAS definition line for line, and the measurement agrees: 0
difference in all 54 cells. `"math"` parts from both only when a cumulative weight lands
exactly on pW. Random fractional weights never do, so all 54 synthetic cells agree. Equal
weights do it whenever n·p is a whole number:

| case | SAS | `"math"` (gtsummary) | `"school"` |
|---|---|---|---|
| x = 1..10, w = 1, median | 5.5 | 5 | 5.5 |
| x = 1..50, w = 1, P16 | 8.5 | 8 | 8.5 |
| x = 1..4, w = (0.5, 1, 1, 0.5), median | 2.5 | 2 | 2.5 |

Over 2,000 random unit-weight groups (n from 20 to 120, values at one decimal), **48%** had at
least one of P16, median or P84 differ between SAS and `"math"`. Whether this matters for
matching weights depends on the data. A matching weight is exactly 1 for a treated patient
with e ≤ 0.5 and for a control with e ≥ 0.5, so when the treated group is a minority most of
its weights are 1. A group where all of them are 1 hits pW exactly.

**Counts.** Exact. `{n}`, `{N}`, `{p}` and `{N_nonmiss}` under `tbl_svysummary()` are the
`proc freq` and summed-weight numbers. `{n_unweighted}` and `{N_unweighted}` are also
available.

### 3.2 The renderers

A `tbl_svysummary` object has class `c("tbl_svysummary", "gtsummary")`, and
`gtsummary::add_overall()` works on it. Measured 2026-10-16: **`hv_man_table()` and
`hv_man_table_jtcvs()` both render one without change**, because `.check_gtsummary()` tests
`inherits(x, "gtsummary")` and the renderers read only `table_body`.

One seam does break. `.format_blackstone_mean_sd()` reads the unrounded mean and SD from
`tbl$cards[c("tbl_summary", "add_overall")]`, and a weighted table's card is named
`tbl_svysummary`. Left alone, the group columns keep gtsummary's default rounding (`62±9`
in the smoke test) while the Overall column gets the house rule, and nothing fails.

## 4. Design

### 4.1 The argument

`weight = NULL`: the name of a numeric column, as a string, the way `by` is. It is the
`%summarytable` name. It goes **last in the signature**, after `normal`, so positional calls
keep working, as `continuous_stat` and `normal` did before it.

Validation, in this function's own words like every other check:

- the column exists, is numeric, and has no missing or negative values;
- **Σw > 1 in every group** (and overall when `overall = TRUE`), because the `VARDEF=WDF`
  divisor is Σw − 1. Weights normalized to sum to 1 fail here with a sentence saying so,
  where SAS would print a missing SD;
- `weight` is not listed in `groups` and is not `by`.

`hv-sas-glossary.R` maps `weight` to "weighted summaries are not supported" today. That entry
becomes `arg = "weight"`, so `WEIGHT =` passed through `...` names the argument to use. The
glossary is the file the partial-match bug lived in; read the entry with `[[`.

### 4.2 The engine

With `weight` set, `hv_tbl_summary()` builds
`survey::svydesign(ids = ~1, weights = stats::reformulate(weight), data = data)` and passes
it to `gtsummary::tbl_svysummary()` with the same `statistic`, `type`, `value`, `missing` and
`include` lists it builds today. Everything downstream (section map, `add_overall()`, the
renderer attributes, `relabel()`) runs unchanged. That is the point of choosing
`tbl_svysummary()`: the weighted table is the same object the renderers already take, built
by the same code path, with one constructor swapped.

`survey` goes in **Suggests**, with a loud stop when `weight` is set and it is missing, the
pattern `.has_broom()` already uses. Only the weighted path needs it.

### 4.3 The definitions: SAS's

**Recommendation: adopt SAS's definitions for the SD and the percentiles.** Means, counts,
percentages and the N come from `tbl_svysummary()` unchanged, since they are identical.

- **SD**: Σw(x − x̄)²/(Σw − 1), `VARDEF=WDF`.
- **Percentiles and median**: `survey::svyquantile(qrule = "school")`.

`hv_tbl_summary()` exists to port `%summarytable`, and a biostatistician migrating a job will
set the R table beside the SAS one and compare. A 0.1% SD difference that turns `10.0` into
`9.9` is a discrepancy someone has to explain. The cost is small: both statistics are
recomputed per group from the data and written over gtsummary's `sd`, `median` and `p##`
entries in the cards, the same seam `.format_blackstone_mean_sd()` already reads from. That
function's `card_names` gains `"tbl_svysummary"`, which it needs either way (section 3.2).
The median and percentile cells are then formatted from the corrected cards, as the
mean ± SD cell already is.

The alternative is to keep survey's definitions and document the difference. That is less
code, and survey's SD is the better estimator in principle because it does not depend on the
scale of the weights. The 2021 change log shows `VARDEF=WDF` was a deliberate choice, made
for matching weights, whose scale is meaningful. Open question 2.

### 4.4 Printing weighted counts

Under `weight`, the `n` and `N_nonmiss` statistics are printed through a port of
`__WCountf.`:

| value | printed |
|---|---|
| 0 | `0` |
| 0 < x < 0.001 | `<0.001` |
| 0.001 ≤ x ≤ 0.1 | 3 places |
| 0.1 < x < 1 | 2 places |
| x ≥ 1 | 1 place, no thousands separator (house rule, as for unweighted counts) |

A ten-line formatter passed through `digits =`, where `label_style_number(big.mark = "")`
goes today. **Rounding:** SAS's `(round)` picture rounds half up on the decimal value.
`formatC()` rounds the binary value, and the measurement shows `12.25` printing as `12.2`
where SAS prints `12.3`. The formatter should round half up with a small tolerance, so that
it matches SAS. That differs on purpose from the EHB/Blackstone rule, which rounds ties to
even, but that rule governs mean ± SD pairs, not counts. Open question 4.

Percentages keep gtsummary's `{p}`. The `*` footnote, "Number of non-missing values.", is
wrong under a weight; it becomes "Sum of weights over non-missing values." (wording is open
question 5). `hv_stat_label` is unchanged.

### 4.5 Comparison columns under a weight

**`compare` must be `"none"` when `weight` is set**, or `hv_tbl_summary()` stops with a
sentence naming the route below. `tbl_svysummary()` offers `add_p()`, but its tests are
design-based (`svyranktest()`, `svychisq()`), not `%mw_var`'s bootstrap, and `add_difference()`
gives the generic SMD, not `%stddiff`'s. Either would produce a plausible number that is not
the number SAS printed, which is worse than none.

**Recommendation: the template joins the columns, through a new export in hvtiRtables.**

```r
hv_tbl_compare(tbl, values, label, test_name = NULL)
```

- `values`: a named character vector, variable name to the text shown on that variable's
  label row. Formatting stays with the caller, which knows whether it holds a percentage or
  a p-value.
- `label`: the column header, as `hv_trailing` carries it today (`"P"`, `"Std. Diff. (%)"`).
- `test_name`: optional, written to `table_body$test_name` so `hv_test_footnotes_jtcvs()`
  letters the column. `.hv_test_labels` gains an entry for the matching-weight bootstrap.

It writes `hv_compare_col` and sets `hv_trailing`, the contract `hv_tbl_summary()`'s own
`compare` path already uses, so both renderers and `hv_test_footnotes_jtcvs()` pick it up
with no change. It errors when a name in `values` is not a variable in the table, the
`groups` contract applied to a new input. It goes in `_pkgdown.yml`. It works on unweighted
tables too, which is how the related finding in section 5.1 gets fixed without touching
`compare = "smd"`.

The template, at tier 4, then does:

```r
tbl <- hv_tbl_summary(dta, by = "grp", groups = groups,
                      continuous = cont, binary = bin, categorical = cat,
                      compare = "none", percentiles = c(16, 84),
                      overall = FALSE, weight = "mt_wt")
sd <- hvtiRpropensity::ps_stddiff(dta, "grp", gaussian = con1,
                                  nong_ord = c(con2, con3, ord1),
                                  binary = bin, categorical = cat2,
                                  weight_col = "mt_wt")$tables$stddiff
tbl <- hv_tbl_compare(tbl, stats::setNames(sprintf("%.1f", 100 * sd$stddiff),
                                           sd$variable),
                      label = "Std. Diff. (%)")
```

and the same with `ps_mw_var(..., seed = )` for a p-value column. Two comparison columns on
one table means `hv_trailing` must hold two entries; it is already a named vector, but only
one column has been exercised. That is checked before implementation, not assumed.

**Why not call hvtiRpropensity from `hv_tbl_summary()`.** hvtiRtables is tier 1 in the hvtiR
release order and depends on no hvtiR package. hvtiRpropensity is tier 2 and sits in a
Suggests cycle with hvtiPlotR. An `Imports` edge would move hvtiRtables below both. A
`Suggests` edge is allowed by the ordering rules, but it would make a tier-1 package's printed
output depend on a 0.2.x API in another repository, and every change to `ps_stddiff()`'s
return shape would become an hvtiRtables defect. hvtiRtemplates already suggests both
packages, so joining there adds no edge anywhere.

## 5. Related findings

### 5.1 The unweighted SMD is not `%stddiff`'s either

`compare = "smd"` uses `gtsummary::add_difference(~ "smd")`. `%summarytable`'s `ASD=` column
comes from `%stddiff`, which splits Gaussian from non-Gaussian and ordinal variables and prints
a percentage. Measured on the synthetic cohort, without weights:

| variable | `%stddiff` bucket | gtsummary | `ps_stddiff()` | ratio |
|---|---|---|---|---|
| age | Gaussian | −0.325 | 0.324 | 1.003 |
| no ties | Gaussian | −0.053 | 0.053 | 1.003 |
| **skewed** | **non-Gaussian** | −0.239 | **0.185** | **1.30** |
| female | binary | −0.254 | 0.254 | 1.000 |
| class (4 levels) | categorical | 0.160 | 0.160 | 1.000 |

Binary and categorical agree exactly. Gaussian agrees to 0.3%. **Non-Gaussian is off by 30%**
here, since `%stddiff` does not use a mean-difference formula for that bucket at all. The
signs are opposite: gtsummary reports first level minus second, `ps_stddiff()` treated minus
control. And `ps_stddiff()` returns a proportion where SAS printed a percentage. Whether SAS's
`ASD=1` column shows the absolute value is open question 8.

`hv_tbl_compare()` lets a template show `ps_stddiff()`'s numbers in every panel today. Whether
`compare = "smd"` itself should change is a separate decision, and not this design's.

### 5.2 `ps_mw_var()` reports its own SDs, and they match neither

`ps_mw_var()` returns per-group `sd_0` and `sd_1` beside its p-value. For age in group 0 it
reports **8.52**, where SAS's definition gives 9.95 and survey's 9.95. The table's SDs
must come from `hv_tbl_summary()`, not from `ps_mw_var()`. Why it differs is a question for
hvtiRpropensity; it may be a different estimator, or a defect.

### 5.3 The bootstrap p-value moves with the seed

`ps_mw_var()` at `n_rep = 1000`, seeds 1 and 2: p = 0.435 / 0.453, 0.622 / 0.627,
0.289 / 0.290. SAS ran `%mw_var` with `SEED=-1`, a fresh seed every run, so no SAS table ever
reproduced its own p-values to the third place either. The template should fix the seed and
print it in the footnote.

### 5.4 A SAS defect in the weighted Total column

With `WEIGHT=` and `TOTALCOL=1`, the macro computes the all-groups statistics into
`_meansall_` and then transposes `_means_`, the by-group table, into `_tmeansall_`
(line 1760). As read, the Total column's weighted mean, SD and percentiles are the by-group
ones, not the overall ones. `tp.dc.stddiff.summarytable.sas` sets `TOTALCOL=0`, so it is not
hit there. The R Overall column will be correct, and will not match SAS where SAS hits it.

## 6. Testing, when implemented

In `test-hv-tbl-summary.R`:

- SD against a hand computation of Σw(x − x̄)²/(Σw − 1) on a five-row fixture;
- the three exact-hit percentile cases in section 3.1, which `"math"` would fail;
- the `__WCountf.` boundaries: 0, 0.0004, 0.001, 0.1, 0.35, 1, 12.25 (expect `12.3`);
- every new validation sentence, and `compare != "none"` with `weight`;
- the weighted group columns get EHB/Blackstone rounding, not only Overall;
- `hv_tbl_compare()` on a weighted and an unweighted table, through both renderers and
  `hv_test_footnotes_jtcvs()`.

`test-contract-parity.R` needs nothing new: no renderer changes. A weighted fixture uses
`haven_labelled` over double, the shape `read_sas()` returns.

## 7. Open questions

1. **Is the weighted panel needed?** The meeting decides. If not, nothing here is built.
2. **SAS's definitions or survey's** for the SD and the percentiles? Recommended: SAS's,
   for migration parity (section 4.3).
3. **Confirm the SAS column on SAS.** Run `proc univariate` with `WEIGHT` and `VARDEF=WDF`
   on the script's synthetic data on the SAS server. That would also settle whether SAS
   applies a tolerance when it tests cᵢ = pW, which `"school"` does not.
4. **Half-up rounding for weighted counts**, as SAS does, against ties-to-even as the
   EHB/Blackstone rule does for mean ± SD?
5. **Footnote and header wording** under a weight: the `*` footnote, and whether the stat
   label says "weighted".
6. **`survey` in Suggests or Imports.** Recommended: Suggests.
7. **Zero weights.** Proposed: allowed, contributing nothing. Negative and missing: an error,
   stricter than SAS.
8. **The SMD's sign and unit**: absolute or signed, percentage or proportion, in all three
   panels.
9. **`ps_mw_var()` on a multi-level categorical.** A binary outcome was measured and works.
   `%summarytable` ran `%mw_var` on categorical variables too (`mtwtp_cat`), and how a
   multi-level variable gets one p-value has not been checked.
10. **Two trailing columns.** A p-value and a standardized difference on one weighted table
    need `hv_trailing` to carry two entries through both renderers. Untested.
