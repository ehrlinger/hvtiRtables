# PR #23 review fix: `.assert_stat_convention()` message names the wrong renderer

## The change

`.assert_stat_convention()` (R/hv-validate.R) gained a `caller` parameter,
following the file's existing `arg = "tbl"` convention, defaulting to
`"hv_man_table_jtcvs"` so the existing wired caller
(R/hv-man-table-jtcvs.R:177, no explicit argument) is byte-identical to
before. The CORR caller (R/hv-man-table.R:132) now passes
`caller = "hv_man_table"`.

## Before/after message, both callers

**hv_man_table_jtcvs() (default `caller`, unchanged):**

Before and after (identical):
> `` `tbl` was not built with the "{N_obs} ||| {stat}" convention hv_man_table_jtcvs() requires, so column `stat_1` cannot be split into its N and statistic parts. Build it with hv_tbl_summary(), or pass statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"). First unparseable value: "...". ``

**hv_man_table() (new `caller = "hv_man_table"`):**

Before (defect):
> `` `tbl` was not built with the "{N_obs} ||| {stat}" convention hv_man_table_jtcvs() requires, ... ``
(wrongly named the JTCVS renderer)

After (fixed):
> `` `tbl` was not built with the "{N_obs} ||| {stat}" convention hv_man_table() requires, so column `stat_1` cannot be split into its N and statistic parts. Build it with hv_tbl_summary(), or pass statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"). First unparseable value: "...". ``

All other clauses are identical between the two messages, including
"Build it with `hv_tbl_summary()`" (correct advice for both renderers
after this PR).

## Item 4 investigation: R/hv-validate.R:405 (`.assert_footnote_entries`, "hv_man_table_jtcvs() interleaves")

Checked all callers of `.assert_footnote_entries()`: only
`R/hv-man-table-save-jtcvs.R:93`. The CORR sibling,
`R/hv-man-table-save.R`, does its own footnote-text validation via
`.check_footnote_text()` directly and never calls
`.assert_footnote_entries()`. So this assertion is genuinely JTCVS-only
and the message is correctly scoped. **Left unchanged.**

## Item 5: class-wide search for the same defect pattern

Delegated a systematic grep-and-reachability-trace across all of `R/`
(stop/warning/message text, roxygen `#'`, and plain `#` comments) for
any text naming one CORR/JTCVS sibling while being reachable from both.

Found and fixed:
- **R/hv-tbl-summary.R** (`hv_tbl_summary()` roxygen) — the
  `@description`, `@return`, and `@seealso` stated the function's
  output was "ready for `hv_man_table_jtcvs()`" only. But this PR makes
  `hv_man_table()` (CORR) an equally valid direct consumer of
  `hv_tbl_summary()` output (that's the whole point of
  `.split_stat_sentinel()`/`.has_stat_sentinel()` in
  R/hv-man-table.R). Fixed lines 9, 101, 104 to name both
  `hv_man_table()` and `hv_man_table_jtcvs()` as valid renderers, while
  keeping the `hv_stat_label`/`hv_trailing` attribute documentation
  (lines 20-25) naming only `hv_man_table_jtcvs()` — verified those two
  attributes are read only by `hv_man_table_jtcvs()`'s call path
  (`R/hv-test-footnotes-jtcvs.R:81`, `hvtiRtables-package.R` JTCVS
  example) and never by `hv_man_table()`, so that scoping is correct.

Checked and confirmed correctly single-sibling (not defects, not
touched):
- `R/hv-validate.R:301` `.assert_jtcvs_groups()` — called only from
  `R/hv-man-table-jtcvs.R:162`.
- `R/hv-validate.R:371` `.assert_footnote_entries()` — see item 4 above.
- `R/hv-man-table.R:98,130` comments mentioning "the JTCVS renderer" in
  `.has_stat_sentinel()`/`.split_stat_sentinel()` — these functions are
  CORR-only callees; the JTCVS mention describes where the sentinel
  convention originates, not a caller claim.
- All roxygen in `hv-man-table-save-jtcvs.R`, `hv-man-table-jtcvs.R`,
  `hv-test-footnotes-jtcvs.R`, `hv-check-docx.R`,
  `hvtiRtables-package.R` — each references only genuinely JTCVS-only
  functions/callers.

No other instance of the defect class was found.

## Roxygen / man/ regeneration

`R/hv-tbl-summary.R` roxygen changed -> ran
`Rscript -e 'devtools::document()'`. Only `man/hv_tbl_summary.Rd`
changed; committed.

## Tests added

- `tests/testthat/test-hv-validate.R`: `.assert_stat_convention` names
  the caller in its message" — asserts the default message names
  `hv_man_table_jtcvs()` and the `caller = "hv_man_table"` message
  names `hv_man_table()` **and explicitly asserts the JTCVS name is
  absent** (`expect_false(grepl("hv_man_table_jtcvs()", ...))`), not
  just that the CORR name is present.
- `tests/testthat/test-hv-man-table.R`: "hv_man_table's convention
  error names itself, not JTCVS" — same negative assertion end-to-end
  through `hv_man_table()`.
- `tests/testthat/test-hv-man-table-jtcvs.R`: "hv_man_table_jtcvs's
  convention error still names itself" — regression proving the
  default-`caller` message is unchanged and does NOT contain
  `hv_man_table()`.

## NEWS.md

Added one bullet under the existing `# hvtiRtables 0.9.7` / `## Bug
fixes` heading. No version bump (per constraints).

## Test / lint / check results

- `devtools::test()`: **423 tests, 0 failures, 0 warnings, 0 skips**
  (ran twice — once before, once after reinstalling the package to
  avoid the project's known lintr stale-install false-positive; count
  unchanged both times). ~36-45s wall.
- `lintr::lint_package()`: initially 3 lints (1 false-positive
  `object_usage_linter` "unused argument" caused by a stale installed
  copy of the package -- resolved by `devtools::install()`; 1 real
  hanging-indent lint on the new `caller` parameter continuation line;
  1 real line-length lint on an 83-char `test_that()` title). All three
  fixed. Final: **0 lints**, ~2.5s.
- `devtools::check(document = FALSE)`: **0 errors, 0 warnings, 1
  NOTE** ("hidden files and directories: .git") -- the known,
  pre-existing spurious NOTE from checking inside a git worktree
  (`.git` is a file, not a directory, in a worktree, so R CMD build's
  VCS exclusion misses it); not a defect introduced by this change.
  Duration **1m 8.9s**, well under the project's 10-minute budget.
