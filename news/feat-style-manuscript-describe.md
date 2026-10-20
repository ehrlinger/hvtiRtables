* The manuscript style gains its second layout, `"describe"`, for tables that describe
  cohorts or repeated measures side by side (dev/specs/2026-10-17-table-styles-design.md,
  section 5.1): `hv_man_table(tbl, style = "manuscript", layout = "describe")`. Each group
  spans its own count and statistic, so every group has its count, and an Overall column and
  comparison columns appear when the table carries them. Everything else is the comparison
  layout's: the full grid, shaded section rows spanning the table, no font of its own, and
  US Letter pages. `layout = "compare"` is the default, and the report style takes no
  `layout`.
  - `hv_man_table()`'s `layout` argument follows `style`, so a call passing every argument
    by position reaches `...` at the seventh, not the sixth. A SAS stray argument such as
    `%summarytable`'s `STYLE=` therefore meets the check at position 7.
  - Describe's marks follow the notation standard: `*` on each group's `n` and `†` on each
    statistic, with `*Patients with non-missing data.` and the dagger note below the table,
    and `hv_man_table_save(ft, file, caption = )` writes the caption above it.
  - `hv_man_table_display()` shows a describe table; it refused one before.
* **Deprecated:** `hv_man_table_jtcvs()`, `hv_man_table_save_jtcvs()` and
  `hv_test_footnotes_jtcvs()` warn on every call and go in the next release. Until then their
  arguments keep their meaning: `groups` and `trailing` choose the same columns, and
  `stat_label` names the statistic.
  - **Their output changes:** the table is drawn in the describe layout, with the same
    columns as before but the manuscript's grid, shading, notes (`*Patients with non-missing
    data.` for `a. Patients with data available.`) and the document's font.
  - `hv_man_table_save_jtcvs()` writes `caption` above the table and the table's own notes
    below it, as `hv_man_table_save()` does. It drops a test footnote that
    `hv_test_footnotes_jtcvs()` wrote when the table already names that test, as an
    `hv_tbl_summary()` table does in its dagger note and with Fisher's mark on its P values.
    Every other positional `footnotes` entry keeps a lettered superscript on its cells,
    lettered from `a`, with its line after the table's own notes; the unnamed test notes of
    a plain gtsummary table stay lettered the same way.
  - Move to `hv_man_table(tbl, style = "manuscript", layout = "describe")` and
    `hv_man_table_save(ft, file, caption = )`; the test notes then come from the table.
