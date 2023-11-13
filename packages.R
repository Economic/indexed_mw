## library() calls go here
library(targets)
library(tarchetypes)

# conflicts and other options
library(conflicted)
conflict_prefer("filter", "dplyr", quiet = TRUE)
conflict_prefer("lag", "dplyr", quiet = TRUE)
options(usethis.quiet = TRUE)

# packages for this analysis
suppressPackageStartupMessages({
  library(tidyverse)
  library(realtalk)
  library(readxl, include.only = "read_excel")
  library(bea.R)
  library(epiextractr)
  library(haven)
})