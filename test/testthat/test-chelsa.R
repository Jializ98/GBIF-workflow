test_that("terra::extract gives consistent results", {
  chelsa_dir <- here("data-raw/chelsa")
  lotvs_file <- here("data/community/lotvs/lotvs_dm.rds")
  
  expect_error(
    chelsa_ras <- load_chelsa(chelsa_vars = c("bio1", "bio12"), chelsa_dir = chelsa_dir),
    NA
  )
  # Load and preprocess the LOTVS dataset
  lotvs <- read_rds(lotvs_file) |>
    dm_flatten_to_tbl("tbl_composition", .recursive = TRUE) |>
    # Remove any columns starting with "bio" followed by a number, as these bioclimatic variables are inaccurate
    select(-matches("^bio\\d+"))
  expect_error(
    lotvs_chelsa <- extract_chelsa_occ(
      chelsa_ras = chelsa_ras,
      occ_data = lotvs
    ),
    NA
  )
  extract_results <- lotvs_chelsa$bio1[1:2]
  expected_results <- c(8.75, 8.75)
  
  expect_equal(extract_results, expected_results, tolerance = 1e-8)
})
