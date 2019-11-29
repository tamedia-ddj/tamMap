# tamMap - ggplot2 and tidy Swiss data centric suite

Suite of convenience functions for geospatial mapping of Swiss data. It integrates geographical data at different levels (municipality, cantons, ...), cities. It also incorporates various municipality & cantons socio-econmic and voting indicators. Focus is on low levels functions for maximum flexibility

It relies on bleeding edge R packages, primarily *sf* and *tidyverse*. 

## Installation

It will probably never be on CRAN. To be installed from github:

``` r
# install.packages("devtools")
devtools::install_github("d-qn/taMap")
```

## TODO
* Use swisstopop API to get geospatial data
* Add more G1 resolution geodata (only 2018 Gemeinde so far)

### Clean up
* Use swisstopop API to get geospatial data

### Features
* Add Geneva : water bodies, land use. As done [here](https://xvrdm.github.io/2017/09/15/create-maps-from-sitg-files-with-sf-and-ggplot2/) but with esri2sf 

```
library(esri2sf)
url <- 'https://ge.ch/sitgags1/rest/services/VECTOR/SITG_OPENDATA_02/MapServer/6186'
df <- esri2sf(url)
```

* create a hex tile map of communes with geogrid and save it
* inlet_helpers: use [gglocator](https://stackoverflow.com/questions/9450873/locator-equivalent-in-ggplot2-for-maps?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa) to find the shift. Seems broken though

## Examples

### Show the %foreigners vs % vote UDC by municipalities

![](man/figures/README-municipalitiyIndicators_scatter.png)

```{r municipalities features}
require(tidyverse)
library(tamMap)
communeData <- loadCommunesCHportraits()
colnames(communeData)

# Select only "surface" indicators
colIdx <- which(attr(communeData, "indicatorGroup") == "Surface")
head(communeData[,colIdx])

## Show the %foreigners vs % vote UDC
g1 <- ggplot(data = as.data.frame(communeData), aes(x = `Etrangers en %`, y = UDC)) + 
  geom_point(aes(size = Habitants), alpha = 0.5)
g1
```


### A long example to show a map with a zoom inlet map of Geneva

![](man/figures/README-inletMap-1.png)

```{r inletMap, echo = FALSE}
library(tamMap)
require(sf)
require(tidyverse)
require(rmapshaper)

shp_ch_paths_2018 <- shp_path(2018)
# loop and load the geo data in a named list
shp_ch_geodata <- shp_ch_paths_2018 %>% map(function(x) {
  layerName <- st_layers(x)
  st_read(x, layer = layerName$name, 
          options = "ENCODING=latin1", stringsAsFactors = F) %>% 
  select(ends_with("NR"), ends_with("NAME"))
})

# shift and scale up canton Geneva for the inlet map
geo_subset <- shp_ch_geodata$municipalities %>% filter(KTNR == 25)
inlet_geo <- shiftScale_geo(geo = geo_subset, scaleF = 4.4)
# Create circles sf to encompass the inlet map and its original location
geo_subset_coord <- encircle_coord(geo_subset)
inlet_coord <- encircle_coord(inlet_geo)
cone_sfc <- cone_geo(geo_subset_coord, inlet_coord)
circle_zoom_sfc <- encircle_geo(geo_subset_coord)
circle_inlet_sfc <- encircle_geo(inlet_coord)

# simplify muni geo, under 0.7 simplification and the lakes will look odd
shp_ch_geodata$municipalities <- 
  shp_ch_geodata$municipalities %>% ms_simplify(keep_shapes=T, keep = 0.75)

# plot
gp <- ggplot() +
  geom_sf(data = cone_sfc, fill = "lightgrey", lwd = 0, alpha = 0.2) +  
  geom_sf(data = circle_zoom_sfc, fill = "lightgrey", lwd = 0, alpha = 0.5) +
  geom_sf(data = circle_inlet_sfc, fill = "lightgrey", lwd = 0, alpha = 0.5) +
  geom_sf(data = shp_ch_geodata$municipalities, aes(fill = GMDNR), 
    lwd = 0.05, colour = "#0d0d0d") +
  #geom_sf(data = eauGe, fill = "blue") +
  geom_sf(data = inlet_geo, aes(fill = GMDNR), lwd = 0.1, colour = "#0d0d0d") +
  geom_sf(data = shp_ch_geodata$cantons, lwd = 0.15, colour = "#333333", fill = NA) +
  geom_sf(data = shp_ch_geodata$country, lwd = 0.25, colour = "#000d1a", fill = NA) +
  geom_sf(data = shp_ch_geodata$lakes  %>% 
            filter(SEENAME != "Lago di Como"), lwd = 0, fill = "#0066cc")

  gp + 
    theme_map() +
    scale_fill_viridis_c()  +
    coord_sf(datum = NA, expand = F)
```

```{r same but interactive, echo = F, eval = F}
  ## Same as above but interactive !
  library(ggiraph)
  require(htmltools)
  # repalce quote signs
  
  shp_ch_geodata$municipalities$GMDNAME <- 
    gsub("'", "_", shp_ch_geodata$municipalities$GMDNAME)
  inlet_geo$GMDNAME <- gsub("'", "_", inlet_geo$GMDNAME)
  
  gpi <- ggplot() +
    geom_sf(data = cone_sfc, fill = "lightgrey", 
            lwd = 0, alpha = 0.2,  colour = "transparent") +  
    geom_sf(data = circle_zoom_sfc, fill = "lightgrey", 
            lwd = 0, alpha = 0.5, colour = "transparent") +
    geom_sf(data = circle_inlet_sfc, fill = "lightgrey", 
            lwd = 0, alpha = 0.5, colour = "transparent") +
    geom_sf_interactive(
      data = shp_ch_geodata$municipalities, 
      aes(fill = GMDNR, tooltip = GMDNAME, data_id = GMDNAME), 
      lwd = 0.05, colour = "#0d0d0d"
    ) +
    geom_sf_interactive(
      data = inlet_geo, 
      aes(fill = GMDNR, tooltip = GMDNAME, data_id = GMDNAME),
      lwd = 0.1, colour = "#0d0d0d"
    ) +
  geom_sf(data = shp_ch_geodata$cantons, lwd = 0.15, 
          colour = "#333333", fill = NA) +
  geom_sf(data = shp_ch_geodata$country, 
          lwd = 0.25, colour = "#000d1a", fill = NA) +
  geom_sf(data = shp_ch_geodata$lakes %>% filter(SEENAME != "Lago di Como"), 
          lwd = 0, fill = "#0066cc", colour = "transparent")
  gpi <- gpi + 
    theme_map() +
    scale_fill_viridis_c()  +
    coord_sf(datum = NA, expand = F)
  
  ggiraph( ggobj = gpi, width = 1)
```

### Muncipalities with only the productive areas 

![](man/figures/README-productive_municipality.png)

```{r productive area map, echo = FALSE}
require(tidyverse)
library(tamMap)
muni_prod <- shp_path(2019, dirGeo = "CH/productive") %>% 
  st_read(options = "ENCODING=latin1")

muni_prod %>% 
  ggplot() +
  geom_sf(aes(fill = GDENR), lwd = 0) +
  theme_map() +
  labs(title = "A silly choroepleth map of BFS muncipality ID, but showing only the productive areas")

```

### Swiss cantonal tilemap

![](man/figures/README-tilemap_canton_CH.png)
```{r cantonal tilemap, echo = FALSE}
# load tilemap sf object
tmap_ch <- tilemap_ch()

# load all federal ballot results
fballot_canton <- loadCantonsCHFederalBallot() 
# select only the no Billag ballot
idx <- which(colnames(fballot_canton) == "5950")
vote <- fballot_canton[,idx] %>% enframe()
tmap_ch <- left_join(tmap_ch, vote, by = c("Name" = "name"))

ggplot(tmap_ch) + 
  geom_sf(data = , aes(fill = value)) +
  theme_map() +
  # add canton 2 letters labels
   geom_sf_text(aes(label = Name), 
                hjust = 0.5, vjust = 0.5, colour = "white", size = 2.5) +
   scale_fill_viridis_c(option = "B") +
   labs(title = paste0("Pourcentage oui au vote du ", attr(fballot_canton, "date")[idx], " sur:\n",
                       attr(fballot_canton, "ballotName")[idx]))

```

### Geneva map only with water bodies

![](man/figures/README-GenevaMapWater-1.png)

```{r GenevaMapWater, echo = F}
shp_ch_paths_2018 <- shp_path(2018)

# loop and load the geo data in a named list
shp_ch_geodata <- shp_ch_paths_2018[c('municipalities')] %>% 
  map(function(x) {
    layerName <- st_layers(x)
       st_read(x, layer = layerName$name, 
          options = "ENCODING=latin1", stringsAsFactors = F) %>% 
  select(ends_with("NR"), ends_with("NAME"))
})

gva <- shp_ch_geodata$municipalities %>% filter(KTNR == 25)

# get water bodies (river & lake)
library(esri2sf)
url <- 'https://ge.ch/sitgags1/rest/services/VECTOR/SITG_OPENDATA_02/MapServer/6186'
water <- esri2sf(url)

ggplot() + 
 geom_sf(
   data = gva,
   aes(fill = GMDNR), lwd = 0, colour = "#0d0d0d"
 ) + 
 geom_sf(
   data = water, lwd = 0.65, fill = "lightblue", 
   alpha = 1, colour = "lightblue"
 ) +
 theme_map() +
 coord_sf(datum = NA, expand = F)

```

