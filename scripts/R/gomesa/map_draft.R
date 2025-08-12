# ABOUT:  ---------------------------------------------------------------
# Author: Edward Leland
# This script generates a stylized map showing Louisiana's submerged lands,
# a proposed 3-9 nautical mile expansion zone, and associated oil and gas wells.
# A captioned blurb provides context for royalty revenue implications.


# SETUP:  ---------------------------------------------------------------

## Libraries ------------------------------------------------------------
library(sf)
library(tidyverse)
library(showtext)
library(blancocentR)
library(here)
library(maptiles)
library(terra)
library(ggspatial)
library(cowplot)
library(rnaturalearth)
library(ggtext)

## Fonts & Themes -------------------------------------------------------
source(here("..", "..", "..", "Central Data", "theme_bc_showtext_safe.R"))
font_add_google("Quicksand", "quicksand")
font_add_google("Bitter", "bitter")
showtext_auto(TRUE)
showtext_opts(dpi = 300)


# DATA LOADING & TRANSFORMATION:  --------------------------------------

# Load shapefiles
la_submerged    <- st_read(here("raw", "GIS", "og_boundary", "og_boundary.shp"))
expansion_zone  <- st_read(here("raw", "GIS", "Temp", "Difference.shp"))
expansion_wells <- st_read(here("raw", "GIS", "New_Leases", "new_wells.shp"))
gulf_wells      <- st_read(here("raw", "GIS", "gulf_wells", "gulf_wells.shp"))

# Reproject to EPSG:3857 for web mapping
la_submerged_3857    <- st_transform(la_submerged, 3857)
expansion_zone_3857  <- st_transform(expansion_zone, 3857)
expansion_wells_3857 <- st_transform(expansion_wells, 3857)
gulf_wells_3857      <- st_transform(gulf_wells, 3857)

# Set bounding box for tile fetching
bbox_coords <- c(xmin = -10450000, ymin = 3100000, xmax = -9850000, ymax = 3550000)
bbox_sfc <- st_as_sfc(st_bbox(bbox_coords, crs = st_crs(3857)))

# Get base map tiles
tiles <- get_tiles(x = bbox_sfc, provider = "CartoDB.Positron", zoom = 8)

# Map fill colors (matching Blanco Center palette)
map_cols <- list(
  "Proposed expansion"    = col_la,
  "Federal Gulf leases"   = mid_gray,
  "Current state waters"  = col_la,
  "New LA leases"         = misc_pal$midnight
)

fill_levels <- c("Current state waters", "Proposed expansion", "New LA leases", "Federal Gulf leases")


# MAIN MAP:  -----------------------------------------------------------

main_map <- ggplot() +
  layer_spatial(data = tiles) +
  geom_sf(data = expansion_zone_3857, aes(fill = "Proposed expansion"), color = NA, alpha = 0.3) +
  geom_sf(data = la_submerged_3857, aes(fill = "Current state waters"), color = NA, linewidth = 0.6) +
  geom_sf(data = gulf_wells_3857, aes(fill = "Federal Gulf leases"), color = NA, size = 0.3, alpha = 0.5) +
  geom_sf(data = expansion_wells_3857, aes(fill = "New LA leases"), color = NA, size = 1.2) +
  
  scale_fill_manual(
    name = NULL,
    values = unlist(map_cols),
    breaks = fill_levels,
    labels = c(
      "Current state waters" = "Current 3 NM boundary",
      "Proposed expansion"   = "Proposed 3-9 NM expansion",
      "New LA leases"        = "New Louisiana leases",
      "Federal Gulf leases"  = "Federal Gulf leases"
    )
  ) +
  coord_sf(
    crs = 3857,
    xlim = bbox_coords[c("xmin", "xmax")],
    ylim = bbox_coords[c("ymin", "ymax")],
    expand = FALSE
  ) +
  theme_bc_showtext_safe(void = TRUE) +
  theme(
    legend.position = "bottom",
    plot.title = element_textbox(margin = margin(b = 10))
  ) +
  labs(
    title = "Louisiana Submerged Lands and Proposed Expansion",
    subtitle = "Oil and gas leases in the Gulf, highlighting current state waters, federal leases,\nand leases impacted by the proposed state jurisdiction expansion.",
    caption = "Sources: BOEM, EIA, Marketwatch | Basemap: CartoDB | Blanco Center | Visualization by Edward Leland"
  )


# BLURB: Why This Matters  ---------------------------------------------

blurb_text <- paste0(
  "<span style='font-family: Bitter; color: #1A242F; font-size: 18pt;'>Why this matters</span><br><br>",
  "<span style='font-family: Quicksand; color: #575E66; font-size: 12pt;'>",
  "Governor Landry has suggested expanding the current 3 nautical mile (NM) maritime boundary of Louisiana to the 9 NM limit used by Texas and Florida. ",
  "Between September 2023 and August 2024, oil and gas well leases in the proposed 3–9 NM zone ",
  "generated <b>$74.6 million</b> in royalty revenue.<br><br>",
  "Under current law, $67.5 million of these royalties go to the federal government. ",
  "By expanding Louisiana’s maritime jurisdiction, the state could reclaim these earnings — ",
  "a small but meaningful share of the <b>$7.3 billion</b> produced across all active Gulf leases.",
  "</span>"
)

blurb_plot <- ggplot(data.frame(x = 1, y = 1), aes(x, y)) +
  geom_textbox(
    label = blurb_text,
    width = unit(0.85, "npc"),
    size = 8,
    halign = 0,
    valign = 1,
    box.color = NA,
    fill = NA,
    lineheight = .9
  ) +
  xlim(0, 2) + ylim(0, 2) +
  theme_bc_showtext_safe(void = TRUE)


# COMBINE & EXPORT:  ---------------------------------------------------

combined_plot <- plot_grid(
  blurb_plot,
  main_map,
  ncol = 2,
  rel_widths = c(1, 2.2),
  labels = NULL
)

# Save output
ggsave(
  here("output", "social_media_map", "final.png"),
  combined_plot,
  width = 14,
  height = 9,
  dpi = 300,
  bg = "white"
)
