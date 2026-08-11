# Public-surface contract discipline

**Date:** 2026-08-11
**Status:** approved (design)
**Scope:** all 8 exported functions of `hvtiRtables`

## Problem

`hvtiRtables` exists to be a safer, stricter facade over `gtsummary` and
`flextable` for a biostats team whose R depth is beginner-level. Where it
lets bad input leak through to a cryptic downstream error, or silently
accepts out-of-spec formatting, it fails its own design goal.

An audit of the public surface found the contract to be roughly 60%
enforced, with the gaps clustered by authorship era rather than scattered
at random: the JTCVS-mode functions, written later, did not inherit the
validation idiom the CORR-mode functions established. That clustering is
the signature of consistency maintained by author discipline rather than
by structure, and it is the root cause this design addresses.

### Review standard

1. No cryptic downstream errors from public APIs.
2. No undocumented accepted behavior.
3. No documented behavior that isn't enforced.
4. No inconsistent argument contracts across sibling functions.
5. Examples reflect real biostats workflows, not toy syntax.

## Audit findings

Six defects, verified by execution against the working tree at `56f25c1`.

| # | Function | Defect | Failure mode |
| --- | --- | --- | --- |
| 1 | `hv_tbl_summary()` | Type buckets may overlap; documented "exactly one" contract unenforced | Cryptic: `Summary type is "dichotomous" but no summary value has been assigned.` |
| 2 | `hv_man_table_jtcvs()` | `font_size` unvalidated; accepts `10`, and vectors such as `c(11, 12)` | Silent out-of-spec output |
| 3 | `hv_man_table_jtcvs()` | `groups` names not checked against `tbl$table_body` | Cryptic: `non-character argument` |
| 4 | `hv_man_table_save_jtcvs()` | `file` unvalidated before `dirname()` | Cryptic: `a character vector argument expected` |
| 5 | `hv_man_table_jtcvs()` | `" ||| "` statistic convention not asserted | **Silent**: renders a complete, correctly styled, entirely empty table |
| 6 | `hv_man_table_save_jtcvs()` | `footnotes[[k]]$text` unvalidated | **Silent**: writes `.docx` with a dangling `a.` marker and no footnote text |

Defects 5 and 6 are the most severe despite not appearing in the original
review: they produce plausible-looking output rather than stopping. A user
who sees `non-character argument` files a bug; a user who gets an
empty-but-well-formatted Table 1 may paste it into a manuscript.

Both silent defects sit in the JTCVS render/save path, which is not
coincidence. Those functions do structural reshaping (`strsplit`, row
interleaving, cell-targeted markers) where "no match" has a natural
degenerate value (`NA`, `""`). The CORR functions largely delegate to
`gtsummary::as_flex_table()`, leaving nowhere for a silent default to hide.
Reshaping code needs assertions, not only argument checks.

### Coverage before this work

| Argument | CORR branch | JTCVS branch |
| --- | --- | --- |
| `tbl` / `ft` class | enforced | enforced |
| `font_size` | enforced (`11` or `12`) | **unenforced** |
| `font` | **unenforced** | **unenforced** |
| `file` | enforced | **unenforced** |
| `footnotes` structure | enforced (symbols) | partial (`row`/`col` only) |
| `groups` names exist | n/a | **unenforced** |
| `" \|\|\| "` convention | n/a | **unenforced** |
| `stat_label` | n/a | **unenforced** |
| `by` (`hv_tbl_summary`) | leaks `gtsummary` vocabulary | — |
| type-bucket overlap | **unenforced** | — |

## Decisions

- **Scope:** full public-surface audit of all 8 exported functions, not
  only the known defects. A partial pass leaves the sibling inconsistency
  in place, merely relocated.
- **`font_size` in JTCVS mode:** adopt the CORR rule exactly,
  `font_size %in% c(11, 12)`. This is a breaking change for callers
  currently passing other values; acceptable at v0.9.4 pre-1.0 with an
  internal user base, and such tables were already out of house spec.
- **`font`:** shape validation (single non-empty string), not a value
  whitelist. Times New Roman is the house default, but a journal
  requiring Arial is legitimate. `flextable` silently substitutes unknown
  font names, so a typo deserves detection while a deliberate override
  does not deserve blocking.
- **Architecture:** shared internal validators (approach B below), not
  extended inline checks and not a new dependency.
- **Vignette:** include one end-to-end vignette, with `R CMD check`
  rebuild time measured and reported against the 10-minute release gate
  before it is committed.

