utils::globalVariables(c("RSID"))

#' Convert parquet hivestyle data to csv for LD-score regression
#'
#' @param dir filepath to the directory parent directory of tidyGWAS_hivestyle
#'
#' @return commandline code
#' @export
#'
#' @examples \dontrun{
#' code <- to_ldsc("files/sumstats/height2022")
#' }

to_ldsc <- function(dir) {
  paths <- tidyGWAS_paths(dir)
  hm3 <- arrow::read_tsv_arrow(paths$system_paths$ldsc$hm3)
  dset <- arrow::open_dataset(paths$hivestyle)

  if("B" %in% dset$schema$names)  {
    effect <- "B"
  } else if("Z" %in% dset$schema$names) {
    effect <- "Z"
  } else {
    stop("Both B and Z is missing from sumstats. Cannot create LDSC format")
  }

  dplyr::filter(dset, RSID %in% hm3$SNP) |>
    dplyr::collect() |>
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N"))) |>
    data.table::fwrite(paths$ldsc_temp, sep = "\t")


}


run_ldsc <- function(paths) {
  paths <- tidyGWAS_paths(paths)

  prepare_sumstats <- glue::glue("R -e 'downstreamGWAS::to_ldsc(commandArgs(trailingOnly = TRUE)[1])'")|>
    paste0(" --args ", paths$base)
  job1 <- glue::glue(
    "{paths$system_paths$ldsc$munge_sumstats.py} ",
    "--sumstats {paths$ldsc_temp} ",
    "--out {paths$ldsc_munged} ",
    "--snp RSID ",
    "--a1 EffectAllele ",
    "--a2 OtherAllele ",
    "--merge-alleles {paths$system_paths$ldsc$hm3} ",
    "--chunksize 500000 "

  )
  job2 <- glue::glue(
    "{paths$system_paths$ldsc$ldsc.py} ",
    "--h2 {paths$ldsc_munged}.sumstats.gz ",
    "--ref-ld-chr {paths$system_paths$ldsc$eur$wld} ",
    "--w-ld-chr {paths$system_paths$ldsc$eur$wld} ",
    "--out {paths$ldsc_h2}"

  )

  c(prepare_sumstats, job1, glue::glue("rm {paths$ldsc_temp}"), job2)


}

#' Parse the output of LDSC --h2
#'
#' @param path to log file
#'
#' @return a tibble
#' @export
#'
#' @examples \dontrun{
#' parse_ldsc_h2("ldsc_h2.log")
#' }
parse_ldsc_h2 <- function(path) {

  dataset_name <- fs::path_file(fs::path_dir(fs::path_dir(fs::path_dir(path))))
  df <- readLines(path)

  if(length(df) != 32){
    return(dplyr::tibble(dataset_name=dataset_name, obs_h2=NA_real_,
                         obs_se=NA_real_, lambda=NA_real_,
                         mean_chi2=NA_real_, intercept=NA_real_,
                         intercept_se=NA_real_, ratio=NA_real_))
  }

  obs_h2 <- as.numeric(stringr::str_extract(df[26], "\\d{1}\\.\\d{1,5}"))

  obs_se <- stringr::str_extract(df[26], "\\(\\d{1}\\.\\d{1,5}") %>%
    stringr::str_remove(., "\\(") %>%
    as.numeric()

  lambda <- stringr::str_extract(df[27], " \\d{1}\\.\\d{1,5}") %>%
    as.numeric()

  mean_chi2 <- stringr::str_extract(df[28], " \\d{1}\\.\\d{1,5}") %>%
    as.numeric()

  intercept <- stringr::str_extract(df[29], " \\d{1}\\.\\d{1,5}") %>%
    as.numeric()

  intercept_se <- stringr::str_extract(df[29], "\\(\\d{1}\\.\\d{1,5}") %>%
    stringr::str_remove(., "\\(") %>%
    as.numeric()
  ratio <- stringr::str_extract(df[30], " \\d{1}\\.\\d{1,5}") %>%
    as.numeric()

  dplyr::tibble(dataset_name, obs_h2, obs_se, lambda, mean_chi2, intercept, intercept_se, ratio)
}











#
# cleansumstats_pldsc <- function(paths, ldscores) {
#
#
#   sumstats <- paste0(paths[["ldsc_sumstats"]], ".sumstats.gz")
#
#   # Check that ldscores are a vector of characters
#   if(!missing(ldscores)) stopifnot(is.character(ldscores))
#
#   # create output directories
#   outdirs <- purrr::map_chr(ldscores, \(ld) create_pldsc_names(paths = paths, ldscores = ld))
#
#   # Create all the pldsc jobs
#   jobs <- purrr::map2(ldscores, outdirs,  \(ldscores, outdir) run_pldsc(
#     sumstats = sumstats,
#     outdir = outdir,
#     ldscores = ldscores
#   )) |>
#     purrr::reduce(c)
#
#
#   # create the output directories, write out all the jobs,
#   fs::dir_create(outdirs, recurse = TRUE)
#   writeLines(jobs, paths[['pldsc_slurm']])
#   glue::glue("chmod 700 {paths[['pldsc_slurm']]} && {paths[['pldsc_slurm']]}")
#
#   paths[['pldsc_slurm']]
#
# }



# run_pldsc <- function(sumstats, outdir, ldscores) {
#   if(ldscores[1]== "") {
#     name <- "baseline_annotations"
#     job1 <- ldsc_partitioned(
#       outname = name,
#       sumstats = sumstats,
#       outdir = outdir,
#       base_ldscore = Sys.getenv("pldsc_base_ldscore"),
#       weights = Sys.getenv("pldsc_weights"),
#       freq = Sys.getenv("pldsc_freq")
#     )
#   } else {
#
#     all_celltypes <- fs::dir_ls(ldscores)
#     job1 <- purrr::map2(
#       all_celltypes,
#       fs::path_file(all_celltypes),
#       \(celltype, name) ldsc_partitioned(
#         ld1 = celltype,
#         outname = name,
#         sumstats = sumstats,
#         outdir = outdir,
#         base_ldscore = Sys.getenv("pldsc_base_ldscore"),
#         weights = Sys.getenv("pldsc_weights"),
#         freq = Sys.getenv("pldsc_freq")
#       )
#     )
#   }
#
#   purrr::map_chr(job1, \(code) glue::glue("sbatch --time=00:30:00 --output={outdir}/slurm-%j.out --mem=4gb --wrap='module unload python && module load ldsc && {code}'"))
#
#
# }
#
# ldsc_partitioned <- function(
#     ld1,
#     outname,
#     sumstats,
#     outdir,
#     base_ldscore,
#     weights,
#     freq
# )
# {
#
#   if(!missing(ld1)) {
#     glue::glue(
#       "ldsc.py ",
#       "--h2 {sumstats} ",
#       "--ref-ld-chr {base_ldscore},{ld1}/baseline. ",
#       "--w-ld-chr {weights} ",
#       "--overlap-annot ",
#       "--frqfile-chr {freq} ",
#       "--print-coefficients ",
#       "--out {outdir}/{outname}"
#     )
#
#   } else {
#     glue::glue(
#       "ldsc.py ",
#       "--h2 {sumstats} ",
#       "--ref-ld-chr {base_ldscore} ",
#       "--w-ld-chr {weights} ",
#       "--overlap-annot ",
#       "--frqfile-chr {freq} ",
#       "--print-coefficients ",
#       "--out {outdir}/{outname}"
#     )
#   }
#
# }
