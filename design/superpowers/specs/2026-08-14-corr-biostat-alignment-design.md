# Aligning hvtiRtables for CORR biostatisticians — design

Date: 2026-08-14
Status: approved, pending implementation plan

## Problem

`hvtiRtables` is documented as an R package with a SAS migration note appended.
Its intended user is the opposite: a CORR biostatistician fluent in the
`%summarytable` macro and the `tp.dc.*` template family, who knows `gtsummary`
barely or not at all. That reader arrives knowing what `CON3=`, `PP=`,
`TBLTITLE=` and `ADDFN=` do, and needs to find out what this package calls
them and where the numbers will differ.

The current documentation does not serve that reader, and in six specific
places it misleads them. A sweep of `summarytable.sas`'s parameter docstring
(`~/Documents/macro.library/summarytable.sas`) and the real template calls in
`~/Documents/template/descriptive/templates/` against this package's
`README.md`, roxygen, and `_pkgdown.yml` produced the findings below.

## Reader

A CORR biostatistician porting an existing `%summarytable` program to R.
Assumed fluent in the macro and the `tp.dc.*` templates. Assumed to have no
`gtsummary` knowledge, and not to want any beyond what the port requires.
Documentation written for this reader states the SAS thing first and the R
thing second, in every case.

## Scope

Three tracks are in scope for "align for CORR biostats" across the estate.
**Only track 1 is in scope for this spec:**

1. **hvtiRtables** — make this package legible to a macro-fluent reader.
   Reference structure, vocabulary, one feature gap, one new vignette.
