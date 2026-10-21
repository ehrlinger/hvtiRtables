# Table styles

A table is drawn in a style named by its role. The report style is the
working table of an analysis report. The manuscript style is the table a
journal receives, laid out by what the table does: `"compare"` for
groups it compares, `"describe"` for cohorts or repeated measures it
describes side by side.

This page draws one table in each, then prints the matrix of what
differs. The matrix is read from
[`hv_table_style()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_table_style.md)
when the page is built, so it is not copied by hand. Some properties are
labels the renderers do not read yet; the matrix lists them as the style
records them.

## One table

``` r

library(hvtiRtables)
```

The data are
[`gtsummary::trial`](https://www.danieldsjoberg.com/gtsummary/reference/trial.html),
a simulated trial that ships with gtsummary. Age is shown as mean±SD and
the marker level as a median, so the table also carries the mark the
house standard puts on the statistic fewer rows use (`¶`).

``` r

tbl <- hv_tbl_summary(
  gtsummary::trial, by = "trt",
  groups = list(Demography = c("age", "marker"),
                Disease = c("stage", "grade")),
  continuous = c("age", "marker"), categorical = c("stage", "grade"),
  mean_sd = "age", show_variable = FALSE
)
key <- c(SD = "standard deviation")
```

`show_variable = FALSE` leaves out the Variable column a report shows on
screen. Every saved `.docx` drops it, and each table here is drawn as it
is saved.

## The report style

``` r

report <- hv_man_table(tbl)
hv_man_table_save(report, "table-styles-report.docx",
                  abbreviations = key)
```

[TABLE]

The saved file:
[table-styles-report.docx](https://ehrlinger.github.io/hvtiRtables/articles/table-styles-report.docx).

## The manuscript style, compare

``` r

compare <- hv_man_table(tbl, style = "manuscript")
hv_man_table_save(compare, "table-styles-compare.docx",
                  abbreviations = key,
                  caption = "Table 1. Baseline characteristics")
```

**Table 1. Baseline characteristics**

| Characteristic | n\* | Overall (N = 200) | Chemotherapy Treatment† |  | P† |
|----|----|----|----|----|----|
|  |  |  | Drug A (N = 98) | Drug B (N = 102) |  |
| Demography |  |  |  |  |  |
| Age | 189 | 47±14.3¶ | 47±14.7¶ | 47±14.0¶ | .7 |
| Marker Level (ng/mL) | 190 | 0.64 \[0.12, 1.9\] | 0.84 \[0.15, 2.1\] | 0.52 \[0.10, 1.7\] | .085 |
| Disease |  |  |  |  |  |
| T Stage | 200 |  |  |  | .9 |
| T1 |  | 53 (27) | 28 (29) | 25 (25) |  |
| T2 |  | 54 (27) | 25 (26) | 29 (28) |  |
| T3 |  | 43 (22) | 22 (22) | 21 (21) |  |
| T4 |  | 50 (25) | 23 (23) | 27 (26) |  |
| Grade | 200 |  |  |  | .9 |
| I |  | 68 (34) | 35 (36) | 33 (32) |  |
| II |  | 68 (34) | 32 (33) | 36 (35) |  |
| III |  | 64 (32) | 31 (32) | 33 (32) |  |
| \*Patients with non-missing data. |  |  |  |  |  |
| †Values are No. (%) or median \[15th, 85th percentiles\]; P values from the Wilcoxon rank sum test and Pearson's chi-square test. |  |  |  |  |  |
| ¶Mean±SD. |  |  |  |  |  |
| Key: SD, standard deviation |  |  |  |  |  |

The saved file:
[table-styles-compare.docx](https://ehrlinger.github.io/hvtiRtables/articles/table-styles-compare.docx).

## The manuscript style, describe

``` r

describe <- hv_man_table(tbl, style = "manuscript", layout = "describe")
hv_man_table_save(describe, "table-styles-describe.docx",
                  abbreviations = key,
                  caption = "Table 2. The treatment arms side by side")
```

**Table 2. The treatment arms side by side**

| Characteristic | Overall (N = 200) |  | Drug A (N = 98) |  | Drug B (N = 102) |  | P† |
|----|----|----|----|----|----|----|----|
|  | n\* | No. (%) or Median \[15th, 85th percentiles\]† | n\* | No. (%) or Median \[15th, 85th percentiles\]† | n\* | No. (%) or Median \[15th, 85th percentiles\]† |  |
| Demography |  |  |  |  |  |  |  |
| Age | 189 | 47±14.3¶ | 91 | 47±14.7¶ | 98 | 47±14.0¶ | .7 |
| Marker Level (ng/mL) | 190 | 0.64 \[0.12, 1.9\] | 92 | 0.84 \[0.15, 2.1\] | 98 | 0.52 \[0.10, 1.7\] | .085 |
| Disease |  |  |  |  |  |  |  |
| T Stage |  |  |  |  |  |  | .9 |
| T1 | 200 | 53 (27) | 98 | 28 (29) | 102 | 25 (25) |  |
| T2 | 200 | 54 (27) | 98 | 25 (26) | 102 | 29 (28) |  |
| T3 | 200 | 43 (22) | 98 | 22 (22) | 102 | 21 (21) |  |
| T4 | 200 | 50 (25) | 98 | 23 (23) | 102 | 27 (26) |  |
| Grade |  |  |  |  |  |  | .9 |
| I | 200 | 68 (34) | 98 | 35 (36) | 102 | 33 (32) |  |
| II | 200 | 68 (34) | 98 | 32 (33) | 102 | 36 (35) |  |
| III | 200 | 64 (32) | 98 | 31 (32) | 102 | 33 (32) |  |
| \*Patients with non-missing data. |  |  |  |  |  |  |  |
| †Values are No. (%) or median \[15th, 85th percentiles\]; P values from the Wilcoxon rank sum test and Pearson's chi-square test. |  |  |  |  |  |  |  |
| ¶Mean±SD. |  |  |  |  |  |  |  |
| Key: SD, standard deviation |  |  |  |  |  |  |  |

The saved file:
[table-styles-describe.docx](https://ehrlinger.github.io/hvtiRtables/articles/table-styles-describe.docx).

## Units in labels

A label, a level, a note or the caption can carry a superscript or a
subscript, written as in Pandoc: `^2^` raises the 2 and `~2~` lowers it.
The study writes plain text, in its
[`vars()`](https://dplyr.tidyverse.org/reference/vars.html) or its data
build, and every style sets it. A pair holds no whitespace, so
`~5 years` prints as typed.

``` r

units <- gtsummary::trial
units$bsa <- 1.6 + (units$age %% 10) / 20
attr(units$bsa, "label") <- "BSA (m^2^)"
bsa <- hv_tbl_summary(units, by = "trt", groups = list(Size = "bsa"),
                      continuous = "bsa", show_variable = FALSE)
```

| Characteristic | n\* | Overall (N = 200) | Chemotherapy Treatment† |  | P† |
|----|----|----|----|----|----|
|  |  |  | Drug A (N = 98) | Drug B (N = 102) |  |
| Size |  |  |  |  |  |
| BSA (m2) | 189 | 1.8 \[1.6, 2.0\] | 1.8 \[1.6, 2.0\] | 1.8 \[1.6, 2.0\] | .077 |
| \*Patients with non-missing data. |  |  |  |  |  |
| †Values are No. (%) or median \[15th, 85th percentiles\]; P values from the Wilcoxon rank sum test. |  |  |  |  |  |
| Key: BSA, body surface area |  |  |  |  |  |

## What a web page cannot show

The tables above are
[`hv_man_table_display()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table_display.md)’s
HTML, built from the same code the saver uses for its marks and notes.
Fill, grid, spans, weight, alignment, marks and note wording are the
saved file’s. Some of the `.docx` is Word’s alone; open the saved files
to see it:

