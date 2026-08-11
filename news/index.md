# Changelog

## hvtiRtables 0.9.6

### Bug fixes

- `binary` variables now pass an explicit event value to `gtsummary`
  instead of letting it infer one. Its inference is type-sensitive in a
  way that hit the SAS import path: a `haven_labelled` column over a
  *double* base type – what
  [`haven::read_sas()`](https://haven.tidyverse.org/reference/read_sas.html)
  produces, since every SAS numeric is an 8-byte float – failed with
  `Summary type is "dichotomous" but no summary value has been assigned.`,
  while the otherwise-identical integer-backed column worked. The event
  is the `TRUE`, `1`, or `Yes` side in every accepted encoding.

## hvtiRtables 0.9.5

### Breaking changes

- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now enforces `font_size` of 11 or 12, the same house rule
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  has always enforced. Calls passing any other value, or a vector, now
  error.
- `abbreviations` must be a character vector, as documented. A list
  previously worked by accident.

### Bug fixes

- `abbreviations` and `footnotes` are now type-checked before the
  empty-value shortcut. An empty value previously skipped the type check
  entirely, so `abbreviations = list()` was accepted while
  `abbreviations = list(N = "x")` errored. `NULL` and `character(0)`
  remain no-ops for `abbreviations`; `NULL` and
  [`list()`](https://rdrr.io/r/base/list.html) for `footnotes`.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now errors when `tbl` was not built with the `{N_obs} ||| {stat}`
  statistic convention. It previously rendered a complete, correctly
  styled, entirely empty table.
- Both savers now enforce one footnote-text contract, through shared
  code.
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  errors when a footnote entry has no `text`;
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  now does the same for its `symbol -> text` list, which previously
  *wrote* the `.docx` for `list("*" = NULL)` (header marked
  `Characteristic*`, a footnote paragraph of `"* "`), and equally for
  `NA` (`"* NA"`), a number (`"* 1"`), and a length-2 vector
  (`"* a* b"`). The two savers’ messages share the contract sentence but
  no longer share one fixed label or fix: each names the bad entry the
  way its own caller would look for it (`footnotes[["*"]]` for
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md),
  `footnotes[[k]]$text` for
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md))
  instead of a shared, list-position label that made a CORR caller count
  entries to find their symbol.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now enforces its documented “exactly one type bucket” contract instead
  of failing inside `gtsummary`.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now checks each variable’s data against the bucket it was put in, not
  just that the buckets don’t overlap. A non-numeric variable in
  `continuous` previously produced `"{N} ||| NA (NA, NA)"` cells, which
  satisfy the `|||` convention check because the convention genuinely is
  applied and only the statistic is `NA` — so the table rendered and
  saved as a complete, correctly styled, all-`NA` manuscript table off
  nothing but `gtsummary` *messages*. `binary` now requires at most two
  distinct non-missing values AND a form `gtsummary` can dichotomize
  (logical, `0`/`1`, `Yes`/`No`), which is what removes the leaked
  “Summary type is "dichotomous" but no summary value has been
  assigned.” error. A column with no non-missing values is rejected in
  any bucket. `categorical` keeps no type rule.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  validates `groups` names against `tbl$table_body`, replacing a base-R
  `non-character argument` error.
- [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  now rejects a `groups` name given twice, replacing `flextable`’s
  `duplicated col_keys: n_stat_1, disp_stat_1` — internal column names
  the caller never wrote.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now rejects a `groups` section holding no variables
  (e.g. `list(Demo = character(0))`, plausible when `groups` is built
  from a filter that returns nothing).
  [`list()`](https://rdrr.io/r/base/list.html) was already caught; a
  named-but-empty section leaked the base-R “`names` must be `NULL` or a
  character vector, not an empty integer vector.”.
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  validates `file`, replacing a base-R
  `a character vector argument expected` error.
- [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  now checks each `footnotes` entry is a list before reading its fields.
  Dropping the outer nesting (`footnotes = list(row =, col =, text =)`),
  or passing a bare string, leaked
  `$ operator is invalid for atomic vectors`.
- A footnote entry with no `col` now reports what arrived and lists
  `ft`’s columns. The message previously ended at a bare colon with
  nothing after it.
- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  validates `by` in the package’s own vocabulary.
- Every validation message’s `Received:` clause now names the class even
  when the value is not length 1. The clause exists for the
  argument-order slip, where the class mismatch is the tell, but it
  reported a bare `a vector of length 8` for a 200-row data frame (8
  columns) and `a vector of length 5` for a `gtsummary` table — losing
  exactly the diagnostic it was written for. Those now read
  `tbl_df of length 8` and `tbl_summary of length 5`.
- The `binary` bucket error no longer always says “Recode to 0/1”, which
  was impossible advice for a constant column (already 0/1, with no
  event to recode — the fix is moving it to `categorical`) and for a
  factor whose only problem is an unused level (the fix is
  [`droplevels()`](https://rdrr.io/r/base/droplevels.html)). Every other
  case keeps the “Recode to 0/1” fix.

### Documentation

- New
  [`?hvtiRtables`](https://ehrlinger.github.io/hvtiRtables/reference/hvtiRtables-package.md)
  package topic explaining which rendering mode to use, with both
  pipelines end to end.
- New vignette walking a complete JTCVS table from data frame to checked
  `.docx`.
- Every function’s help now states its arguments’ accepted values
  exhaustively and carries a “Common mistakes” section.

## hvtiRtables 0.9.4

### New features

- [`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  reads a written `.docx` and reports the three constructs the CORR
  manuscript table rules prohibit, returning one row per finding and
  zero rows when the file is clean: floating layers (`w:framePr`
  paragraphs, `w:txbxContent` text boxes), hidden spacer columns (a
  column both entirely empty and under 0.1 inch wide), and footnotes
  written as a row inside the table rather than as text below it. The
  first two are structural and high confidence; the third is a
  marker-prefix heuristic, so read it as a prompt to look rather than as
  proof. It reads the file rather than the object that produced it, so
  it catches violations introduced anywhere in the pipeline, including
  by a hand edit after the fact.
  [`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md)
  and
  [`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)
  do not call it — run it on the path yourself when you want the check.

### Bug fixes

- [`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
  now checks up front that `compare = "smd"` or `"both"` is used with
  exactly two groups, and errors naming `by` and the group count if not.
  [`gtsummary::add_difference()`](https://www.danieldsjoberg.com/gtsummary/reference/add_difference.html)
  requires two groups and previously failed three different ways, none
  naming anything the caller wrote: it threw an internal message about
  `tbl_summary(by)` for a genuine 3+ group variable and for a single
  group, and, when `by` was a factor carrying an unused level, did not
  error at all but returned `estimate` as `NA`, silently rendering an
  empty comparison column. That last case now errors too, with a hint
  pointing at [`droplevels()`](https://rdrr.io/r/base/droplevels.html).
  `compare = "pvalue"` and `"none"` are unaffected and still work at any
  number of groups.

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
