# hv_man_table_display() puts on a flextable what hv_man_table_save()
# writes around it in Word: the header marks, the footnotes and the
# abbreviation key. The two share their code; these tests hold them to
# the same output.

# A table with every kind of mark: the default * and dagger, and a
# double dagger on the Fisher p-value of a sparse binary.
dp_ft <- function() {
  set.seed(3)
  d <- data.frame(
    grp = rep(c("A", "B"), each = 40),
    age = round(stats::rnorm(80, 60, 10)),
    rare = c(rep(1, 3), rep(0, 37), 1, rep(0, 39))
  )
  hv_man_table(hv_tbl_summary(
    d, by = "grp", groups = list(D = c("age", "rare")),
    continuous = "age", binary = "rare", compare = "pvalue"
  ))
}

dp_abbr <- c(SD = "standard deviation", IQR = "interquartile range")

# Text of each cell in a flextable part's row, chunks joined, by column.
# flextable writes a line break as "<br>" where Word has a newline.
dp_row_text <- function(ft, part, row) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == part & ch$.row_id == row, ]
  vapply(ft$col_keys, function(k) {
    gsub("<br>", "\n", paste(ch$txt[ch$.col_id == k], collapse = ""),
         fixed = TRUE)
  }, "")
}

# Each footer line's text: a footer line spans the table, so read it once.
dp_footer_lines <- function(ft) {
  ch <- flextable::information_data_chunk(ft)
  ch <- ch[ch$.part == "footer" & ch$.col_id == ft$col_keys[1], ]
  vapply(split(ch$txt, ch$.row_id), paste, "", collapse = "")
}

# The saved .docx: the header row's cell texts and the note paragraphs
# after the table.
dp_docx <- function(path) {
  s <- officer::docx_summary(officer::read_docx(path))
  hdr <- s[s$content_type == "table cell" & s$is_header & s$row_id == 1, ]
  hdr <- hdr[order(hdr$cell_id), ]
  tbl_at <- min(s$doc_index[s$content_type == "table cell"])
  notes <- s$text[s$content_type == "paragraph" & s$doc_index > tbl_at &
                    nzchar(s$text)]
  list(header = hdr$text, notes = notes)
}

test_that("display and .docx carry the same marks, notes and key", {
  skip_if_not_installed("broom")
  ft <- dp_ft()
  path <- tempfile(fileext = ".docx")
  hv_man_table_save(ft, path, abbreviations = dp_abbr)
  saved <- dp_docx(path)
  shown <- hv_man_table_display(ft, abbreviations = dp_abbr)
  # The display keeps the report's Variable column; the saved table never
  # has one. Every other header cell matches.
  shown_header <- dp_row_text(shown, "header", 1)
  expect_true("hv_variable" %in% names(shown_header))
  expect_identical(unname(shown_header[names(shown_header) != "hv_variable"]),
                   saved$header)
  # The lines the helper adds, after any footer gtsummary already put on
  # the table (its test note), which the saver keeps in the table too.
  added <- dp_footer_lines(shown)[-seq_len(flextable::nrow_part(ft, "footer"))]
  expect_identical(unname(added), saved$notes)
  # And the content is the expected content, not merely equal.
  expect_true(any(grepl("\\*$", saved$header)))
  expect_true(any(grepl("†$", saved$header)))
  expect_false(any(grepl("‡", saved$header)))
  expect_identical(saved$notes[1], "* Number of non-missing values.")
  expect_identical(saved$notes[3], "‡ Fisher exact test.")
  expect_identical(
    saved$notes[4],
    "Key: IQR, interquartile range; SD, standard deviation"
  )
})

test_that("the double dagger stays on the Fisher cell, off the header", {
  skip_if_not_installed("broom")
  shown <- hv_man_table_display(dp_ft())
  ch <- flextable::information_data_chunk(shown)
  expect_true(any(ch$.part == "body" & ch$txt == "‡"))
  expect_false(any(ch$.part == "header" & ch$txt == "‡"))
})

