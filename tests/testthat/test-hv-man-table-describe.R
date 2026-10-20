ds_tbl <- function(...) {
  hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = c("age", "grade")),
    continuous = "age", categorical = "grade", show_variable = FALSE, ...
  )
}
ds <- function(tbl = ds_tbl(), ...) {
  hv_man_table(tbl, style = "manuscript", layout = "describe", ...)
}
ds_hdr <- function(ft, i) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == "header" & ch$.row_id == i, ]
  vapply(ft$col_keys, function(k) {
    paste(ch$txt[ch$.col_id == k], collapse = "")
  }, character(1))
}

test_that("describe: a count beside each group, Overall and P when carried", {
  ft <- ds()
  expect_identical(
    ft$col_keys,
    c("label", "n_stat_0", "disp_stat_0", "n_stat_1", "disp_stat_1",
      "n_stat_2", "disp_stat_2", "hv_compare_col")
  )
  expect_identical(attr(ft, "hv_layout"), "describe")
  expect_identical(attr(ft, "hv_style"), hv_table_style("manuscript"))
  d <- ft$body$dataset
  age <- which(d$row_type == "label" & d$variable == "age")
  a <- gtsummary::trial$age[gtsummary::trial$trt == "Drug A"]
  expect_identical(d$n_stat_1[age], as.character(sum(!is.na(a))))
  expect_match(d$disp_stat_1[age], "^[0-9.]+ \\[[0-9.]+, [0-9.]+\\]$")
  none <- ds(ds_tbl(overall = FALSE, compare = "none"))
  expect_identical(none$col_keys, c("label", "n_stat_1", "disp_stat_1",
                                    "n_stat_2", "disp_stat_2"))
})

test_that("describe: each group spans its pair; row 2 names them", {
  ft <- ds()
  expect_identical(flextable::nrow_part(ft, "header"), 2L)
  top <- ds_hdr(ft, 1)
  expect_identical(
    unname(top[c("label", "n_stat_0", "n_stat_1", "n_stat_2",
                 "hv_compare_col")]),
    c("Characteristic", "Overall (N = 200)", "Drug A (N = 98)",
      "Drug B (N = 102)", "P")
  )
  stat <- "No. (%) or Median [15th, 85th percentiles]"
  expect_identical(unname(ds_hdr(ft, 2)[-c(1, 8)]),
                   rep(c("n", stat), 3))
  # flextable span matrices are doubles.
  expect_equal(unname(ft$header$spans$rows[1, ]),
               c(1, 2, 0, 2, 0, 2, 0, 1))
  expect_equal(unname(ft$header$spans$columns[, c(1, 8)]),
               matrix(c(2, 0), 2, 2))
})

test_that("describe: the grid, the shaded spanning sections, no font", {
  tbl <- hv_tbl_summary(
    gtsummary::trial, by = "trt",
    groups = list(Demography = "age", Disease = "grade"),
    continuous = "age", categorical = "grade", show_variable = FALSE
  )
  ft <- hv_man_table(tbl, layout = "describe",
                     style = hv_table_style("manuscript", fill = "#A5C9EB"))
  sec <- which(ft$body$dataset$is_section)
  n <- length(ft$col_keys)
  expect_length(sec, 2L)
  for (i in sec) {
    expect_equal(unname(ft$body$spans$rows[i, ]), c(n, rep(0, n - 1L)))
    expect_true(all(ft$body$styles$cells$background.color$data[i, ] ==
                      "#A5C9EB"))
  }
  for (side in c("top", "bottom", "left", "right"))
    expect_true(all(ft$body$styles$cells[[paste0("border.width.", side)]]$data
                    == 0.5), info = side)
  expect_true(all(is.na(ft$body$styles$text$font.family$data)))
  expect_true(all(ft$header$styles$text$bold$data))
  expect_true(all(abs(ft$body$rowheights - 300 / 1440) < 1e-9))
  expect_false(ft$properties$opts_word$split)
})

test_that("describe: the manuscript's widths, so two groups and P fit", {
  ft <- ds(ds_tbl(overall = FALSE))
  w <- ft$body$colwidths
  names(w) <- ft$col_keys
  expect_equal(unname(w[c("label", "n_stat_1", "disp_stat_1",
                          "hv_compare_col")]), c(2.0, 0.6, 1.1, 0.6))
  expect_equal(sum(w), 6.0)
})

test_that("describe: the manuscript's notes and the marks on cells", {
  d <- gtsummary::trial
  d$rare <- factor(ifelse(seq_len(nrow(d)) <= 3, "yes", "no"))
  tbl <- hv_tbl_summary(
    d, by = "trt", groups = list(A = c("age", "marker", "rare")),
    continuous = c("age", "marker"), categorical = "rare",
    mean_sd = "age", show_variable = FALSE
  )
  ft <- ds(tbl)
  notes <- attr(ft, "hv_footnotes")
  expect_identical(names(notes), c("*", "\u2020", "\u2021", "\u00B6"))
  expect_identical(notes[["*"]], "Patients with non-missing data.")
  expect_match(notes[["\u2020"]],
               "^Values are No\\. \\(%\\) or median \\[15th, 85th")
  expect_identical(names(attr(ft, "hv_body_marks")), c("\u2021", "\u00B6"))
  ch <- flextable::information_data_chunk(ft)
  body <- ft$body$dataset
  row_of <- function(v) which(body$row_type == "label" & body$variable == v)
  sup <- ch$.part == "body" & ch$vertical.align == "superscript"
  expect_true(any(sup & ch$.row_id == row_of("rare") &
                    ch$.col_id == "hv_compare_col" & ch$txt == "\u2021"))
  for (k in c("disp_stat_0", "disp_stat_1", "disp_stat_2"))
    expect_true(any(sup & ch$.row_id == row_of("age") & ch$.col_id == k &
                      ch$txt == "\u00B6"), info = k)
  expect_false(any(sup & ch$.col_id %in% c("n_stat_1", "n_stat_2")))
})

