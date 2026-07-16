.reshape_jtcvs_body <- function(tbl, groups) {
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
    out[[paste0("n_", col)]] <- vapply(parts, function(p) if (length(p) == 2) p[1] else NA_character_, character(1))
    out[[paste0("disp_", col)]] <- vapply(parts, function(p) if (length(p) == 2) p[2] else NA_character_, character(1))
  }

  if (!has_sections) {
    rownames(out) <- NULL
    return(out)
  }

  # a row is a "new section" if this is the first row, or groupname_col
  # changed since the previous row
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
      result <- rbind(result, out[(prev + 1L):(insert_before[k] - 1L), , drop = FALSE])
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
