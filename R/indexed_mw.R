
create_fed_mw_data <- function(fed_mw_data) {
  fed_mw_data %>% 
    rename(value = minimum_wage) %>% 
    mutate(series_type = "actual")
}


create_indexed_mw_data_year <- function(
    mw_data,
    index_source, 
    index_level_var, 
    base_year) {
  
  fed_mw_base <- mw_data %>% 
    filter(year == base_year) %>% 
    pull(value)
  
  index_data <- index_source %>% 
    select(year, index = all_of(index_level_var))
  
  index_base <- index_data %>% 
    filter(year == base_year) %>% 
    pull(index)

  index_data %>%
    arrange(year) %>% 
    mutate(index = index / index_base) %>% 
    mutate(value = fed_mw_base * index) %>% 
    filter(year >= base_year)
}

create_indexed_mw_data <- function(
    mw_data,
    index_source, 
    index_level_var, 
    index_type_name, 
    base_year) {
  
  names(base_year) <- base_year
  
  base_year %>% 
    map(
      ~ create_indexed_mw_data_year(
        mw_data,
        index_source,
        index_level_var,
        base_year = .x
      )
    ) %>% 
    list_rbind(names_to = "base_year") %>% 
    mutate(base_year = as.numeric(base_year)) %>% 
    select(year, base_year, value) %>% 
    mutate(
      index_type = index_type_name,
      series_type = "indexed"
    )
}

combine_indexed_data <- function(indexed_data_list, cpi_data, meta_data) {
  cpi_base <- cpi_data %>% 
    filter(year == final_actual_data_year) %>% 
    pull(cpi)
  
  nominal_data <- list_rbind(indexed_data_list) %>% 
    mutate(series_deflated = "nominal")
  
  nominal_data %>% 
    inner_join(cpi_data, by = "year") %>% 
    mutate(value = value * cpi_base / cpi) %>% 
    select(year, base_year, value, index_type, series_type) %>% 
    mutate(series_deflated = "real") %>% 
    bind_rows(nominal_data) %>% 
    mutate(
      value = round(value, digits = 2),
      data_version = meta_data
    ) 
}