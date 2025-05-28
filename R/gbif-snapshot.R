library(arrow)
library(aws.s3)
library(CoordinateCleaner)

# Utility function to set up the S3 bucket connection
setup_s3_bucket <- function(bucket_name, endpoint, region, proxy = NULL) {
  if (!is.null(proxy)) {
    s3_bucket(
      bucket = bucket_name,
      endpoint_override = endpoint,
      region = region,
      proxy_options = proxy
    )
  } else {
    s3_bucket(
      bucket = bucket_name,
      endpoint_override = endpoint,
      region = region
    )
  }
}

# Function to download and filter GBIF snapshot
gbif_snapshot_download <- function(
    bucket_fs,
    snapshot_path,
    local_save_dir,
    filter_kingdom = "Plantae",
    filter_phylum = "Tracheophyta") {
  if (!dir.exists(local_save_dir)) {
    dir.create(local_save_dir, recursive = TRUE, showWarnings = FALSE)
  }

  filtered_data <- open_dataset(snapshot_path) |>
    filter(kingdom == filter_kingdom, phylum == filter_phylum)

  filtered_data |>
    write_dataset(local_save_dir, format = "parquet", partitioning = c("class", "order"))
}


# Function to retrieve GBIF occurrences
gbif_snapshot_retrieve <- function(save_path, gbif_snapshot_path, taxonomy_list) {
  dir.create(save_path, recursive = TRUE, showWarnings = FALSE)

  class_order_list <- taxonomy_list |>
    distinct(class, order)

  for (i in seq_len(nrow(class_order_list))) {
    class_val <- class_order_list$class[i]
    order_val <- class_order_list$order[i]
    parquet_path <- file.path(gbif_snapshot_path, paste0("class=", class_val), paste0("order=", order_val))
    taxonomy_record <- taxonomy_list |>
      filter(class == class_val, order == order_val)
    process_taxonomy_record(taxonomy_record, parquet_path, save_path)
  }
}

# Function to process a taxonomy record
process_taxonomy_record <- function(taxonomy_record, parquet_path, save_path) {
  cli_text("Reading GBIF parquet: {.path {parquet_path}}")
  cli_text("No. of taxonomy records: {nrow(taxonomy_record)}")

  species_keys <- taxonomy_record |>
    filter(rank == "SPECIES") |>
    pull(usageKey) |>
    unique()
  genus_list <- taxonomy_record |>
    filter(rank == "GENUS") |>
    pull(genus) |>
    unique()

  cli_text("Number of species keys: {length(species_keys)}")
  cli_text("Number of genus names: {length(genus_list)}")

  all_occ <- open_dataset(parquet_path) |>
    filter(specieskey %in% species_keys | genus %in% genus_list) |>
    filter(!is.na(decimallatitude) & !is.na(decimallongitude)) |>
    filter(occurrencestatus == "PRESENT") |>
    select(
      species, genus, family, specieskey, decimallongitude, decimallatitude,
      countrycode, taxonkey, basisofrecord, occurrencestatus,
      lastinterpreted, issue, year, coordinateprecision, coordinateuncertaintyinmeters
    ) |>
    collect()

  for (key in species_keys) {
    species_save_path <- file.path(save_path, paste0("specieskey_", key, ".rds"))

    if (file.exists(species_save_path)) {
      cat(paste0("File already exists: ", species_save_path, "\n"))
      next
    }

    species_occ <- all_occ |> filter(specieskey == key)
    saveRDS(species_occ, species_save_path, compress = TRUE)
    cli_text("Saved species key: {.val {key}} with {nrow(species_occ)} records")
  }

  for (genus_name in genus_list) {
    genus_save_path <- file.path(save_path, paste0("genus_", genus_name, ".rds"))

    if (file.exists(genus_save_path)) {
      cat(paste0("File already exists: ", genus_save_path, "\n"))
      next
    }

    genus_occ <- all_occ |> filter(genus == genus_name)
    saveRDS(genus_occ, genus_save_path, compress = TRUE)
    cli_text("Saved genus: {.val {genus_name}} with {nrow(genus_occ)} records")
  }

  cli_alert_success("All taxonomy records processed.")
}

# For running on Slurm
args <- commandArgs(trailingOnly = TRUE)

if (interactive() == FALSE && length(args) > 0) {
  mode <- args[1]

  if (mode == "download") {
    bucket_fs <- setup_s3_bucket(
      bucket_name = "gbif-open-data-us-east-1",
      endpoint = "https://s3.us-east-1.amazonaws.com",
      region = "us-east-1",
      proxy = "http://proxy1.arc-ts.umich.edu:3128"
    )

    gbif_snapshot_url <- bucket_fs$path("occurrence/2025-05-01/occurrence.parquet")
    local_save_dir <- here("data-raw/gbif/Vascular-Plants-2025-05-01")

    gbif_snapshot_download(bucket_fs, gbif_snapshot_url, local_save_dir)
  }

  if (mode == "retrieve") {
    taxonomy_list <- readRDS(here("data/taxonomy/lotvs-gbif-taxonomy.rds"))
    snapshot_path <- here("data-raw/gbif/Vascular-Plants-2025-05-01")
    save_path <- here("data/occurrence/gbif-snapshot")
    clean <- TRUE

    gbif_snapshot_retrieve(save_path, snapshot_path, taxonomy_list)
  }
}
