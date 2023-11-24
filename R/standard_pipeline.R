

# pf <- "~/shared/gwas_sumstats/updated_sumstats/accumbens/"
run_defaults <- function(parent_folder, steps = c("ldsc", "clumping")) {
    paths <- tidyGWAS_paths(parent_folder)

    ldsc_code <- run_ldsc(pf)
    code <- glue::glue("downstreamGWAS::run_ldsc(\"{fs::path_real(paths$base)}\")")
    glue::glue("Rscript --quiet -e '{code}'")
    run_ldsc_script <- glue::glue("sh {fs::path_real(fs::path(paths$ldsc, 'run_ldsc.sh'))}")



}
