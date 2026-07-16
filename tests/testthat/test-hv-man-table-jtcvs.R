library(dplyr)
library(gtsummary)

mk_jtcvs_tbl <- function() {
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10)),
    nyha = factor(sample(c("I", "II", "III"), n, replace = TRUE))
  )
  dta$age[sample(n, 5)] <- NA

  dta |>
    tbl_summary(
      by = group,
      statistic = list(
        all_continuous() ~ "{N_obs} ||| {mean} ± {sd}",
        all_categorical() ~ "{N_obs} ||| {n} ({p}%)"
      ),
      missing = "no"
    ) |>
    modify_table_body(
      mutate,
      groupname_col = case_when(variable == "age" ~ "Demographics", TRUE ~ "Cardiac")
    )
}

test_that(".reshape_jtcvs_body splits N_obs and stat into paired columns", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  age_row <- reshaped[reshaped$label == "age", ]
  expect_identical(age_row$n_stat_1, "27")
  expect_true(grepl("±", age_row$disp_stat_1))
  expect_identical(age_row$n_stat_2, "33")
})

test_that(".reshape_jtcvs_body marks section-header rows and blanks their stats", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  sec <- reshaped[reshaped$is_section, ]
  expect_identical(sec$label, c("Demographics", "Cardiac"))
  expect_true(all(is.na(sec$n_stat_1)))
  expect_true(all(is.na(sec$disp_stat_1)))
})

test_that(".reshape_jtcvs_body leaves categorical parent rows blank, not erroring", {
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(
    mk_jtcvs_tbl(), groups = c(stat_1 = "Group A", stat_2 = "Group B")
  )
  nyha_row <- reshaped[reshaped$label == "nyha", ]
  expect_true(is.na(nyha_row$n_stat_1))
})

test_that(".reshape_jtcvs_body works when groupname_col was never set (no sections)", {
  set.seed(42)
  n <- 60
  dta <- data.frame(
    group = factor(sample(c("A", "B"), n, replace = TRUE)),
    age = round(rnorm(n, 60, 10))
  )
  dta$age[sample(n, 5)] <- NA
  tbl <- dta |> tbl_summary(
    by = group,
    statistic = list(all_continuous() ~ "{N_obs} ||| {mean} ± {sd}"),
    missing = "no"
  )
  expect_false("groupname_col" %in% names(tbl$table_body))
  reshaped <- hvtiRtables:::.reshape_jtcvs_body(tbl, groups = c(stat_1 = "Group A", stat_2 = "Group B"))
  expect_false(any(reshaped$is_section))
  expect_identical(nrow(reshaped), nrow(tbl$table_body))
})
