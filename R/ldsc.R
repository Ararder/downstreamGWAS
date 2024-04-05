utils::globalVariables(c("RSID",".", "job"))


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
run_ldsc <- function(parent_folder, ..., write_script = TRUE) {

  #check args
  stopifnot(rlang::is_bool(write_script))
  rlang::check_required(parent_folder)

  paths <- tidyGWAS_paths(parent_folder)

  prepare_sumstats <- glue::glue("R -e 'downstreamGWAS::to_ldsc(commandArgs(trailingOnly = TRUE)[1])'")|>
    paste0(" --args ", paths$base)


  # ldsc munge --------------------------------------------------------------


  sumstats <- in_work_dir(fs::path_file(paths$ldsc_temp))
  out <- in_work_dir(fs::path_file(paths$ldsc_munged))
  merge_alleles <- in_ref_dir(paths$system_paths$ldsc$hm3)

  code <- .munge(
    sumstats = sumstats,
    out = out,
    merge_alleles = merge_alleles
  )

  munge_code <- with_container(
    "python /tools/ldsc/munge.py ",
    paste0(code, " && rm /mnt/temp.csv.gz"),
    config_key = "ldsc",
    workdir = paths$ldsc
  )



  # ldsc h2 ----------------------------------------------------------------------

  sumstats <- in_work_dir("ldsc.sumstats.gz")
  ref_ld <- in_ref_dir(paths$system_paths$ldsc$eur_wld)
  out_h2 <- in_work_dir(fs::path_file(paths$ldsc_h2))

  code_h2 <- .h2(
    sumstats = sumstats,
    ref_ld_chr = ref_ld,
    w_ld_chr = ref_ld,
    out = out_h2
  )

  h2_full <- with_container(
    "python /tools/ldsc/ldsc.py",
    code_h2,
    config_key = "ldsc",
    workdir = paths$ldsc
  )

  complete_code <- c(munge_code, h2_full)


  # out ---------------------------------------------------------------------



  if(isTRUE(write_script)) {
    write_script_to_disk(complete_code, fs::path(paths$ldsc, "run_ldsc.sh"))

  } else {

    complete_code
  }


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


#' Run stratified LDscore regression using the --h2-cts flag
#'
#' @param parent_folder the filepath to a [tidyGWAS::tidyGWAS()] folder
#' @param cts_file filepath to cts file
#' @param write_script should the code be written to a file?
#' @param ... optional slurm argument
#' @param out filepath to output directory. Defaults to "sldsc" in the ldsc folder
#'
#' @return a character vector
#' @export
#'
#' @examples \dontrun{
#'   run_sldsc_cts(tempdir(), "siletti2023.cts")
#' }
#'
run_sldsc_cts <- function(
    parent_folder,
    cts_file,
    write_script = TRUE,
    ...,
    out = NULL
    ) {
  # get paths
  rlang::check_required(parent_folder)
  stopifnot("write_script should be either TRUE or FALSE" = rlang::is_bool(write_script))
  paths <- tidyGWAS_paths(parent_folder)
  basedir <- paths$ldsc
  out <- out %||% fs::path(basedir, "sldsc")

  fs::dir_create(out)
  slurm_out = fs::path_expand(fs::path(out, "slurm-%j.out"))



  # filepaths from container perspective ------------------------------------

  # preset filepaths
  weights <- in_ref_dir(paths$system_paths$sldsc$eur$weights)
  freq <- in_ref_dir(paths$system_paths$sldsc$eur$freq)
  ref_ld_chr <- in_ref_dir(paths$system_paths$sldsc$eur$base_ldscore)
  sumstats <- in_work_dir("ldsc.sumstats.gz")

  # variable filepath
  cts <- in_ref_dir(cts_file)
  container_out <- in_work_dir(fs::path(fs::path_ext_remove(cts_file)))


  # -------------------------------------------------------------------------


  code <- .stratified_ldsc_cts(
    sumstats = sumstats,
    ref_ld_chr = ref_ld_chr,
    ref_ld_chr_cts = cts,
    weights = weights,
    freq = freq,
    out = container_out
    )



  # containerize the ode ----------------------------------------------------


  script <- with_container(
    exe_path = "python /tools/ldsc/ldsc.py",
    code = code,
    config_key = "ldsc",
    workdir = basedir
  )


  # slurm -------------------------------------------------------------------

  header <- slurm_header(output = slurm_out, ...)

  full_script <- c(header, script)


  # -------------------------------------------------------------------------
  # return the script
  if(write_script)  {
    write_script_to_disk(full_script, fs::path(out, paste0(cts_file, ".sh")))
    } else  {
    full_script
  }


}



# -------------------------------------------------------------------------

.h2 <- function(
    sumstats,
    ref_ld_chr,
    w_ld_chr,
    out
) {
  glue::glue(
    "--h2 {sumstats} ",
    "--ref-ld-chr {ref_ld_chr} ",
    "--w-ld-chr {w_ld_chr} ",
    "--out {out}"
  )
}

.munge <- function(
    sumstats,
    out,
    snp = "RSID",
    a1 = "EffectAllele",
    a2 = "OtherAllele",
    merge_alleles
) {

  glue::glue(
    "--sumstats {sumstats} ",
    "--out {out} ",
    "--snp {snp} ",
    "--a1 {a1} ",
    "--a2 {a2} ",
    "--merge-alleles {merge_alleles} ",
    "--chunksize 500000"
  )
}

.stratified_ldsc_cts <- function(
    sumstats,
    ref_ld_chr,
    ref_ld_chr_cts,
    weights,
    freq,
    out

) {
  glue::glue(
    "--h2-cts {sumstats} ",
    "--ref-ld-chr {ref_ld_chr} ",
    "--ref-ld-chr-cts {ref_ld_chr_cts} ",
    "--w-ld-chr {weights} ",
    "--overlap-annot ",
    "--frqfile-chr {freq} ",
    "--out {out}"
  )
}
