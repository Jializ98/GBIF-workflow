library(arrow)
library(rgbif)

# Function to split a vector into chunks
split_into_chunks <- function(x, chunk_size) {
  split(x, ceiling(seq_along(x) / chunk_size))
}

# Function to get the total occurrence count
get_total_occurrence_count <- function(taxon_chunks) {
  total_occurrence_count <- 0
  for (chunk in taxon_chunks) {
    taxon_list <- str_c(chunk, collapse = ";")
    count <- occ_count(
      taxonKey = taxon_list,
      hasCoordinate = TRUE,
      hasGeospatialIssue = FALSE,
      occurrenceStatus = "PRESENT",
      basisOfRecord = "HUMAN_OBSERVATION"
    )
    total_occurrence_count <- total_occurrence_count + count
  }
  return(total_occurrence_count)
}

# Function to submit the occurrence data download request
submit_occ_download <- function(lotvs_backbone_usage_key) {
  occ_download(
    pred_in("taxonKey", lotvs_backbone_usage_key),
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred("occurrenceStatus", "PRESENT"),
    pred("basisOfRecord", "HUMAN_OBSERVATION"),
    format = "SIMPLE_PARQUET"
  )
}

# Function to downloading customized GBIF data
gbif_custom_download <- function(lotvs_backbone_path) {
  # Load lotvs_backbone from provided path
  lotvs_backbone <- read_rds(lotvs_backbone_path)
  taxon_chunks <- split_into_chunks(lotvs_backbone$usageKey, 1000)

  total_occurrence_count <- get_total_occurrence_count(taxon_chunks)
  print(total_occurrence_count)

  submit_occ_download(lotvs_backbone$usageKey)
}

# Function to read GBIF data and write it into separate files
gbif_custom_retrieve <- function(taxonomy_file_path, data_file_path, species_dir_path, genus_dir_path) {
  # Read taxonomy data
  lotvs_backbone_taxonomy <- readRDS(taxonomy_file_path)
  local_df <- open_dataset(paste0(data_file_path, "/occurrence.parquet"),
    factory_options = list(exclude_invalid_files = TRUE)
  )

  write_chunks(
    local_df, lotvs_backbone_taxonomy |> filter(rank == "SPECIES"),
    "SPECIES", species_dir_path, 100
  )
  write_chunks(
    local_df, lotvs_backbone_taxonomy |> filter(rank == "GENUS"),
    "GENUS", genus_dir_path, 20
  )
}

# Utility function to write dataset chunks based on taxonomic rank
write_chunks <- function(local_df, lotvs_backbone_taxonomy, rank, dir_path, chunk_size) {
  dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

  if (rank == "SPECIES") {
    keys <- lotvs_backbone_taxonomy %>%
      pull(usageKey)
    column <- "specieskey"
  } else {
    keys <- lotvs_backbone_taxonomy %>%
      pull(genus)
    column <- "genus"
  }

  keys_chunks <- split(keys, ceiling(seq_along(keys) / chunk_size))

  walk2(
    keys_chunks,
    seq_along(keys_chunks),
    function(keys_chunk, idx) {
      message("Writing ", rank, " chunk ", idx, " of ", length(keys_chunks))
      local_df %>%
        filter(!!sym(column) %in% keys_chunk) %>%
        write_dataset(
          path = dir_path,
          format = "parquet",
          partitioning = column,
          existing_data_behavior = "overwrite"
        )
    }
  )
}

# If run with command line arguments (i.e., Slurm), execute the function
if (interactive() == FALSE && is.null(knitr::opts_knit$get("rmarkdown.pandoc.to"))) {
  # Define file paths
  lotvs_backbone_path <- here("data/taxonomy/test-taxonomy.rds")
  data_dir_unzipped <- here("data/raw-gbif/customized/parquet/0011898-250426092105405")
  species_path <- here("data/occurrence/gbif-custom/species")
  genus_path <- here("data/occurrence/gbif-custom/genus")

  gbif_custom_retrieve(lotvs_backbone_path, data_dir_unzipped, species_path, genus_path)
}
