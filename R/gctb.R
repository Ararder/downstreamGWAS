#' Run sbayerc with tidyGWAS structure
#'
#' @inheritParams run_ldsc
#' @param thread_rc threads for rescaling
#' @param thread_imp threads for imputing
#'
#' @return a filepath or character vector
#' @export
#'
#' @examples \dontrun{
#' run_sbayesrc()
#' }
run_sbayesrc <- function(parent_folder, ..., write_script = TRUE, thread_rc = 8, thread_imp = 4) {
  stopifnot(rlang::is_bool(write_script))
  paths <- tidyGWAS_paths(parent_folder)
  header <- slurm_header(..., output = fs::path_expand(fs::path(paths$sbayesrc, "slurm-%j.out")))
  fs::dir_create(paths$sbayesrc)

  munge <- glue::glue("R -e \"downstreamGWAS::to_ma('{parent_folder}')\"")



  # container paths ---------------------------------------------------------

  workdir <- paths$sbayesr
  ldm <- in_ref_dir(paths$system_paths$sbayesrc$ldm)
  ma_file <- in_work_dir(fs::path_file(paths$ma_file))
  annot <- in_ref_dir(paths$system_paths$sbayesrc$annot)
  out <- in_work_dir("sbrc")



  # construct code ----------------------------------------------------------

  tidy <- with_container(
    code = glue::glue("\"SBayesRC::tidy('{ma_file}',LDdir='{ldm}',output='{ma_file}')\""),
    image = "sbayesrc",
    workdir = workdir,
    R_code=TRUE
  )

  impute <- with_container(
    code = glue::glue("\"SBayesRC::impute('{ma_file}',LDdir='{ldm}',output='{ma_file}')\""),
    image = "sbayesrc",
    workdir = workdir,
    env = glue::glue("OMP_NUM_THREADS={thread_imp}"),
    setup_exists = TRUE,
    R_code=TRUE
  )

  rescale <- with_container(
    code = glue::glue("\"SBayesRC::sbayesrc('{ma_file}',LDdir='{ldm}',outPrefix='{out}', annot='{annot}')\""),
    image = "sbayesrc",
    workdir = workdir,
    env = glue::glue("OMP_NUM_THREADS={thread_rc}"),
    setup_exists = TRUE,
    R_code=TRUE
  )


  code <- c(
    paths$system_paths$container_dependency,
    "\n",
    munge,
    "\n",
    tidy,
    "\n",
    impute,
    "\n",
    rescale,
    "\n"
  )

  cleanup <- glue::glue("rm {paths$sbayesrc}/*.rds")
  ma_files <- glue::glue("rm {paths$sbayesrc}/sumstats.ma*")
  tune_txt <- glue::glue("rm {paths$sbayesrc}/sbrc_tune_inter.txt*")
  rm1 <- glue::glue("rm {paths$sbayesrc}/sbrc.mcmcsamples*")
  rm2 <- glue::glue("rm {paths$sbayesrc}/sbrc_tune*")
  gzip_file <- glue::glue("gzip {paths$sbayesrc}/sbrc.txt")



  cleanup <- c(cleanup, ma_files, tune_txt, gzip_file, rm1,rm2)
  all_code <- c(header, code, cleanup)

  if(isTRUE(write_script)) {

    p <- fs::path(paths$sbayesrc, "sbayesrc.sh")
    writeLines(all_code, p)
    return(p)

  } else {
    return(all_code)

  }


}


run_sbayesrc_req <- function() {
  sp <- get_system_paths()
  sp$sbayesrc$container
  ldm <- paste0(sp$sbayesrc$annot)
  annot <- paste0(sp$sbayesrc$ldm, "/ldm.info")

  check_dependency(annot, "reference")
  check_dependency(ldm, "reference")
  check_dependency(sp$sbayesrc$container, "container")


}