### Architecture alternatives considered

- **A — extend the inline `stop()` idiom.** Smallest diff, matches
  existing style. Rejected: leaves `font_size` validated in two places,
  `file` in two, `tbl`-class in four, with consistency resting on author
  discipline — the mechanism that already failed and produced these six
  defects.
- **B — shared internal validators. Chosen.** One definition per
  contract, one message, one test. Converts "learn one rule once" from an
  aspiration into a structural property. Costs one file and a small
  indirection when reading a public function.
- **C — adopt `checkmate` or `rlang::abort()`.** Rejected: adds an
  `Imports` to a package facing a `R CMD check` release gate, for messages
  that will not read better to a beginner than a hand-written sentence.
  `rlang` would additionally import an upstream house voice, the opposite
  of the goal.

## Section 1 — Validation architecture

New internal file `R/hv-validate.R`; nothing exported. Two layers, kept
distinct because they answer different questions.

### Layer 1 — argument validators

Each takes the value plus the caller's argument name for the message,
errors on failure, and returns invisibly. No predicate variants
(`is_valid_*`): every use in this package is fail-fast at function entry,
and offering both forms invites drift.

| Validator | Contract |
| --- | --- |
| `.check_gtsummary(x, arg)` | inherits `"gtsummary"` |
| `.check_flextable(x, arg)` | inherits `"flextable"` |
| `.check_string(x, arg)` | single non-`NA`, non-empty string |
| `.check_font_size(x, arg)` | single numeric, `%in% c(11, 12)` |
| `.check_file(x, arg)` | single non-empty string **and** parent directory exists |
| `.check_abbreviations(x, arg)` | named character vector, all names non-empty |

There is deliberately no `.check_font()`. Its contract — single non-`NA`,
non-empty string — is identical to `.check_string()`, and `font` is
validated by calling `.check_string(font, "font")`. A separate wrapper
would add a name without adding a rule, and would be the first place a
future edit could make the two drift apart. `stat_label` and `caption`
use `.check_string()` for the same reason.

`.check_file()` folds the string check and the `dir.exists()` check
together because both savers already perform exactly those two steps in
sequence; splitting them leaves two things to remember instead of one.

The `arg` parameter is threaded explicitly rather than inferred via
`deparse(substitute())`, which breaks under `do.call()` and yields garbage
names when the caller passes an expression.

### Layer 2 — precondition assertions

These check relationships between arguments, or between an argument and
the data it references. They are what the audit shows is actually missing.

- `.assert_type_buckets(continuous, binary, categorical)` — each is a
  character vector; no variable appears in more than one. **Defect 1.**
- `.assert_jtcvs_groups(tbl, groups)` — `groups` is a named character
  vector of length ≥ 1, and every name is a column in `tbl$table_body`.
  **Defect 3.**
- `.assert_stat_convention(tb, groups)` — for each group column, every
  **non-`NA`** cell splits into exactly two parts on `" ||| "`. Runs
  before `.reshape_jtcvs_body()`, so nothing renders on failure.
  **Defect 5.**
- `.assert_footnote_entries(footnotes, ft)` — the existing `row`/`col`
  checks, plus `text` must be a single non-empty string. **Defect 6.**

The non-`NA` qualifier in `.assert_stat_convention()` is load-bearing and
was established empirically: a valid `hv_tbl_summary()` table legitimately
carries `NA` stat cells on the parent `label` row of a multi-level
categorical variable. A rule requiring every cell to split would reject
correct tables.

### Ordering rule

Every public function validates all arguments before performing any work.
No partial `.docx`, no half-built `flextable`. `hv_man_table_save_jtcvs()`
currently validates `caption` before `file`; both move above the first
`officer` call. `.check_abbreviations()` is hoisted out of
`.add_abbreviations_key()` so it fires at function entry rather than
mid-render.

### Additional change beyond the six defects

`hv_tbl_summary()`'s `by` gains shape and existence validation, reusing
the wording already present in that file for `groups` variables
(`` "Variable(s) not found in `data`: " ``). The upstream `gtsummary`
errors for `by` are unusually good — they list available columns and
suggest `tbl_strata()` — but having `by` fail differently from `groups`
within the same function is precisely the inconsistency this work targets.

## Section 2 — Error-message contract

Six rules, codifying what the package's best existing messages already do.
The exemplar is `hv_tbl_summary()`'s `compare` error, which states the
violated rule, reports what arrived, diagnoses a likely cause, and names
two ways out.

- **M1** — Open with the argument name in backticks, exactly as the user
  typed it.
