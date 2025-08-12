<!-- Configure MathJax and load it -->
<script>
window.MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\(', '\\)']],
    displayMath: [['$$','$$'], ['\\[','\\]']]
  }
};
</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>

# Overview

This document outlines a refactored and modularized R workflow for estimating royalty revenue from Louisiana offshore oil and gas production (2023–2024), emphasizing:

- **New leases in the proposed 3–9 NM expansion zone**
- **All active leases for context and comparison**
- **GOMESA-eligible leases (effective date >= 2006)**
- A parameterized **share rate** scenario

Outputs include formatted comparison tables and time-aggregated summaries via `{gt}`.

---

# Data Sources

- **Production**: `mv_productiondata.txt`
- **New leases**: `new_non_8g.csv`, `new_8g_leases.csv`
- **All leases**: `all_active.csv`
- **Economic indicators**:
  - WTI monthly price: MarketWatch (`FUTURE_US_XNYM.csv`)
  - Henry Hub gas spot price: EIA CSV
  - NGL composite: EIA CSV (optional condensate proxy)

---

# Key Assumptions

- **Royalty revenue per commodity**:

  $$
  \text{Revenue}_c = \text{Volume}_c \times \text{Price}_c \times \frac{\text{Royalty Rate}}{100}
  $$

- **GOMESA-eligibility**: Leases with effective date \geq 2006-01-01

- **Date column** created via:

  ```r
  mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y"))
  ```

- **Share rate**:

  ```r
  share_rate <- 0.27
  ```

---

# Setup

```r
library(tidyverse)
library(here)
library(janitor)
library(lubridate)
library(scales)
library(gt)
library(readxl)
library(writexl)
```

---

# 1. Production Filter (Core Window)

```r
production_clean <- read.table(here("raw", "mv_productiondata.txt"), sep = ",", header = TRUE) %>%
  filter((PROD_YEAR == '2023' & PROD_MONTH %in% 9:12) |
         (PROD_YEAR == '2024' & PROD_MONTH %in% 1:8))
```

---

# 2. Economic Data Wrangling

```r
convert_date_index <- function(df) {
  df[-(1:3), , drop = FALSE] %>%
    mutate(date = as.Date(paste("01", rownames(.)), format = "%d %b %Y")) %>%
    filter(date >= "2023-09-01", date <= "2024-08-01")
}

combined_econ <- {
  oil <- read.csv(here("raw", "FUTURE_US_XNYM.csv")) %>%
    rowwise() %>%
    mutate(oil_price = mean(c_across(-Date))) %>%
    transmute(date = lubridate::my(Date), oil_price)

  gas <- convert_date_index(read.csv(here("raw", "Henry_Hub_Natural_Gas_Spot_Price.csv"))) %>%
    rename(gas_price = 2)

  cond <- convert_date_index(read.csv(here("raw", "U.S._Natural_Gas_Liquid_Composite_Price.csv"))) %>%
    rename(condensate_price = 2)

  full_join(oil, gas, by = "date") %>%
    full_join(cond, by = "date") %>%
    mutate(across(everything(), as.numeric))
}
```

---

# 3. Revenue Function

```r
calculate_revenue <- function(df, oil_col, gas_gwg, gas_owg, cond_col, royalty_col) {
  df %>%
    mutate(
      oil_revenue = .data[[oil_col]] * oil_price * .data[[royalty_col]] / 100,
      gas_revenue = (.data[[gas_gwg]] + .data[[gas_owg]]) * gas_price * .data[[royalty_col]] / 100,
      condensate_revenue = .data[[cond_col]] * condensate_price * .data[[royalty_col]] / 100,
      total_revenue = oil_revenue + gas_revenue + condensate_revenue
    )
}
```

---

# 4. New Leases in Proposed Zone

```r
new_non_8g <- read.table(here("raw", "new_non_8g.csv"), sep = ",", header = TRUE)

processed_non_8g <- new_non_8g %>%
  left_join(production_clean, by = c("LEASE_NUMB" = "LEASE_NUMBER")) %>%
  mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y")) %>%
  left_join(combined_econ, by = "date") %>%
  calculate_revenue("LEASE_OIL_PROD", "LEASE_GWG_PROD", "LEASE_OWG_PROD", "LEASE_CONDN_PROD", "ROYALTY_RA")
```

---

# 5. All Active Leases

```r
all_active <- read.csv(here("raw", "all_active.csv"))

processed_all <- all_active %>%
  left_join(production_clean, by = "LEASE_NUMBER") %>%
  mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y")) %>%
  left_join(combined_econ, by = "date") %>%
  calculate_revenue("LEASE_OIL_PROD", "LEASE_GWG_PROD", "LEASE_OWG_PROD", "LEASE_CONDN_PROD", "ROYALTY_RATE")
```

