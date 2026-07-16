.reshape_jtcvs_body <- function(tbl, groups, trailing = NULL) {
  tb <- tbl$table_body
  has_sections <- "groupname_col" %in% names(tb)

  out <- data.frame(
    label = tb$label,
    is_section = FALSE,
    row_type = tb$row_type,
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
  }

  if (!is.null(trailing)) {
    out[[names(trailing)]] <- tb[[names(trailing)]]
  }

  if (!has_sections) {
    rownames(out) <- NULL
    return(out)
  }

  is_section <- c(TRUE, tb$groupname_col[-1] != tb$groupname_col[-nrow(tb)])

  # Insert one section-header row before each run of same-groupname_col rows
  section_starts <- which(is_section)
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
#' Use this instead of [hv_man_table()] when you're building the shape
#' editorial actually needs at JTCVS submission: a 2-row header (group name
#' spanning `na`/stat sub-columns) and bold-italic, row-spanning section
#' headers in the body, matching the journal's own submission template.
#' This is a separate mode, not a replacement for [hv_man_table()]'s
#' flat-header CORR house style; the two exist because CORR reports and
#' JTCVS submissions want different things from the same header row.
#'
#' @param tbl A `gtsummary` table object whose `statistic` argument used
#'   `"{N_obs} ||| {<stat>}"` for every group column (see `groups`).
#' @param groups Named character vector, `stat_<k>` column name in
#'   `tbl$table_body` -> spanning header label (include the group's N in
#'   the label text yourself, e.g. `c(stat_1 = "Group A (n=60)")`).
#' @param trailing Optional named character vector of length 1, an existing
#'   `tbl$table_body` column name -> header label, for a trailing
#'   comparison column (e.g. `c(std_diff = "Std. Diff.")` or
#'   `c(p_value = "P")`). Must already exist in `tbl$table_body`.
#' @param font Font family. Default `"Times New Roman"` (house rule).
#' @param font_size Font size in points. Default `12`; pass `11` for wide
#'   tables.
#'
#' @return A `flextable` with a 2-row header and merged section rows, ready
#'   for [hv_man_table_save_jtcvs()].
#'
#' @seealso [hv_man_table()] for the flat-header CORR house-style mode.
#'   [hv_man_table_save_jtcvs()] to write the result to a compliant `.docx`.
#'
#' @examples
#' library(gtsummary)
#' tbl <- trial |>
#'   tbl_summary(
#'     by = trt,
#'     statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
#'     include = c(age, grade)
#'   )
#' ft <- hv_man_table_jtcvs(
#'   tbl,
#'   groups = c(stat_1 = "Drug A (n=98)", stat_2 = "Drug B (n=102)")
#' )
#'
#' @export
hv_man_table_jtcvs <- function(tbl, groups, trailing = NULL,
                               font = "Times New Roman", font_size = 12) {
  if (!inherits(tbl, "gtsummary"))
    stop("`tbl` must be a gtsummary table object.", call. = FALSE)
  if (is.null(names(groups)) || any(!nzchar(names(groups))))
    stop("`groups` must be a named character vector.", call. = FALSE)

  reshaped <- .reshape_jtcvs_body(tbl, groups, trailing)

  n_cols <- unlist(lapply(names(groups), function(g) paste0("n_", g)))
  disp_cols <- unlist(lapply(names(groups), function(g) paste0("disp_", g)))
  interleaved <- as.vector(rbind(n_cols, disp_cols))
  col_keys <- c("label", interleaved, if (!is.null(trailing)) names(trailing))

  ft <- flextable::flextable(reshaped, col_keys = col_keys)

  header_labels <- list(label = "Characteristic")
  for (g in names(groups)) {
    header_labels[[paste0("n_", g)]] <- "na"
    header_labels[[paste0("disp_", g)]] <- "No. (%) or Mean \u00B1 SD"
  }
  if (!is.null(trailing)) header_labels[[names(trailing)]] <- unname(trailing)
  ft <- do.call(flextable::set_header_labels, c(list(x = ft), header_labels))

  top_values <- c("Characteristic", unname(groups))
  top_widths <- c(1L, rep(2L, length(groups)))
  if (!is.null(trailing)) {
    top_values <- c(top_values, "")
    top_widths <- c(top_widths, 1L)
  }
  ft <- flextable::add_header_row(
    ft, top = TRUE, values = top_values, colwidths = top_widths
  )

  sec_i <- which(reshaped$is_section)
  ft <- flextable::merge_h(ft, i = sec_i, part = "body")
  ft <- flextable::bold(ft, i = sec_i, part = "body", bold = TRUE)
  ft <- flextable::italic(ft, i = sec_i, part = "body", italic = TRUE)

  level_i <- which(reshaped$row_type == "level")
  if (length(level_i) > 0)
    ft <- flextable::padding(ft, i = level_i, j = "label", padding.left = 20)

  ft <- flextable::font(ft, fontname = font, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")

  ft
}
