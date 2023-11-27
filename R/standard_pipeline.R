


run_defaults <- function(parent_folder, steps = c("ldsc", "clumping")) {
  # pf <- "~/shared/gwas_sumstats/updated_sumstats/accumbens/"
    paths <- tidyGWAS_paths(parent_folder)

    ldsc_code <- run_ldsc(parent_folder, write_script = "yes")
    code <- glue::glue("downstreamGWAS::run_ldsc(\"{fs::path_real(paths$base)}\")")
    glue::glue("Rscript --quiet -e '{code}'")
    run_ldsc_script <- glue::glue("sh {fs::path_real(fs::path(paths$ldsc, 'run_ldsc.sh'))}")



}
