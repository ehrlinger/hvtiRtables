# hvtiRtables 1.0.0

First supported release. The package is now the HVTI CORR group's table
interface rather than a working draft: the two manuscript renderers, the
`%summarytable` migration path, and the checks that keep a written `.docx`
inside house rules are all in place and covered.

What the 1.0.0 claim means in practice:

- **Both house styles are complete and symmetric where they should be.**
  `hv_man_table()` and `hv_man_table_jtcvs()` both consume `hv_tbl_summary()`
  output, and the places the two families genuinely differ - `caption` on the
  JTCVS saver only, the two footnote shapes - are documented as differences
  rather than papered over.
- **The SAS interface is documented from the macro side.** `vignette("sas-migration")`
  ports a `%summarytable` program end to end, including the defaults that differ
  and the `QNTLDEF=5` / `quantile(type = 2)` trap.
- **Macro parameter names teach.** Passing `class=`, `con1=` or `tbltitle=` to any
  public function errors with the R argument and the function that takes it,
  resolved against the caller's CORR/JTCVS family.
- **The `dc` prefix formally belongs here.** `hvtiRtemplates`' allocation map
  assigns the `dc.*` descriptive-table macro family to this package, so the
  `%summarytable` port has a governing decision behind it rather than a
  precedent.

No API changes since 0.9.7. This release is the claim of support, not new
behavior.

# hvtiRtables 0.9.7

## New features

- `hv_man_table()` now accepts an `hv_tbl_summary()` table. It splits
  each `"{N_obs} ||| {stat}"` cell into a flat `No.` column immediately
  before the statistic it counts — the same two values the JTCVS
  renderer puts under a merged spanning header, without the merge.
  Previously the separator rendered literally into the Word table
  (`98 ||| 46 (32, 63)`), so the SAS-macro interface was usable only in
  JTCVS mode. The count is kept rather than discarded because house
  rule 8 requires it and `hv_man_footnotes()` ships a `*` footnote
  describing it. A plain `gtsummary::tbl_summary()` table carries no
  such convention and passes through unchanged.
- A table where only *some* cells carry the convention is now rejected,
  through the same assertion the JTCVS renderer uses. Splitting it would
  have left the rest blank.

## Bug fixes

- The house footnote symbols now attach to the count column when the
  table has one. With the split above, a sectioned table's first column
  is `groupname_col`, so the marker would otherwise have landed on the
  section-label column.
- A CORR table missing the `"{N_obs} ||| {stat}"` convention now raises
  an error naming `hv_man_table()`, not `hv_man_table_jtcvs()`. The
  internal assertion the two renderers share previously hardcoded the
  JTCVS renderer's name in its message.

# hvtiRtables 0.9.6

## New features

* `hv_tbl_summary()` gains `overall =`, the `%summarytable` `TOTALCOL=`
  equivalent, adding an Overall column across all groups. Defaults to
  `FALSE`; the macro's own default is `TOTALCOL=1`.
* `hv_tbl_summary()`, `hv_man_table()`, `hv_man_table_jtcvs()`,
  `hv_man_table_save()`, and `hv_man_table_save_jtcvs()` now error on a
  `%summarytable` parameter name, naming the R argument and the function
  that takes it, rather than silently ignoring it.
* New vignette, "Porting a `%summarytable` program to R".

## Documentation

* The README's migration table stated that `CON1=` maps to `continuous`.
  It does not: `CON1=` was mean +/- SD with ANOVA, and `continuous`
  reproduces `CON3=`. Corrected.

## Bug fixes

- `binary` variables now pass an explicit event value to `gtsummary`
  instead of letting it infer one. Its inference is type-sensitive in a
  way that hit the SAS import path: a `haven_labelled` column over a
  *double* base type -- what `haven::read_sas()` produces, since every
  SAS numeric is an 8-byte float -- failed with `Summary type is
  "dichotomous" but no summary value has been assigned.`, while the
  otherwise-identical integer-backed column worked. The event is the
  `TRUE`, `1`, or `Yes` side in every accepted encoding.

# hvtiRtables 0.9.5

## Breaking changes

- `hv_man_table_jtcvs()` now enforces `font_size` of 11 or 12, the same
  house rule `hv_man_table()` has always enforced. Calls passing any
  other value, or a vector, now error.
- `abbreviations` must be a character vector, as documented. A list
  previously worked by accident.

