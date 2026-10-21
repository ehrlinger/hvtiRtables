* Study-supplied text can carry superscripts and subscripts, written as in
  Pandoc: a label `"BSA (m^2^)"` raises the 2 and `"HbA~1c~"` lowers the 1c.
  It applies to labels, levels, the `by` levels and section names in every
  style and layout, and to the notes, the abbreviation key and the caption
  `hv_man_table_save()` writes. A pair holds no whitespace, so `"~5 years"`
  prints as typed, and text without markup is unchanged.
  `hv_check_docx()` reports any markup a saved file still holds as plain
  text, as a `"markup"` finding.
