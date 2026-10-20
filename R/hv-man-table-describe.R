# The "manuscript" style's "describe" layout (design section 5.1), for a
# table that describes cohorts or repeated measures side by side: each
# group spans its own (n, statistic) pair, and row 2 names them. An
# Overall column and comparison columns appear when the table carries
# them. Everything else is "compare"'s: the grid, the shaded section
# rows, the notes, the font and the page.
#
# `groups` maps each statistic column to its header, `trailing` each
# comparison column to its header (NULL for none), and `stat_label`
# names the statistic in row 2. hv_man_table() passes the table's own;
# the deprecated hv_man_table_jtcvs() passes its caller's, unchanged.
.man_table_describe <- function(tbl, style, groups, trailing, stat_label) {
  stat_label <- stat_label %||% "No. (%) or Mean\u00B1SD"
  .assert_stat_convention(tbl$table_body, groups, caller = "hv_man_table")
  body <- .reshape_jtcvs_body(tbl, groups, trailing)
  g <- names(groups)
  n_cols <- paste0("n_", g)
  disp <- paste0("disp_", g)
  med <- intersect(paste0("med_", g), names(body))
  pair <- lapply(g, function(k) {
    intersect(paste0(c("n_", "disp_", "med_"), k), names(body))
  })
  keys <- c("label", unlist(pair), names(trailing))

  ft <- flextable::flextable(body, col_keys = keys)
  sub <- c(
    list(label = "Characteristic"),
    stats::setNames(as.list(rep("n", length(g))), n_cols),
    stats::setNames(as.list(rep(stat_label, length(g))), disp),
    stats::setNames(as.list(rep(
      attr(tbl, "hv_median_label", exact = TRUE) %||% "Median",
      length(med)
    )), med),
    as.list(trailing)
  )
  ft <- do.call(flextable::set_header_labels, c(list(x = ft), sub))
  ft <- flextable::add_header_row(
    ft, top = TRUE,
    values = c("Characteristic", unname(groups), unname(trailing)),
    colwidths = c(1L, lengths(pair), rep(1L, length(trailing)))
  )
  ft <- flextable::merge_v(ft, j = c("label", names(trailing)),
                           part = "header")

  ft <- .dress_manuscript(ft, body, keys, style)
  ft <- flextable::width(ft, j = "label", width = 2.0)
  ft <- flextable::width(ft, j = c(n_cols, names(trailing)), width = 0.6)
  ft <- flextable::width(ft, j = c(disp, med), width = 1.1)

  ft <- .mark_compare(ft, tbl, body, disp, style, stat_label)
  attr(ft, "hv_layout") <- "describe"
  # The saver and the display mark these columns, named for the groups
  # the table was built with, whatever those columns are called.
  attr(ft, "hv_pairs") <- list(n = n_cols, stat = disp)
  ft
}
