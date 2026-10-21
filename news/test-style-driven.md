* The table-style output tests now read fill, row height, font, font size and
  note wording from `hv_table_style()` instead of repeating them, so a change
  to the house style moves the expectations with it. One test still pins the
  defaults. No change for users.
