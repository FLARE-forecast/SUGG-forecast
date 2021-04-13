
if (!require('pacman')) install.packages('pacman'); library('pacman')
pacman::p_load(tidyverse, lubridate, VIM, naniar, missMDA, Amelia, mice, FactoMineR, broom, aws.s3)

remotes::install_github("cboettig/neonstore", force = T)
remotes::install_github("eco4cast/EFIstandards", force = T)
remotes::install_github("FLARE-forecast/flare", force = T)
remotes::install_github("FLARE-forecast/noaaGEFSpoint", force = T)

# Set up the directories
siteID = "SUGG"
siteID_neon = c("BARC","OSBS")
lake_directory <- getwd()
products = c("DP1.00098.001", "DP1.00002.001", "DP1.00023.001", "DP1.00006.001", "DP1.00001.001", "DP1.00004.001")
buoy_products = c("DP1.20264.001","DP1.20252.001")

local_directory <- file.path(getwd(), "data", "NOAA_data")
date = seq(from = as.Date("2020-09-30"), to = as.Date("2020-12-30"), by = "days")
cycle = c("00")
noaa_data_location <- file.path(getwd(),"data","NOAA_data","noaa","NOAAGEFS_1hr",siteID)
files_noaa <- list.files(noaa_data_location)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### DOANLOAD THE NEWEST NOAA DATA ###
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source(file.path(lake_directory, "data_download/NOAA_downloads.R"))

for(i in 1:length(date)){
  for(g in 1:length(cycle)){
      download_noaa_files_s3(siteID = siteID,
                             date = date[i], 
                             cycle = cycle[g], 
                             local_directory <- local_directory)
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### DOANLOAD THE NEWEST NEON DATA ###
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

source(file.path(lake_directory, "data_download/NEON_downloads.R"))

subDir <- "neonstore"
if (file.exists(file.path(getwd(),"data",subDir))){
  Sys.setenv("NEONSTORE_DB" = "/Users/ryanmcclure/Documents/SUGG-forecast/data/neonstore/")
  Sys.setenv("NEONSTORE_HOME" = "/Users/ryanmcclure/Documents/SUGG-forecast/data/neonstore/")
  neonstore::neon_dir()
} else {
  dir.create(file.path(getwd(),"data",subDir))
  Sys.setenv("NEONSTORE_HOME" = "/Users/ryanmcclure/Documents/SUGG-forecast/data/neonstore/")
  Sys.setenv("NEONSTORE_DB" = "/Users/ryanmcclure/Documents/SUGG-forecast/data/neonstore/")
  neonstore::neon_dir()
}

download_neon_files(siteID_neon = siteID_neon, 
                    products = products,
                    siteID = siteID,
                    buoy_products = buoy_products)
