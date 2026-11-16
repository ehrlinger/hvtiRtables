* Errors a caller may want to catch now carry a class, as the hvtiR API rubric asks:
  `hv_check_docx()` on a missing or non-Word file signals `hvtiRtables_invalid_docx`, and
  `hv_tbl_summary()` asked for p-values without 'broom' signals
  `hvtiRtables_missing_package`. Their messages now begin with the function's name.
