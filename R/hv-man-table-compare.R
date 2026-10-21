# The "manuscript" style's "compare" layout (design section 5): a full
# grid; a two-row header with "Characteristic" and "n" merged down and
# the grouping's name spanning its levels; one overall n column; shaded
# section rows spanning the table; no font of its own. Built from the
# body the JTCVS renderer reshapes, as the "describe" layout is, so the
# two layouts share their cells and differ in their counts.
.man_table_compare <- function(tbl, style) {
  .check_manuscript_tbl(tbl)
  tb <- tbl$table_body
  if (any(grepl("^hv_median_stat_[0-9]+$", names(tb))))
    stop("The compare layout shows one statistic per group, and ",
         "continuous_stat = \"both\" shows two. Build the table with ",
         "continuous_stat = \"median\" or \"mean\"; layout = ",
         "\"describe\" or the report style draws \"both\".",
         call. = FALSE)

  by_label <- attr(tbl, "hv_by_label", exact = TRUE)
  groups <- .group_labels(tbl)
  stat_cols <- names(groups)
  .assert_stat_convention(tb, groups, caller = "hv_man_table")

  compare <- attr(tbl, "hv_trailing", exact = TRUE)
  body <- .reshape_jtcvs_body(tbl, groups, c(hv_n = "n", compare))
  disp <- paste0("disp_", stat_cols)
  keys <- c("label", "hv_n", disp, names(compare))

  ft <- flextable::flextable(body, col_keys = keys)
  ft <- do.call(flextable::set_header_labels, c(
    list(x = ft, label = "Characteristic", hv_n = "n"),
    as.list(stats::setNames(unname(groups), disp)), as.list(compare)
  ))
  if (!is.null(by_label)) {
    overall <- "stat_0" %in% stat_cols
    top <- c("Characteristic", "n", if (overall) groups[["stat_0"]],
             by_label, unname(compare))
    widths <- c(1L, 1L, if (overall) 1L, sum(stat_cols != "stat_0"),
                rep(1L, length(compare)))
    ft <- flextable::add_header_row(ft, top = TRUE, values = top,
                                    colwidths = widths)
    down <- c("label", "hv_n", if (overall) "disp_stat_0", names(compare))
    ft <- flextable::merge_v(ft, j = down, part = "header")
  }

  ft <- .dress_manuscript(ft, body, keys, style)
  ft <- flextable::width(ft, j = "label", width = 2.0)
  ft <- flextable::width(ft, j = c("hv_n", names(compare)), width = 0.6)
  ft <- flextable::width(ft, j = disp, width = 1.1)

  ft <- .mark_compare(ft, tbl, body, disp, style)
  attr(ft, "hv_layout") <- "compare"
  .apply_markup(ft)
}

# A manuscript table is drawn from the overall count and the grouping's
# name hv_tbl_summary() records.
.check_manuscript_tbl <- function(tbl) {
  if (!"hv_n" %in% names(tbl$table_body))
    stop("style = \"manuscript\" needs a table from hv_tbl_summary(), ",
         "which carries each variable's overall count for the n column.",
         call. = FALSE)
  invisible(NULL)
}

# Each statistic column's header, "<level> (N = n)", or "All patients
# (N = n)" for a table with no grouping.
.group_labels <- function(tbl) {
  stat_cols <- grep("^stat_[0-9]+$", names(tbl$table_body), value = TRUE)
  hdr <- tbl$table_styling$header
  hdr <- hdr[match(stat_cols, hdr$column), , drop = FALSE]
  by_label <- attr(tbl, "hv_by_label", exact = TRUE)
  level <- if (is.null(by_label)) "All patients" else hdr$modify_stat_level
  stats::setNames(sprintf("%s (N = %s)", level, hdr$modify_stat_n),
                  stat_cols)
}

