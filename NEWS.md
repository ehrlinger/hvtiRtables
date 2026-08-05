# hvtiRtables 0.9.2

## Bug fixes

- `hv_tbl_summary(compare = "both")` reported a wrong standardized mean
  difference. `add_difference()` ran after `add_p()`, and in that order
  `gtsummary` overwrites the `estimate` column with a raw mean difference
  for continuous variables and leaves it `NA` for binary and categorical
  ones. A table could render `0.7 (SMD -1.0)` where the true SMD was
  -0.03, under a column header saying SMD, and categorical variables
  showed no SMD at all. The two calls are now ordered
  `add_difference()` then `add_p()`, which reproduces
  `add_difference()`'s own output exactly for continuous, binary, and
  categorical variables alike. `compare = "pvalue"`, `"smd"`, and
  `"none"` are unaffected, since none of them runs both calls.

  The same reordering preserves `add_p()`'s `test_name` column, which
  `add_difference()` had been overwriting with `"smd"`.

# hvtiRtables 0.9.1

## New features

- `hv_tbl_summary()`: a thin wrapper over `gtsummary::tbl_summary()` /
  `add_p()` / `add_difference()` modeled on the interface biostats team
  members already know from the `%summarytable` SAS macro — a grouped,
  ordered variable list and variable-type buckets
  (`continuous`/`binary`/`categorical`), rather than gtsummary's own
  tidyselect interface. Always uses a blanket non-parametric test for
  continuous variables (no per-variable Gaussian classification) and
  reports `median (P15, P85)` by default, matching `hv_man_footnotes()`'s
  house convention. `compare` adds a p-value, standardized mean
  difference, or both, as a trailing column. Returns a plain `gtsummary`
  object ready for `hv_man_table_jtcvs()`. See the README's "Migrating
  from the `%summarytable` SAS macro" section for a parameter-mapping
  table and worked example.
- `hv_man_table_jtcvs()` gains a `stat_label` parameter (default
  `"No. (%) or Mean ± SD"`, unchanged for existing callers) so callers
  whose statistic is a median, not a mean, can set an accurate
  sub-header — `hv_tbl_summary()` sets this automatically.

# hvtiRtables 0.9.0

## New features

- Initial release. `hv_man_table()` converts a `gtsummary` table object
  into a flextable complying with HVTI CORR's "Table Construction for
  Manuscripts" rules (flat header, no merged cells, house font/rounding
  rules). `hv_man_table_save()` writes it to a `.docx` with footnotes and
  an abbreviation key as text below the table. `hv_man_footnotes()`
  supplies the house-universal N and median/percentile footnotes used as
  `hv_man_table_save()`'s default.
- JTCVS submission mode: `hv_man_table_jtcvs()` builds a merged-header
  `flextable` (spanning group headers, N/statistic column pairs) matching
  the JTCVS journal submission template, and `hv_man_table_save_jtcvs()`
  writes it to a `.docx` with a bold `Table N. Caption` paragraph and
  lettered (`a.`, `b.`, ...) footnotes targeted to specific body cells.
  Section-header rows are bold with `#CAEDFB` shading and column widths
  are set explicitly, matching the canonical "Table Construction for
  Manuscripts" house example and avoiding the header/number wrapping
  `flextable`'s default column sizing produced.

## Bug fixes

- `hv_man_table_jtcvs()`'s `trailing` argument is now validated: a name
  absent from `tbl$table_body`, an unnamed value, or a value of length
  other than 1 now raises a clear error instead of either silently
  dropping the column or failing later with an unrelated internal error.
