# hvtiRtables 0.9.5

## Breaking changes

- `hv_man_table_jtcvs()` now enforces `font_size` of 11 or 12, the same
  house rule `hv_man_table()` has always enforced. Calls passing any
  other value, or a vector, now error.
- `abbreviations` must be a character vector, as documented. A list
  previously worked by accident.

## Bug fixes

- `hv_man_table_jtcvs()` now errors when `tbl` was not built with the
  `{N_obs} ||| {stat}` statistic convention. It previously rendered a
  complete, correctly styled, entirely empty table.
- Both savers now enforce one footnote-text contract, through shared
  code and with the same message. `hv_man_table_save_jtcvs()` errors
  when a footnote entry has no `text`; `hv_man_table_save()` now does
  the same for its `symbol -> text` list, which previously *wrote* the
  `.docx` for `list("*" = NULL)` (header marked `Characteristic*`, a
  footnote paragraph of `"* "`), and equally for `NA` (`"* NA"`), a
  number (`"* 1"`), and a length-2 vector (`"* a* b"`).
- `hv_tbl_summary()` now enforces its documented "exactly one type
  bucket" contract instead of failing inside `gtsummary`.
- `hv_man_table_jtcvs()` validates `groups` names against
  `tbl$table_body`, replacing a base-R `non-character argument` error.
- `hv_man_table_save_jtcvs()` validates `file`, replacing a base-R
  `a character vector argument expected` error.
- `hv_tbl_summary()` validates `by` in the package's own vocabulary.

## Documentation

- New `?hvtiRtables` package topic explaining which rendering mode to
  use, with both pipelines end to end.
- New vignette walking a complete JTCVS table from data frame to
  checked `.docx`.
- Every function's help now states its arguments' accepted values
  exhaustively and carries a "Common mistakes" section.

# hvtiRtables 0.9.4

## New features

- `hv_check_docx()` reads a written `.docx` and reports the three
  constructs the CORR manuscript table rules prohibit, returning one row
  per finding and zero rows when the file is clean: floating layers
  (`w:framePr` paragraphs, `w:txbxContent` text boxes), hidden spacer
  columns (a column both entirely empty and under 0.1 inch wide), and
  footnotes written as a row inside the table rather than as text below
  it. The first two are structural and high confidence; the third is a
  marker-prefix heuristic, so read it as a prompt to look rather than as
  proof. It reads the file rather
  than the object that produced it, so it catches violations introduced
  anywhere in the pipeline, including by a hand edit after the fact.
  `hv_man_table_save()` and `hv_man_table_save_jtcvs()` do not call it —
  run it on the path yourself when you want the check.

## Bug fixes

- `hv_tbl_summary()` now checks up front that `compare = "smd"` or
  `"both"` is used with exactly two groups, and errors naming `by` and
  the group count if not. `gtsummary::add_difference()` requires two
  groups and previously failed three different ways, none naming
  anything the caller wrote: it threw an internal message about
  `tbl_summary(by)` for a genuine 3+ group variable and for a single
  group, and, when `by` was a factor carrying an unused level, did not
  error at all but returned `estimate` as `NA`, silently rendering an
  empty comparison column. That last case now errors too, with a hint
  pointing at `droplevels()`. `compare = "pvalue"` and `"none"` are
  unaffected and still work at any number of groups.

# hvtiRtables 0.9.3

## New features

- `hv_test_footnotes_jtcvs()`: builds the lettered p-value footnotes the
  SAS `%summarytable` macro emits, reading `gtsummary`'s `test_name`
  column off an `hv_tbl_summary()` result and returning the list
  `hv_man_table_save_jtcvs()` already accepts. Letters follow a fixed
  order (Wilcoxon, Kruskal-Wallis, chi-square, Fisher), filtered to the
  tests used, so two tables using the same tests agree. ANOVA never
  appears, since this package tests continuous variables
  non-parametrically throughout.

## Bug fixes

- `hv_man_table_save_jtcvs()` now validates each footnote's `row` and
  `col` against the table being rendered. A row index computed against a
  different object previously marked the wrong cell silently.

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