test_that("footnotes = NULL shows no marks and no notes, only the key", {
  skip_if_not_installed("broom")
  ft <- dp_ft()
  # The double dagger on the Fisher cell needs its note, so NULL is
  # refused here exactly as the saver refuses it.
  expect_error(hv_man_table_display(ft, footnotes = NULL),
               "The table marks cells with", fixed = TRUE)
  plain <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none"
  ))
  shown <- hv_man_table_display(plain, footnotes = NULL,
                                abbreviations = dp_abbr)
  expect_identical(dp_row_text(shown, "header", 1),
                   dp_row_text(plain, "header", 1))
  expect_identical(unname(dp_footer_lines(shown)),
                   "Key: IQR, interquartile range; SD, standard deviation")
})

test_that("nothing to add leaves the table without a footer", {
  plain <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none"
  ))
  shown <- hv_man_table_display(plain, footnotes = NULL)
  expect_identical(flextable::nrow_part(shown, "footer"), 0L)
})

test_that("display refuses what the saver refuses, in the same words", {
  # No p-values needed, so no broom: these checks run on every install.
  ft <- hv_man_table(fx_plain_tbl())
  for (bad in list(list(`#` = "x"), list("unnamed"),
                   list(`*` = NA_character_))) {
    m1 <- tryCatch(hv_man_table_save(ft, tempfile(fileext = ".docx"),
                                     footnotes = bad),
                   error = conditionMessage)
    m2 <- tryCatch(hv_man_table_display(ft, footnotes = bad),
                   error = conditionMessage)
    expect_identical(m1, m2)
  }
  m1 <- tryCatch(hv_man_table_save(ft, tempfile(fileext = ".docx"),
                                   abbreviations = 1),
                 error = conditionMessage)
  m2 <- tryCatch(hv_man_table_display(ft, abbreviations = 1),
                 error = conditionMessage)
  expect_identical(m1, m2)
  m1 <- tryCatch(hv_man_table_save("nope", tempfile(fileext = ".docx")),
                 error = conditionMessage)
  m2 <- tryCatch(hv_man_table_display("nope"), error = conditionMessage)
  expect_identical(m1, m2)
})

test_that("a display copy cannot be saved to Word", {
  skip_if_not_installed("broom")
  shown <- hv_man_table_display(dp_ft(), abbreviations = dp_abbr)
  expect_error(
    hv_man_table_save(shown, tempfile(fileext = ".docx")),
    "`ft` is a display copy from hv_man_table_display()",
    fixed = TRUE
  )
})

test_that("display refuses a JTCVS table, whose notes are lettered", {
  expect_error(hv_man_table_display(fx_jtcvs_ft()),
               "`ft` is a JTCVS table from hv_man_table_jtcvs()",
               fixed = TRUE)
})

test_that("display refuses its own result rather than marking it twice", {
  plain <- hv_man_table(fx_plain_tbl())
  once <- hv_man_table_display(plain, abbreviations = dp_abbr)
  expect_error(hv_man_table_display(once),
               "`ft` is a display copy from hv_man_table_display()",
               fixed = TRUE)
})

test_that("the footer lines take the table's font and size", {
  # No footer of its own, so the new lines cannot copy one's style.
  ft <- hv_man_table(hv_tbl_summary(
    gtsummary::trial, by = "trt", groups = list(D = "age"),
    continuous = "age", compare = "none"
  ), font = "Arial", font_size = 12)
  expect_identical(flextable::nrow_part(ft, "footer"), 0L)
  shown <- hv_man_table_display(ft, abbreviations = dp_abbr)
  sty <- shown$footer$styles$text
  expect_true(all(sty$font.size$data == 12))
  expect_true(all(sty$font.family$data == "Arial"))
})

test_that("a manuscript display writes its notes in the manuscript's words", {
  ft <- hv_man_table_display(hv_man_table(fx_hv_tbl(), style = "manuscript"))
  foot <- flextable::information_data_chunk(ft)
  foot <- foot[foot$.part == "footer", ]
  first <- foot[foot$.row_id == 1, ]
  expect_identical(paste(first$txt, collapse = ""),
                   "*Patients with non-missing data.")
  expect_false(any(first$vertical.align == "superscript"))
})
