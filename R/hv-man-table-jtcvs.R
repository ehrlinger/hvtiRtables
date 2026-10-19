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

#' Build a JTCVS-format manuscript table with merged spanning headers
#'
#' Stage 2 of the `%summarytable` split: shapes the table. The macro
#' controlled this with `STYLE=` and `PAGE=`, which have no equivalent
#' here -- house style is fixed, and the only choice is flat header
#' versus JTCVS spanning header.
#'
#' Use this instead of [hv_man_table()] when you're building the shape
#' editorial actually needs at JTCVS submission: a 2-row header (group name
#' spanning `n`/stat sub-columns, `Characteristic` spanning both rows) and
#' bold, row-spanning section headers in the body, with no fill colour.
#' Each `n` carries a superscript `a`, which [hv_man_table_save_jtcvs()]
#' footnotes as "Patients with data available." This is
#' a separate mode, not a replacement for [hv_man_table()]'s flat-header
#' CORR house style; the two exist because CORR reports and JTCVS
#' submissions want different things from the same header row.
#'
#' On a table that mixes mean and median, the mark on the minority cells is
#' a lettered superscript `b` with its own note, so the test footnotes letter
#' from `c` rather than `b`.
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
#' @return A `flextable` with a 2-row header and merged section rows, ready
#'   for [hv_man_table_save_jtcvs()]. It carries an `hv_header_footnotes`
#'   attribute, the text of the `n` superscript, which that saver writes.
#'
#' @seealso [hv_man_table()] for the flat-header CORR house-style mode.
#'   [hv_man_table_save_jtcvs()] to write the result to a compliant `.docx`.
#'
#' @examples
#' library(gtsummary)
#' tbl <- trial |>
#'   tbl_summary(
#'     by = trt,
#'     statistic = list(
#'       all_continuous() ~ "{N_nonmiss} ||| {mean}±{sd}",
#'       all_categorical() ~ "{N_nonmiss} ||| {n} ({p}%)"
#'     ),
#'     include = c(age, grade),
#'     missing = "no"
#'   )
#' ft <- hv_man_table_jtcvs(
#'   tbl,
#'   groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
#' )
#'
#' @export
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               stat_label = NULL,
                               font = "Times New Roman", font_size = 12,
                               ...) {
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

  reshaped <- .reshape_jtcvs_body(tbl, groups, trailing)

  n_cols <- unlist(lapply(names(groups), function(g) paste0("n_", g)))
  disp_cols <- unlist(lapply(names(groups), function(g) paste0("disp_", g)))
  med_cols <- intersect(paste0("med_", names(groups)), names(reshaped))
  interleaved <- unlist(lapply(names(groups), function(g) {
    intersect(paste0(c("n_", "disp_", "med_"), g), names(reshaped))
  }))
  # No Variable column, whatever hv_tbl_summary(show_variable =) said: a
  # JTCVS table is a manuscript table, and its saver would drop it.
  col_keys <- c("label", interleaved,
                if (!is.null(trailing)) names(trailing))

  ft <- flextable::flextable(reshaped, col_keys = col_keys)

  header_labels <- list(label = "Characteristic")
  for (g in names(groups)) {
    header_labels[[paste0("n_", g)]] <- "n"
    header_labels[[paste0("disp_", g)]] <- stat_label
  }
  for (m in med_cols)
    header_labels[[m]] <- attr(tbl, "hv_median_label", exact = TRUE) %||%
      "Median"
  for (col in names(trailing)) header_labels[[col]] <- trailing[[col]]
  ft <- do.call(flextable::set_header_labels, c(list(x = ft), header_labels))

  top_values <- c("Characteristic", unname(groups))
  top_widths <- c(1L, 2L + (paste0("med_", names(groups)) %in% med_cols))
  top_values <- c(top_values, rep("", length(trailing)))
  top_widths <- c(top_widths, rep(1L, length(trailing)))
  ft <- flextable::add_header_row(
    ft, top = TRUE, values = top_values, colwidths = top_widths
  )
  # One "Characteristic", spanning both header rows, not one per row.
  ft <- flextable::merge_v(ft, j = "label", part = "header")
  # A real superscript: as plain header text the "a" printed as "na".
  # The saver writes the matching footnote. The test footnotes letter from
  # "b", or from "c" when a minority mark has taken "b".
  ft <- flextable::append_chunks(
    ft, i = 2, j = n_cols, part = "header", flextable::as_sup("a")
  )

  sec_i <- which(reshaped$is_section)
  # Each section row spans the table in one cell (design matrix row 1).
  # merge_h() merged only the blank cells beside the label, which left
  # the label in a cell of its own beside one wide empty one.
  for (i in sec_i)
    ft <- flextable::merge_at(ft, i = i, j = col_keys, part = "body")
  ft <- flextable::bold(ft, i = sec_i, part = "body", bold = TRUE)
  ft <- flextable::align(ft, j = "label", align = "left", part = "all")

  level_i <- which(reshaped$row_type == "level")
  if (length(level_i) > 0)
    ft <- flextable::padding(ft, i = level_i, j = "label", padding.left = 20)

  ft <- flextable::font(ft, fontname = font, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")

  # The minority statistic's mark (hv_tbl_summary()'s hv_cell_marks). This
  # renderer letters its notes, so the cells take the next free letter,
  # "b", and the note joins the header notes, which the saver writes.
  # Phase 3 moves this layout onto the standard's section sign and pilcrow.
  header_notes <- list(a = "Patients with data available.")
  marks <- attr(tbl, "hv_cell_marks", exact = TRUE)
  mark_note <- if (!is.null(marks))
    attr(tbl, "hv_footnotes", exact = TRUE)[[marks$symbol]]
  if (!is.null(mark_note)) {
    i <- which(reshaped$row_type == "label" &
                 reshaped$variable %in% marks$variables)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = disp_cols, part = "body",
                                     flextable::as_sup("b"))
      header_notes$b <- mark_note
    }
  }
  attr(ft, "hv_header_footnotes") <- header_notes

  ft <- flextable::width(ft, j = "label", width = 2.5)
  ft <- flextable::width(ft, j = n_cols, width = 0.6)
  ft <- flextable::width(ft, j = disp_cols, width = 0.9)
  if (length(med_cols))
    ft <- flextable::width(ft, j = med_cols, width = 0.9)
  if (!is.null(trailing))
    ft <- flextable::width(ft, j = names(trailing), width = 0.6)

  ft
}
