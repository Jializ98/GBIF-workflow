test_that("gbif_custom_download() works with a single taxon", {
  path <- here("tests/testthat/tmp/gbif-custom/occurrence.parquet")
  if (file.exists(path)) skip("Customized GBIF file already downloaded.")
  
  skip_on_cran()

  full_path <- here::here("data/taxonomy/lotvs-gbif-taxonomy.rds")
  tax_df <- readRDS(full_path)

  # Just pick one species and one genus
  one_species <- tax_df[tax_df$rank == "SPECIES", , drop = FALSE][1, , drop = FALSE]
  one_genus <- tax_df[tax_df$rank == "GENUS", , drop = FALSE][1, , drop = FALSE]

  # Combine into a single data frame
  test_taxon <- rbind(one_species, one_genus)

  # Save to a temp RDS file for testing
  test_tax_path <- here::here("tests/testthat/tmp/test-taxonomy.rds")
  dir.create(dirname(test_tax_path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(test_taxon, test_tax_path)

  expect_error(gbif_custom_download(test_tax_path), NA)
})


test_that("gbif_custom_retrieve() runs without error and creates output", {
  path <- here("tests/testthat/tmp/gbif-custom/occurrence.parquet")
  if (!file.exists(path)) skip("Customized GBIF file not found. Please check your GBIF account or use the link in example_parquet to download manually.")
  
  skip_on_cran()

  lotvs_backbone_path <- here::here("tests/testthat/tmp/test-taxonomy.rds")
  data_dir_unzipped   <- here::here("tests/testthat/tmp/gbif-custom")
  species_path <- here::here("tests/testthat/tmp/gbif-custom/test_species")
  genus_path   <- here::here("tests/testthat/tmp/gbif-custom/test_genus")

  # Create temp dirs
  dir.create(species_path, recursive = TRUE, showWarnings = FALSE)
  dir.create(genus_path, recursive = TRUE, showWarnings = FALSE)

  expect_error(
    gbif_custom_retrieve(lotvs_backbone_path, data_dir_unzipped, species_path, genus_path),
    NA
  )

  # Optionally test output files
  expect_true(length(list.files(species_path)) > 0)
  expect_true(length(list.files(genus_path)) > 0)
})
