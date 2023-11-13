bea_grab <- function(tablename, bea_key) {
  bea_specs <- list(
    'UserID' = bea_key,
    'Method' = 'GetData',
    'datasetname' = 'NIPA',
    'TableName' = tablename,
    'Frequency' = 'A',
    'Year' = 'X'
  )
  beaGet(bea_specs, asWide = FALSE) %>% 
    as_tibble()
}

create_bls_hours <- function(hours_raw_data, final_value) {
  bls_hours <- read_excel(hours_raw_data, skip = 2) %>% 
    filter(
      Basis == "All workers", 
      Component == "Total U.S. economy", 
      Measure == "Hours worked"
    ) %>% 
    select(matches(" Q[1-4]"), -matches("^1947")) %>% 
    pivot_longer(everything()) %>% 
    mutate(year = as.numeric(str_sub(name, 1, 4))) %>% 
    mutate(count = n(), .by = year) %>% 
    filter(count == 4) %>% 
    summarize(hours = mean(value), .by = year)
  
  year_max <- bls_hours %>% 
    filter(year == max(year)) %>% 
    pull(year)
  
  bls_hours %>% 
    add_row(year = year_max + 1, hours = final_value)
}

create_productivity_data <- function(hours_data, bea_key, final_value) {
  bea_nnp <- bea_grab("T10705", bea_key) %>% 
    filter(LineNumber == 14) %>% 
    transmute(year = as.numeric(TimePeriod), nnp = DataValue)
  
  year_max <- bea_nnp %>% 
    filter(year == max(year)) %>% 
    pull(year)
  
  bea_nnp %>%
    add_row(year = year_max + 1, nnp = final_value) %>% 
    inner_join(hours_data, by = "year") %>% 
    mutate(prod = nnp / hours)
}


