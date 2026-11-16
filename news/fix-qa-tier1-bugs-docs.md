* `hv_man_table_save()` and `hv_man_table_display()`: `footnotes = NULL` suppresses the
  default notes only. On a table whose cells carry `‡`, `§` or `¶` it is refused, as before,
  and the error now says so instead of asking for a list the caller meant not to pass. The
  help says the same.
* `hv_tbl_summary()`: a mean ± SD cell the EHB/Blackstone rule cannot round (an SD of zero,
  or a single patient's NA) still keeps gtsummary's text, and now warns, as a median cell
  already did.
* The abbreviation key is sorted the same in every locale (case folded, then radix), so a Mac
  and lri write the same `.docx`.
* Both savers refuse a `file` that does not end in `.docx`.
* `hv_man_table()`'s `digits`, which never did anything, is deprecated: passing it warns once
  per session.
* The deprecated JTCVS functions now say when they go: deprecated in 1.0.8, removed in the
  next minor release.