#' Run Sbayes-S with tidyGWAS structure
#'
#' @param parent_folder filepath to a [tidyGWAS::tidyGWAS()] folder
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
    write_script = TRUE,
    pi = "0.01",
    hsq = "0.5",
    num_chains = "4",
    chain_length = "25000",
    burn_in = "5000",
    seed = "2023",
    thread = "8"
    ) {
  rlang::check_required(parent_folder)
  stopifnot(rlang::is_bool(write_script))


  # get default paths -------------------------------------------------------

  paths <- tidyGWAS_paths(parent_folder)

  # slurm -------------------------------------------------------------------

  header <- slurm_header(..., output = fs::path_expand(fs::path(paths$sbayes, "slurm-%j.out")))


  # sbayess code ----------------------------------------------------------

  ldm <- in_ref_dir(paths$system_paths$gctb$ldm_s)
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
    code = paste0("gctb ",code),
    image = "gctb",
    workdir = paths$sbayes
  )


  # force dir, create ma file -----------------------------------------------

  fs::dir_create(paths$sbayes)
  # code <- glue::glue("Rscript -e --silent ")
  # to_ma(parent_folder, fs::path(paths$sbayes, "sumstats.ma"))



  full_script <- c(header, script)
  if(write_script) {

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

#' Check if required files exist for Sbayes-S
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' run_sbayess_req()
#' }
run_sbayess_req <- function() {
  sp <- get_system_paths()
  info <- paste0(sp$gctb$ldm_s, ".info")
  bin <- paste0(sp$gctb$ldm_s,".bin")

  check_dependency(bin, "reference")
  check_dependency(info, "reference")
  check_dependency(sp$gctb$container, "container")


}



# mbat --------------------------------------------------------------------

#' run mBAT-combo gene-test in GCTB
#'
#' @param parent_folder filepath to a tidyGWAS folder
#' @param ... arguments to slurm
#' @param write_script should the code be written to disk?
#' @param outfolder Where to write the output
#' @param thread_num number of threads to use
#'
#' @return a character vector with the script or a filepath
#' @export
#'
#' @examples \dontrun{
#' mbat_combo("path_to_tidyGWAS/folder/sumstat1")
#' }
run_mbat_combo <- function(parent_folder, ..., write_script = TRUE, outfolder=NULL, thread_num = 10) {

  # filepaths
  paths <- tidyGWAS_paths(parent_folder)
  outfolder <- outfolder %||% fs::path(parent_folder, "analysis", "mbat_combo")
  fs::dir_create(outfolder)
  out <- fs::path(outfolder, "sumstats.ma")
  to_ma <- glue::glue("R -e \"downstreamGWAS::to_ma('{parent_folder}',out='{out}')\"")

  # filepaths inside container
  container <- fs::path(paths$system_paths$downstreamGWAS_folder, "containers", paths$system_paths$gcta$container)
  ref_genome <- in_ref_dir(paths$system_paths$genome_refs$merged_1kg)
  ma_file <- in_work_dir("sumstats.ma")
  gene_list <- in_ref_dir(paths$system_paths$gctb$mbat_gene_list_b37)
  out <- in_work_dir("mbat-combo")

  # mbat code
  code <- glue::glue(
    "gcta --bfile {ref_genome} ",
    "--mBAT-combo {ma_file} ",
    "--mBAT-gene-list {gene_list} ",
    "--out {out} ",
    "--thread-num {thread_num}"
  )

  # containerize the code
  script <- with_container(
    code = code,
    image = "gcta",
    workdir = outfolder
  )

  # slurm header
  header <- slurm_header(..., output = fs::path_expand(fs::path(outfolder, "slurm-%j.out")))

  full_script <- c(header, script)

  # return ------------------------------------------------------------------

  if(write_script) {

    p <- fs::path(outfolder, "mbat-combo.sh")
    writeLines(full_script, p)
    return(p)

  } else {
    return(full_script)

  }

}