- **M2** — State the contract, not the violation: "must be 11 or 12", not
  "is invalid". The message should teach the rule to someone meeting it
  for the first time.
- **M3** — Report what arrived when it is short and safe to print: a
  class, a length, the offending names. Never dump a data frame or a
  `gtsummary` object.
- **M4** — End with a runnable fix: an `e.g.` literal, the helper that
  computes the value, or the alternative argument setting.
- **M5** — No upstream error vocabulary. Never surface `tidyselect`,
  `dichotomous`, or `non-character argument`. Naming `gtsummary` as the
  *origin of a concept* is permitted and often necessary ("the `stat_<k>`
  columns `gtsummary` creates, one per level of `by`"). The rule bans
  relaying upstream *sentences*, not acknowledging upstream *nouns*.
- **M6** — `call. = FALSE` on every `stop()`.

### Specified messages

| # | Message |
| --- | --- |
| 1 | `` `mpg` appears in more than one of `continuous`, `binary`, and `categorical`. Every variable must be classified exactly once. Overlapping: mpg (continuous, binary). `` |
| 2 | `` `font_size` must be 11 or 12 (house rule: 12pt, 11pt permitted for wide tables). Received a vector of length 2. `` |
| 3 | `` `groups` names must be columns in `tbl$table_body`. Not found: stat_3. Available: stat_1, stat_2. `` |
| 4 | `` `file` must be a single non-empty file path. Received: numeric of length 1. `` |
| 5 | `` `tbl` was not built with the "{N_obs} \|\|\| {stat}" convention hv_man_table_jtcvs() requires, so column `stat_1` cannot be split into its N and statistic parts. Build it with hv_tbl_summary(), or pass statistic = list(all_continuous() ~ "{N_obs} \|\|\| {mean} ± {sd}"). First unparseable value: "22 (52%)". `` |
| 6 | `` `footnotes[[1]]$text` must be a single non-empty string; it is missing. Each footnote needs list(row =, col =, text =). `` |

Messages 2 and 4 are verbatim copies of wording already in
`hv_man_table()` and `hv_man_table_save()`. That is the purpose of the
shared layer: the same rule produces the same sentence regardless of which
function the user called.

Message 5 leads with `hv_tbl_summary()` rather than the raw `statistic =`
argument, so the error routes the user toward the API that applies the
convention automatically.

### Anti-drift enforcement

A meta-test greps every `stop(` in `R/` and asserts it carries
`call. = FALSE`, failing the first time a new check omits the house
convention.

## Section 3 — Documentation requirements

Two structural gaps exist today: there is no package-level Rd (so
`?hvtiRtables` errors, which is the first thing a beginner types after
`library()`), and there are no vignettes (so the README's end-to-end
material is unreachable from an R console or an offline install).

### Rd contract, per exported function

1. **`@param` states the accepted set exhaustively and says so.**
   `hv_man_table()`'s `font_size` ends "No other values are permitted";
   `hv_man_table_jtcvs()`'s does not. Once both enforce the rule, both
   state it in the same sentence.
2. **Defaults explained by origin, not only value.** "Default `12` (house
   rule 5; `11` permitted for wide tables)" tells the user whether they
   may change it. `percentiles` is the existing model.
3. **New `@section Common mistakes:` block**, 2–4 entries per function,
   each *symptom → cause → fix*. This directly serves "what the error
   means and how to fix it" and exists nowhere today. Entries for
   now-fixed defects are retained: a user meeting the new error will
   search the help for the error's words, and the entry is where the fix
   lives.
4. **`@return` on every exported object.** Already compliant across all
   8; recorded here as a baseline for the CRAN Cookbook release gate
   rather than re-derived at release time.
5. **Examples reflect real study tables.** `gtsummary::trial` is a genuine
   clinical dataset and most examples already use it. The outlier is
   `hv_tbl_summary()`, whose example summarizes `mtcars` engine
   displacement; it is replaced with a baseline-characteristics table
   (demography and comorbidity sections, `by` treatment arm, median with
   15th/85th percentiles).

### Package-level Rd

`R/hvtiRtables-package.R` answers the question a new user has before any
function help is useful: which mode do I want? CORR flat-header for
internal reports, JTCVS merged-header for that journal's submission, plus
both pipelines end to end in a few lines each.

### Vignette

