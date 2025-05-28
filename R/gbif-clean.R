clean_occ <- function(occ_data) {
  # basic filter
  occ_data <- occ_data |>
    filter(basisofrecord == "HUMAN_OBSERVATION") |>
    filter(is.na(coordinateuncertaintyinmeters) | coordinateuncertaintyinmeters <= 10000)
  if (nrow(occ_data) == 0) {
    cli_alert_danger("No records after filtering.")
    return(NULL)
  }
  # clean coordinates
  flags <- clean_coordinates(
    x = occ_data,
    lon = "decimallongitude",
    lat = "decimallatitude",
    countries = "countrycode",
    species = "species",
    tests = c("capitals", "centroids", "duplicates", "equal", "gbif", "institutions", "seas", "zeros")
  )
  occ_data_cleaned <- occ_data[flags$.summary, ]
  return(occ_data_cleaned)
}


clean_occ_files <- function(input_dir, output_dir) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  rds_files <- list.files(input_dir, pattern = "\\.rds$", full.names = TRUE)
  for (file in rds_files) {
    message("Processing: ", basename(file))
    data <- readRDS(file)
    cleaned_data <- clean_occ(data)
    output_path <- file.path(output_dir, basename(file))
    saveRDS(cleaned_data, output_path)
  }
}