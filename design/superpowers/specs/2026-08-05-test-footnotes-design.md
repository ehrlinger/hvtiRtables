# hv_test_footnotes_jtcvs(): automatic lettered test footnotes: design

Date: 2026-08-05
Status: approved, pending implementation plan
Depends on: PR #11 (`feat/hv-tbl-summary`), which introduces
`hv_tbl_summary()` and the `hv_compare_col` column this feature reads.

## Problem

The SAS `%summarytable` macro marks every p-value cell with a superscript
letter identifying which statistical test produced it, and defines the
letters in a footnote below the table. From the real stratified example
output (`summarytable_stratified_grp_res.docx`, the Resilia tissue aortic
valve study also used as the source for the
[hv_tbl_summary() spec](2026-07-17-hv-tbl-summary-sas-migration-design.md)),
the footnote reads:

```
p-values: a=ANOVA, b=Kruskal-Wallis test, c=Pearson's chi-square test,
d=Fisher's Exact test.
```

and the body cells read `<.0001c`, `.12a`, `.0072a`.

Everything needed to reproduce this in R already exists, but nothing
connects the two ends:

- `gtsummary::add_p()` records which test ran per row in a `test_name`
  column of `tbl$table_body`, and that column survives untouched on the
  object `hv_tbl_summary()` returns.
- [`hv_man_table_save_jtcvs()`](../../../R/hv-man-table-save-jtcvs.R)
  already renders lettered footnotes attached to specific body cells, via
  its `footnotes = list(list(row =, col =, text =))` argument.

The gap is entirely in the middle. Today a caller can build these
footnotes by hand from `test_name`, but they must map gtsummary's internal
test identifiers to readable labels themselves, and must compute body-row
indices that account for the section-header rows
[`hv_man_table_jtcvs()`](../../../R/hv-man-table-jtcvs.R) interleaves. Both
are error-prone, and the second fails silently: a wrong index marks the
wrong cell rather than raising an error.

## Scope

One new exported function, two small internal refactors, and one bug fix
in `hv_tbl_summary()` that this feature depends on. No new table class, no
new renderer, no new statistics.

Explicitly out of scope: automatic footnotes for the flat CORR renderer
(`hv_man_table()`/`hv_man_table_save()`), which uses a fixed symbol set on
the header row rather than lettered body-cell markers, and which strips
section-header rows so its row indices differ.

## Empirical grounding

Every claim below about gtsummary's behavior was verified against
gtsummary 2.5.1 during this design session rather than assumed.

**The `test_name` vocabulary is four values, not the SAS macro's four.**
Running `add_p()` over continuous, dichotomous, multi-level, and sparse
categorical variables at both 2 groups and 3 groups produces exactly:

| `test_name` | When |
|---|---|
| `wilcox.test` | continuous, 2 groups |
| `kruskal.test` | continuous, 3+ groups |
| `chisq.test.no.correct` | categorical, expected counts adequate |
| `fisher.test` | categorical, sparse |

No ANOVA and no t-test appear, which is the blanket-nonparametric scope
decision from the
[hv_tbl_summary() spec](2026-07-17-hv-tbl-summary-sas-migration-design.md)
showing up in the data. The letter set therefore differs from the SAS
macro's: `%summarytable` classifies each continuous variable as Gaussian
or non-Gaussian and emits ANOVA for the Gaussian ones, whereas this
package never does.

**`test_name` is populated on every row of a variable** (`label`, `level`,
`missing`), but `p.value` is non-NA only on the `label` row. Markers must
therefore be placed by looking at the displayed comparison column, not at
`test_name`.

**A vector-valued `row` already works.**
`hv_man_table_save_jtcvs()` passes `fn$row` straight through as
`flextable::append_chunks()`'s `i` argument
([R/hv-man-table-save-jtcvs.R:70](../../../R/hv-man-table-save-jtcvs.R)),
and `append_chunks(i = c(1, 3), ...)` was confirmed to attach the same
superscript to both rows. Collapsing many cells onto one letter needs no
code change in the save function, only a documentation correction: its
`@param footnotes` currently describes `row` as a single index.

