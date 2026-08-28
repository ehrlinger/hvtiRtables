# Contributing to hvtiRtables

Thank you for contributing! This guide covers two tracks:

- **Track A — Porting a SAS table macro** (for biostatisticians and
  analysts): adding a new table-building function that mirrors a SAS macro
  the team already uses.
- **Track B — Package infrastructure** (for R package developers):
  dependency changes, CI, testing, and CRAN-style compliance.

---

## Quick start

```r
# 1. Install development dependencies
install.packages("devtools")
devtools::install_deps(dependencies = TRUE)

# 2. Load the package without installing
devtools::load_all()

# 3. Run all checks (must pass before a PR is merged)
devtools::check()

# 4. Run tests only
devtools::test()

# 5. Regenerate documentation
devtools::document()
```

Run the suite with `devtools::test()` or `testthat::test_local()`. Both
load the package first. `testthat::test_dir("tests/testthat")` does
not, so its failures are artifacts of the invocation rather than
package defects.

---

## Track A — Porting a SAS table macro

If you have a SAS table macro (e.g. `%summarytable`) and want to add an R
equivalent:

1. **Create `R/hv-my-table.R`** — one file per function.
2. **Write the function as a thin wrapper over `gtsummary`** — this
   package's whole premise is "starts from a `gtsummary` object." Reuse
   `gtsummary::tbl_summary()`/`add_p()`/`add_difference()`'s existing,
   tested statistical machinery rather than reimplementing test selection,
   p-values, or standardized differences. Your function's job is
   translating a house-style interface (grouped variable lists,
   SAS-macro-familiar parameter names) into the right `gtsummary` call —
   not computing statistics from scratch.
3. **Feed the result into the existing renderers** — `hv_man_table()`/
   `hv_man_table_save()` for the flat CORR house style, or
   `hv_man_table_jtcvs()`/`hv_man_table_save_jtcvs()` for JTCVS
   submissions. Don't invent a new table class or a new renderer unless an
   existing one genuinely cannot express the output shape.
4. **Write roxygen docs** — include `@param` (naming the SAS-parameter
   equivalent for each argument, e.g. "`%summarytable` `PP=` equivalent"),
   `@return`, `@seealso`, and `@examples`.
5. **Run `devtools::document()`** to regenerate `NAMESPACE` and `.Rd` files.
6. **Add a migration cheat-sheet section to `README.md`** — a heading
   named for the macro you ported ("Migrating from the `%yourmacro` SAS
   macro"), a parameter-mapping table listing every SAS macro argument
   against its R equivalent and explicitly marking what is not supported,
   and a worked side-by-side example showing a real macro call next to
   the equivalent R call.
7. **Add the function** to the right section in `_pkgdown.yml`.
8. **Write tests** in `tests/testthat/test-hv-my-table.R` (matching the
   existing hyphenated file naming): input validation, each documented
   option, and at least one characterization test against a real example
   table if one is available. See `test-hv-man-table-jtcvs.R`'s
   "reproduces template's header/section shape" test for the pattern —
   synthetic data engineered to reproduce a real table's actual N counts
   and section grouping, since real patient-level data is rarely
   available to check into the repo.
9. **Update `NEWS.md`** under the current dev version.
10. Open a pull request against `main`.

---

## Track B — Package infrastructure

For changes to `DESCRIPTION`, CI workflows, testing infrastructure, or
package-level architecture:

- **New dependencies** must be justified and added to the right field
  (`Imports` for runtime, `Suggests` for test-only). Check the target
  package's own namespace exports before adding a new dependency — several
  tidyselect helpers (`all_of()`, `everything()`) and gtsummary formatters
  (`style_pvalue()`, `style_sigfig()`) are already re-exported through
  `gtsummary`, so `dplyr`/`tidyselect` rarely need to become hard Imports.
- **CI** runs `R CMD check --as-cran`, `lintr::lint_package()`, test
  coverage (via Codecov), and the pkgdown site build on push
  (`.github/workflows/`). All checks must pass.
- **Versioning**: patch-digit bumps (`0.9.0` → `0.9.1`) are fine for
  incremental features and fixes as they land. Never bump the minor or
  major digit without explicit maintainer direction — features accumulate
  under the current minor until a deliberate release consolidates them.
  Every version bump updates both `DESCRIPTION` and `NEWS.md`.
- **Breaking changes** to existing function signatures require a `NEWS.md`
  entry; prefer adding a new optional parameter with a backward-compatible
  default over changing existing behavior (see `hv_man_table_jtcvs()`'s
  `stat_label` parameter for a worked example).

---

## Code conventions

| Convention | Rule |
|---|---|
| File names | `kebab-case.R` (e.g. `hv-man-table-jtcvs.R`) |
| Function names | `hv_<concept>()`, e.g. `hv_man_table()`, `hv_man_table_jtcvs()`, `hv_tbl_summary()` |
| House font/rounding | Times New Roman, 12pt (11pt permitted for wide tables, house rule 5) — set once via each renderer's `font`/`font_size` params, never hard-coded elsewhere |
| Footnotes | House-universal footnotes live in `hv_man_footnotes()`; study-specific ones are passed by the caller, never hard-coded into a table-building function |
| Statistics | Reuse `gtsummary`'s own defaults (Wilcoxon/Kruskal-Wallis for continuous, chi-square-with-Fisher's-fallback for categorical) rather than writing custom test-selection logic |
| Tests | Hyphenated file names matching the source file (`R/hv-my-table.R` → `tests/testthat/test-hv-my-table.R`); `Config/testthat/edition: 3` |
| Docs | `docs/` is reserved for pkgdown's build output only (gitignored) — design documents and implementation plans live under `dev/specs/` |

---

## Getting help

- Open an [issue](https://github.com/ehrlinger/hvtiRtables/issues) to
  discuss a new port before writing code.
- Tag `@ehrlinger` for review on all pull requests.
