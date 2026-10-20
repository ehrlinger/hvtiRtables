# Row indices at which a new section begins. hv_man_table_jtcvs() inserts
# one section-header row immediately before each of these.
.jtcvs_section_starts <- function(tb) {
  if (!"groupname_col" %in% names(tb)) return(integer(0))
  which(c(TRUE, tb$groupname_col[-1] != tb$groupname_col[-nrow(tb)]))
}

# Rendered flextable body row for each gtsummary table_body row. Each row
# shifts down by the number of section headers inserted at or before it.
# The cumulative sum is taken over an indicator that is TRUE *at* each
# section start, not before it: the header inserted ahead of a section's
# first row pushes that row down as well.
.jtcvs_body_row_index <- function(tb) {
  is_start <- logical(nrow(tb))
  is_start[.jtcvs_section_starts(tb)] <- TRUE
  seq_len(nrow(tb)) + cumsum(is_start)
}

.reshape_jtcvs_body <- function(tbl, groups, trailing = NULL) {
  tb <- tbl$table_body
  has_sections <- "groupname_col" %in% names(tb)

  out <- data.frame(
    label = tb$label,
    is_section = FALSE,
    row_type = tb$row_type,
    variable = tb$variable,
    stringsAsFactors = FALSE
  )

  for (col in names(groups)) {
    parts <- strsplit(tb[[col]], " \\|\\|\\| ")
    out[[paste0("n_", col)]] <- vapply(
      parts, function(p) if (length(p) == 2) p[1] else NA_character_,
      character(1)
    )
    out[[paste0("disp_", col)]] <- vapply(
      parts, function(p) if (length(p) == 2) p[2] else NA_character_,
      character(1)
    )
    # hv_tbl_summary(continuous_stat = "both") keeps the median in a
    # column of its own beside each group's statistic.
    med <- paste0("hv_median_", col)
    if (med %in% names(tb)) out[[paste0("med_", col)]] <- tb[[med]]
  }

  for (col in names(trailing)) out[[col]] <- tb[[col]]

  if (!has_sections) {
    rownames(out) <- NULL
    return(out)
  }

  # Insert one section-header row before each run of same-groupname_col rows
  section_starts <- .jtcvs_section_starts(tb)
  section_labels <- tb$groupname_col[section_starts]
  sec_rows <- out[rep(NA_integer_, length(section_starts)), , drop = FALSE]
  sec_rows$label <- section_labels
  sec_rows$is_section <- TRUE
  sec_rows$row_type <- "section"
  stat_cols <- setdiff(names(out), c("label", "is_section", "row_type"))
  sec_rows[stat_cols] <- NA_character_

  insert_before <- section_starts
  result <- out[0, , drop = FALSE]
  prev <- 0L
  for (k in seq_along(insert_before)) {
    if (insert_before[k] > prev + 1L) {
      result <- rbind(
        result, out[(prev + 1L):(insert_before[k] - 1L), , drop = FALSE]
      )
    }
    result <- rbind(result, sec_rows[k, , drop = FALSE])
    prev <- insert_before[k] - 1L
  }
  if (prev < nrow(out)) {
    result <- rbind(result, out[(prev + 1L):nrow(out), , drop = FALSE])
  }
  rownames(result) <- NULL
  result
}

