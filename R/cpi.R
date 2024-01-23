create_cpi_data <- function(annual_data, monthly_data, data_version) {
  # final_year_cpi <- monthly_data %>% 
  #   filter(year == 2023 & month == 7) %>% 
  #   pull(3)
  # 
  # annual_data %>% 
  #   rename(cpi = 2) %>% 
  #   add_row(year = 2023, cpi = final_year_cpi)
  annual_data %>% 
    rename(cpi = 2)
}