# What both manuscript layouts share (design section 5.1): section rows
# spanning the table, bold and shaded; a full grid; the header bold; no
# font of its own; 300-twip rows kept whole; the header repeated.
.dress_manuscript <- function(ft, body, keys, style) {
  sec_i <- which(body$is_section)
  for (i in sec_i)
    ft <- flextable::merge_at(ft, i = i, j = keys, part = "body")
  level_i <- which(body$row_type == "level")
  if (length(level_i) > 0L)
    ft <- flextable::padding(ft, i = level_i, j = "label",
                             padding.left = 20)

  ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::align(ft, j = "label", align = "left", part = "all")
  ft <- flextable::bold(ft, bold = style$header_bold, part = "header")
  line <- officer::fp_border(color = "black", width = 0.5)
  ft <- flextable::border_remove(ft)
  ft <- flextable::border_outer(ft, border = line, part = "all")
  ft <- flextable::border_inner(ft, border = line, part = "all")
  # border_outer() over "all" leaves the body's own top edge at 0 (the
  # header's foot draws the line), so the first row's top is set here and
  # Word has no unset border to arbitrate against the header's.
  ft <- flextable::border(ft, i = 1, border.top = line, part = "body")
  if (length(sec_i) > 0L) {
    ft <- flextable::bold(ft, i = sec_i, part = "body", bold = TRUE)
    ft <- flextable::bg(ft, i = sec_i, bg = style$fill, part = "body")
  }
  # NA leaves the run's font and size unset in the .docx, so the table
  # takes the document's body font (design question 5).
  ft <- flextable::font(ft, fontname = style$font, part = "all")
  ft <- flextable::fontsize(ft, size = style$font_size, part = "all")
  ft <- flextable::valign(ft, valign = "center", part = "all")
  ft <- flextable::height_all(ft, height = style$row_height / 1440,
                              part = "all")
  ft <- flextable::hrule(ft, rule = "atleast", part = "all")
  flextable::set_table_properties(ft, opts_word = list(
    split = !style$keep_rows, repeat_headers = style$repeat_header
  ))
}

# The notes in the manuscript's words, and the marks on cells: Fisher's
# double dagger on its P, and the minority statistic's section sign or
# pilcrow on every statistic cell of its rows (Phase 1's rule).
.mark_compare <- function(ft, tbl, body, disp, style,
                          stat_label = attr(tbl, "hv_stat_label",
                                            exact = TRUE)) {
  tb <- tbl$table_body
  notes <- attr(tbl, "hv_footnotes", exact = TRUE)
  notes[["*"]] <- style$count_note
  # The test names and the SMD definition explain the comparison column,
  # so they are in the note only when the table shows it.
  shown <- "hv_compare_col" %in% ft$col_keys
  tests <- if (shown) attr(tbl, "hv_test_note", exact = TRUE)
  smd <- if (shown) attr(tbl, "hv_smd", exact = TRUE)
  notes[["\u2020"]] <- .stat_note(stat_label, style)
  notes[["\u2020"]] <- .append_note(notes[["\u2020"]], tests)
  # Under "both" the cells read "(SMD 0.1)"; under "smd" the header says
  # "Std. Diff.".
  if (!is.null(smd))
    notes[["\u2020"]] <- .append_note(
      notes[["\u2020"]],
      .smd_sentence(if (identical(smd, "both")) "SMD" else "Std. Diff.",
                    ci = FALSE)
    )
  rows <- function(vars) {
    which(body$row_type == "label" & body$variable %in% vars)
  }
  marks <- character(0)
  ddag <- "\u2021"
  if (!is.null(notes[[ddag]])) {
    # A Fisher test that failed (FEXACT can run out of workspace) keeps
    # its test name and returns no P; a mark there would sit alone in an
    # empty cell, so only a P that exists is marked, as .mark_fisher()
    # does for the report.
    ok <- shown && all(c("test_name", "p.value") %in% names(tb))
    fisher <- if (ok) {
      tb$variable[!is.na(tb$test_name) & tb$test_name == "fisher.test" &
                    !is.na(tb$p.value)]
    }
    i <- rows(fisher)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = "hv_compare_col",
                                     part = "body", flextable::as_sup(ddag))
      marks[[ddag]] <- notes[[ddag]]
    } else {
      # No cell carries the mark, so the note would have nothing to
      # explain, and the saver would put it on the header, where it
      # would claim every P.
      notes[[ddag]] <- NULL
    }
  }
  cm <- attr(tbl, "hv_cell_marks", exact = TRUE)
  if (!is.null(cm) && !is.null(notes[[cm$symbol]])) {
    i <- rows(cm$variables)
    if (length(i) > 0L) {
      ft <- flextable::append_chunks(ft, i = i, j = disp, part = "body",
                                     flextable::as_sup(cm$symbol))
      marks[[cm$symbol]] <- notes[[cm$symbol]]
    }
  }
  attr(ft, "hv_footnotes") <- .order_notes(notes)
  attr(ft, "hv_body_marks") <- if (length(marks) > 0L) marks
  attr(ft, "hv_style") <- style
  attr(ft, "hv_test_note") <- tests
  attr(ft, "hv_smd") <- smd
  ft
}
