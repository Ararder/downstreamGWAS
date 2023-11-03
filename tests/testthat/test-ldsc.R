test_that("munge LDSC works", {
  skip()
  dir <- withr::local_tempdir()
  newdir <- fs::dir_copy("~/shared/gwas_sumstats/updated_sumstats/adhd2023/", dir)

  paths <- tidyGWAS_paths(newdir)

  job <- run_ldsc(paths)
  writeLines(job, fs::path(paths$ldsc, "run_ldsc.sh"))

})


