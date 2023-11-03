test_that("multiplication works", {
  skip()
  path <- "~/shared/gwas_sumstats/updated_sumstats/bip2021/"
  dir <- withr::local_tempdir()
  paths <- tidyGWAS_paths(dir)
  paths$hivestyle <- "~/shared/gwas_sumstats/updated_sumstats/bip2021/tidyGWAS_hivestyle/"


  job <- run_sbayesrc("~/shared/gwas_sumstats/updated_sumstats/bip2021/")
  paths


})