**`compare = "both"` is currently broken.** `hv_tbl_summary()` calls
`add_p()` then `add_difference()`. In that order gtsummary overwrites
`test_name` with `"smd"` and the `estimate` column stops being a
standardized difference:

```r
add_p() then add_difference():   test_name = "smd",         estimate = -0.9999612
add_difference() then add_p():   test_name = "wilcox.test", estimate = -0.0306604
```

For `gtsummary::trial$age` the correct SMD is -0.0307; -0.99996 is the raw
mean difference. Reversing the two calls fixes the wrong statistic and
preserves the test names this feature needs. See "The compare = both fix"
below.

## Architecture

A standalone helper that produces the `footnotes` list the save function
already accepts:

```
hv_tbl_summary(data, ...)  ->  gtsummary object
                                 |  table_body$test_name
                                 |  table_body$hv_compare_col
                                 |  table_body$groupname_col
                                 v
                   hv_test_footnotes_jtcvs(tbl)
                                 |
                                 v
              list(list(row = c(4, 9, 12), col = "hv_compare_col",
                        text = "Wilcoxon rank-sum test."), ...)
                                 |
                                 v
              hv_man_table_save_jtcvs(ft, ..., footnotes = <that>)
```

The helper takes the **gtsummary** object, not the flextable. This is
forced, not stylistic: `hv_man_table_save_jtcvs()` receives only `ft`, and
by that point `test_name` and `groupname_col` have both been discarded by
`.reshape_jtcvs_body()`. Putting the automation on the save function would
mean threading a gtsummary object into a renderer that is deliberately
flextable-in, docx-out.

A standalone helper is also the option that composes. Its return value is
an ordinary list, so study-specific footnotes concatenate with `c()`, and
rewording is ordinary list manipulation. This is the same shape as the
existing [`hv_man_footnotes()`](../../../R/hv-man-footnotes.R), which
returns a plain list rather than taking override arguments.

### Naming

`hv_test_footnotes_jtcvs()`, with the `_jtcvs` suffix the package already
uses for renderer-specific functions (`hv_man_table_jtcvs()`,
`hv_man_table_save_jtcvs()`). The suffix is load-bearing rather than
cosmetic: the returned `row` indices are only valid against
`hv_man_table_jtcvs()` output, because `hv_man_table()` removes the
section-header rows that shift them
([R/hv-man-table.R:13](../../../R/hv-man-table.R)). A suffix-free
`hv_test_footnotes()` would sit next to `hv_man_footnotes()`, which serves
the CORR renderer, and imply the wrong association.

## Interface

```r
hv_test_footnotes_jtcvs(tbl)
```

**`tbl`**: a `gtsummary` object, normally from `hv_tbl_summary()`. Must be
the same object passed to `hv_man_table_jtcvs()`, since the row indices are
computed from its `table_body`.

**Returns**: a list of `list(row =, col =, text =)` entries, one per
distinct statistical test present, in the canonical order below, ready to
pass as `hv_man_table_save_jtcvs()`'s `footnotes` argument. Returns
`list()` when there are no test-based p-values to mark.

### Worked example

```r
tbl <- hv_tbl_summary(
  dat, by = "grp",
  groups     = list(Demography = c("age", "female")),
  continuous = "age", binary = "female",
  compare    = "pvalue"
)
ft <- hv_man_table_jtcvs(
  tbl,
  groups     = c(stat_1 = "PERIMOUNT (n=4190)", stat_2 = "Resilia (n=3758)"),
  trailing   = attr(tbl, "hv_trailing"),
  stat_label = attr(tbl, "hv_stat_label")
)
hv_man_table_save_jtcvs(
  ft, "table1.docx",
  caption   = "Table 1. Baseline Characteristics",
  footnotes = c(
    hv_test_footnotes_jtcvs(tbl),
    list(list(row = 1, col = "n_stat_1",
              text = "Patients with data available."))
  )
)
```

Test footnotes take letters `a`, `b`, ... in the order returned; the
study-specific note takes the next letter. Letters are assigned by the
save function from list position, so the caller controls ordering by
choosing the `c()` order.

## Test-label mapping

Fixed canonical order, filtered to the tests actually present in the
table:

