
call_gctb <- function(workdir) {

  paths <- get_system_paths()
  gctb <- fs::path(paths$containers, paths$gctb$container)
  singularity_start <- singularity_mount(workdir)

  glue::glue("{singularity_start}{gctb} gctb")
}

#' Capture code to run sbayesRC
#'
#' @param paths a list of filepaths, see [sbayesrc()] for which filepaths are required
#' @param thread number of threads to use
#'
#' @return a character vector
#' @export
#'
#' @examples \dontrun{
#' wrapper_sbayesrc()
#' }
wrapper_sbayesrc <- function(paths, thread=4) {
  workdir <- paths$sbayesr
  ldm <- glue::glue("/src/{paths$system_paths$gctb$ldm}")
  ma_file <- glue::glue("/mnt/{fs::path_file(paths$ma_file)}")
  imp_file <- glue::glue("/mnt/{fs::path_file(paths$imp_ma_file)}")
  annot <- glue::glue("/src/{paths$system_paths$gctb$annot}")
  out <- "/mnt/sbrc"
  sbayesrc(
    workdir = workdir,
    ldm = ldm,
    ma_file = ma_file,
    imp_file = imp_file,
    annot = annot,
    out = out,
    thread = thread
  )

}

#' Capture code to run sbayesRC
#'
#' @param workdir work directory
#' @param ldm filepath to ldm folder
#' @param ma_file filepath to.am file
#' @param imp_file filepath to imputed .ma file
#' @param annot filepath to the annotation file
#' @param out filepath prefix to outfiles
#' @param thread number of threads
#'
#' @return a character vector
#' @export
#'
#' @examples \dontrun{
#' sbayesrc()
#' }
sbayesrc <- function(workdir, ldm, ma_file, imp_file, annot, out, thread=4) {

  impute <- glue::glue(
   "{call_gctb(workdir)} ",
   "--ldm-eigen {ldm} ",
   "--gwas-summary {ma_file} ",
   "--impute-summary ",
   "--out {imp_file} ",
   "--thread {thread}"
   )

  # for rescale

  rescale <- glue::glue(
   "{call_gctb(workdir)} ",
   "--ldm-eigen {ldm} ",
   "--gwas-summary {imp_file} ",
   "--sbayes RC ",
   "--annot {annot} ",
   "--out {out} ",
   "--thread {thread}"
  )

  c(impute, "\n", rescale)


}


#' Run sbayerc with tidyGWAS structure
#'
#' @inheritParams run_ldsc
#' @inheritDotParams sbayesrc workdir ldm ma_file imp_file annot out thread
#' @param ...
#'
#' @return a filepath or character vector
#' @export
#'
#' @examples \dontrun{
#' run_sbayesrc()
#' }
run_sbayesrc <- function(parent_folder, write_script = c("no","yes"), ...) {
  paths <- tidyGWAS_paths(parent_folder)
  header <- slurm_header(...)
  code <- c(get_dependencies(), wrapper_sbayesrc(paths))

  if(write_script == "yes") {

    p <- fs::path(paths$sbayesrc, "sbayesrc.sh")
    writeLines(c(header, code), p)
    return(p)

  } else {
    return(code)

  }


}



