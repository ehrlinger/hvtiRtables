# hv_tbl_summary() — SAS %summarytable migration wrapper — design

Date: 2026-07-17
Status: approved, pending implementation plan

## Problem

The biostats team's most frequently used SAS table is built by `%summarytable`
(referenced via `%include "!MACROS/summarytable.sas"` in calling scripts like
`dc.summarytable_JR.sas`) — a baseline-characteristics/summary table macro
with ~20 parameters covering variable classification (`CON1`/`CON2`/`CON3`/
`CAT1`/`CAT2`/`ORD1`), grouped/ordered variable lists (`LIST=`, using comment
blocks like `/* Demography */`), statistical test selection (Gaussian vs.
non-Gaussian per continuous variable, chi-square vs. Fisher's exact for
categorical), p-values and/or standardized differences (`PVALUES`, `ASD`),
weighting, and propensity-matched mode.

Two real example outputs were examined this session (`summarytable_overall.docx`,
`summarytable_stratified_grp_res.docx`, from a Resilia tissue aortic valve study,
n=7948): an ungrouped "Overall" table and a 3-group ("Overall" / "PERIMOUNT" /
"Resilia") stratified comparison with p-values. Both show a `Variable`
(internal SAS name) column separate from `Factor` (human label), N+stat
column pairs per group with a spanning group header, bold section-header rows
for variable groups (Demography, Symptoms, ...), indented categorical
sub-levels, and lettered p-value footnotes marking which test ran per row
(`a=ANOVA, b=Kruskal-Wallis, c=Pearson's chi-square, d=Fisher's Exact`).

This is the structural pattern `hv_man_table_jtcvs()` already renders (2-row
spanning header, N/stat pairs, bold+`#CAEDFB`-shaded section rows) — the gap
is entirely upstream, in getting from a raw dataset + a SAS-macro-style
grouped variable list to the correct `gtsummary` object.

## Scope

First sub-project only: the non-matched, non-weighted case (both example
docs are this shape). Propensity-matched mode (`PROPENMT=`) and weighted
summaries (`WEIGHT=`) are explicitly deferred — separate future work, not
part of this spec.

## Architecture — thin wrapper over gtsummary, not a from-scratch engine