#' Deprecated: Build a JTCVS-Format Manuscript Table with Merged Headers
#'
#' **Deprecated.** Use
#' `hv_man_table(tbl, style = "manuscript", layout = "describe")`, the
#' manuscript style's describe layout, which this layout became. This
#' function warns on every call and goes in the next release.
#'
#' Stage 2 of the `%summarytable` split: shapes the table. The macro
#' controlled this with `STYLE=` and `PAGE=`. This renderer is the
#' journal's one layout and takes neither; the CORR styles are chosen by
#' `style =` in [hv_man_table()]. Pages are US Letter.
#'
#' Until it goes, it passes its arguments through to that layout: `groups`
#' and `trailing` choose the same group, Overall and comparison columns,
#' and `stat_label` names the statistic under each group. The table is
#' drawn in the manuscript style, not the JTCVS look it drew before: a
#' full grid, shaded section rows spanning the table, `*` and `†` notes,
#' and no font of its own. `font` and `font_size` are checked and set
#' nothing.
#'
#' @section Common mistakes:
#' **"`tbl` was not built with the `{N_nonmiss} ||| {stat}` convention."**
#' The table came from a plain [gtsummary::tbl_summary()] call. Build
#' it with [hv_tbl_summary()], which applies the convention
#' automatically, or pass
#' `statistic = list(all_continuous() ~ "{N_nonmiss} ||| {mean} ({sd})")`.
#' Before this check existed, such a table rendered every cell blank.
#'
#' **"`groups` names must be columns in `tbl$table_body`."** Group
#' names are the `stat_<k>` columns `gtsummary` creates, one per level
#' of the `by` variable -- not the group labels. Two groups give
#' `stat_1` and `stat_2`.
#'
#' **"`font_size` must be 11 or 12."** House rule 5. Use `11` only for
#' wide tables.
#'
#' @param tbl A `gtsummary` table object whose `statistic` argument
#'   used `"{N_nonmiss} ||| {<stat>}"` for every group column.
#'   [hv_tbl_summary()] applies this convention for you. A table
#'   without it is rejected, since its cells cannot be split into
#'   their N and statistic parts.
#' @param groups Named character vector, `stat_<k>` column name in
#'   `tbl$table_body` -> spanning header label (include the group's N
#'   in the label text yourself, e.g. `c(stat_1 = "Group A (n=60)")`).
#'   Every name must be a column of `tbl$table_body`, and each may
#'   appear at most once; unknown names are rejected with the available
#'   ones listed, and a repeated name is rejected too.
#' @param trailing Optional named character vector, existing
#'   `tbl$table_body` column name -> header label, one entry per trailing
#'   comparison column, laid out in the order given (e.g.
#'   `c(std_diff = "Std. Diff.")` or `c(p_value = "P")`). Each must
#'   already exist in `tbl$table_body`. A table from [hv_tbl_summary()],
#'   with any columns [hv_tbl_compare()] added, records the right value
#'   as its `hv_trailing` attribute.
#' @param stat_label Sub-header text under each group's statistic column.
#'   Default `NULL` takes it from the table: [hv_tbl_summary()] records the
#'   statistic it used (e.g.
#'   `"No. (%) or Median [15th, 85th percentiles]"`), so the header
#'   cannot disagree with the cells. A
#'   table without that record falls back to `"No. (%) or Mean±SD"`;
#'   pass the right text yourself for any other statistic.
#' @param font Font family. Default `"Times New Roman"` (house rule).
#'   Any single non-empty string is accepted: `flextable` silently
#'   substitutes an unknown font name, so a typo would otherwise pass
#'   unnoticed, while a deliberate override is legitimate.
#' @param font_size Font size in points. Default `12` (house rule 5);
#'   pass `11` for wide tables. No other values are permitted -- the
#'   same rule [hv_man_table()] enforces.
#' @param ... Not used. Present so that `%summarytable` parameter names
#'   produce an error naming the argument to use instead.
#'
#' @return A `flextable` in the manuscript style's describe layout, ready
#'   for [hv_man_table_save()].
#'
#' @seealso [hv_man_table()] for the flat-header CORR house-style mode.
#'   [hv_man_table_save_jtcvs()] to write the result to a compliant `.docx`.
#'
#' @examples
#' # Instead of hv_man_table_jtcvs() and hv_man_table_save_jtcvs():
#' tbl <- hv_tbl_summary(
#'   gtsummary::trial, by = "trt",
#'   groups = list(Demography = c("age", "grade")),
#'   continuous = "age", categorical = "grade", compare = "none"
#' )
#' ft <- hv_man_table(tbl, style = "manuscript", layout = "describe")
#' out <- tempfile(fileext = ".docx")
#' hv_man_table_save(ft, out, caption = "Table 2. Baseline Characteristics")
#'
#' @export
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               stat_label = NULL,
                               font = "Times New Roman", font_size = 12,
                               ...) {
  .Deprecated(msg = .jtcvs_deprecated(
    "hv_man_table_jtcvs",
    paste0("Use hv_man_table(tbl, style = \"manuscript\", ",
           "layout = \"describe\"), which draws the same columns.")
  ))
  .check_sas_args(list(...), "hv_man_table_jtcvs")
  .check_gtsummary(tbl)
  .assert_jtcvs_groups(tbl, groups)
  # The label follows the table it describes. A fixed "Mean±SD" default
  # mislabeled every median table built without an explicit stat_label.
  if (is.null(stat_label))
    stat_label <- attr(tbl, "hv_stat_label", exact = TRUE) %||%
      "No. (%) or Mean\u00B1SD"
  .check_string(stat_label, "stat_label")
  .check_string(font, "font")
  .check_font_size(font_size)
  if (!is.null(trailing)) {
    if (!is.character(trailing) || length(trailing) == 0L ||
          is.null(names(trailing)) || anyNA(names(trailing)) ||
          any(!nzchar(names(trailing))))
      stop("`trailing` must be a named character vector, one entry per ",
           "column (e.g. c(std_diff = \"Std. Diff.\")).", call. = FALSE)
    if (anyDuplicated(names(trailing)))
      stop("`trailing` names a column more than once: ",
           names(trailing)[duplicated(names(trailing))][1], ".",
           call. = FALSE)
    absent <- setdiff(names(trailing), names(tbl$table_body))
    if (length(absent) > 0L)
      stop("`trailing` name `", absent[1], "` is not a column ",
           "in `tbl$table_body`.", call. = FALSE)
  }
  # Runs before .reshape_jtcvs_body(), so a table lacking the
  # convention errors rather than rendering every cell blank.
  .assert_stat_convention(tbl$table_body, groups)
  # Design D3: the same columns, `groups` and `trailing` as given, drawn
  # in the manuscript style's describe layout. `font` and `font_size`
  # are checked as before and set nothing: the manuscript style takes
  # the font of the document it is saved into.
  .man_table_describe(tbl, hv_table_style("manuscript"), groups, trailing,
                      stat_label)
}

# The deprecation every JTCVS function raises (design D3): it names the
# call that replaces it and says when the function goes.
.jtcvs_deprecated <- function(old, instead) {
  paste0(old, "() is deprecated and goes in the next release. ", instead)
}
