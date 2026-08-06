# Changelog

## hvtiRtables 0.9.3

### New features

- [`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md):
  builds the lettered p-value footnotes the SAS `%summarytable` macro
  emits, reading `gtsummary`’s `test_name` column off an
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  result and returning the list
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  already accepts. Letters follow a fixed order (Wilcoxon,
  Kruskal-Wallis, chi-square, Fisher), filtered to the tests used, so
  two tables using the same tests agree. ANOVA never appears, since this
  package tests continuous variables non-parametrically throughout.

### Bug fixes

- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now validates each footnote’s `row` and `col` against the table being
  rendered. A row index computed against a different object previously
  marked the wrong cell silently.

## hvtiRtables 0.9.2

### Bug fixes

- `hv_tbl_summary(compare = "both")` reported a wrong standardized mean
  difference.
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  ran after
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html),
  and in that order `gtsummary` overwrites the `estimate` column with a
  raw mean difference for continuous variables and leaves it `NA` for
  binary and categorical ones. A table could render `0.7 (SMD -1.0)`
  where the true SMD was -0.03, under a column header saying SMD, and
  categorical variables showed no SMD at all. The two calls are now
  ordered
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  then
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html),
  which reproduces
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)’s
  own output exactly for continuous, binary, and categorical variables
  alike. `compare = "pvalue"`, `"smd"`, and `"none"` are unaffected,
  since none of them runs both calls.

  The same reordering preserves
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)’s
  `test_name` column, which
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  had been overwriting with `"smd"`.

## hvtiRtables 0.9.1

### New features

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md):
  a thin wrapper over
  [`gtsummary::tbl_summary()`](https://www.danieldsjoberg.com/gtsummary/reference/tbl_summary.html)
  /
  [`add_p()`](https://www.danieldsjoberg.com/gtsummary/reference/add_p.html)
  /
  [`add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  modeled on the interface biostats team members already know from the
  `%summarytable` SAS macro — a grouped, ordered variable list and
  variable-type buckets (`continuous`/`binary`/`categorical`), rather
  than gtsummary’s own tidyselect interface. Always uses a blanket
  non-parametric test for continuous variables (no per-variable Gaussian
  classification) and reports `median (P15, P85)` by default, matching
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)’s
  house convention. `compare` adds a p-value, standardized mean
  difference, or both, as a trailing column. Returns a plain `gtsummary`
  object ready for
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md).
  See the README’s “Migrating from the `%summarytable` SAS macro”
  section for a parameter-mapping table and worked example.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  gains a `stat_label` parameter (default `"No. (%) or Mean ± SD"`,
  unchanged for existing callers) so callers whose statistic is a
  median, not a mean, can set an accurate sub-header —
  [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  sets this automatically.

## hvtiRtables 0.9.0

### New features

- Initial release.
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  converts a `gtsummary` table object into a flextable complying with
  HVTI CORR’s “Table Construction for Manuscripts” rules (flat header,
  no merged cells, house font/rounding rules).
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  writes it to a `.docx` with footnotes and an abbreviation key as text
  below the table.
  [`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md)
  supplies the house-universal N and median/percentile footnotes used as
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)’s
  default.
- JTCVS submission mode:
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  builds a merged-header `flextable` (spanning group headers,
  N/statistic column pairs) matching the JTCVS journal submission
  template, and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  writes it to a `.docx` with a bold `Table N. Caption` paragraph and
  lettered (`a.`, `b.`, …) footnotes targeted to specific body cells.
  Section-header rows are bold with `#CAEDFB` shading and column widths
  are set explicitly, matching the canonical “Table Construction for
  Manuscripts” house example and avoiding the header/number wrapping
  `flextable`’s default column sizing produced.

### Bug fixes

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)’s
  `trailing` argument is now validated: a name absent from
  `tbl$table_body`, an unnamed value, or a value of length other than 1
  now raises a clear error instead of either silently dropping the
  column or failing later with an unrelated internal error.