---

# 6. Share Rate Comparison

```r
shared_revenue <- (sum(processed_all$total_revenue, na.rm = TRUE) -
                   sum(processed_non_8g$total_revenue, na.rm = TRUE)) * share_rate
expansion_extra_revenue <- sum(processed_all$total_revenue, na.rm = TRUE) - shared_revenue
```

---

# 7. GOMESA Summary Table

```r
gomesa_eligible <- processed_all %>%
  clean_names() %>%
  mutate(date_effective = as.Date(ymd_hms(lease_eff_date, tz = "UTC")),
         gomesa = date_effective >= as.Date("2006-01-01"))

summary_stats <- gomesa_eligible %>%
  summarise(
    total_oil_bbl = sum(lease_oil_prod, na.rm = TRUE),
    gomesa_oil_bbl = sum(lease_oil_prod[gomesa], na.rm = TRUE),
    total_gas_mcf = sum(lease_gwg_prod + lease_owg_prod, na.rm = TRUE),
    gomesa_gas_mcf = sum((lease_gwg_prod + lease_owg_prod)[gomesa], na.rm = TRUE)
  ) %>%
  mutate(
    pct_oil_gomesa = 100 * gomesa_oil_bbl / total_oil_bbl,
    pct_gas_gomesa = 100 * gomesa_gas_mcf / total_gas_mcf
  )
```

---

# 8. Output Table

```r
summary_table <- summary_stats %>%
  pivot_longer(cols = everything(), names_to = "metric", values_to = "value") %>%
  separate(metric, into = c("group", "type"), sep = "_", extra = "merge") %>%
  pivot_wider(names_from = type, values_from = value) %>%
  gt(rowname_col = "group") %>%
  tab_header(title = md("**GOMESA vs Total Summary**")) %>%
  fmt_number(columns = everything(), decimals = 0)

gtsave(summary_table, here("output", "GOMESA_vs_total_calculations", "GOMESA_table.png"))
```

---

# 9. Map: Louisiana Submerged Lands and Expansion Zone

This section generates a stylized map showing Louisiana's submerged lands, a proposed 3–9 NM expansion zone, and nearby oil and gas wells. The visualization illustrates spatial relationships between current state waters, the potential expansion area, and relevant lease activity.

A captioned blurb summarizes the policy context:

> Between September 2023 and August 2024, wells in the proposed 3–9 NM zone generated **$74.6M** in royalty revenue. Under current law, **$67.5M** of this goes to the federal government. Expanding the state boundary could redirect those revenues to Louisiana.

### Key Code Chunks

```r
# Load and reproject shapefiles
la_submerged    <- st_read(here("raw", "GIS", "og_boundary", "og_boundary.shp"))
expansion_zone  <- st_read(here("raw", "GIS", "Temp", "Difference.shp"))
expansion_wells <- st_read(here("raw", "GIS", "New_Leases", "new_wells.shp"))
gulf_wells      <- st_read(here("raw", "GIS", "gulf_wells", "gulf_wells.shp"))

la_submerged_3857    <- st_transform(la_submerged, 3857)
expansion_zone_3857  <- st_transform(expansion_zone, 3857)
expansion_wells_3857 <- st_transform(expansion_wells, 3857)
gulf_wells_3857      <- st_transform(gulf_wells, 3857)

# Fetch basemap tiles
bbox_coords <- c(xmin = -10450000, ymin = 3100000, xmax = -9850000, ymax = 3550000)
bbox_sfc <- st_as_sfc(st_bbox(bbox_coords, crs = st_crs(3857)))
tiles <- get_tiles(x = bbox_sfc, provider = "CartoDB.Positron", zoom = 8)

# Draw map
main_map <- ggplot() +
  layer_spatial(data = tiles) +
  geom_sf(data = expansion_zone_3857, aes(fill = "Proposed expansion"), alpha = 0.3) +
  geom_sf(data = la_submerged_3857, aes(fill = "Current state waters")) +
  geom_sf(data = gulf_wells_3857, aes(fill = "Federal Gulf leases"), size = 0.3, alpha = 0.5) +
  geom_sf(data = expansion_wells_3857, aes(fill = "New LA leases"), size = 1.2) +
  theme_void()

# Save output
save_path <- here("output", "social_media_map", "final.png")
ggsave(save_path, main_map, width = 14, height = 9, dpi = 300)
```

For full plotting and styling logic, see: `scripts/R/gomesa/map_draft.R`

The rendered map is saved as:

```
output/social_media_map/final.png
```

---

# 10. Next Steps

- Add map visualization for proposed 3–9 NM leases
- Historical GOMESA summary by fiscal year
- Include more detailed fiscal sensitivity analysis (price, volume)
- Parametrize lease filters and share rate threshold

