# Surfaces R's `$` partial-matching on lists as a warning during the
# test run. Added after a real bug: `entry$note` on a `.sas_param_map`
# entry with only a `note_other`/`note_corr`/`note_jtcvs` field silently
# resolved to that field instead of NULL, leaking one family's note text
# to the other. See test-hv-sas-glossary.R.
options(warnPartialMatchDollar = TRUE)
