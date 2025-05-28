test_that("gbif_snapshot_retrieve() works on snapshot and one taxonomy record", {
  skip_on_cran()
  # Set test paths
  gbif_snapshot_path <- here("data-raw/gbif/Vascular-Plants-2025-05-01")
  gbif_dir <- here::here("tests/testthat/tmp/gbif-snapshot")
  dir.create(gbif_dir, recursive = TRUE, showWarnings = FALSE)
  test_lotvs_backbone_taxonomy <- readRDS(here("tests/testthat/tmp/test-taxonomy.rds"))
  # Run function
  expect_error(
    gbif_snapshot_retrieve(
      save_path = gbif_dir,
      gbif_snapshot_path = gbif_snapshot_path,
      taxonomy_list = test_lotvs_backbone_taxonomy,
      clean = T
    ),
    NA
  )  
  
  gbif_dir <- here::here("tests/testthat/tmp/gbif-snapshot/noclean")
  expect_error(
    gbif_snapshot_retrieve(
      save_path = gbif_dir,
      gbif_snapshot_path = gbif_snapshot_path,
      taxonomy_list = test_lotvs_backbone_taxonomy,
      clean = F
    ),
    NA
  )
  
  expect_error(
    clean_occ_files(
      input_dir = gbif_dir, 
      output_dir = here("tests/testthat/tmp/gbif-snapshot/cleaned")
    ),
    NA
  )
  sp_example_function_clean <- readRDS("~/proj-grassland2/tests/testthat/tmp/gbif-snapshot/specieskey_2685484.rds")
  sp_example_files_clean <- readRDS("~/proj-grassland2/tests/testthat/tmp/gbif-snapshot/cleaned/specieskey_2685484.rds")
  expect_equal(
    nrow(sp_example_function_clean), nrow(sp_example_files_clean)
  )
})