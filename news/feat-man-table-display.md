* New `hv_man_table_display()` adds to a flextable from `hv_man_table()`
  what `hv_man_table_save()` writes around it in Word, so a report shows
  the same table in HTML: the asterisk and dagger header marks, the
  footnotes and the abbreviation key, the last two as footer lines. It
  shares that code with the saver, so the two cannot disagree. Both savers
  refuse its result, whose notes are rows inside the table.