`vignettes/hvtiRtables.Rmd` walks a complete study table:
`hv_tbl_summary()` → `hv_man_table_jtcvs()` → `hv_man_table_save_jtcvs()`
→ `hv_check_docx()`, with footnotes and an abbreviation key. Adds
`knitr` and `rmarkdown` to `Suggests` and a `VignetteBuilder` field.

Rebuild time is measured and reported against the 10-minute overall
`R CMD check` gate before the vignette is committed. The content is small
`gtsummary` tables over `trial` (n = 200), so the expected cost is well
under a minute, but the measurement governs, not the estimate.

### pkgdown

Any new Rd topic is registered in `_pkgdown.yml`'s reference index.
pkgdown errors on unregistered topics, so an unregistered package-level Rd
would convert a documentation improvement into a broken site build.

## Section 4 — Test strategy

Baseline: 213 tests, 34 `expect_error` (~16% of assertions on error
paths). This work adds an estimated 65–80 tests, bringing error-path
coverage to roughly a third, and introduces two test kinds that do not
exist today.

1. **Validator unit tests** — new `tests/testthat/test-hv-validate.R`, one
   `test_that()` per validator. Each asserts: accepts every valid form;
   rejects each invalid *shape* separately (wrong class, length 0,
   length > 1, `NA`, empty string); message matches the Section 2
   contract. Testing shapes individually rather than as one lumped "rejects
   bad input" case is what catches the `font_size = c(11, 12)` class of
   bug — a lumped test passes while a vector slips through.

2. **Contract-parity tests** — assert that sibling functions reject the
   same input with the *same message*:

   ```r
   test_that("font_size contract is identical across both renderers", {
     for (bad in list(10, c(11, 12), "12", NA_real_, numeric(0))) {
       m1 <- tryCatch(hv_man_table(tbl, font_size = bad),
                      error = conditionMessage)
       m2 <- tryCatch(hv_man_table_jtcvs(tbl, groups = g, font_size = bad),
                      error = conditionMessage)
       expect_identical(m1, m2)
     }
   })
   ```

   Applied to `font_size` across both renderers, `file` across both
   savers, and `tbl`-class across all four consumers. `expect_identical()`
   is deliberately stricter than `expect_match()`: the requirement is that
   the two messages are the same sentence, so the test must fail when they
   drift by a word.

3. **Regression tests for the six defects**, one apiece, named for the
   defect and asserting the new message.

4. **Silent-failure tests carry a second assertion.** For defects 5 and 6,
   `expect_error()` alone would pass even if the function errored *after*
   writing a malformed file. Each gets a paired
   `expect_false(file.exists(out))`, the executable form of Section 1's
   ordering rule. This assertion shape is missing from the current suite
   and is what would have caught both defects.

5. **Meta-test** on `call. = FALSE`, as specified in Section 2.

6. **Shared fixtures** in `tests/testthat/helper-fixtures.R`. The parity
   tests need the same `gtsummary` object across several files, and helper
   files load under `test_check()`, `test_local()`, and `test_dir()`
   alike.

7. **CONTRIBUTING.md** gains one line on the test-invocation papercut: use
   `devtools::test()` or `testthat::test_local()`, which load the package;
   `testthat::test_dir()` does not, and its failures are artifacts of that
   rather than package defects.

Line coverage will move very little — these tests exercise `stop()` lines
that are individually cheap — while the suite becomes substantially better
at catching regressions. The coverage delta should not be read as a weak
result.

## Out of scope

- Replacing the `" ||| "` sentinel coupling between `hv_tbl_summary()` and
  `hv_man_table_jtcvs()`. It is a genuine design smell, but redesigning
  the interface is a much larger change than this pass; asserting on the
  convention is the proportionate fix.
- The unused `digits` argument to `hv_man_table()`, documented as reserved
  for a future version. Left as is.
- Any change to table rendering, layout, or house formatting output.
- Version bump and release. This branch changes behavior; the version
  decision is the maintainer's.

## Success criteria

1. All six audited defects produce a package-level error matching its
   specified message, and neither silent defect produces output.
2. `font_size`, `file`, and `tbl`-class reject identical input with
   identical messages across sibling functions, enforced by parity tests.
3. Every exported function's `@param` entries state their accepted values
   exhaustively; every enforced rule is documented and every documented
   rule is enforced.
4. `?hvtiRtables` resolves to a package-level topic that explains the
   CORR/JTCVS mode choice.
5. One end-to-end vignette builds, with measured `R CMD check` time
   reported against the 10-minute gate.
6. Full suite passes under `devtools::test()`; `R CMD check --as-cran`
   with the manual built is 0/0/0.