- **The page.** Every style saves to US Letter. The report turns
  landscape when it has three or more statistic columns or is wider than
  a portrait page; the manuscript turns only on width.
- **The manuscript’s font.** The manuscript style sets no font, so in
  Word the table takes the document’s body font. Here it takes this
  page’s font.
- **Rows and pages.** Row heights in twips, rows kept whole on a page,
  and the header repeated on a new page are Word’s pagination.
- **Notes and caption.** Here the notes are footer lines of the table
  and the caption a bold line above it. In Word both are paragraphs, the
  caption above the table and the notes below it, in the same words.
- **The dark theme.** The example tables (flextable) are shown on white,
  as in Word, whatever the site’s theme; the matrix and rules tables
  below follow the site’s theme. The site’s CSS rule whitens every
  flextable on the site, the reference examples included.
- **The abbreviation key.** In the saved file the key is one paragraph
  below the notes, in the form `Key: A, definition`, with each
  abbreviation in italics (house rule 14). Here it is the same
  paragraph.

## The matrix

The manuscript style takes two columns because its layout is an argument
of
[`hv_man_table()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_man_table.md),
not a property of the style, so one style object serves both tables. A
row the same in every style is listed once, after the matrix.

| Property | report | manuscript, compare | manuscript, describe |
|:---|:---|:---|:---|
| Section row | label in the first cell, bold, left; fill on every cell of the row, unmerged | spans the full width, bold; filled | spans the full width, bold; filled |
| Borders | horizontal rules only | full grid: box plus all inner lines, single 0.5 pt | full grid: box plus all inner lines, single 0.5 pt |
| Header | one row: a `No.` column before each group’s `<group> N = n`; `*` on the first `No.`, `†` on each group | two rows: `Characteristic` and `n*` merged down, the grouping’s name with `†` spanning its levels; row 2 `<level> (N = n)` | two rows: each group, `<level> (N = n)`, spans its own (n, statistic) pair; row 2 names them, `n*` and the statistic with `†` |
| Non-missing count | one column per group | one overall `n*` column | one `n*` column per group, Overall’s included |
| Note markers | the house symbols by meaning, superscript, then a space | the house symbols by meaning, at the start of the note, not superscript | the house symbols by meaning, at the start of the note, not superscript |
| Count note | `Number of non-missing values.` | `Patients with non-missing data.` | `Patients with non-missing data.` |
| Statistic note | `No. (%) or Median [15th, 85th percentiles].` | `Values are No. (%) or median [15th, 85th percentiles].` | `Values are No. (%) or median [15th, 85th percentiles].` |
| Font | Times New Roman 12 pt | none set: the document’s body font | none set: the document’s body font |
| Caption | optional: bold, above the table, when given | required: bold, above the table | required: bold, above the table |
| Row height | auto | at least 300 twips, rows kept on one page | at least 300 twips, rows kept on one page |
| Variable column | on screen only; every saved `.docx` drops it | never | never |
| Merged cells | none | header and section rows | header and section rows |

What every style shares:

| Property | Every style |
|:---|:---|
| Fill color | `#CAEDFB`; `hv_table_style(fill =)` sets it |
| Overall and comparison columns | shown when the table carries them |
| Continuous values | `9.9 [8.5, 11]`, `63±13`: the house standard |
| Categorical values | `30 (42)`: the house standard |
| Abbreviations | `Key: A, …; B, …` |
| Alignment and weight | header bold; first column left, others centered |
| Header repeated on a new page | yes |
| Page | US Letter, landscape when wide, else portrait |

The values are the house standard, which
[`hv_tbl_summary()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_tbl_summary.md)
writes for every style: P values without a leading zero (`.013`,
`<.001`, `>.9`), and the statistic fewer rows use marked on its cells,
`§` on a median among means and `¶` on a mean among medians. A journal
that prints the submitted table can change the fill:
`hv_table_style("manuscript", fill = "#A5C9EB")`.

## The house rules

*Table Construction for Manuscripts* (7/14/2026) was written for tables
edited by hand for submission. A generated table is never edited by
hand, so a rule that exists to keep a hand-edited table editable became
a style property: the report keeps it, and the manuscript keeps it or
sets it aside where the submissions did. A content rule says what a
reader needs whoever made the table, and binds every style.
[`hv_check_docx()`](https://ehrlinger.github.io/hvtiRtables/reference/hv_check_docx.md)
checks the rules marked checked in any saved file; rule 3 is checked as
each style keeps it, strictly with `style = "report"` and allowing
header and full-width section merges otherwise.

| Rule | What it asks | Kind | report | manuscript | Checked |
|:---|:---|:---|:---|:---|:---|
| 2 | No blank paragraph where the table is pasted | hand edit | kept | kept |  |
| 3 | No merged cells | hand edit | kept | set aside: merges its header and section rows | yes |
| 5 | Times New Roman, 12 pt (11 pt for a wide table) | hand edit | kept | set aside: the document’s body font |  |
| 8 | The count note reads “Number of non-missing values.” | hand edit | kept | set aside: “Patients with non-missing data.” |  |
| 13 | Notes below the table, never inside it | content | kept | kept | yes |
| 14 | One abbreviation key, sorted, below the notes | hand edit | kept | kept |  |
|  | No hidden spacing columns | content | kept | kept | yes |
|  | No floating layers (text boxes, frames) | content | kept | kept | yes |
|  | The non-missing count is shown, and its note says what it counts | content | kept | kept |  |
|  | Every statistic is named and every mark explained | content | kept | kept |  |
|  | Every abbreviation in the table is defined | content | kept | kept |  |

Each file saved above passes, checked as the style that wrote it. A
count of 0 means the saved file has no findings:

``` r

nrow(hv_check_docx("table-styles-report.docx", style = "report"))
#> [1] 0
nrow(hv_check_docx("table-styles-compare.docx", style = "manuscript"))
#> [1] 0
nrow(hv_check_docx("table-styles-describe.docx", style = "manuscript"))
#> [1] 0
```
