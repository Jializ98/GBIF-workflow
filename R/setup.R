# Install and load 'zhulabtools' package
if (!require(devtools)) {
  install.packages("devtools")
}
devtools::install_github("zhulabgroup/zhulabtools@r")
library(zhulabtools)

# Manage project shared packages
check_install_packages(c("here", "tidyverse", "rgbif","testthat"))
load_packages(c("cli", "here", "tidyverse","rgbif", "testthat"))

# Create folder for symbolic links to raw data on Turbo

create_symlink_turbo("data/raw-gbif/snapshot", "datasets/vegetation/GBIF/Vascular-Plants-2025-05-01/")
