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

This write‑up documents a reproducible workflow (R + `{tidyverse}`) to estimate royalty revenue from Louisiana offshore oil & gas production. It covers:

- **New leases inside the proposed 3–9 nautical mile (NM) zone** (a potential expansion of Louisiana jurisdiction).
- **All active Gulf leases** for context and comparison.
- **GOMESA‑eligible production and revenue (post‑2006)** aggregated by fiscal year.
- A **map** visualizing Louisiana submerged lands, the proposed expansion zone, and wells.

Outputs include formatted tables (via `{gt}`) and a social-map graphic.

> Time window for the main comparison tables: **September 2023 – August 2024**.  
> Historical GOMESA summary spans **2013–2024** with effective‑date checks back to **2006**.

---

# Data Sources

- **Production**: BOEM monthly lease‑level production exports (`mv_productiondata.txt` and ten‑year slices).
- **Lease metadata**: `all_active.csv` (incl. royalty rates where present).  
- **Royalty rate backfill**: BOEM fixed‑width tape (`LSETAPE.DAT`) parsed via `read_fwf()`.
- **Commodity prices**:  
  - WTI (NYMEX) monthly price history (xlsx).  
  - Henry Hub spot monthly (EIA CSV).  
  - (Optional) NGL composite price for condensate (EIA CSV) — used in the first pass.
- **GIS**: Submerged lands boundary, proposed 3–9 NM difference polygon, Gulf wells, and “new” LA wells.

All files are read with `here()` from `raw/` (and subfolders) and written to `output/`.

---

# Key Assumptions & Formulas

- **Royalty revenue** is computed per lease, per month, per commodity:  
  $$
  \text{Revenue}_c = \text{Volume}_c \times \text{Price}_c \times \frac{\text{Royalty Rate}}{100}
  $$
  where $c \in \{\text{oil}, \text{gas}, \text{condensate}\}$.

- **Gas BTU adjustment** (ten‑year/GOMESA section): Henry Hub price is divided by **1.038** to approximate an MMBtu→Mcf conversion used in legacy reports:  
  $$
  \text{Gas Revenue} = (\text{GWG} + \text{OWG}) \times \frac{\text{Henry Hub}}{1.038} \times \frac{\text{Royalty Rate}}{100}
  $$

- **GOMESA eligibility**: leases with **effective date ≥ 2006‑01‑01**.

- **Proposed expansion zone**: state jurisdiction from **3 NM → 9 NM**; “new leases” inside this band are analyzed separately for the Sept‑2023–Aug‑2024 window.

- **Share rate** for illustrative fiscal impact:** `share_rate = 0.27`** (parameterized).

> Caveat: These are **high-level estimates** using public prices and reported volumes. Transportation, quality differentials, and contractual specifics are not modeled.


---

# Environment

```r
library(tidyverse)
library(here)
library(janitor)
library(lubridate)
library(scales)
library(gt)
# GIS & viz (for the map section)
library(sf); library(maptiles); library(ggspatial); library(cowplot); library(ggtext)
```

Project uses `{here}` for stable paths and `{janitor}` for clean names.

---

# 1) Load & Filter Production (Core Window)

```r
production <- read.table(here("raw", "mv_productiondata.txt"), sep = ",", header = TRUE)

production_clean <- production %>% 
  filter((PROD_YEAR == "2023" & PROD_MONTH %in% 9:12) |
         (PROD_YEAR == "2024" & PROD_MONTH %in% 1:8))
```

Create a monthly **`date`** field on all production joins:

```r
mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y"))
```

---

# 2) Price Curves (Monthly)

Helper to normalize EIA “date in rownames” sheets:

```r
convert_date_index <- function(df) {
  df <- df[-(1:3), , drop = FALSE]
  df$date <- rownames(df)
  df$date <- as.Date(paste("01", df$date), format = "%d %b %Y")
  df %>% filter(date >= "2023-09-01", date <= "2024-08-01")
}
```

WTI monthly (from xlsx or CSV) + Henry Hub monthly (EIA):

```r
# Example: WTI from xlsx with (Month, Year) → Date
month_full <- tolower(month.name)
get_month_number <- function(mstr) {
  idx <- which(sapply(month_full, function(m) grepl(tolower(mstr), m)))
  if(length(idx)) idx[1] else NA_integer_
}

oil_econ <- readxl::read_xlsx(here("raw","ten_year","oil_prices","PriceHistory_23.xlsx"), skip = 1) %>%
  mutate(month_num = sapply(Month, get_month_number),
         date = as.Date(paste(Year, month_num, "01", sep = "-"))) %>%
  transmute(date, oil_price = `NYMEX - Light Sweet Crude $/bbl`)

gas_econ <- read.csv(here("raw", "Henry_Hub_Natural_Gas_Spot_Price.csv")) %>%
  convert_date_index() %>%
  rename(gas_price = 2)
```

