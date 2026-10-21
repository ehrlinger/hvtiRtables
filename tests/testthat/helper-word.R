# Readers for a saved .docx: the Word XML, as the reader sees it in Word.

wx_ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")

wx_doc <- function(path) {
  xdir <- tempfile()
  on.exit(unlink(xdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = xdir)
  xml2::read_xml(file.path(xdir, "word", "document.xml"))
}

wx_text <- function(node) {
  paste(xml2::xml_text(xml2::xml_find_all(node, ".//w:t", wx_ns)),
        collapse = "")
}

# One list per table row, one element per cell: its text, its
# superscript text, its paragraph justification and its fill.
wx_rows <- function(doc) {
  trs <- xml2::xml_find_all(doc, "//w:tbl//w:tr", wx_ns)
  lapply(trs, function(tr) {
    lapply(xml2::xml_find_all(tr, "./w:tc", wx_ns), function(tc) {
      sup <- xml2::xml_find_all(
        tc, ".//w:r[w:rPr/w:vertAlign[@w:val='superscript']]/w:t", wx_ns
      )
      jc <- xml2::xml_attr(xml2::xml_find_first(tc, ".//w:jc", wx_ns), "val")
      fill <- xml2::xml_attr(xml2::xml_find_first(tc, ".//w:shd", wx_ns),
                             "fill")
      list(text = wx_text(tc), sup = paste(xml2::xml_text(sup), collapse = ""),
           jc = jc, fill = fill)
    })
  })
}

# The runs of the first Word paragraph whose text contains `has`, each as
# list(text, align, bold, italic). A w:b or w:i written off
# (w:val="0" or "false") is not bold or italic.
wx_runs <- function(path, has) {
  doc <- wx_doc(path)
  p <- xml2::xml_find_first(
    doc, sprintf("//w:p[contains(string(.), '%s')]", has), wx_ns
  )
  on <- function(r, tag) {
    node <- xml2::xml_find_first(r, sprintf(".//w:rPr/w:%s", tag), wx_ns)
    !inherits(node, "xml_missing") &&
      !xml2::xml_attr(node, "val") %in% c("0", "false")
  }
  lapply(xml2::xml_find_all(p, ".//w:r", wx_ns), function(r) {
    va <- xml2::xml_find_first(r, ".//w:vertAlign", wx_ns)
    list(text = xml2::xml_text(r),
         align = if (inherits(va, "xml_missing")) "baseline" else
           xml2::xml_attr(va, "val"),
         bold = on(r, "b"), italic = on(r, "i"))
  })
}
