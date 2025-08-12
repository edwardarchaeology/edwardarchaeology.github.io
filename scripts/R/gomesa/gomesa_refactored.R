# SETUP ----------------------------------------------------------------
library(tidyverse)
library(here)
library(janitor)
library(scales)
library(gt)
library(lubridate)
library(readxl)
library(writexl)

# Load production and lease data
load_production_data <- function() {
  read.table(here("raw", "mv_productiondata.txt"), sep = ",", header = TRUE) %>%
    filter((PROD_YEAR == '2023' & PROD_MONTH %in% 9:12) | 
             (PROD_YEAR == '2024' & PROD_MONTH %in% 1:8))
}

load_lease_data <- function(file, id_col = "LEASE_NUMBER") {
  read.table(here("raw", file), sep = ",", header = TRUE) %>%
    rename_with(~ id_col, matches("LEASE", ignore.case = TRUE))
}


# ECONOMIC DATA PROCESSING ---------------------------------------------
convert_date_index <- function(df) {
  df[-(1:3), , drop = FALSE] %>%
    mutate(
      date = as.Date(paste("01", rownames(.)), format = "%d %b %Y")
    ) %>%
    filter(date >= "2023-09-01", date <= "2024-08-01")
}

load_econ_data <- function() {
  oil <- read.csv(here("raw", "FUTURE_US_XNYM.csv")) %>%
    rowwise() %>%
    mutate(row_avg = mean(c_across(-Date))) %>%
    transmute(date = my(Date), oil_price = row_avg)
  
  gas <- convert_date_index(read.csv(here("raw", "Henry_Hub_Natural_Gas_Spot_Price.csv"))) %>%
    rename(gas_price = 2)
  
  cond <- convert_date_index(read.csv(here("raw", "U.S._Natural_Gas_Liquid_Composite_Price.csv"))) %>%
    rename(condensate_price = 2)
  
  oil %>% full_join(gas, by = "date") %>% full_join(cond, by = "date")
}


# REVENUE CALCULATIONS -------------------------------------------------
calculate_revenue <- function(df, oil_col = "LEASE_OIL_PROD", gas_gwg = "LEASE_GWG_PROD", 
                              gas_owg = "LEASE_OWG_PROD", cond_col = "LEASE_CONDN_PROD",
                              royalty_col = "ROYALTY_RATE") {
  df %>%
    mutate(
      oil_revenue = .data[[oil_col]] * oil_price * .data[[royalty_col]] / 100,
      gas_revenue = (.data[[gas_gwg]] + .data[[gas_owg]]) * gas_price * .data[[royalty_col]] / 100,
      condensate_revenue = .data[[cond_col]] * condensate_price * .data[[royalty_col]] / 100,
      total_revenue = oil_revenue + gas_revenue + condensate_revenue
    )
}


# FINAL PROCESSING & EXPORT --------------------------------------------

# Main function for all lease types
process_leases <- function(lease_df, prod_df, econ_df, id_col = "LEASE_NUMBER", royalty_col = "ROYALTY_RATE") {
  lease_df %>%
    left_join(prod_df, by = setNames("LEASE_NUMBER", id_col)) %>%
    mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y")) %>%
    left_join(econ_df, by = "date") %>%
    filter(!is.na(date)) %>%
    calculate_revenue(royalty_col = royalty_col)
}

# GOMESA summary
summarize_gomesa <- function(df, eff_date_col = "LEASE_EFF_DATE") {
  df <- df %>% clean_names()
  df$date_effective <- as.Date(ymd_hms(df[[eff_date_col]], tz = "UTC"))
  df$gomesa_eligible <- df$date_effective >= as.Date("2006-01-01")
  
  df %>%
    mutate(date = make_date(prod_year, prod_month, 1)) %>%
    summarise(
      total_oil_bbl = sum(lease_oil_prod, na.rm = TRUE),
      total_oil_revenue = sum(lease_oil_prod * royalty_rate / 100 * oil_price, na.rm = TRUE),
      gomesa_oil_bbl = sum(lease_oil_prod[gomesa_eligible], na.rm = TRUE),
      gomesa_oil_revenue = sum(lease_oil_prod[gomesa_eligible] * royalty_rate[gomesa_eligible] / 100 * oil_price[gomesa_eligible], na.rm = TRUE),
      total_gas_mcf = sum(lease_gwg_prod + lease_owg_prod, na.rm = TRUE),
      total_gas_revenue = sum((lease_gwg_prod + lease_owg_prod) * royalty_rate / 100 * gas_price, na.rm = TRUE),
      gomesa_gas_mcf = sum((lease_gwg_prod + lease_owg_prod)[gomesa_eligible], na.rm = TRUE),
      gomesa_gas_revenue = sum(((lease_gwg_prod + lease_owg_prod)[gomesa_eligible] * royalty_rate[gomesa_eligible] / 100 * gas_price[gomesa_eligible]), na.rm = TRUE)
    ) %>%
    mutate(
      pct_oil_gomesa = 100 * gomesa_oil_bbl / total_oil_bbl,
      pct_gas_gomesa = 100 * gomesa_gas_mcf / total_gas_mcf
    )
}

# Table formatter
format_summary_table <- function(summary_df) {
  summary_df %>%
    pivot_longer(cols = everything(), names_to = "metric", values_to = "value") %>%
    mutate(
      category = case_when(
        grepl("^gomesa", metric) ~ "GOMESA",
        grepl("^total", metric) ~ "Total",
        TRUE ~ NA_character_
      ),
      metric_clean = str_replace_all(metric, "^(gomesa_|total_)", "") %>%
        str_replace_all("_", " ") %>%
        tools::toTitleCase()
    ) %>%
    filter(!is.na(category)) %>%
    pivot_wider(names_from = metric_clean, values_from = value) %>%
    mutate(across(`Oil Bbl`:`Gas Mcf`, ~ comma(.x, accuracy = 1)),
           across(contains("Revenue"), ~ dollar(.x, accuracy = 1))) %>%
    gt(rowname_col = "category") %>%
    cols_label(
      `Oil Bbl` = "Oil (bbl)",
      `Oil Revenue` = "Oil Revenue",
      `Gas Mcf` = "Gas (mcf)",
      `Gas Revenue` = "Gas Revenue"
    ) %>%
    tab_header(
      title = md("**Production and Revenue Summary**"),
      subtitle = md("*September 2023 – August 2024*")
    ) %>%
    tab_footnote("Data sourced from BOEM, EIA, MarketWatch", locations = cells_title(groups = "title")) %>%
    tab_style(style = cell_text(weight = "bold"), locations = cells_stub(rows = "GOMESA"))
}