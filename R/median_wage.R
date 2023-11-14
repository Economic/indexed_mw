median_by_year <- function(data, var, w) {
  data %>%
    filter(!is.na(.data[[var]])) %>%
    summarize(
      value = MetricsWeighted::weighted_median(.data[[var]], w = .data[[w]]),
      .by = year
    ) %>%
    mutate(wage_var = var)
}

create_median_wage <- function(ipums_asec_dta_gz) {
  asec_raw <- read_dta(ipums_asec_dta_gz)
  
  org_raw <- load_org(
    1979:2023, 
    year, orgwgt, wage, wageotc, wage_noadj, wageotc_noadj
  )
  
  org_wage_vars <- org_raw %>% 
    colnames() %>%
    str_subset("^wage") 
  
  median_wages_org <- org_wage_vars %>% 
    map(~ median_by_year(org_raw, .x, w = "orgwgt")) %>% 
    list_rbind()
  
  # average hours for full/part time workers using basic data available from asec
  asec_hours_ftpt <- asec_raw %>%
    filter(
      age >= 16,
      classwkr %in% c(21, 24, 25, 27, 28),
      ahrsworkt > 0 & ahrsworkt < 999,
      asecwt > 0
    ) %>%
    mutate(full_time = case_when(
      ahrsworkt < 35 ~ 0,
      ahrsworkt >= 35 ~ 1
    )) %>%
    summarize(
      hours_actual_avg = weighted.mean(ahrsworkt, w = asecwt), 
      .by = c(year, full_time)
    )
  
  asec_clean <- asec_raw %>%
    # employee defined as last year class: wage/salary private, wage/salary gov
    mutate(employee = ifelse(classwly %in% c(22, 25, 27, 28), 1, 0)) %>%
    filter(
      # positive wage income
      incwage > 0 & incwage < 99999998,
      # public or private employee class
      employee == 1,
      # dropping relatively small number of cases with zero/negative weights
      asecwt > 0,
      # stick to 16+
      age >= 16
    ) %>%
    mutate(weeks_intervalled = case_when(
      wkswork2 == 1 ~ (1  + 13) / 2,
      wkswork2 == 2 ~ (14 + 26) / 2,
      wkswork2 == 3 ~ (27 + 39) / 2,
      wkswork2 == 4 ~ (40 + 47) / 2,
      wkswork2 == 5 ~ (48 + 49) / 2,
      wkswork2 == 6 ~ (50 + 52) / 2
    )) %>%
    mutate(weeks_continuous = ifelse(wkswork1 == 0, NA, wkswork1)) %>%
    mutate(full_time = case_when(
      fullpart == 1 ~ 1,
      fullpart == 2 ~ 0
    )) %>%
    mutate(year = year - 1) %>%
    left_join(asec_hours_ftpt, by = c("year", "full_time")) %>%
    mutate(hours_2040 = case_when(
      full_time == 1 ~ 40,
      full_time == 0 ~ 20
    )) %>%
    mutate(hours_usual = ifelse(uhrsworkly <= 99, uhrsworkly, NA)) %>%
    mutate(
      wage_int_usual = incwage / (weeks_intervalled * hours_usual),
      wage_con_usual = incwage / (weeks_continuous * hours_usual),
      wage_int_actual = incwage / (weeks_intervalled * hours_actual_avg),
      wage_con_actual = incwage / (weeks_continuous * hours_actual_avg)
    ) %>%
    mutate(
      wage_ftfy_orig = ifelse(ahrsworkt >=35 & ahrsworkt <= 99 & wkswork2 == 6, incwage / (51 * ahrsworkt), NA),
      wage_ftfy_new = ifelse(full_time == 1 & wkswork2 == 6, incwage / (51 * 40), NA)
    )
  
  asec_wage_vars <- asec_clean %>%
    colnames() %>%
    str_subset("^wage") 
  
  median_wages_asec <- asec_wage_vars %>% 
    map(~ median_by_year(asec_clean, .x, w = "asecwt")) %>% 
    list_rbind()
  
  median_wages_asec %>% 
    bind_rows(median_wages_org) %>% 
    filter(wage_var %in% c("wage_int_actual", "wageotc_noadj")) %>% 
    summarize(median_wage = mean(value), .by = year)
}
