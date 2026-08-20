@AGENTS.md

# Claude Code specifics

[`AGENTS.md`](AGENTS.md), imported above, is the operational contract and applies in full. It is written
to be tool neutral so that Codex and other agents read the same rules. Only the Claude Code
affordances live here.

## Before you touch code

`AGENTS.md` says to orient before editing. In Claude Code the way to do that is the codemap:
it lives in the Obsidian vault under `Claude/repomaps/` and is read via the `read-codemap`
skill (`/codemap hvtiRtables`). If the codemap looks stale, say so and offer to refresh it
(`/regenerate-codemap`) rather than working from a guess.

If the vault is not available, say so rather than staying quiet about it, then orient from the
repo itself — `NAMESPACE`, `R/`, `CONTRIBUTING.md` — before editing.

## Editing one renderer

`AGENTS.md` requires that a change to one renderer be made to the other. In practice: after
touching `hv-man-table.R` or `hv-man-table-jtcvs.R`, run

```r
devtools::test(filter = "contract-parity")
```

before anything else. It is fast, and it is the test that fails when the two error contracts
drift by a word — which is easy to do when editing only the file you were asked about.

## Prose

`AGENTS.md` points at the house voice. In Claude Code, apply the `ehrlinger-writing` skill:
it carries the same voice, reader persona and project context, kept in sync from the vault
sources. For documentation *structure*, the `r-package-style` skill is the companion.
