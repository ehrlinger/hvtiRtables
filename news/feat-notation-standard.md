* Tables follow the house notation standard (dev/specs/2026-10-17-table-styles-design.md,
  section 5.2). **Existing tables change:**
  - Medians are shown in brackets, each number to 2 significant digits and a value of 10 or
    more to the units place: `102 [63, 170]`, `0.31 [0.21, 0.39]`. The statistic note reads
    "Median [15th, 85th percentiles]".
  - P values drop the leading zero: `.013`, `<.001`, `>.9`.
  - A table mixing medians and means marks the cells of whichever statistic fewer rows use, a
    section sign on medians and a pilcrow on means, with a note for each; the row-label
    suffixes ("Age, Mean±SD") and the "No. (%) or as labeled" note are gone.
  - Mean ± SD is unchanged: `63±13`, unspaced, EHB paired rounding.
  - Exact ties in a median or percentile round to even, as for mean +/- SD: 62.5 shows as 62,
    where gtsummary and SAS showed 63.
  - In `hv_man_table_jtcvs()` the mark is a lettered superscript `b` with its own note, so the
    test footnotes letter from `c` (they were `b`, `c`).
  - Passing `footnotes = hv_man_footnotes()` explicitly on a mixed table now errors unless the
    footnotes carry the mark's note. `§` and `¶` are reserved on mixed tables; use `||` for a
    study note.