2. **hvtiRtemplates** — the corpus-wide crosswalk over 240 legacy templates
   and 495 macro files. That package's README already claims this mandate
   ("the legacy SAS template corpus and macro library as a reference
   specification"). Separate spec.
3. **`dc.*` port** — porting the `dc.*` descriptive-table template family, and
   the `proc_contents()`/`proc_means()` work already shipped in
   `hvtiRutilities`. This is a port, not documentation, and per the standing
   handoff it must not start speculatively. Separate spec.

## Findings the work must address

Each was verified against the macro source or the real template calls, not
inferred.

| # | Current documentation | Actual behavior |
|---|---|---|
| 1 | README maps `CON1=` to `continuous`, and lists `CON2=`/`CON3=` as unsupported. | Backwards. `CON1=` is mean ± SD with one-way ANOVA. `hv_tbl_summary()`'s continuous behavior is exactly `CON3=` (`median [P(1), P(2)]`, Kruskal-Wallis) plus `PP=`. `CON3=` is the parameter that survives; `CON1=`/`CON2=` are the ones with no equivalent. |
| 2 | Silent. | `%summarytable` fuses computation and document output. `RTFFILE=`, `PDFFILE=`, `XMLFILE=`, `TBLTITLE=`, `ADDFN=`, `PRINTFN=`, `STYLE=`, `PAGE=`, `CWIDTH1-3=`, `PAPERSIZE=` are output parameters in the same call as `CON1=`. The README's mapping table covers only the computation half, so a reader looking up `TBLTITLE=` or `ADDFN=` finds nothing — the answers are `caption =` and `footnotes =` on the save functions. |
| 3 | README: `TOTALCOL=`/`NCOL=` "handled automatically". | `NCOL=` yes, via the `{N_obs}` pair. `TOTALCOL=` no: `hv_tbl_summary()` never calls `gtsummary::add_overall()`, so there is no way to produce the Overall column the macro adds by default. This is a feature gap, not a documentation gap. (`NCOL=3` is "both overall and per-group Ns"; the package produces per-group only, i.e. `NCOL=2` behavior.) |
| 4 | Spec and README: "chi-square, automatically falling back to Fisher's exact". | True on both sides, at **different thresholds**. `CUTEXACT=50` fires Fisher's exact when ≥50% of cells have expected count <5. `gtsummary` fires when *any* expected count is <5. The same data can select a different test, and therefore print a different footnote letter. |
| 5 | Unsupported list names `WEIGHT=`, `PROPENMT=`, `CON2=`/`CON3=`, `SUBSET=`, `SORTBY=`. | Also unsupported and unlisted: `COLPCT=0` (row percentages), `MISSCOL=`, `ADHOC=`, `ODDSRATIOS=`, `CUTEXACT=`, and the output-formatting parameters from finding 2 that have no R equivalent (`STYLE=`, `PAGE=`, `CWIDTH*=`, `PAPERSIZE=`). |
| 6 | Silent in user-facing docs. | Two traps recorded only in specs and memory: SAS `QNTLDEF=5` (the house default) corresponds to `stats::quantile(type = 2)`, not R's default `type = 7`; and `haven::read_sas()` returns `haven_labelled` over double, which is why `binary`/`categorical` must be stated rather than inferred. The latter appears only as a roxygen `@param` aside. |

### Findings that did *not* survive verification

Recorded here so they are not re-raised. An earlier reading of the macro's
nominal defaults suggested two divergences that the real template calls
contradict:

- **Percentiles.** The macro's nominal default is `PP=16 84`. But
  `tp.dc.stddiff.summarytable.sas` calls `pp=15 85` and
  `tp.dc.stddiffci.sumtbl.sas` calls `pp=16 84` — both are live house practice.
  `hv_tbl_summary()`'s `percentiles = c(15, 85)` matches the former and
  `hv_man_footnotes()`'s existing footnote text. **Keep it.** The existing
  `hv_stat_label` attribute already renders the percentiles actually used into
  the sub-header, so a reader can never silently misread which pair produced a
  column. Document the divergence; do not change the default.
- **`compare`.** The macro's nominal default is `PVALUES=0`. Every real
  template call passes `pvalues=1`. `compare = "pvalue"` already matches
  practice. **Keep it.**

The earlier spec's claim that the macro default is `PP=14 86`
(`2026-07-17-hv-tbl-summary-sas-migration-design.md`) is wrong; 14/86 was a
macro bug corrected on 2021/06/15. Not worth amending a historical spec, but
the migration vignette must not repeat it.

## Architecture — the four-stage spine

The organizing idea for every deliverable below is that **`%summarytable` does
in one call what this package splits into four stages**, and the split is the
first thing a macro-fluent reader must internalize.

| Stage | hvtiRtables | `%summarytable` parameters that land here |
|---|---|---|
| Compute stats and tests | `hv_tbl_summary()` | `DATA=`, `CLASS=`, `CON*=`, `CAT*=`, `ORD1=`, `LIST=`, `PP=`, `PVALUES=`, `ASD=`, `TOTALCOL=` |
| Shape the table | `hv_man_table()`, `hv_man_table_jtcvs()` | `STYLE=`, `PAGE=`, header options |
| Write the file | `hv_man_table_save()`, `hv_man_table_save_jtcvs()` | `RTFFILE=`, `PDFFILE=`, `TBLTITLE=`, `ADDFN=`, `PRINTFN=` |
| Verify the file | `hv_check_docx()` | *(no analogue — new capability)* |

Flat-header versus JTCVS is a journal choice within stage 2, not a stage of
its own.

## Deliverables

### D1 — Reference index restructured (`_pkgdown.yml`)

Replace the current R-concept sections ("Building Tables from Data",
"Flat-Header Tables", "JTCVS Merged-Header Tables", "Footnotes", "Checking
Written Files") with the four spine stages, each titled to name the SAS
analogue it replaces. Flat-header and JTCVS become sub-groupings under stage 2.

Each section's `desc:` states the SAS analogue first.

### D2 — Roxygen vocabulary coverage

`hv_tbl_summary()` already names the macro parameter in every `@param`. Extend
the same treatment to the functions that received none:

- `hv_man_table_save()` / `hv_man_table_save_jtcvs()`: `caption` names
  `TBLTITLE=`; `footnotes` names `ADDFN=` and `PRINTFN=`; the output path names
  `RTFFILE=`/`PDFFILE=`.
- `hv_man_table()` / `hv_man_table_jtcvs()`: `stat_label`, `groups`, `trailing`
  described against what the macro emitted in the same position.
- `hv_man_footnotes()` / `hv_test_footnotes_jtcvs()`: name the macro's lettered
  test-footnote block as the thing being reproduced, and state that `a=ANOVA`
  never appears here (consequence of the blanket non-parametric choice).

### D3 — Errors that teach the translation

Public functions gain `...` capture. Any argument name matching a known
`%summarytable` parameter produces an error naming the R argument to use
instead, and — where the parameter belongs to a different stage — which
function to pass it to.

Two shapes:

- Same stage: passing `class=` to `hv_tbl_summary()` errors with
  "`class` is the `%summarytable` name; use `by =`."
- Different stage: passing `tbltitle=` to `hv_tbl_summary()` errors with
  "`tbltitle` is a `%summarytable` output parameter; pass `caption =` to
  `hv_man_table_save()`."
- No equivalent: passing `weight=` errors with "`WEIGHT=` (weighted summaries)
  is not supported."

Implemented as one static lookup table shared by all public functions, keyed by
lowercased macro parameter name, mapping to a message. Not a general
did-you-mean matcher — an explicit table, so every message is written and
reviewed rather than generated.

**Real argument aliases are explicitly rejected.** Two permanent names for one
argument doubles the validation surface and lets SAS habits persist instead of
converting. The error gets the same teaching moment at a fraction of the cost.

### D4 — `TOTALCOL=` equivalent (the one behavior change)

`hv_tbl_summary()` gains `overall = FALSE`, adding a `gtsummary::add_overall()`
column when `TRUE` and `by` is non-`NULL`. Documented as the `TOTALCOL=`
equivalent.

Default is `FALSE`, not the macro's `TOTALCOL=1`, because the package's
existing renderers take a `groups` vector naming each `stat_<k>` column, and
silently introducing an extra column would break every existing caller's
`groups` argument. The divergence from the macro default is documented in the
migration vignette's defaults table rather than resolved in favor of the macro.

Note for implementation: `totalcol=3` appears in some real template calls, but
the macro tests only `%IF &TOTALCOL=1`, so those calls produce no Overall
column. Reproduce the macro's *behavior*, not the apparent intent of the call.

### D5 — `vignettes/sas-migration.Rmd`

Title: "Porting a `%summarytable` program to R". Ordered so the costly parts
come first.

1. **The four-stage split** — the spine table above, stated as the first thing
   after the intro. One macro call becomes three or four R calls, and the
   parameters the reader knows are distributed across them.
2. **Defaults that differ** — `TOTALCOL=1` versus `overall = FALSE`; the
   `CUTEXACT=50` versus any-expected-<5 threshold; `CON1=` mean ± SD versus
   blanket median; `PP=` house variation (15/85 and 16/84 both live). Each row
   gives the SAS default, the R default, and the one-line fix.
3. **A ported call, line by line** — the real `%summarytable` call from
   `tp.dc.stddiff.summarytable.sas`, not executed, beside its
   `hv_tbl_summary()` equivalent, annotated where a parameter moved stage
   rather than mapped.
4. **Parameter map, corrected** — full table over every `%summarytable`
   parameter, routing each to a stage or to "not supported", with findings 1,
   2 and 5 fixed.
5. **Why my p-value moved** — `ORD1=` folded to chi-square rather than
   Kruskal-Wallis; the `CUTEXACT` threshold; blanket non-parametric testing on
   former `CON1=` variables. Frames the missing `a=ANOVA` footnote letter as a
   consequence, not a defect.
6. **Percentiles and `QNTLDEF`** — executed chunk demonstrating
   `quantile(c(1, 2, 3, 4), 0.25, type = 2)` → 1.5 against `type = 7` → 1.75,
   identified as the `QNTLDEF=5` equivalence. States that `gtsummary`'s `{pXX}`
   tokens already use `type = 2`, so `hv_tbl_summary()` is correct, and that
   any hand-written `quantile()` call in ported code is not.
7. **Reading the SAS data in** — `haven::read_sas()` yielding `haven_labelled`
   over double, and why `binary`/`categorical` must be stated rather than
   inferred.

Executed chunks use `gtsummary::trial`, so the vignette builds on CI. The
worked side-by-side in section 3 is not executed, so it can use the real
template call. The vignette ends at the `gtsummary` object and links to the
existing end-to-end vignette for rendering.

### D6 — README section trimmed

The migration section shrinks to the four-stage table, a one-paragraph
statement of the biggest divergence, and a link to the vignette. The corrected
detail lives in the vignette, in one place. The factually wrong `CON1=` row
(finding 1) must not survive anywhere.

## Testing

- Unit tests for D3: each entry in the lookup table produces an error, and the
  message names the correct R argument. One test per stage-shape (same stage,
  different stage, no equivalent).
- Unit tests for D4: `overall = TRUE` adds exactly one column and only when
  `by` is non-`NULL`; `overall = TRUE` with `by = NULL` errors rather than
  silently doing nothing; default `FALSE` reproduces current output unchanged.
- Regression test for the `QNTLDEF` claim the vignette makes:
  `quantile(c(1, 2, 3, 4), 0.25, type = 2) == 1.5`. Guards the documented
  equivalence against a future change of computation path.
- Vignette builds clean under `R CMD check` with the manual, within the
  standing check-time budget.

## Explicitly out of scope

- Tracks 2 and 3 above (hvtiRtemplates crosswalk; `dc.*` port).
- Changing `percentiles` or `compare` defaults — verified above as already
  matching house practice.
- Real argument aliases (D3 rationale).
- Weighted, propensity-matched, and matching-weighted modes (`WEIGHT=`,
  `PROPENMT=`, `MWOUTCOMES=`), unchanged from the original migration spec.
- Matching the `CUTEXACT=50` threshold by overriding `gtsummary`'s test
  selection. Documented as a divergence; changing it would mean re-implementing
  test selection, which the thin-wrapper architecture exists to avoid.

## Versioning

D4 adds an argument and D3 adds errors on input previously ignored, so this is
a behavior change, not a documentation-only release.

**The maintainer's stated intent (2026-08-14) is that this work leads to
`1.0.0`** — the point at which the package is claimed as the CORR group's
supported table interface rather than a working draft. That is a deliberate,
human-reviewed release, not a digit bumped when the last task passes.

Two consequences the implementation must respect:

1. **Do not set `1.0.0` from this plan.** Work accumulates under the current
   `0.9.x` patch line. The maintainer cuts `1.0.0` when the feature set is
   complete, in a separate release commit.
2. **`1.0.0` triggers the full release gate**, internal destination
   notwithstanding: complete CRAN Cookbook audit, `R CMD check --as-cran`
   **with** the manual built and vignettes built, overall check time under ten
   minutes, reverse-dependency check, and `urlchecker::url_check()`. The new
   vignette adds to check time and the new pkgdown `articles:` block adds URLs,
   so both gates are live concerns for this work specifically, not boilerplate.

What is *not* yet decided is whether `1.0.0` is cut from this spec's work alone
or waits on further alignment (most plausibly the `dc` prefix landing, per the
separate macro-allocation work). That remains the maintainer's call.
