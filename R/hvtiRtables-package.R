#' hvtiRtables: Manuscript-Compliant Table Construction
#'
#' Turns `gtsummary` table objects into MS Word tables that comply with
#' HVTI CORR's "Table Construction for Manuscripts" rules. Two
#' rendering modes exist because CORR reports and JTCVS submissions
#' want different things from the same header row.
#'
#' @section Which mode do I want?:
#' **CORR house style** — flat, non-merged header, no hidden spacer
#' columns, footnotes as text below the table. Use for internal reports
#' and any journal without its own template.
#'
#' ```
#' tbl <- gtsummary::tbl_summary(dta, by = "trt")
#' ft  <- hv_man_table(tbl)
#' hv_man_table_save(ft, "table1.docx")
#' ```
#'
#' **JTCVS submission format** — two-row merged spanning header,
#' shaded section rows, lettered cell-targeted footnotes. Use when
#' submitting to that journal.
#'
#' ```
#' tbl <- hv_tbl_summary(
#'   dta, by = "trt",
#'   groups = list(Demography = c("age", "sex")),
#'   continuous = "age", categorical = "sex"
#' )
#' ft <- hv_man_table_jtcvs(
#'   tbl, groups = c(stat_1 = "A (n=98)", stat_2 = "B (n=102)"),
#'   stat_label = attr(tbl, "hv_stat_label"),
#'   trailing = attr(tbl, "hv_trailing")
#' )
#' hv_man_table_save_jtcvs(
#'   ft, "table1.docx", caption = "Table 1. Baseline Characteristics",
#'   footnotes = hv_test_footnotes_jtcvs(tbl)
#' )
#' ```
#'
#' @section Checking a finished document:
#' [hv_check_docx()] reads any `.docx` and reports the structural
#' patterns the house rules forbid. Neither saver runs it on its own
#' output, so call it on the path afterwards.
#'
#' @keywords internal
"_PACKAGE"
