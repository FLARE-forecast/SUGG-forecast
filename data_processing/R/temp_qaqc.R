temp_qaqc <- function(realtime_file,
                      surface_sonde,
                      profiles,
                      qaqc_file,
                      maintenance_file,
                      input_file_tz,
                      focal_depths,
                      local_tzone,
                      config){
  
  d <- readr::read_csv(realtime_file)
  d_therm <- d %>% dplyr::rename(timestamp = timestamp,
                                 depth = depth,
                                 value = value) %>%
    dplyr::mutate(variable = "temperature",
                  method = "thermistor",
                  value = ifelse(is.nan(value), NA, value),
                  hour = lubridate::hour(timestamp))%>%
    rename(date = timestamp)%>%
    filter(date < "2020-12-05 00:00:00")
  
  d_top <- readr::read_csv(surface_sonde)

  d_therm_top <- d_top %>% select(-X1)%>%
    dplyr::rename(timestamp = dateTime,
                                 depth = sensorDepth,
                                 value = waterTemp) %>%    
    dplyr::mutate(timestamp = mdy_hm(timestamp))%>%
    rename(date = timestamp)%>%
    arrange(date)%>%
    na.omit(.)%>%
    mutate(time = lubridate::floor_date(date, unit = "hour"))%>%
    group_by(time) %>%
    summarize_at(c("value"), mean, na.rm = TRUE)%>%
    mutate(variable = "temperature",
           method = "sonde",
           value = ifelse(is.nan(value), NA, value),
           value = ifelse(value ==0,NA,value),
           value = ifelse(value ==25, NA, value),
           hour = lubridate::hour(time),
           depth = 0.5)%>%
    select(time, hour, depth, value, variable, method)%>%
    rename(date = time)
  
  
  d_prof <- readr::read_csv(profiles)%>%
    rename(date = timestamp)
  
  d <- d_therm %>% mutate(depth = as.numeric(depth))
  d_top <- d_therm_top %>% mutate(depth = as.numeric(depth))
  d_prof <- d_prof %>% mutate(depth = as.numeric(depth))
  
  d <- bind_rows(d,d_top)
  d <- bind_rows(d, d_prof)
  
  write_csv(d, paste0(config$qaqc_data_location,"/observations_postQAQC_long.csv"))
}