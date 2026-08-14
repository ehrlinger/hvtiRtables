# Porting a %summarytable program to R

``` r

library(hvtiRtables)
```

This is written for someone who knows `%summarytable` and the `tp.dc.*`
templates, and does not want to learn `gtsummary` beyond what the port
requires. It ends at the summary object; rendering it is covered in
[`vignette("hvtiRtables")`](https://ehrlinger.github.io/hvtiRtables/articles/hvtiRtables.md).

## One macro call becomes three

`%summarytable` computes the table *and* writes the document. Its
`RTFFILE=`, `TBLTITLE=`, `ADDFN=`, `STYLE=` and `PAGE=` parameters sit
in the same call as `CON1=` and `CLASS=`. This package splits that work,
so the parameters you know are distributed across separate calls:

| Stage | Function | Macro parameters that land here |
|----|----|----|
| Compute stats and tests | [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md) | `DATA=`, `CLASS=`, `CON*=`, `CAT*=`, `ORD1=`, `LIST=`, `PP=`, `PVALUES=`, `ASD=`, `TOTALCOL=` |
| Shape the table | [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md), [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md) | *(none - house style is fixed)* |
| Write the file | [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md), [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md) | `RTFFILE=`, `PDFFILE=`, `XMLFILE=`, `TBLTITLE=`, `ADDFN=`, `PRINTFN=` |
| Verify the file | [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md) | *(no analogue)* |

If you pass a macro parameter to the wrong stage, the error says which
function takes it:

``` r

hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = "age"), continuous = "age",
  tbltitle = "Table 1"
)
#> Error:
#> ! `tbltitle` is a `%summarytable` parameter this package handles at a different stage: pass `caption =` to `hv_man_table_save_jtcvs()`.
```

## Defaults that differ

Five places where a faithful-looking port produces different numbers.

| Macro | Default there | Default here | Fix |
|----|----|----|----|
| `TOTALCOL=` | `1` - Overall column included | `overall = FALSE` | `overall = TRUE` |
| `CON1=` | mean +/- SD, one-way ANOVA | median (percentiles), Kruskal-Wallis | none - see below |
| `PP=` | `16 84` nominal; house templates use both `15 85` and `16 84` | `percentiles = c(15, 85)` | `percentiles = c(16, 84)` |
| `CUTEXACT=` | Fisher when \>=50% of cells have expected \< 5 | Fisher when *any* expected \< 5 | none - not tunable |
| `ORD1=` | `n (%)`, Kruskal-Wallis | folds into `categorical`, chi-square | none |

`overall = FALSE` is the one deliberate departure from a macro default.
The renderers take a `groups` vector naming each `stat_<k>` column, so a
column appearing by default would break every existing call.

## A ported call

The `%summarytable` call from `tp.dc.stddiff.summarytable.sas`:

``` sas
%summarytable(data=built,
              class=grp_res,
              con3=&nongau.,
              cat1=&binary.,
              cat2=&catg.,
              pp=15 85,
              totalcol=0,
              pvalues=1,
              list=
    /* Demography */
       female AGE BSA race_gp
    /* Symptoms */
       surgstat nyha_pr
);
```

and its equivalent. Note that `pp=` and `list=` map straight across,
`totalcol=0` is the default here so it disappears, and `pvalues=1`
becomes `compare = "pvalue"`:

``` r

tbl <- hv_tbl_summary(
  built,
  by = "grp_res",
  groups = list(
    Demography = c("female", "AGE", "BSA", "race_gp"),
    Symptoms   = c("surgstat", "nyha_pr")
  ),
  continuous  = c("AGE", "BSA"),
  binary      = c("female", "surgstat"),
  categorical = c("race_gp", "nyha_pr"),
  compare     = "pvalue",
  percentiles = c(15, 85)
)
```

## Parameter map

| `%summarytable` | Here | Notes |
|----|----|----|
| `DATA=` | `data` |  |
| `CLASS=` | `by` |  |
| `LIST=` | `groups` | a named list; the section comments become the names |
| `CON1=` | `continuous` | **statistic changes** - mean +/- SD becomes median (percentiles) |
| `CON2=` | `continuous` | **statistic changes** - median (min, max) becomes median (percentiles) |
| `CON3=` | `continuous` | direct equivalent; this is the behavior `continuous` reproduces |
| `CAT1=` | `binary` |  |
| `CAT2=` | `categorical` |  |
| `ORD1=` | `categorical` | **test changes** - Kruskal-Wallis becomes chi-square |
| `PP=` | `percentiles` |  |
| `PVALUES=` | `compare = "pvalue"` |  |
| `ASD=` | `compare = "smd"` / `"both"` |  |
| `TOTALCOL=` | `overall` | default differs - see above |
| `NCOL=` | automatic | per-group Ns always shown; `NCOL=3`’s overall N needs `overall = TRUE` |
| `TBLTITLE=` | `caption` | **JTCVS only** - [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md) writes no caption |
| `ADDFN=` | `footnotes` | on the save function |
| `PRINTFN=` | `footnotes = hv_man_footnotes()` | **CORR only.** The house block is CORR-shaped and cannot be passed to [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md), which needs `list(row =, col =, text =)` entries; build those, or use [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md). It also hard-codes the 15th/85th percentiles, so change it if you change `percentiles` |
| `RTFFILE=`, `PDFFILE=`, `XMLFILE=` | `file` | output is always `.docx` |

The save stage is a sibling pair, and the two do not take the same
arguments: only
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
has `caption`. For a flat-header CORR table the title goes in the
document, not the call.

Not supported: `WEIGHT=`, `PROPENMT=`, `MWOUTCOMES=`, `SUBSET=` (subset
the data frame first), `SORTBY=` (order comes from `groups`), `COLPCT=0`
(row percentages), `MISSCOL=`, `ADHOC=`, `ODDSRATIOS=`, `CUTEXACT=`,
`STYLE=`, `PAGE=`, `CWIDTH1-3=`, `PAPERSIZE=`.

## Why my p-value moved

Three causes, in order of how often they explain it.

1.  **A `CON1=` variable.** The macro ran one-way ANOVA on it. Every
    continuous variable here is tested non-parametrically. This is also
    why no footnote letter reads `a=ANOVA`.
2.  **An `ORD1=` variable.** The macro ran Kruskal-Wallis; folded into
    `categorical`, it gets chi-square. No trend test is run.
3.  **A sparse categorical variable.** Both switch to Fisher’s exact, at
    different thresholds - `CUTEXACT=50` needs half the cells to have
    expected counts below 5, `gtsummary` needs one.

## Percentiles and QNTLDEF

SAS’s house `QNTLDEF=5` is not R’s default quantile definition. It
corresponds to `type = 2`:

``` r

stats::quantile(c(1, 2, 3, 4), 0.25, type = 2, names = FALSE)  # SAS house
#> [1] 1.5
stats::quantile(c(1, 2, 3, 4), 0.25, type = 7, names = FALSE)  # R default
#> [1] 1.75
```

Medians agree at every n; Q1, Q3 and `pNN` diverge silently.
`gtsummary`’s `{pXX}` statistics already use `type = 2`, so
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
matches SAS without intervention. **Any
[`stats::quantile()`](https://rdrr.io/r/stats/quantile.html) call you
write by hand in ported code does not** - pin `type = 2` explicitly.

The percentiles actually used are recorded on the table object as
`attr(tbl, "hv_stat_label")`, but nothing consumes that attribute
automatically.
[`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)’s
`stat_label` argument defaults to a literal mean-and-SD string, so a
`percentiles = c(16, 84)` table rendered without an explicit
`stat_label =` claims mean/SD over median columns. You MUST pass it
yourself:

``` r

tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "marker")),
  continuous = c("age", "marker"),
  percentiles = c(16, 84)
)
attr(tbl, "hv_stat_label")
#> [1] "No. (%) or Median (16th, 84th percentile)"
```

``` r

ft <- hv_man_table_jtcvs(
  tbl,
  groups = c(stat_1 = "Drug A", stat_2 = "Drug B"),
  stat_label = attr(tbl, "hv_stat_label")
)
```

## Reading the SAS data in

[`haven::read_sas()`](https://haven.tidyverse.org/reference/read_sas.html)
returns `haven_labelled` columns over doubles, because every SAS numeric
is an 8-byte float. A 0/1 flag therefore arrives looking like a
continuous variable, and type guessers classify it as one.

This is why `binary` and `categorical` are stated rather than inferred:
name every variable in exactly one of `continuous`, `binary` or
`categorical`, and a misclassification is an error rather than a wrong
table.

``` r

hv_tbl_summary(
  gtsummary::trial, groups = list(D = "age"),
  continuous = "age", binary = "age"
)
#> Error:
#> ! `age` appears in more than one of `continuous`, `binary`, and `categorical`. Every variable must be classified exactly once. Overlapping: age (continuous, binary).
```
