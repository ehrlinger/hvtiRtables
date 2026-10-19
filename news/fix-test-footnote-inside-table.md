* `hv_man_table()` no longer carries gtsummary's own footnotes inside the table. A saved table
  with `compare = "pvalue"` (or `"smd"` or `"both"`) ended in a footer row reading "1Wilcoxon
  rank sum test; Pearson's Chi-squared test", with a raised digit on the p-value header, and
  `compare = "both"` added an "Abbreviation: CI = Confidence Interval" row: house rule 13 puts
  notes below the table. **Existing tables change:**
  - The dagger note now names the tests behind the p-values ("... Median [15th, 85th
    percentiles]; P values from the Wilcoxon rank sum test and Pearson's chi-square test."),
    and the dagger marks the p-value header as well as the statistic headers. Fisher's exact
    test keeps its own double dagger and is not repeated. A table with no p-values has no test
    sentence.
  - A table showing a confidence interval (`compare = "both"`) defines `CI` in the key. Passing
    `abbreviations` to `hv_man_table_save()` or `hv_man_table_display()` replaces that key.
* `hv_check_docx()` flags a last-row cell that opens with a superscript number, the form
  gtsummary writes a footnote in, and one that starts "Abbreviation:". It returned no findings
  for the tables above.
