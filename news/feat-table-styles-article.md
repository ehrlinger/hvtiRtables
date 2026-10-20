* The package site gains a "Table styles" article: one synthetic table drawn in each style and
  layout (report; manuscript, compare; manuscript, describe), beside the matrix of their
  properties, and a table of the house rules saying which are content rules, binding every
  style, and which are hand-edit rules, and which styles keep each. The matrix is written from
  `hv_table_style()` when the site is built, so it is read from the style objects, not copied by hand. Each table's
  saved `.docx` is a download on the page. `?hv_man_table` and `?hv_table_style` link to it.
* The site keeps flextable tables on white in its dark theme (`pkgdown/extra.css`), as they
  appear in Word, reference examples included.
* `hv_man_table_display()` shows a manuscript table in the page's font and size. The manuscript
  style sets no font, and in HTML its table fell back to the browser's default font, a serif,
  so it looked set in the report's Times New Roman, while its notes were in Helvetica.