| Order | `test_name` | Footnote text |
|---|---|---|
| 1 | `wilcox.test` | `Wilcoxon rank-sum test.` |
| 2 | `kruskal.test` | `Kruskal-Wallis test.` |
| 3 | `chisq.test.no.correct` | `Pearson chi-square test.` |
| 4 | `fisher.test` | `Fisher exact test.` |

Canonical order rather than order of first appearance: it mirrors the SAS
macro's own listing order (ANOVA, Kruskal-Wallis, chi-square, Fisher), and
it means any two tables in a manuscript that use the same set of tests get
the same letters regardless of how their variables happen to be ordered.
Order of first appearance would swap letters between two tables that
differ only in whether a continuous or a categorical variable comes first.

`"smd"` is a recognized value that deliberately maps to nothing, since a
standardized difference is not a test.

Any other value is appended after the canonical four, sorted
alphabetically, using the raw `test_name` string as its footnote text, and
a `warning()` names the unmapped values. Unmapped values are only
reachable from a hand-built object that passed `add_p(test = ...)`, since
`hv_tbl_summary()` never sets `test`. Warning-plus-fallback rather than
silent omission: a marked cell whose letter has no definition, or an
unmarked cell in an otherwise marked column, is worse than an ugly label.

There is no override argument for the wording. The return value is a plain
list; callers reword with ordinary list operations, exactly as
`hv_man_footnotes()`'s documentation already shows.

## Row-index computation

This is the known sharp edge and the part most worth getting structurally
right.

`hv_man_table_jtcvs()` inserts one section-header row immediately before
each run of same-`groupname_col` rows, so for gtsummary body row `i` the
rendered flextable body row is:

```
i + sum(section_starts <= i)
```

The `<=` rather than `<` is the easy thing to get wrong: the header
inserted before a section's first row pushes that row itself down as well.

Rather than reimplement the section-start rule in the helper and let two
copies drift apart, the existing logic inside `.reshape_jtcvs_body()`
([R/hv-man-table-jtcvs.R:33](../../../R/hv-man-table-jtcvs.R)) is extracted
into a shared internal:

```r
.jtcvs_section_starts <- function(tb) {
  if (!"groupname_col" %in% names(tb)) return(integer(0))
  which(c(TRUE, tb$groupname_col[-1] != tb$groupname_col[-nrow(tb)]))
}
```

`.reshape_jtcvs_body()` is rewritten to call it, with behavior unchanged
and the existing `test-hv-man-table-jtcvs.R` tests as the check. The
helper derives its indices from the same function, so there is one source
of truth. A dedicated test asserts that the helper's computed index for a
known variable equals that row's actual position in
`.reshape_jtcvs_body()`'s output, so the two cannot silently diverge if
either is edited later.

The extraction preserves the current handling of `NA` in `groupname_col`
exactly (`which()` drops `NA`, so a row with no section does not start
one). That is pre-existing behavior and not in scope to change here;
`hv_tbl_summary()` assigns every row a section.

## Which cells get a marker

A cell is marked when both of these hold for its row:

1. The comparison column is non-`NA`. The column name is taken from
   `names(attr(tbl, "hv_trailing"))` when that attribute is set, otherwise
   `"hv_compare_col"`.
2. `test_name` maps to a real test in the table above.

All rows sharing a test collapse into a single entry with a vector-valued
`row`, so one letter is defined once and marks every cell it applies to.
Without this, a 30-row table with three tests would need 30 entries and 30
footnote paragraphs, and would exhaust the 26-letter alphabet the save
function caps at.

### Empty cases

`list()` is returned, with no warning, when:

- `by = NULL` or `compare = "none"`: no comparison column exists.
- `compare = "smd"`: every `test_name` is `"smd"`.
- No row has a non-`NA` comparison value.

`list()` composes correctly in both directions: `c(list(), other)` equals
`other`, and `hv_man_table_save_jtcvs(footnotes = list())` iterates zero
times. Callers do not need a conditional around the helper.

### compare = "both"

After the reorder below, `"both"` mode yields real test names and the
letter attaches to the combined cell, which reads e.g. `0.72 (SMD -0.03)`.
The letter marks only the p-value portion of that cell. This is documented
in the function's `@details` rather than worked around, since splitting
the cell would mean changing the column format that
[the hv_tbl_summary() spec](2026-07-17-hv-tbl-summary-sas-migration-design.md)
settled on.

