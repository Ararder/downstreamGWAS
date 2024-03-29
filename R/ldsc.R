utils::globalVariables(c("RSID",".", "job"))



ldsc_call <- function(workdir) {

  paths <- get_system_paths()


  ldsc_path <- fs::path(paths$containers, paths$ldsc$container)
  singularity_start <- singularity_mount(workdir)

  glue::glue("{singularity_start}{ldsc_path} python /tools/ldsc")

}



#' Run munge LDSC and LDSC -h2 from tidyGWAS
#'
#' @param parent_folder Folder to sumstats cleaned with tidyGWAS. see [tidyGWAS::tidyGWAS()] output_folder
#' @param write_script Should the code be written to a bash script?
#'
#' @return a path to slurm script
#' @export
#'
#' @examples \dontrun{
#' script_location <- run_ldsc("my_sumstats/tidygwas/height2022")
#' }
run_ldsc <- function(parent_folder, write_script = c("no", "yes")) {
  write_script <- rlang::arg_match(write_script)
  dep <- get_dependencies()
  paths <- tidyGWAS_paths(parent_folder)

  prepare_sumstats <- glue::glue("R -e 'downstreamGWAS::to_ldsc(commandArgs(trailingOnly = TRUE)[1])'")|>
    paste0(" --args ", paths$base)


  munge <- glue::glue(
    "{ldsc_call(paths$ldsc)}/munge_sumstats.py ",
    "--sumstats /mnt/{fs::path_file(paths$ldsc_temp)} ",
    "--out /mnt/{fs::path_file(paths$ldsc_munged)} ",
    "--snp RSID ",
    "--a1 EffectAllele ",
    "--a2 OtherAllele ",
    "--merge-alleles /src/{paths$system_paths$ldsc$hm3} ",
    "--chunksize 500000 && rm /mnt/{fs::path_file(paths$ldsc_temp)}"
  )



  h2 <- glue::glue(
    "{ldsc_call(paths$ldsc)}/ldsc.py ",
    "--h2 /mnt/ldsc.sumstats.gz ",
    "--ref-ld-chr /src/{paths$system_paths$ldsc$eur_wld} ",
    "--w-ld-chr /src/{paths$system_paths$ldsc$eur_wld} ",
    "--out /mnt/{fs::path_file(paths$ldsc_h2)}"

  )

# out ---------------------------------------------------------------------


  code <- c(dep, prepare_sumstats, munge, h2)
  if(write_script =="yes") {
    writeLines(code, fs::path(paths$ldsc, "run_ldsc.sh"))
    return(fs::path(paths$ldsc, "run_ldsc.sh"))
  } else {

    return(code)
  }


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

  obs_se <- stringr::str_extract(df[26], "\\(\\d{1}\\.\\d{1,5}") |>
    stringr::str_remove(string = _, pattern = "\\(") |>
    as.numeric()

  lambda <- stringr::str_extract(df[27], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  mean_chi2 <- stringr::str_extract(df[28], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  intercept <- stringr::str_extract(string = df[29], pattern = " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  intercept_se <- stringr::str_extract(string = df[29],pattern =  "\\(\\d{1}\\.\\d{1,5}") |>
    stringr::str_remove(string = _, pattern =  "\\(") |>
    as.numeric()
  ratio <- stringr::str_extract(df[30], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  dplyr::tibble(dataset_name, obs_h2, obs_se, lambda, mean_chi2, intercept, intercept_se, ratio)
}



#' Estimate genetic correlation between two GWAS using LDSC
#'
#' @param parent_folder filepath to tidyGWAS output
#' @param parent_folder2 filepath to tidyGWAS output
#' @param outdir Folder to save logfile in
#' @param workdir temporary working folder
#'
#' @return code to run in slurm
#' @export
#'
#' @examples \dontrun{
#' ldsc_rg("my_sumstats/tidygwas/height2022", "my_sumstats/tidygwas/height2022", "~/")
#' }
ldsc_rg <- function(parent_folder, parent_folder2, outdir, workdir=tempdir()) {
  f1 <- tidyGWAS_paths(parent_folder)
  f2 <- tidyGWAS_paths(parent_folder2)
  system_paths <- get_system_paths()

  create_dir <- glue::glue("mkdir -p {workdir}")
  p1 <- paste0(f1$ldsc_munged, ".sumstats")
  p2 <- paste0(f2$ldsc_munged, ".sumstats")
  new_1 <- glue::glue("{f1$name}.sumstats")
  new_2 <- glue::glue("{f2$name}.sumstats")


  move_files <- glue::glue("cp {p1} {workdir}/{new_1} && cp {p2} {workdir}/{new_2}")
  name <- paste0(f1$name, "_X_", f2$name)
  main_code <- glue::glue(
    "{ldsc_call(workdir)}/ldsc.py ",
    "--rg {new_1},{new_2} ",
    "--ref-ld-chr /src/{system_paths$ldsc$eur_wld} ",
    "--w-ld-chr /src/{system_paths$ldsc$eur_wld} ",
    "--out {name} "
  )
  c(move_files, "\n", main_code)

}



#' run Stratified LDscore regression on tidyGWAS formatted sumstats
#'
#' @inheritParams run_ldsc
#' @param ldscore which cell-type atlas to use. Has to match an entry in the reference file
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' run_sldsc("path_to_tidyGWAS")
#' }
run_sldsc <- function(parent_folder, ldscore = c("superclusters", "clusters"), write_script = c("no", "yes")) {

  # parse input args
  write_script <- rlang::arg_match(write_script)
  ldscore <- rlang::arg_match(ldscore)
  paths <- tidyGWAS_paths(parent_folder)

  # get ldscores for cell-type annotation
  ref <- paths$system_paths$reference
  ldscores_path <- paths$system_paths$sldsc$cell_types[[ldscore]]

  # have to construct filepaths starting from .../ldsc/, as this is was the container observes
  celltypes <- fs::path("/src/", withr::with_dir(ref,fs::dir_ls(ldscores_path)), "baseline.")
  celltype_names <- fs::path_file(fs::path_dir(celltypes))

  # slsc requires the 'base' ldscores, weights and freq
  base <- fs::path("/src/", paths$system_paths$sldsc$eur$base_ldscore)
  weights <- fs::path("/src/", paths$system_paths$sldsc$eur$weights)
  freq <-  fs::path("/src/", paths$system_paths$sldsc$eur$freq)

  # need to make sure the output directory exists
  output_dir <- fs::dir_create(fs::path(paths$ldsc, "sldsc", ldscore))




  jobs <- purrr::map2(celltypes,celltype_names,  \(annot, name) stratified_ldsc(
    # first argument - annotation ldscore
    annot_ldscore = annot,
    out = glue::glue("/mnt/sldsc/{ldscore}/", name),

    # container call and reference files
    ldsc_exe = glue::glue("{ldsc_call(paths$ldsc)}/ldsc.py "),
    sumstats = "/mnt/ldsc.sumstats.gz",
    baseline_ldscore = base,
    weights = weights,
    freq = freq
  )) |>
    purrr::reduce(c)

  code <- c(get_dependencies(), jobs)

  if(write_script == "yes" ){
    slurm <- fs::path(paths$ldsc, glue::glue("sldsc/{ldscore}/run_all.sh"))
    writeLines(code, slurm)
    return(slurm)

  } else {
    return(code)
  }

}


stratified_ldsc <- function(
    ldsc_exe,
    sumstats,
    annot_ldscore,
    baseline_ldscore,
    weights,
    freq,
    out

) {
  glue::glue(
    "{ldsc_exe}",
    "--h2 {sumstats} ",
    "--ref-ld-chr {annot_ldscore},{baseline_ldscore} ",
    "--w-ld-chr {weights} ",
    "--overlap-annot ",
    "--frqfile-chr {freq} ",
    "--print-coefficients ",
    "--out {out}"
  )
}


