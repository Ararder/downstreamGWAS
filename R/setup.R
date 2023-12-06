#' Setup required filepaths for downstreamGWAS
#'
#' @param dir in what directory should the config file be stored?
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' setup("my_dsg/folder/")
#' }
setup <- function(dir) {
  yml <- yaml::read_yaml(fs::path(fs::path_package("downstreamGWAS"), "extdata/filepaths.yml"))
  outpath <- fs::path(dir, ".filepaths.yml")
  yaml::write_yaml(yml, outpath)
  if(!fs::file_exists('~/.Renviron')) fs::file_create("~/.Renviron")
  cli::cli_bullets(
    c(
    "{.strong downstreamGWAS requires you to specify filepaths in the file we just created: }",
    "{.path {outpath}}",
    "1. {.var containers}: 'filepath/to/folders/where/containers_exist'",
    "2. {.var reference}: 'filepath/to/folders/with/refence_data'",
    "Optionally, you can specify third directory to enables some shortcuts for working with available sumstats.",
    "3. {.var sumstats_folder}: 'filepath/to/sumstats/cleaned_with_tidygwas/'",
    "Lastly, if you are using a HPC that uses a module system, you need to explain how apptainer/singularity is loaded.
    By default, downstreamGWAS attempts to load singularity/apptainer with ml singularity apptainer, but this might not always work"
    )
  )

  cli::cli_alert_success("Wrote yml template to {.path {outpath}}")
  cli::cli_inform("Open {.path {outpath}} and set the filepaths to containers and reference")
  cli::cli_alert_info("Added {.code DSG_PATHS=\"{fs::path_real(outpath)}\"} to {.path {fs::path_real('~/.Renviron')}}")
  cmd <- glue::glue("echo DSG_PATHS=\"{fs::path_real(outpath)}\" >> {fs::path_real('~/.Renviron')}")
  system(cmd)



}

#' Check if [setup()] worked correctly
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' check_setup
#' }
check_setup <- function() {
  var <- Sys.getenv("DSG_PATHS")
  if(var == "") {
    cli::cli_alert_danger("Could not find {.var DSG_PATHS} in .Renviron file")
  } else {
    cli::cli_alert_success("Found {.var DSG_PATHS} set to {.path {var}}")
    cli::cli_inform("Attempting to parse {.path {var}}")
  }

  paths <- get_system_paths()
  stopifnot(
    "Container directory does not yet exist" =
    fs::dir_exists(paths$containers)
  )
  stopifnot(
    "reference directory does not yet exist" =
      fs::dir_exists(paths$reference)
  )
}

sif_script <- function() {
  paths <- get_system_paths()
  script <- glue::glue(
    "# These scripts can be run to download and build the apptainer images used to run downstreamGWAS",
    "\n",
    glue::glue("cd {paths$containers}"),
    "\n",
    get_dependencies(),
    "\n",
    "apptainer pull docker://arvhar/genetics:latest",
    "\n",
    "apptainer pull docker://arvhar/ldsc:latest",
    "\n",
    "apptainer pull docker://arvhar/tidygwas:latest",
    )
  script_path <- fs::path(paths$containers, "download_apptainers.sh")
  writeLines(script, script_path)
  system(glue::glue("chmod +x {script_path}"))
  cli::cli_alert_success("Wrote apptainer download script to {.path {script_path}}")

}


#' Read downstreamGWAS filepaths from yaml file
#'
#' @return a nested list of filepaths
#' @export
#'
#' @examples \dontrun{
#' get_system_paths()
#' }
get_system_paths <- function() {
  yaml::read_yaml(Sys.getenv("DSG_PATHS"), readLines.warn = FALSE)
}


#' Create the folder structure and filepaths for downstreamGWAS directory
#'
#' @param dir filepath to folder
#'
#' @return a list of filepaths
#' @export
#'
#' @examples \dontrun{
#'  tidyGWAS_paths("gwas/height2022")
#' }
tidyGWAS_paths <- function(dir) {

  base <- dir
  name <- fs::path_dir(dir)
  sbayesrc <- fs::path(dir, "analysis/sbayesrc")

  # ldsc --------------------------------------------------------------------
  ldsc = fs::path(dir, "analysis/ldsc")
  clumping = fs::path(dir, "analysis/clumping")
  out <- list(
    system_paths = get_system_paths(),
    base = dir,
    name = fs::path_file(dir),
    hivestyle = fs::path(dir, "tidyGWAS_hivestyle"),
    analysis  = fs::path(dir, "analysis"),

    ldsc = ldsc,
    ldsc_temp = fs::path(ldsc, "temp.csv.gz"),
    ldsc_munged = fs::path(ldsc, "ldsc"),
    ldsc_h2 = fs::path(ldsc, "ldsc_h2"),

    magma = fs::path(dir, "analysis/magma"),
    sbayesrc = sbayesrc,
    ma_file = fs::path(sbayesrc, "sumstats.ma"),
    imp_ma_file = fs::path(sbayesrc, "sumstats.imputed.ma"),
    clumping = clumping,
    clump_temp = fs::path(clumping, "temp.tsv")

  )

  # -------------------------------------------------------------------------


  fs::dir_create(out$ldsc)
  fs::dir_create(out$magma)
  fs::dir_create(out$clumping)

  out
}


write_existing_columns <- function(paths) {
  #
  outfile <- fs::path(fs::path_dir(paths$hivestyle), "existing_columns.txt")

  # connnect to dataframe and get column names
  dset <- arrow::open_dataset(paths$hivestyle)

  # save them to existing_columns.txt
  writeLines(dset$schema$names, outfile)


}

# parse_tidyGWAS <- function(parent_folder) {
#
#   if(fs::dir_exists(fs::path(parent_folder, "tidyGWAS_hivestyle"))) {
#     return
#   }
#
#   #fs::path(parent_folder, "cleaned_GRCh38.csv")
#   fs::path(parent_folder, "tidyGWAS_hivestyle")
#
#
# }



