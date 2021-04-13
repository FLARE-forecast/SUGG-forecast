# Function to extract and clean up the NEON data from NEON
download_neon_files <- function(siteID_neon, siteID, products, buoy_products){

        # Download newest products
        neonstore::neon_download(product = products, site = siteID_neon)
        
        # Store the NEON met data products
        neonstore::neon_store("SECPRE_30min-basic")
        neonstore::neon_store("2DWSD_30min-basic")
        neonstore::neon_store("SLRNR_30min-basic")
        neonstore::neon_store("SAAT_30min-basic")
        neonstore::neon_store("RH_30min-basic")
        neonstore::neon_store("BP_30min-basic")

        
        # Tidy up the met data
        # Airtemp
        airtemp <- neonstore::neon_table(table = "SAAT_30min-basic", site = "BARC") %>%
          select(endDateTime, tempSingleMean)%>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("tempSingleMean"), mean, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        # Radiation
        radiation <- neonstore::neon_table(table = "SLRNR_30min-basic", site = "BARC") %>%
          select(endDateTime, inSWMean, inLWMean) %>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("inSWMean", "inLWMean"), mean, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        # Humidity
        humidity <- neonstore::neon_table(table = "RH_30min-basic", site = "BARC") %>% 
          select(endDateTime, RHMean)%>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("RHMean"), mean, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        # Precipitation
        precip  <- neonstore::neon_table(table = "SECPRE_30min-basic", site = "OSBS") %>%
          select(endDateTime, secPrecipBulk) %>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("secPrecipBulk"), sum, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        # Wind Speed
        windspeed <- neonstore::neon_table(table = "2DWSD_30min-basic", site = "BARC")%>%  
          select(endDateTime, windSpeedMean)%>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("windSpeedMean"), sum, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        # Pressure
        pressure <- neonstore::neon_table(table = "BP_30min-basic", site = "BARC") %>%
          select(endDateTime, staPresMean)%>%
          mutate(time = lubridate::floor_date(endDateTime, unit = "hour"))%>%
          select(-endDateTime)%>%
          group_by(time) %>%
          summarize_at(c("staPresMean"), mean, na.rm = TRUE)%>%
          arrange(time)%>%
          mutate(time = time - 5*3600)
        
        
        met_target <- full_join(radiation, airtemp, by = "time")%>%
          full_join(., humidity, by = "time")%>%
          full_join(., windspeed, by = "time")%>%
          full_join(., precip, by = "time")%>%
          full_join(., pressure, by = "time")%>%
          rename(ShortWave = inSWMean, LongWave = inLWMean, AirTemp = tempSingleMean,
                 RelHum = RHMean, WindSpeed = windSpeedMean, Rain = secPrecipBulk, Pressure = staPresMean)%>%
          mutate(Rain = Rain/3600)%>% # convert from mm/hr to m/d 
          mutate(Pressure = Pressure*1000)%>%
          mutate(ShortWave = ifelse(ShortWave<=0,0,ShortWave))%>%
          filter(time >= "2018-08-06")
        
        met_target <- as.data.frame(met_target)
        write_csv(met_target, "./data/met_data_w_gaps.csv")
        
        
        # Download newest products
        neonstore::neon_download(product = buoy_products, site = siteID)
        
        # Store the NEON buoy data products
        neonstore::neon_store("TSD_30_min-basic")
        neonstore::neon_store("dep_secchi-basic")
        
        # Water temperature by depth
        # ----------------------------------------------------------------------------------------
        water_temp <- neonstore::neon_table(table = "TSD_30_min-basic", site = "SUGG")%>% 
          select(endDateTime, thermistorDepth, tsdWaterTempMean) %>%
          arrange(endDateTime, thermistorDepth)%>%
          rename(depth = thermistorDepth)%>%
          rename(value = tsdWaterTempMean)%>%
          rename(timestamp = endDateTime)%>%
          mutate(variable = "temperature",
                 hour = lubridate::hour(timestamp- 5*3600),
                 method = "thermistor",
                 value = ifelse(is.nan(value), NA, value))%>%
          select(timestamp, hour, depth, value, variable, method)%>%
          mutate(timestamp = timestamp - 5*3600)
        
        write_csv(water_temp, "./data/temp_data.csv")
        
        
        secchi <- neonstore::neon_table(table = "dep_secchi-basic", site = "SUGG") %>%
                select(date, secchiMeanDepth) %>%
                arrange(date)%>%
                mutate(hour = lubridate::hour(date- 5*3600))%>%
                mutate(depth = NA)%>%
                rename(timestamp = date)%>%
                rename(value = secchiMeanDepth)%>%
                mutate(variable = "secchi",
                       method = "secchi")%>%
                select(timestamp, hour, depth, value, variable, method)%>%
                mutate(timestamp = timestamp - 5*3600)
        
        kw <- secchi %>% select(value) %>% na.omit(.)%>%
                summarize(kw = 1.7/mean(value))
        
        write_csv(secchi, "./data/secchi_data.csv")

}