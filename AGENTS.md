# hvtiRtables

Manuscript table builders for the HVTI CORR group. Eight exports across
two renderer families: the house tables
([`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md),
[`hv_man_table_save()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save.md))
and the JTCVS journal variants
([`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md),
[`hv_man_table_save_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_save_jtcvs.md)),
plus
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md),
[`hv_man_footnotes()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_footnotes.md),
[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
and
[`hv_test_footnotes_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_test_footnotes_jtcvs.md).

**The two renderer families are the defining fact of this package.**
They must not drift, and there is a test suite whose only job is to
enforce that.

This file is the operational contract and applies in full. It is tool
neutral, so Codex and any other agent read the same rules. Claude Code
affordances live in `CLAUDE.md`, which imports this file.

`CONTRIBUTING.md` carries the quick-start commands and the
SAS-table-porting workflow. It is not restated here.

## Definition of done

- `devtools::test()` passes. The runner is `tests/testthat.R`.
- `devtools::check()` is **0 errors, 0 warnings, 0 notes**. Verified
  2026-08-20 at 1.0.0 (1m 16s with `--no-manual` and vignettes skipped;
  the manual has its own gate).
- `devtools::document()` has been run and `man/` and `NAMESPACE` are
  committed with the source change.
- A change to one renderer has been made to the other, or
  `test-contract-parity.R` will say so.

## The automated gates

| workflow | fails on |
|----|----|
| `R-CMD-check.yaml` | `R CMD check` across platforms |
| `check-manual.yaml` | the PDF manual build |
| `lint.yaml` | [`lintr::lint_package()`](https://lintr.r-lib.org/reference/lint.html) |
| `pkgdown.yaml` | the site build |
| `house-style.yaml` | the composed house style |
| `test-coverage.yaml` | coverage upload |

## Rules for this repo

- **The two renderers share one contract, and `test-contract-parity.R`
  enforces it.** For the same invalid input,
  [`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md)
  and
  [`hv_man_table_jtcvs()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_jtcvs.md)
  must fail with the **same sentence**. The suite uses
  `expect_identical()` rather than `expect_match()` deliberately — the
  requirement is word-for-word, so the test fails when the two drift by
  a single word. **Adding a validation to one renderer means adding it
  to the other**, and the parity test is how a reviewer finds out you
  did not. It exists to make sibling divergence a *test failure* rather
  than a review finding.
- **Partial matching on `$` is a warning during tests, on purpose.**
  `tests/testthat/setup-partial-match.R` sets
  `options(warnPartialMatchDollar = TRUE)` after a real bug:
  `entry$note` on a `.sas_param_map` entry that had only `note_other` /
  `note_corr` / `note_jtcvs` silently resolved to one of those instead
  of `NULL`, **leaking one family’s footnote text into the other**.
  Write `entry[["note"]]`, and treat a partial-match warning in a test
  run as a defect rather than noise.
- **`.lintr` is bare `linters_with_defaults()`**, so lintr’s default
  **80-character** limit applies with every default linter on. ⚠️ The
  family disagrees on this: `hvtiRdatabuild` is 100, `hvtiPlotR` 120,
  `hvtiRtemplates`
  135. Read `.lintr` rather than assuming.
- **Roxygen markdown is ENABLED** (`Roxygen: list(markdown = TRUE)`). ⚠️
  `hvtiRutilities` and `hvtiRtemplates` have no such field and need Rd
  markup instead.
- **`VignetteBuilder` is `knitr` here**, not `quarto`. ⚠️
  `hvtiRutilities`, `hvtiRdatabuild`, `hvtiPlotR`, `hvtiRtemplates` and
  `hvtiR` all use quarto. Vignettes here are `.Rmd`.
- **[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
  validates rendered Word output.** A table that builds is not a table
  that renders correctly; the docx check is the closer to the loop, not
  an optional extra.
- **`testthat` edition 3.** Test files are `test-*.R` with a hyphen. ⚠️
  `hvtiPlotR` uses `test_*.R`.
- Every exported object must be added to `_pkgdown.yml` — the reference
  index is explicit (6 titled sections). ⚠️ `hvtiRtemplates`
  deliberately has none and auto-indexes.

## Gotchas

- **`DESCRIPTION` has no `Date:` field here**, so there is nothing to
  refresh on a version bump — unlike most of the family, where a stale
  `Date` is a live risk.
- The JTCVS variants encode **one journal’s** house requirements. A
  change that is right for the journal is not automatically right for
  the CORR tables, and the parity suite covers error contracts, not
  layout — layout divergence is legitimate and must be deliberate.
- `hv-sas-glossary.R` maps SAS parameter names onto R arguments. It is
  the file the partial-match bug lived in; changes there deserve the
  `[[ ]]` discipline above.

## Git and versioning

- **Never push to `main`.** Branch, then open a PR and let the
  maintainer merge.
- **`main` is protected by a GitHub ruleset, and nothing in this repo
  records that.** A clone shows no trace of it, so it is stated here.
  The ruleset is named `protect main`, is identical across all twelve
  repositories in the HVTI R package family, and enforces four rules on
  the default branch: no deletion, no force-push, pull-request-only, and
  an **automatic Copilot code review** on every PR. A rejected push
  comes from the server, not a local hook. ⚠️ It currently requires
  **zero approvals**. `require_code_owner_review` is set but inert
  because no repository in the family has a `CODEOWNERS` file, so a PR
  can merge unreviewed.
- Versions are **straight three digits** (`1.0.0`). Never a `.9000`
  suffix or a fourth digit.
- **Patch-digit bumps only**, as fixes land. Minor and major are the
  maintainer’s decision.
- **Bump when you name a version, not when you merge.** A pull request
  lands without touching `Version:`. Its entry goes under a
  `# hvtiRtables (unreleased)` heading in `NEWS.md`, which you add when
  it is not already there. A separate commit then renames that heading
  to the new version and updates `DESCRIPTION`, at most once a day. The
  heading is gone again after a bump, so the next change re-adds it.
  `.claude/house-style.md` carries the rule and the reasoning.

## Change discipline

1.  **Think before coding.** Do not assume, ask. If the request is
    ambiguous or a name, path or signature is uncertain, surface the
    confusion rather than running with a guess.
2.  **Simplicity first.** Write the minimum that solves the stated
    problem.
3.  **Surgical changes.** Touch only what the task requires. Raise
    nearby problems separately.
4.  **Goal-driven execution.** State what done looks like before
    starting, and use tests as the criterion. For a renderer change,
    “done” includes the other renderer.

## Prose

Documentation prose follows the house voice. Table documentation has a
specific reader: a statistician assembling a manuscript under a
journal’s constraints, who needs to know which renderer to reach for and
why the two differ.
