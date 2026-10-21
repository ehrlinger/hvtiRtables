cmp_tbl <- function(...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", ...
  )
}
cmp <- function(tbl = cmp_tbl()) hv_man_table(tbl, style = "manuscript")
hdr_text <- function(ft, i) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == "header" & ch$.row_id == i, ]
  vapply(ft$col_keys, function(k) {
    paste(ch$txt[ch$.col_id == k], collapse = "")
  }, character(1))
}

test_that("compare: one overall n column, the statistic without its count", {
  tbl <- cmp_tbl()
  ft <- cmp(tbl)
  expect_identical(
    ft$col_keys,
    c("label", "hv_n", "disp_stat_0", "disp_stat_1", "disp_stat_2",
      "hv_compare_col")
  )
  d <- ft$body$dataset
  age <- which(d$row_type == "label" & d$variable == "age")
  expect_identical(d$hv_n[age],
                   tbl$table_body$hv_n[tbl$table_body$variable == "age" &
                                         tbl$table_body$row_type == "label"])
  expect_match(d$disp_stat_1[age], "^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
  expect_false(any(grepl("|||", unlist(d[grep("^disp_", names(d))]),
                         fixed = TRUE)))
})

test_that("compare: a two-row header, the grouping spanning its levels", {
  ft <- cmp()
  expect_identical(flextable::nrow_part(ft, "header"), 2L)
  top <- hdr_text(ft, 1)
  bottom <- hdr_text(ft, 2)
  expect_identical(unname(top[c("label", "hv_n", "disp_stat_0",
                                "disp_stat_1", "hv_compare_col")]),
                   c("Characteristic", "n", "Overall (N = 200)",
                     "Chemotherapy Treatment", "P"))
  expect_identical(unname(bottom[c("disp_stat_1", "disp_stat_2")]),
                   c("Drug A (N = 98)", "Drug B (N = 102)"))
  spans <- ft$header$spans$rows
  expect_equal(unname(spans[1, ]), c(1, 1, 1, 2, 0, 1))
  # Characteristic, n, Overall and P each merged down the two rows.
  down <- ft$header$spans$columns
  expect_equal(unname(down[, c(1, 2, 3, 6)]), matrix(c(2, 0), 2, 4))
})

test_that("compare: section rows span the table and are shaded", {
  s <- hv_table_style("manuscript", fill = "#A5C9EB")
  ft <- hv_man_table(cmp_tbl(), style = s)
  sec <- which(ft$body$dataset$is_section)
  expect_length(sec, 1L)
  expect_equal(unname(ft$body$spans$rows[sec, ]),
               c(length(ft$col_keys), rep(0, length(ft$col_keys) - 1L)))
  expect_true(all(ft$body$styles$cells$background.color$data[sec, ] ==
                    s$fill))
})

test_that("compare: a full grid, no font set, rows at the style height", {
  ft <- cmp()
  for (side in c("top", "bottom", "left", "right"))
    expect_true(all(ft$body$styles$cells[[paste0("border.width.", side)]]$data
                    == 0.5), info = side)
  expect_true(all(is.na(ft$body$styles$text$font.family$data)))
  expect_true(all(is.na(ft$body$styles$text$font.size$data)))
  expect_true(all(ft$body$styles$text$bold$data[!ft$body$dataset$is_section, ]
                  == FALSE))
  expect_true(all(ft$header$styles$text$bold$data == TRUE))
  h <- hv_table_style("manuscript")$row_height
  expect_true(all(abs(ft$body$rowheights - h / 1440) < 1e-9))
  expect_false(ft$properties$opts_word$split)
  expect_true(ft$properties$opts_word$repeat_headers)
})

test_that("compare: manuscript notes, and the marks the cells carry", {
  d <- gtsummary::trial
  d$rare <- factor(ifelse(seq_len(nrow(d)) <= 3, "yes", "no"))
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "marker", "rare")),
    continuous = c("age", "marker"), categorical = "rare",
    mean_sd = "age", show_variable = FALSE
  )
  ft <- cmp(tbl)
  notes <- attr(ft, "hv_footnotes")
  expect_identical(names(notes), c("*", "†", "‡", "¶"))
  ms <- hv_table_style("manuscript")
  expect_identical(notes[["*"]], ms$count_note)
  expect_identical(notes[["†"]],
                   paste0(ms$stat_lead, "No. (%) or median [15th, 85th ",
                          "percentiles]; P values from the Wilcoxon rank ",
                          "sum test."))
  expect_identical(names(attr(ft, "hv_body_marks")), c("‡", "¶"))
  ch <- flextable::information_data_chunk(ft)
  body <- ft$body$dataset
  row_of <- function(v) which(body$row_type == "label" & body$variable == v)
  sup <- ch$.part == "body" & ch$vertical.align == "superscript"
  expect_true(any(sup & ch$.row_id == row_of("rare") &
                    ch$.col_id == "hv_compare_col" & ch$txt == "‡"))
  for (k in c("disp_stat_0", "disp_stat_1", "disp_stat_2"))
    expect_true(any(sup & ch$.row_id == row_of("age") & ch$.col_id == k &
                      ch$txt == "¶"), info = k)
  expect_false(any(sup & ch$.row_id == row_of("marker")))
})

test_that("compare: a Fisher test that returned no P leaves no mark", {
  d <- gtsummary::trial
  d$rare <- factor(ifelse(seq_len(nrow(d)) <= 3, "yes", "no"))
  tbl <- hv_tbl_summary(d, by = "trt", groups = list(A = c("age", "rare")),
                        continuous = "age", categorical = "rare",
                        show_variable = FALSE)
  expect_true("fisher.test" %in% tbl$table_body$test_name)
  # A real FEXACT failure also raises a warning, which the suite must not;
  # the state it leaves, test named and P missing, is set directly.
  tbl <- gtsummary::modify_table_body(tbl, function(tb) {
    tb$p.value[tb$variable == "rare"] <- NA_real_
    tb$hv_compare_col[tb$variable == "rare"] <- NA_character_
    tb
  })
  ft <- cmp(tbl)
  expect_false(any(flextable::information_data_chunk(ft)$txt == "‡"))
  expect_null(attr(ft, "hv_body_marks"))
  expect_false("‡" %in% names(attr(ft, "hv_footnotes")))
})

test_that("compare: an ungrouped table keeps its count column", {
  tbl <- hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                        continuous = "age", show_variable = FALSE)
  ft <- cmp(tbl)
  expect_identical(flextable::nrow_part(ft, "header"), 1L)
  expect_identical(unname(hdr_text(ft, 1)),
                   c("Characteristic", "n", "All patients (N = 200)"))
})

test_that("compare refuses what it cannot draw", {
  expect_error(
    hv_man_table(gtsummary::tbl_summary(gtsummary::trial, include = age),
                 style = "manuscript"),
    "hv_tbl_summary"
  )
  expect_error(cmp(cmp_tbl(continuous_stat = "both")),
               "one statistic.*layout = \"describe\" or the report style")
  expect_error(hv_man_table(cmp_tbl(), font = "Arial", style = "manuscript"),
               "document")
})

test_that("the statistic note in each style's words", {
  m <- hv_table_style("manuscript")
  r <- hv_table_style("report")
  expect_identical(.stat_note("No. (%) or Mean±SD", m),
                   "Values are No. (%) or mean±SD.")
  expect_identical(.stat_note("No. (%) or Mean±SD", r),
                   "No. (%) or Mean±SD.")
})

test_that("compare: the flextable records its layout", {
  expect_identical(attr(cmp(), "hv_layout"), "compare")
})