`hvtiRtables`'s entire premise is "starts from a `gtsummary` object."
`gtsummary` already has mature, tested statistical machinery for everything
`%summarytable` computes: per-group N/stat columns (`tbl_summary()`),
test selection (`add_p()`, including automatic chi-square-vs-Fisher's-exact
fallback), and standardized differences (`add_difference()`, available since
well before this package's `gtsummary >= 2.5.0` floor). Re-implementing any
of this independently would risk a subtly wrong p-value or SMD and diverge
from how every other function in this package works.

`hv_tbl_summary()`'s job is narrow: take a house-style interface modeled on
what SAS users already know from `%summarytable` (grouped/ordered variable
list, variable-type buckets, a comparison-statistic choice) and construct the
correct `tbl_summary()`/`add_p()`/`add_difference()` call. Its output is a
plain `gtsummary` object, handed to the already-built `hv_man_table_jtcvs()`
for rendering. `hv_man_table_jtcvs()`'s existing `groups` mechanism already
handles both the 1-group ("Overall") and N-group (stratified) cases
uniformly, since it takes an arbitrary-length named vector.

**One small renderer change is needed, not "no new rendering logic" as
originally stated here** (caught in Copilot review of this spec):
`hv_man_table_jtcvs()` currently hard-codes its stat sub-header text as the
literal string `"No. (%) or Mean ± SD"` ([R/hv-man-table-jtcvs.R:136](../../../R/hv-man-table-jtcvs.R)),
with no override. Since `hv_tbl_summary()` produces median-based continuous
statistics (see Statistical behavior below), that hard-coded text would be
wrong for its output — the table would say "Mean ± SD" while actually
showing medians. `hv_man_table_jtcvs()` needs a new optional parameter (e.g.
`stat_label`, defaulting to the current `"No. (%) or Mean ± SD"` text so
existing callers are unaffected) that `hv_tbl_summary()` overrides to
`"No. (%) or Median (15th, 85th percentile)"` (see Statistical behavior).
This is a one-parameter, backward-compatible addition to an existing
function, not a new rendering engine — the "thin wrapper" architecture
still holds, this is its one necessary exception.

## Interface

```r
hv_tbl_summary(
  data,
  by = NULL,                  # grouping variable name (string), or NULL for
                               #   a single "Overall" column
  groups,                     # named list: section label -> variable names,
                               #   in display order. Direct equivalent of the
                               #   SAS macro's commented, ordered LIST= block.
                               #   e.g. list(Demography = c("female","age","bsa"),
                               #             Symptoms = c("surgstat","nyha_pr"))
  continuous = character(0),  # variable names summarized as
                               #   median (15th, 85th percentile), matching
                               #   hv_man_footnotes()'s existing house
                               #   convention (see Statistical behavior)
  binary = character(0),      # 0/1 variables, summarized as n (%)
  categorical = character(0), # multi-level variables, all levels shown
                               #   (ordinal variables fold in here too — see
                               #   Deferred)
  compare = c("pvalue", "smd", "both", "none"), # only applies when `by` given
  percentiles = c(15, 85)     # override for a study needing different
                               #   percentiles than the house default
                               #   (SAS macro equivalent: PP=)
)
```

Returns a `gtsummary` object, ready for `hv_man_table_jtcvs()`. Every
variable named in `groups` must appear in exactly one of `continuous` /
`binary` / `categorical`; validated with a clear error, not a silent
mis-classification.

## Statistical behavior

- **Continuous**: blanket non-parametric — Wilcoxon rank-sum (2 groups) /
  Kruskal-Wallis (3+ groups) for every continuous variable, no per-variable
  Gaussian/non-Gaussian classification. This is actually `gtsummary::add_p()`'s
  existing default test for continuous variables, so this requires no custom
  test-selection code, only *not* overriding it. Eliminates the SAS macro's
  `CON2`/`CON3` (Gaussian-classification) parameters and the "which test ran"
  ambiguity for continuous rows — there's only ever one continuous test type.
  Summary statistic is `median (P1, P2)`, defaulting to the **15th/85th
  percentile** — matching `hv_man_footnotes()`'s existing house convention
  ("Median (15th, 85th percentile).") rather than the SAS macro's own default
  of `PP=14 86` (both example calls in this session actually used `pp=16 84`,
  confirming SAS users already override this per study) — overridable via
  `percentiles=`, the direct equivalent of the SAS macro's `PP=`. The stat
  sub-header text passed to `hv_man_table_jtcvs()`'s new `stat_label`
  parameter is generated from whatever `percentiles=` value is in effect
  (e.g. `"No. (%) or Median (15th, 85th percentile)"` at the default), so
  the header always states the percentiles actually used, not a fixed string.
- **Categorical**: `gtsummary::add_p()`'s existing default — chi-square,
  automatically falling back to Fisher's exact when expected cell counts are
  too low. Same behavior the SAS macro's `c=`/`d=` footnote letters describe;
  already automatic, no custom logic needed.
- **SMD**: `gtsummary::add_difference()`.
- **Footnote letters** marking which test ran per row reuse gtsummary's own
  test-name reporting from `add_p()`, not a re-derivation.
- **N column**: `{N_obs}` glue statistic, the same convention
  `hv_man_table_jtcvs()` already uses throughout.

## Scope decisions from this session's discussion

- **`Variable` column (internal SAS/R name) is dropped from the final
  table.** Only the human-readable label appears, matching house rule intent
  (no technical/internal columns in a manuscript table) and how
  `hv_man_table()`/`hv_man_table_jtcvs()` already work.
- **Dual-stat display (mean±SD *and* median[percentiles] shown together) is
  explicitly out of scope as a table feature.** It's a decision-making step,
  not a permanent option: call `hv_tbl_summary()` twice with different
  `statistic=` choices to compare, then finalize with one. No "show both"
  mode in the function itself.
- **Ordinal variables fold into `categorical`**, using standard chi-square/
  Fisher testing, not a trend test (Cochran-Armitage, Jonckheere-Terpstra).
  This is a real scope cut, not a silent one — flagged here and in the
  migration guide as not preserving the SAS macro's `ORD1` distinction.

## Migration guide (SAS → R instruction set)

A companion deliverable alongside the function itself, matching the
`hvtiPlotR` "5-Minute Switch Cheat-Sheet" precedent — biostats team members
who know `%summarytable` need to translate their habits quickly, not learn
`gtsummary` from scratch.

- **Standalone cheat-sheet** (repo README section or vignette): a
  parameter-mapping table, every arg from `%summarytable`'s docstring against
  its `hv_tbl_summary()` equivalent —
  `DATA`→`data`, `CLASS`→`by`, `CON1`/`CAT1`/`CAT2`→
  `continuous`/`binary`/`categorical`, `LIST`→`groups`, `PVALUES`/`ASD`→
  `compare`, `PP`→`percentiles`, `TOTALCOL`/`NCOL`→handled automatically.
  Explicitly marked **not supported in this first pass**: `WEIGHT`,
  `PROPENMT`, `CON2`/`CON3` (Gaussian-classification split — superseded by
  the blanket-nonparametric decision), `SUBSET`, `SORTBY` (ordering comes
  directly from `groups`). Plus a
  worked side-by-side: `dc.summarytable_JR.sas`'s actual call next to the
  equivalent `hv_tbl_summary()` call, using this session's real
  overall/stratified examples.
- **Inline roxygen cross-references**: each `hv_tbl_summary()` argument's
  `@param` doc names its SAS-parameter equivalent, for a reader already at
  `?hv_tbl_summary`.

## Testing

- Characterization tests reproducing key values from both example `.docx`
  files (N counts, at least one continuous median and one categorical n(%),
  the section-header grouping) as a regression guard against real data.
- Unit tests: the `by = NULL` single-column case, each `compare=` option,
  and input validation (a variable in `groups` not classified into any of
  `continuous`/`binary`/`categorical`; an unknown variable name).

## Explicitly deferred (not in this spec)

- Propensity-matched mode (SAS `PROPENMT=`).
- Weighted summaries (SAS `WEIGHT=`).
- Per-variable Gaussian/non-Gaussian classification and dual-statistic
  display as permanent table features (superseded by the blanket-nonparametric
  and exploratory-only decisions above).
- Ordinal-specific trend tests (Cochran-Armitage, Jonckheere-Terpstra).
- Exact function/argument names beyond what's specified here are subject to
  refinement at planning time if implementation reveals a clearer name.
