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

  # read in dummy yaml from package
  yml <- yaml::read_yaml(fs::path(fs::path_package("downstreamGWAS"), "extdata/filepaths.yml"))

  # Save the config file in $HOME/.config
  outpath <- fs::path(Sys.getenv("HOME"), ".config/downstreamGWAS/config.yml")

  # make sure directory exists
  fs::dir_create(fs::path_dir(outpath), recurse = TRUE)
  yaml::write_yaml(yml, outpath)
  cli::cli_alert_success("Wrote the downstreamGWAS config file to {.file {outpath}}")
  cli::cli_alert("downstreamGWAS needs to know three things to get started: ")
  cli::cli_alert("1) the folder with the singularity containers")
  cli::cli_alert("2) the folder with the reference data")
  cli::cli_alert("3) if any code needs to called before running singularity. On many HPCs, you often need to run ml singularity, or something similar")
  cli::cli_alert_info("Please edit {.file {outpath}} and provide the filepaths for containers and reference, and code to make singularity available")

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
  config <- fs::path(Sys.getenv("HOME"), ".config/downstreamGWAS/config.yml")
  yaml::read_yaml(config, readLines.warn = FALSE)
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
  stopifnot("Can only accept vector of length one" = length(dir) == 1)
  split <- fs::path_split(dir)[[1]]

  if(length(split) == 1) {
    dir <- fs::path(get_system_paths()[["sumstats_folder"]], dir)
  }

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



