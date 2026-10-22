* `hv_man_table_save()` takes `orientation = c("auto", "portrait",
  "landscape")`. `"auto"`, the default, is the width rule it already
  followed: a table too wide for a portrait page is written landscape.
  `"portrait"` or `"landscape"` always wins, and a table too wide for the
  chosen page has its columns narrowed in proportion to fit it.
