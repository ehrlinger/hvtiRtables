# Shared argument validators (.check_*) and precondition assertions
# (.assert_*). Layer 1 validates one argument's own shape; layer 2
# validates relationships between arguments, or between an argument and
# the data it references.
#
# All error via stop(call. = FALSE) and return their input invisibly.
# None has a predicate (is_valid_*) form: every use in this package is
# fail-fast at function entry, and offering both forms would be the
# first place the two could drift apart.
#
# There is deliberately no .check_font(): its contract is identical to
# .check_string(), so `font` is validated by .check_string(font, "font").
# A wrapper would add a name without adding a rule.

# The "Received:" clause. Reports class and length rather than the
# value, which keeps the message short for a data frame or a connection,
# and is the most diagnostic thing for the commonest real mistake -- an
# argument-order slip, where the class mismatch is the tell.
.describe <- function(x) {
  if (is.null(x)) return("NULL")
  if (length(x) != 1L)
    return(sprintf("a vector of length %d", length(x)))
  if (is.atomic(x) && is.na(x)) return("NA")
  sprintf("%s of length 1", class(x)[1])
}

.check_gtsummary <- function(x, arg = "tbl") {
  if (!inherits(x, "gtsummary"))
    stop("`", arg, "` must be a gtsummary table object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_flextable <- function(x, arg = "ft") {
  if (!inherits(x, "flextable"))
    stop("`", arg, "` must be a flextable object. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty string. Received: ",
         .describe(x), ".", call. = FALSE)
  invisible(x)
}

.check_font_size <- function(x, arg = "font_size") {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
        !(x %in% c(11, 12)))
    stop("`", arg, "` must be 11 or 12 (house rule: 12pt, 11pt ",
         "permitted for wide tables). Received: ", .describe(x), ".",
         call. = FALSE)
  invisible(x)
}

# Folds the string check and the directory check together because both
# savers already perform exactly those two steps in sequence; splitting
# them would leave two things to remember instead of one.
.check_file <- function(x, arg = "file") {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty file path. Received: ",
         .describe(x), ".", call. = FALSE)
  out_dir <- dirname(x)
  if (!dir.exists(out_dir))
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  invisible(x)
}

.check_abbreviations <- function(x, arg = "abbreviations") {
  if (is.null(x) || length(x) == 0L) return(invisible(x))
  if (!is.character(x))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)). Received: ", .describe(x),
         ".", call. = FALSE)
  nms <- names(x)
  if (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))
    stop("`", arg, "` must be a named character vector ",
         "(c(ABBR = \"expansion\", ...)); every element must have a ",
         "non-empty name.", call. = FALSE)
  invisible(x)
}
