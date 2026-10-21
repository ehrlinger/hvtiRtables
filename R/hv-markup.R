# Superscripts and subscripts in study-supplied text (design
# dev/specs/2026-10-21-label-markup-design.md). A study writes
# "BSA (m^2^)" or "HbA~1c~" as plain text in a label, a level, a `by`
# level, a note, the abbreviation key or the caption, and the renderer
# raises or lowers the marked piece, as Pandoc and Quarto do.

# A pair is a marker, one or more characters with no whitespace and no
# marker, and the same marker again. Anything else prints as typed:
# "~5 years" has no closing marker, "x ^ y ^ z" has whitespace inside,
# and "a^^b" is an empty pair.
.markup_pattern <- "([\\^~])([^\\s\\^~]+)\\1"

# `txt` split into pieces: a data frame of `text` and `align`
# ("baseline", "superscript" or "subscript"), in order. Text without a
# pair comes back as one baseline piece, unchanged.
.markup_pieces <- function(txt) {
  if (is.na(txt) || !grepl(.markup_pattern, txt, perl = TRUE))
    return(data.frame(text = txt, align = "baseline",
                      stringsAsFactors = FALSE))
  m <- gregexpr(.markup_pattern, txt, perl = TRUE)[[1L]]
  starts <- as.integer(m)
  ends <- starts + attr(m, "match.length") - 1L
  text <- character(0)
  align <- character(0)
  at <- 1L
  for (k in seq_along(starts)) {
    if (starts[k] > at) {
      text <- c(text, substr(txt, at, starts[k] - 1L))
      align <- c(align, "baseline")
    }
    text <- c(text, substr(txt, starts[k] + 1L, ends[k] - 1L))
    raise <- substr(txt, starts[k], starts[k]) == "^"
    align <- c(align, if (raise) "superscript" else "subscript")
    at <- ends[k] + 1L
  }
  if (at <= nchar(txt)) {
    text <- c(text, substr(txt, at, nchar(txt)))
    align <- c(align, "baseline")
  }
  data.frame(text = text, align = align, stringsAsFactors = FALSE)
}

# One cell's flextable chunks, each chunk holding a pair split into one
# chunk per piece. A piece copies its chunk's row, so whatever the chunk
# carried (and the NA it leaves for the cell's own font, size, bold and
# color) comes along; only the text and the raised or lowered alignment
# change. Chunks already raised, such as the minority marks, hold no
# pair and are kept as they are.
.split_chunks <- function(chunks) {
  if (!any(grepl(.markup_pattern, chunks$txt, perl = TRUE))) return(chunks)
  out <- lapply(seq_len(nrow(chunks)), function(k) {
    row <- chunks[k, , drop = FALSE]
    pieces <- .markup_pieces(row$txt)
    if (nrow(pieces) == 1L && pieces$align == "baseline") return(row)
    rows <- row[rep(1L, nrow(pieces)), , drop = FALSE]
    rows$txt <- pieces$text
    moved <- pieces$align != "baseline"
    rows$vertical.align[moved] <- pieces$align[moved]
    rows
  })
  out <- do.call(rbind, out)
  out$.chunk_index <- seq_len(nrow(out))
  rownames(out) <- NULL
  out
}

# Every cell of a flextable's header, body and footer, its markup
# rendered. The last step of each table hv_man_table() builds.
.apply_markup <- function(ft) {
  for (part in c("header", "body", "footer")) {
    data <- ft[[part]]$content$data
    if (length(data) == 0L) next
    for (cell in seq_along(data)) data[[cell]] <- .split_chunks(data[[cell]])
    ft[[part]]$content$data <- data
  }
  ft
}