Combine and enforce numeric types:

```r
combined_econ <- full_join(oil_econ, gas_econ, by = "date") %>%
  mutate(across(c(oil_price, gas_price), as.numeric))
```

> In an earlier pass, an **NGL composite** price was also joined as `condensate_price` for condensate revenue.

---

# 3) New Leases in Proposed 3–9 NM Zone

Join “new leases” to the filtered production and to prices; compute royalties.

```r
new_non_8g <- read.table(here("raw","new_non_8g.csv"), sep=",", header=TRUE)
new_non_8g_prod <- left_join(new_non_8g, production_clean,
                             by = c("LEASE_NUMB" = "LEASE_NUMBER")) %>%
  mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y")) %>%
  left_join(combined_econ, by = "date") %>%
  filter(!is.na(date))

roy_non8g <- tibble(
  oil_revenue = LEASE_OIL_PROD * oil_price * ROYALTY_RA/100,
  gas_revenue = (LEASE_GWG_PROD + LEASE_OWG_PROD) * gas_price * ROYALTY_RA/100,
  condensate_revenue = LEASE_CONDN_PROD * (!!sym("condensate_price")) * ROYALTY_RA/100
) %>% replace_na(list(oil_revenue=0, gas_revenue=0, condensate_revenue=0))

total_revenue_non_8g <- sum(roy_non8g$oil_revenue + roy_non8g$gas_revenue + roy_non8g$condensate_revenue, na.rm=TRUE)
```

A parallel calculation was done for **all new leases** within the band; the write‑up focuses on the non‑8g subset because that’s the portion assumed to be shared vs. state‑kept under a 9 NM scenario.

> A simple **sharing scenario** uses `share_rate = 0.27` to estimate the federal/state split under current rules vs. expanded jurisdiction.

---

# 4) All Active Leases (Context)

```r
all_active <- read.csv(here("raw","all_active.csv"))
all_active_prod <- left_join(all_active, production_clean, by = "LEASE_NUMBER") %>%
  mutate(date = as.Date(paste("01", PROD_MONTH, PROD_YEAR), format = "%d %m %Y")) %>%
  left_join(combined_econ, by = "date")

all_rr <- tibble(
  oil_revenue = all_active_prod$LEASE_OIL_PROD * all_active_prod$oil_price * all_active_prod$ROYALTY_RATE/100,
  gas_revenue = (all_active_prod$LEASE_GWG_PROD + all_active_prod$LEASE_OWG_PROD) * all_active_prod$gas_price * all_active_prod$ROYALTY_RATE/100,
  condensate_revenue = all_active_prod$LEASE_CONDN_PROD * (!!sym("condensate_price")) * all_active_prod$ROYALTY_RATE/100
)

total_revenue_all <- sum(rowSums(all_rr, na.rm = TRUE), na.rm = TRUE)
```

These totals are used to contextualize the proposed‑zone revenues (e.g., “\$74.6M vs \$7.3B”).

---

# 5) GOMESA (2013–2024) with Royalty Backfill

Some leases in historical files lacked royalty rate in the “clean” table. To backfill, parse `LSETAPE.DAT` (fixed‑width) and extract the rate:

```r
field_widths <- c(6,10,20,15,15,15,15,10,30,4,4,6,4,5,4,5,15,1,30,2,8,15,20,15,8,5)
field_names  <- c("Lease_Number","Lease_Type","Lease_Date","Field1","Field2","Field3","Field4","Numeric1","Block_Desc","Code1","Code2",
                  "Operation_Code","Block_Code","Operation_Type","Action_Code","Action_Date","Action_Desc","Flag","Description","Region",
                  "Date_1","Field_Name","State","Area","Number","Block")

lease_tape <- readr::read_fwf(".../LSETAPE.DAT", readr::fwf_widths(field_widths, col_names = field_names),
                              col_types = readr::cols(.default = readr::col_character())) %>%
  mutate(Field3 = stringr::str_extract(Field3, "\\\\S+$") |> stringr::str_replace(".*/.", "")) %>%
  transmute(lease_number = Lease_Number, royalty_rate = Field3)
```

Build the historical dataset, flag GOMESA (effective date ≥ 2006‑01‑01), join prices, and compute revenue. Note the **BTU adjustment** on gas price:

```r
gomesa_df <- with_rates_full %>%
  left_join(combined_econ, by = "date") %>%
  mutate(
    oil_revenue = lease_oil_production_bbl * oil_price * royalty_rate/100,
    gas_revenue = (lease_gas_well_gas_production_mcf + lease_oil_well_gas_production_mcf) * (gas_price/1.038) * royalty_rate/100
  )
```

