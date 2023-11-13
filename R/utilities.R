target_to_csv <- function(x) {
  file_name <- paste0(rlang::enexpr(x), ".csv")
  write_csv(x, file_name)
  file_name
}