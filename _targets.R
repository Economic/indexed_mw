## Load your packages, e.g. library(targets).
source("packages.R")

## Globals
data_version <- "November 9, 2023"
bea_key <- Sys.getenv("BEA_API_KEY")

# actual final data year
final_actual_data_year <- 2023
# average of 2023q2 and 2023q3 values - 9 November 2023
final_year_bls_hours <- 294.127
# 2023q2 value - 9 November 2023
final_year_bea_output <- 22679082	

## Functions
lapply(list.files("R", full.names = TRUE), source)
  
tar_plan(
  tar_file(bls_hours_raw, "total-economy-hours-employment.xlsx"),
  
  tar_file(ipums_asec_raw, "cps_00104.dta.gz"),
  
  bls_hours_data = create_bls_hours(bls_hours_raw, final_year_bls_hours),
  
  productivity_data = create_productivity_data(
    bls_hours_data, 
    bea_key, 
    final_year_bea_output
  ),
  
  median_data = create_median_wage(ipums_asec_raw),
  
  fed_mw_data = create_fed_mw_data(us_minimum_wage_annual),
  
  cpi_data = create_cpi_data(c_cpi_u_extended_annual, c_cpi_u_extended_monthly_nsa),
  
  prod_indexed_mw = create_indexed_mw_data(
    mw_data = fed_mw_data,
    index_source = productivity_data, 
    index_level_var = "prod",
    index_type_name = "productivity",
    base_year = c(1968, 2009)
  ),
  
  cpi_indexed_mw = create_indexed_mw_data(
    mw_data = fed_mw_data,
    index_source = cpi_data, 
    index_level_var = "cpi",
    index_type_name = "inflation",
    base_year = c(1968, 2009)
  ),
  
  median_indexed_mw = create_indexed_mw_data(
    mw_data = fed_mw_data,
    index_source = median_data,
    index_level_var = "median_wage",
    index_type_name = "median_wage",
    base_year = c(1968, 2009)
  ),
  
  indexed_mw_data = combine_indexed_data(
    list(prod_indexed_mw, cpi_indexed_mw, median_indexed_mw, fed_mw_data),
    cpi_data,
    data_version 
  ),
  
  tar_file(indexed_mw_data_csv, target_to_csv(indexed_mw_data))
  
)