## Bug fixes

- `abbreviations` and `footnotes` are now type-checked before the
  empty-value shortcut. An empty value previously skipped the type check
  entirely, so `abbreviations = list()` was accepted while
  `abbreviations = list(N = "x")` errored. `NULL` and `character(0)`
  remain no-ops for `abbreviations`; `NULL` and `list()` for `footnotes`.
- `hv_man_table_jtcvs()` now errors when `tbl` was not built with the
  `{N_obs} ||| {stat}` statistic convention. It previously rendered a
  complete, correctly styled, entirely empty table.
- Both savers now enforce one footnote-text contract, through shared
  code. `hv_man_table_save_jtcvs()` errors when a footnote entry has no
  `text`; `hv_man_table_save()` now does the same for its `symbol ->
  text` list, which previously *wrote* the `.docx` for `list("*" =
  NULL)` (header marked `Characteristic*`, a footnote paragraph of
  `"* "`), and equally for `NA` (`"* NA"`), a number (`"* 1"`), and a
  length-2 vector (`"* a* b"`). The two savers' messages share the
  contract sentence but no longer share one fixed label or fix: each
  names the bad entry the way its own caller would look for it
  (`footnotes[["*"]]` for `hv_man_table_save()`,
  `footnotes[[k]]$text` for `hv_man_table_save_jtcvs()`) instead of a
  shared, list-position label that made a CORR caller count entries to
  find their symbol.
- `hv_tbl_summary()` now enforces its documented "exactly one type
  bucket" contract instead of failing inside `gtsummary`.
- `hv_tbl_summary()` now checks each variable's data against the bucket
  it was put in, not just that the buckets don't overlap. A non-numeric
  variable in `continuous` previously produced `"{N} ||| NA (NA, NA)"`
  cells, which satisfy the `|||` convention check because the
  convention genuinely is applied and only the statistic is `NA` — so
  the table rendered and saved as a complete, correctly styled, all-`NA`
  manuscript table off nothing but `gtsummary` *messages*. `binary` now
  requires at most two distinct non-missing values AND a form
  `gtsummary` can dichotomize (logical, `0`/`1`, `Yes`/`No`), which is
  what removes the leaked "Summary type is \"dichotomous\" but no
  summary value has been assigned." error. A column with no non-missing
  values is rejected in any bucket. `categorical` keeps no type rule.
- `hv_man_table_jtcvs()` validates `groups` names against
  `tbl$table_body`, replacing a base-R `non-character argument` error.
- `hv_man_table_jtcvs()` now rejects a `groups` name given twice,
  replacing `flextable`'s `duplicated col_keys: n_stat_1, disp_stat_1`
  — internal column names the caller never wrote.
- `hv_tbl_summary()` now rejects a `groups` section holding no
  variables (e.g. `list(Demo = character(0))`, plausible when `groups`
  is built from a filter that returns nothing). `list()` was already
  caught; a named-but-empty section leaked the base-R "`names` must be
  `NULL` or a character vector, not an empty integer vector.".
- `hv_man_table_save_jtcvs()` validates `file`, replacing a base-R
  `a character vector argument expected` error.
- `hv_man_table_save_jtcvs()` now checks each `footnotes` entry is a
  list before reading its fields. Dropping the outer nesting
  (`footnotes = list(row =, col =, text =)`), or passing a bare string,
  leaked `$ operator is invalid for atomic vectors`.
- A footnote entry with no `col` now reports what arrived and lists
  `ft`'s columns. The message previously ended at a bare colon with
  nothing after it.
- `hv_tbl_summary()` validates `by` in the package's own vocabulary.
- Every validation message's `Received:` clause now names the class
  even when the value is not length 1. The clause exists for the
  argument-order slip, where the class mismatch is the tell, but it
  reported a bare `a vector of length 8` for a 200-row data frame (8
  columns) and `a vector of length 5` for a `gtsummary` table — losing
  exactly the diagnostic it was written for. Those now read
  `tbl_df of length 8` and `tbl_summary of length 5`.
- The `binary` bucket error no longer always says "Recode to 0/1",
  which was impossible advice for a constant column (already 0/1,
  with no event to recode — the fix is moving it to `categorical`)
  and for a factor whose only problem is an unused level (the fix is
  `droplevels()`). Every other case keeps the "Recode to 0/1" fix.

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