Aggregate by **fiscal year** (Aug–Jul in the code below; adjust if needed):

```r
gomesa_fy <- gomesa_df %>%
  mutate(fiscal_year = if_else(production_month >= 8, production_year, production_year - 1),
         fiscal_year_label = paste(fiscal_year, fiscal_year + 1, sep = "-")) %>%
  group_by(fiscal_year_label) %>%
  summarise(
    total_oil_production = sum(lease_oil_production_bbl, na.rm=TRUE),
    total_oil_revenue    = sum(oil_revenue, na.rm=TRUE),
    total_gas_production = sum(lease_gas_well_gas_production_mcf + lease_oil_well_gas_production_mcf, na.rm=TRUE),
    total_gas_revenue    = sum(gas_revenue, na.rm=TRUE),
    .groups = "drop"
  )
```

Render a clean table:

```r
gomesa_table <- gomesa_fy %>%
  gt() %>%
  tab_header(title = md("**Fiscal Year Production and Revenue Summary**"),
             subtitle = md("*Oil and Gas Production and Revenue by Fiscal Year*")) %>%
  fmt_number(columns = everything(), decimals = 0, use_seps = TRUE) %>%
  tab_spanner(label = "Oil", columns = c(total_oil_production, total_oil_revenue)) %>%
  tab_spanner(label = "Gas", columns = c(total_gas_production, total_gas_revenue)) %>%
  cols_label(fiscal_year_label = "Fiscal Year",
             total_oil_production = "Oil (BBL)",
             total_oil_revenue    = "Oil Revenue (USD)",
             total_gas_production = "Gas (MCF)",
             total_gas_revenue    = "Gas Revenue (USD)")
```

---

# 6) Comparison Tables (Sept‑2023–Aug‑2024)

Two simple `{gt}` tables are produced for **New Leases (3–9 NM)** and **All Active**. Values are pre‑formatted strings at this layer for presentation.

```r
new_lease_table <- tibble(
  Category = c("Oil","Gas","Condensate","Total"),
  Volume   = c("6,310,231 BBL","16,287,937 MCF","622,190 BBL",""),
  Revenue  = c("$68,289,498","$5,622,270","$660,930.4","$74,572,698")
)

formatted_table <- new_lease_table %>%
  gt() %>%
  tab_header(title   = md("**Production and Revenue Summary: \\n New Leases (3–9 NM)**"),
             subtitle= md("*September 2023 – August 2024*")) %>%
  tab_footnote(footnote = "Sources: BOEM, EIA, MarketWatch", locations = cells_title(groups="title")) %>%
  tab_style(style = cell_text(weight = "bold"), locations = cells_body(rows = Category == "Total"))
```

The equivalent table is built for **All Active Leases** to contextualize magnitudes.

---

# 7) Map

A composed figure overlays base tiles (`CartoDB.Positron`), **current state waters**, the **proposed 3–9 NM expansion**, and **well points**. The plot is paired with a short explainer (“Why this matters”) and exported at 300 DPI with brand fonts (`Quicksand`, `Bitter`).

Key steps:
1. Read and reproject shapefiles to **EPSG:3857**.  
2. Fetch tiles for a pre‑set bounding box.  
3. Draw fills/points with a restrained palette and bottom legend.  
4. Compose map + blurb with `{cowplot}` and export to `output/social_media_map/final.png`.

---

# 8) Reproducibility Notes

- All paths use `here()`; swap in your project root as needed.  
- Prices are **monthly**, matched to production by `date = first day of month`.  
- **Royalty rate parsing** from `LSETAPE.DAT` depends on widths/fields shown above; verify against your tape version.  
- Gas BTU factor (`1.038`) is a simplifying constant; adapt if using more precise calorific content or contract terms.  
- Where values were not available (e.g., missing condensate price), rows are left `NA` or zero‑filled **only** for presentation tables. Analysis uses `na.rm = TRUE` to avoid biasing totals.

---

# 9) Outputs

- `output/GOMESA_vs_total_calculations/GOMESA_table.png`
- `output/ten_year/ten_year_table.png`
- `output/social_media_map/final.png`
- `output/New_Leases_Table.png`

---

# 10) Next Steps

- Add sensitivity cases for **price volatility** and **alternative BTU factors**.  
- Break out **8(g)** vs **non‑8(g)** explicitly in the proposed zone.  
- Incorporate **quality differentials** (e.g., API gravity for oil) if data become available.  
- Parameterize **fiscal‑year cutoff** and add a toggle in the table headers.

---

*Questions or suggestions? Open an issue in the repo or reach out directly.*
