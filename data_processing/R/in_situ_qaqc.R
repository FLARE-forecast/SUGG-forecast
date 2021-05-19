in_situ_qaqc <- function(insitu_obs_fname,
                         data_location,
                         cleaned_observations_file_long,
                         lake_name_code,
                         config){
  
  print("QAQC Bouy Temperature")
  
  d <- temp_qaqc(realtime_file = insitu_obs_fname[1],
                 surface_sonde = insitu_obs_fname[2],
                 profiles = insitu_obs_fname[3],
                 qaqc_file = cleaned_observations_file_long,
                 input_file_tz = "EST",
                 focal_depths,
                 local_tzone = config$local_tzone,
                 config = config)

  }
