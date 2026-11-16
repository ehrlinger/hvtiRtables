* Errors a caller may want to catch now carry a class, as the hvtiR API rubric asks:
  `hv_check_docx()` on a missing or non-Word file signals `hvtiRtables_invalid_docx` (now
  also for a `word/document.xml` that does not parse or is not a WordprocessingML body, which
  was reported clean), and
  `hv_tbl_summary()` asked for p-values without 'broom' signals
  `hvtiRtables_missing_package`. Their messages now begin with the function's name.