test_that("describe: under continuous_stat = 'both' a group spans three", {
  ft <- ds(ds_tbl(continuous_stat = "both", compare = "none",
                  overall = FALSE))
  expect_identical(ft$col_keys, c("label", "n_stat_1", "disp_stat_1",
                                  "med_stat_1", "n_stat_2", "disp_stat_2",
                                  "med_stat_2"))
  expect_equal(unname(ft$header$spans$rows[1, ]), c(1, 3, 0, 0, 3, 0, 0))
  expect_identical(unname(ds_hdr(ft, 2)[c("disp_stat_1", "med_stat_1")]),
                   c("No. (%) or Mean\u00B1SD",
                     "Median [15th, 85th percentiles]"))
})

test_that("describe: a table with no grouping keeps its count", {
  ft <- ds(hv_tbl_summary(gtsummary::trial, groups = list(A = "age"),
                          continuous = "age", show_variable = FALSE))
  expect_identical(ft$col_keys, c("label", "n_stat_0", "disp_stat_0"))
  expect_identical(unname(ds_hdr(ft, 1)[2]), "All patients (N = 200)")
  expect_identical(unname(ds_hdr(ft, 2)[2]), "n")
})

test_that("a layout is the manuscript style's choice, and one of two", {
  expect_error(hv_man_table(ds_tbl(), layout = "describe"),
               "manuscript style's layouts")
  expect_error(
    hv_man_table(ds_tbl(), style = "manuscript", layout = "wide"),
    "\"compare\" or \"describe\""
  )
  # A gtsummary table with the cell convention but not from
  # hv_tbl_summary(): the layout could draw it, and refuses it instead.
  expect_error(
    hv_man_table(fx_jtcvs_tbl(), style = "manuscript", layout = "describe"),
    "overall count for the n column"
  )
  expect_error(ds(font = "Arial"), "document")
  # "compare" is the default, named or not.
  expect_identical(
    attr(hv_man_table(ds_tbl(), style = "manuscript"), "hv_layout"),
    "compare"
  )
  expect_identical(
    hv_man_table(ds_tbl(), style = "manuscript", layout = "compare")$col_keys,
    hv_man_table(ds_tbl(), style = "manuscript")$col_keys
  )
})

# The dagger note names the tests and defines the SMD only when the table
# shows the column those sentences explain.
test_that("the dagger note names the tests only where the column is shown", {
  dagger <- function(ft) attr(ft, "hv_footnotes")[["\u2020"]]
  names_tests <- function(note) {
    grepl("P values", note, fixed = TRUE) ||
      grepl("standardized", note, fixed = TRUE)
  }
  tbl <- ds_tbl(compare = "both")
  bare <- tbl
  attr(bare, "hv_trailing") <- NULL
  groups <- c(stat_1 = "A", stat_2 = "B")

  with_col <- ds(tbl)
  expect_true("hv_compare_col" %in% with_col$col_keys)
  expect_true(names_tests(dagger(with_col)))
  expect_true(grepl("standardized", dagger(with_col), fixed = TRUE))

  without <- ds(bare)
  expect_false("hv_compare_col" %in% without$col_keys)
  expect_false(names_tests(dagger(without)))
  expect_null(attr(without, "hv_test_note"))
  expect_null(attr(without, "hv_smd"))

  # The deprecated wrapper, with and without the trailing column.
  old <- function(...) {
    jtcvs_quiet(hv_man_table_jtcvs(tbl, groups = groups, ...))
  }
  old_with <- old(trailing = attr(tbl, "hv_trailing"))
  old_none <- old()
  expect_true(names_tests(dagger(old_with)))
  expect_false("hv_compare_col" %in% old_none$col_keys)
  expect_false(names_tests(dagger(old_none)))

  # Saved, the note on the page says the same.
  notes <- function(ft) {
    f <- tempfile(fileext = ".docx")
    jtcvs_quiet(hv_man_table_save_jtcvs(ft, f, caption = "T1."))
    paste(vapply(
      xml2::xml_find_all(wx_doc(f), "//w:tbl/following-sibling::w:p", wx_ns),
      wx_text, character(1)
    ), collapse = "\n")
  }
  expect_true(names_tests(notes(old_with)))
  expect_false(names_tests(notes(old_none)))

  # A test note on a column the table does not show is refused, as before.
  expect_error(
    jtcvs_quiet(hv_man_table_save_jtcvs(
      old_none, tempfile(fileext = ".docx"), caption = "T1.",
      footnotes = list(list(row = 1, col = "hv_compare_col", text = "x"))
    )),
    "col_keys|not a column|`footnotes\\[\\[1\\]\\]\\$col`"
  )
})
