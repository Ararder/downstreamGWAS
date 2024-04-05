#' Run sbayerc with tidyGWAS structure
#'
#' @inheritParams run_ldsc
#' @inheritDotParams sbayesrc workdir ldm ma_file annot out
#' @param thread_rc threads for rescaling
#' @param thread_imp threads for imputing
#' @param ...
#'
#' @return a filepath or character vector
#' @export
#'
#' @examples \dontrun{
#' run_sbayesrc()
#' }
run_sbayesrc <- function(parent_folder, ..., write_script = c("no","yes"), thread_rc = 8, thread_imp = 4) {
  rlang::arg_match(write_script)
  paths <- tidyGWAS_paths(parent_folder)
  header <- slurm_header(..., output = fs::path_expand(fs::path(paths$sbayesrc, "slurm-%j.out")))
  fs::dir_create(paths$sbayesrc)

  munge <- glue::glue("R -e \"downstreamGWAS::to_ma('{parent_folder}')\"")

  code <- c(get_dependencies(), munge, wrapper_sbayesrc(paths = paths, thread_rc = thread_rc, thread_imp = thread_imp))
  cleanup <- glue::glue("rm {paths$sbayesrc}/*.rds")
  ma_files <- glue::glue("rm {paths$sbayesrc}/sumstats.ma*")
  tune_txt <- glue::glue("rm {paths$sbayesrc}/sbrc_tune_inter.txt*")
  gzip_file <- glue::glue("gzip {paths$sbayesrc}/sbrc.txt")

  cleanup <- c(cleanup, ma_files, tune_txt, gzip_file)
  all_code <- c(header, code, cleanup)
  if(write_script == "yes") {

    p <- fs::path(paths$sbayesrc, "sbayesrc.sh")
    writeLines(all_code, p)
    return(p)

  } else {
    return(all_code)

  }


}


#' Capture code to run sbayesRC
#'
#' @param paths a list of filepaths, see [sbayesrc()] for which filepaths are required
#' @param thread_imp number of threads to for the imputation step
#' @param thread_rc number of threads for the rescaling step
#'
#' @return a character vector
#' @export
#'
#' @examples \dontrun{
#' wrapper_sbayesrc()
#' }
wrapper_sbayesrc <- function(paths, thread_imp = 4, thread_rc=8) {
  workdir <- paths$sbayesr
  ldm <- glue::glue("/src/{paths$system_paths$sbayesrc$ldm}")
  ma_file <- glue::glue("/mnt/{fs::path_file(paths$ma_file)}")
  annot <- glue::glue("/src/{paths$system_paths$sbayesrc$annot}")
  out <- "/mnt/sbrc"
  sbayesrc(
    workdir = workdir,
    ldm = ldm,
    ma_file = ma_file,
    annot = annot,
    out = out,
    thread_imp = thread_imp,
    thread_rc = thread_rc
  )

}


#' Run SbayesRC from R with containers
#'
#' @param workdir where will the files be written to?
#' @param ldm path to ldmatrix
#' @param ma_file path to ma file
#' @param annot path to annotation file
#' @param out output folder
#' @param thread_imp how many threads for imputation?
#' @param thread_rc how many threads for rescaling?
#'
#' @return character vector
#' @export
#'
#' @examples \dontrun{
#' sbayesrc(tempdir(), "path_to_ldm", "sumstats.ma", "annot.txt", out = tempdir())
#' }
sbayesrc <- function(workdir, ldm, ma_file, annot,out, thread_imp = 4, thread_rc = 4) {

  tidy <- glue::glue("SBayesRC::tidy('{ma_file}',LDdir='{ldm}',output='{ma_file}')")
  impute <-  glue::glue("SBayesRC::impute('{ma_file}',LDdir='{ldm}',output='{ma_file}')")
  rescale <-  glue::glue("SBayesRC::sbayesrc('{ma_file}',LDdir='{ldm}',outPrefix='{out}', annot='{annot}')")

  container <- call_container(
    "R -e \"Sys.setenv('OMP_NUM_THREADS' = {thread_imp})\" -e ",
    "sbayesrc",
    workdir
    )

  container_rescale <- call_container(
    "R -e \"Sys.setenv('OMP_NUM_THREADS' = {thread_rc})\" -e ",
    "sbayesrc",
    workdir
  )
  job <- c(
    # first we tidy
    glue::glue(container, "\"{tidy}\""),
    # then we impute
    glue::glue(container, "\"{impute}\""),
    # then we rescale,
    glue::glue(container_rescale, "\"{rescale}\"")

  )

  job
}




#' Run Sbayes-S with tidyGWAS structure
#'
#' @param parent_folder filepath to a [tidyGWAS] folder
#' @param ... pass arguments to [slurm_header()]
#' @param write_script should the captured code be written to disk in a .sh file?
#' @param pi argument passed to sbayes
#' @param hsq argument passed to sbayes
#' @param num_chains argument passed to sbayes
#' @param chain_length argument passed to sbayes
#' @param burn_in argument passed to sbayes
#' @param seed argument passed to sbayes
#' @param thread argument passed to sbayes
#'
#' @return a filepath or character vector
#' @export
#'
#' @examples \dontrun{
#' run_sbayess()
#' }
run_sbayess <- function(
    parent_folder,
    ...,
    write_script = c("yes","no"),
    pi = "0.01",
    hsq = "0.5",
    num_chains = "4",
    chain_length = "25000",
    burn_in = "5000",
    seed = "2023",
    thread = "8"
    ) {

  write_script <- rlang::arg_match(write_script)


  # get default paths -------------------------------------------------------

  paths <- tidyGWAS_paths(parent_folder)

  # slurm -------------------------------------------------------------------

  header <- slurm_header(..., output = fs::path_expand(fs::path(paths$sbayes, "slurm-%j.out")))


  # sbayess code ----------------------------------------------------------

  ldm <- in_ref_dir(paths$system_paths$gctb$ldm_s, "gctb")
  ma_file <- in_work_dir("sumstats.ma")
  out <- in_work_dir("SbayesS")


  code <- .sbayess(
    ldm = ldm,
    gwas_summary = ma_file,
    out = out,
    pi = pi,
    hsq = hsq,
    num_chains = num_chains,
    chain_length = chain_length,
    burn_in = burn_in,
    seed = seed,
    thread = thread
  )



  # containerize the code --------------------------------------------------

  script <- with_container(
    exe_path = "gctb",
    code = code,
    config_key = "gctb",
    workdir = paths$sbayes
  )


  # force dir, create ma file -----------------------------------------------

  fs::dir_create(paths$sbayes)
  # code <- glue::glue("Rscript -e --silent ")
  # to_ma(parent_folder, fs::path(paths$sbayes, "sumstats.ma"))



  full_script <- c(header, script)
  if(write_script == "yes") {

    p <- fs::path(paths$sbayes, "sbayess.sh")
    writeLines(full_script, p)
    return(p)

  } else {
    return(full_script)

  }
}


.sbayess <- function(
    ldm,
    gwas_summary,
    out,
    pi,
    hsq,
    num_chains,
    chain_length,
    burn_in,
    seed,
    thread

    ) {
  glue::glue(
    "--sbayes S ",
    "--gwas-summary {gwas_summary} ",
    "--ldm {ldm} ",
    "--out {out} ",
    "--pi {pi} ",
    "--num-chains {num_chains} ",
    "--hsq {hsq} ",
    "--chain-length {chain_length} ",
    "--burn-in {burn_in} ",
    "--seed {seed} ",
    "--thread {thread} ",
    "--no-mcmc-bin"
  )

}



