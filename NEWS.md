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
