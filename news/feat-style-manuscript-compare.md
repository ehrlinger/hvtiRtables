* Tables are drawn in a style named by its role (dev/specs/2026-10-17-table-styles-design.md).
  `hv_table_style()` holds a style's properties; `hv_man_table(style =)` takes `"report"`
  (the default, today's table) or `"manuscript"`.
  - The manuscript style lays out a comparison table as the submissions did: a full grid, a
    two-row header with the grouping spanning its levels, one overall `n` column, shaded
    section rows spanning the table, a bold header and caption, 300-twip rows kept whole, and no font
    of its own, so it takes the document's body font. Its notes begin with the plain symbol:
    `*Patients with non-missing data.`, `†Values are No. (%) or median [15th, 85th
    percentiles].`
  - `hv_man_table_save()` takes `caption`, written bold above the table: the manuscript
    style requires it, and a report may give one.
  - `hv_tbl_summary()` carries each variable's overall non-missing count and the grouping's
    name for the manuscript header.
  - `hv_man_table_display()` shows the notes in the table's style, so a manuscript table's
    notes begin with the plain symbol there as they do in the saved file.
  - The SAS glossary maps `STYLE=` to `style =` (CORR family only) and `TBLTITLE=` to
    `caption =`.
  - The manuscript style refuses what it cannot lay out, each with an error that says what
    to do instead: `font` and `font_size` (it sets no font), `continuous_stat = "both"`
    (one statistic per group), and a table not built by `hv_tbl_summary()` (it reads the
    overall count and the grouping's name that function records).
  - The manuscript's label column is 2.0 in wide, so a Table 1 with Overall, two groups and
    a P value is 6.5 in and stays on a portrait Letter page.
  - `hv_check_docx()` checks merged cells: by default merges only in header rows and in
    section rows that span the table, and none at all with `style = "report"`.
  - `hv_man_table_jtcvs()` section rows now span the table in one cell; they were a label
    beside one merged blank cell.
  - **Existing tables change:** the report shades its section rows (`#CAEDFB` by default,
    every cell, unmerged), its header is now bold throughout (the `N = n` lines and the
    marks were not), and both savers write US Letter pages instead of A4, so a wide table
    now fits a 9.0 in landscape text block instead of 9.7 in.