## The compare = both fix

Two lines reordered in `hv_tbl_summary()` (`R/hv-tbl-summary.R`, which
arrives with PR #11):

```r
# current
if (effective_compare %in% c("pvalue", "both"))
  tbl <- gtsummary::add_p(tbl)
if (effective_compare %in% c("smd", "both"))
  tbl <- gtsummary::add_difference(tbl, gtsummary::everything() ~ "smd")

# reordered
if (effective_compare %in% c("smd", "both"))
  tbl <- gtsummary::add_difference(tbl, gtsummary::everything() ~ "smd")
if (effective_compare %in% c("pvalue", "both"))
  tbl <- gtsummary::add_p(tbl)
```

This is in scope because the feature depends on it: without the reorder,
`"both"` mode has no recoverable test names. It is worth doing on its own
merits regardless, since it also fixes a wrong published statistic. It
changes no behavior for `compare = "pvalue"`, `"smd"`, or `"none"`, each of
which runs at most one of the two calls.

## Save-function guard

`hv_man_table_save_jtcvs()` gains validation of each footnote entry before
rendering:

- `fn$row` must be within `flextable::nrow_part(ft, "body")`.
- `fn$col` must be in `ft$col_keys`.

Both error with the offending entry's position. This catches the failure
mode that motivated automating this in the first place: indices computed
against a different object than the one being rendered, which currently
either marks the wrong cell silently or fails inside flextable with a
message that does not name the footnote.

## Testing

New file `tests/testthat/test-hv-test-footnotes-jtcvs.R`:

- Canonical letter order with all four tests present, and with subsets
  (letters compact to `a`, `b`, ... rather than leaving gaps).
- Each of the four empty cases returns `list()`.
- Unmapped `test_name` warns and falls back to the raw string.
- Anti-drift row-index test: the helper's computed index for a known
  variable equals that row's position in `.reshape_jtcvs_body()`'s output.
- Vector-valued `row`: two variables sharing a test produce one entry with
  two indices, not two entries.
- Characterization test against the SAS example's shape: synthetic data
  engineered to trigger Kruskal-Wallis, chi-square, and Fisher, asserting
  the three expected labels in canonical order and the absence of ANOVA.

Additions to `tests/testthat/test-hv-tbl-summary.R`:

- Regression test pinning `compare = "both"`'s `estimate` to the value
  `add_difference()` alone produces, and asserting `test_name` is not
  `"smd"`.

Additions to `tests/testthat/test-hv-man-table-save-jtcvs.R`:

- Out-of-range `row` and unknown `col` each error.
- A vector-valued `row` attaches the same superscript to every named row.

## Documentation and version

- Roxygen on `hv_test_footnotes_jtcvs()` with `@param`, `@return`,
  `@seealso`, `@details` covering the `"both"` caveat, and a runnable
  `@examples` block.
- `hv_man_table_save_jtcvs()`'s `@param footnotes` corrected to document
  vector-valued `row`.
- New `hv_test_footnotes_jtcvs` entry under `_pkgdown.yml`'s "Footnotes"
  section.
- README's "Migrating from the `%summarytable` SAS macro" section gains the
  footnote step, and its parameter-mapping table notes that the R letter
  set omits ANOVA by design.
- `NEWS.md` and `DESCRIPTION` both move from `0.9.1` to `0.9.2`. Patch
  digit only. The SMD reorder is written up under a "Bug fixes" heading,
  since it changes a reported statistic.

## Explicitly deferred

- Automatic footnotes for the flat CORR renderer.
- A single combined SAS-style footnote line (`p-values: a=..., b=...`).
  The per-test paragraph form is the JTCVS convention this package already
  implements; the combined line would need a new rendering path in
  `hv_man_table_save_jtcvs()` that the helper alone cannot supply.
- Per-variable test overrides (`add_p(test = ...)` passthrough on
  `hv_tbl_summary()`). The helper handles unmapped names gracefully if
  someone builds such an object by hand, but nothing in this package
  produces one.
