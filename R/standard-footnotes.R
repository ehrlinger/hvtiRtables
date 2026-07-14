#' The house-standard manuscript table footnotes
#'
#' Two footnotes are universal to the HVTI CORR "Table Construction for
#' Manuscripts" rules, not specific to any one study, so they live here
#' rather than being re-typed at every [save_manuscript_table()] call site:
#' a `*` for the non-missing-value count (house rule 8, exact wording
#' required) and a `†` explaining the `{median} ({p15}, {p85})` format used
#' for continuous variables throughout these tables. No footnote is needed
#' for the categorical `n (%)` format — the column header text already
#' covers it (house rules 10/12).
#'
#' [save_manuscript_table()]'s `footnotes` parameter defaults to calling
#' this function, so every table gets both automatically. Override with
#' ordinary list operations — no special sentinel values:
#' - Suppress both: `footnotes = NULL`
#' - Change one: `modifyList(standard_footnotes(), list(\`†\` = "custom text"))`
#' - Add a study-specific one alongside: `c(standard_footnotes(), list(\`‡\` = "extra note"))`
#'
#' @return A named list, `list(\`*\` = ..., \`†\` = ...)`, in the format
#'   [save_manuscript_table()]'s `footnotes` parameter expects.
#'
#' @seealso [save_manuscript_table()]
#'
#' @export
standard_footnotes <- function() {
  list(
    `*` = "Number of non-missing values.",
    `†` = "Median (15th, 85th percentile)."
  )
}
