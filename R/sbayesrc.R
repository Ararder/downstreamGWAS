utils::globalVariables(c("multi_allelic", "EffectAllele", "OtherAllele","EAF", "B", "SE", "se", "p"))

#' Transform tidyGWAS to COJO .ma format
#'
#' @param paths crated by `tidyGWAS_paths()`
#'
#' @return a list of filepaths
#' @export
#'
#' @examples \dontrun{
#'   tidyGWAS_paths("/home/arvhar/tidyGWAS_cleaned/height2022")
#' }
#'
to_ma <- function(paths) {
  LDdir <- paths$system_paths$gctb$rc_ldmatrix

  workdir <- fs::dir_create(paths$sbayesrc)



  first <- arrow::open_dataset(paths$hivestyle) |>
    dplyr::filter(!multi_allelic) |>
    dplyr::select(SNP = RSID, A1 = EffectAllele, A2 = OtherAllele, freq=EAF, b=B, se=SE, p=P, N) |>
    dplyr::collect()


  second <- arrow::open_dataset(paths$hivestyle) |>
    dplyr::filter(multi_allelic) |>
    dplyr::select(SNP = RSID, A1 = EffectAllele, A2 = OtherAllele, freq=EAF, b=B, se=SE, p=P, N) |>
    dplyr::collect() |>
    dplyr::group_by(SNP) |>
    dplyr::slice_min(se, n = 1) |>
    dplyr::slice_max(N, n = 1) |>
    dplyr::slice_min(p, n = 1)

  dplyr::bind_rows(first, second) |>
    arrow::write_csv_arrow(paths$ma_file)


  SBayesRC::tidy(
    mafile = paths$ma_file,
    LDdir = LDdir,
    output = paths$ma_file
  )


}


create_imputation_sbayesrc <- function(paths, threads = 16) {
  gctb <- paths$system_paths$gctb$exe
  ldm <- paths$system_paths$gctb$rc_ldmatrix
  out <- paths$imp_ma_file
  glue::glue("{gctb} --ldm-eigen {ldm} --gwas-summary {paths$ma_file} --impute-summary --out {out} --thread {threads}")
}

create_rescaling_sbayesr <- function(paths, threads = 16) {
  gctb <- paths$system_paths$gctb$exe
  ldm <- paths$system_paths$gctb$rc_ldmatrix
  ma <-  paths$imp_ma_file
  annot <- paths$system_paths$gctb$annot_file
  out <- fs::path(paths$sbayesrc, "sumstats_sbrc")
  glue::glue("{gctb} --ldm-eigen {ldm} --gwas-summary {ma} --sbayes RC --annot {annot} --out {out} --thread {threads}")

}



#' Create a slurmjob for SbayesRC
#'
#' @param path filepath to tidyGWAS_hivestyle folder
#'
#' @return a slurm script
#' @export
#'
#' @examples \dontrun{
#' run_sbayesrc("path/to/tidyGWAS_hivestyle")
#' }
run_sbayesrc <- function(path) {
  paths <- tidyGWAS_paths(path)
  fs::dir_create(paths$sbayesrc)
  out_slurm <- fs::path(fs::path_real(paths$sbayesrc), "slurm-%j.out")

  slurm_header <- c(
    "#!/bin/bash",
  "#SBATCH --mem=100gb",
  "#SBATCH --time=72:00:00",
  "#SBATCH --cpus-per-task=16",
  glue::glue("#SBATCH --output={out_slurm}")
  )


  job <- glue::glue("Rscript -e 'downstreamGWAS::to_ma(downstreamGWAS::tidyGWAS_paths(commandArgs(trailingOnly=TRUE)[2]))'",) |>
    paste0(" --args ", path)

  impute_job <- create_imputation_sbayesrc(paths)
  rescaling_job <- create_rescaling_sbayesr(paths)


  slurm_out <- fs::path(paths$sbayesrc, glue::glue("{paths$name}_sbayesrc.sh"))
  writeLines(c(slurm_header, "\n", job, impute_job, rescaling_job), slurm_out)
  slurm_out

}



