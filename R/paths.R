#' Check that the configuration file has been correctly set up
#'
#' @return text to terminal
#' @export
#'
#' @examples \dontrun{
#' check_setup()
#' }
check_setup <- function() {
  outpath <- fs::path(Sys.getenv("HOME"), ".config/downstreamGWAS/config.yml")

  cli::cli_alert("Checking setup...")

  if(!file.exists(outpath)) {
    cli::cli_alert_warning("The downstreamGWAS config file does not exist. Please run setup_dsg() first")
    return(FALSE)
  }


  p <- get_system_paths()


  cli::cli_h1("Checking obligatory fields in the config file...")
  if(rlang::is_empty(p$reference)) {

    cli::cli_alert_danger("The 'reference' field in the config file is empty. Please fill in the path to folder containing the reference data")
    return(FALSE)

  } else if(!fs::dir_exists(p$reference)) {
    cli::cli_alert_danger("The {.code reference} field in the config file points to {.path {p$reference}}, which is not an existing directory. Please fill in the path to folder containing the reference data")
    return(FALSE)
  } else {
    cli::cli_alert_success("The reference data folder is set to {.path {p$reference}} and exists")
  }

  if(rlang::is_empty(p$containers)) {
    cli::cli_alert_danger("The 'containers' field in the config file is empty. Please fill in the path to folder containing the containers")
    return(FALSE)

  } else if(
    !fs::dir_exists(p$containers)) {
    cli::cli_alert_danger("The {.code containers} field in the config file points to {.path {p$containers}}, which is not an existing directory. Please fill in the path to folder containing the containers")
    return(FALSE)
  } else {
    cli::cli_alert_success("The containers folder is set to {.path {p$containers}} and exists")
  }

  cli::cli_alert_success("Looks all good!")

  cli::cli_h2("Checking optional fields in the config file...")


}


# -------------------------------------------------------------------------
# -------------------------------------------------------------------------


#' Read downstreamGWAS filepaths from yaml file
#' downstreamGWAS manages external filepaths through two files:
#'
#' The param.yml file which contains filepaths to reference data and software containers
#' all filepaths start at reference/ or containers/ respectively. The param.yml file
#' is bundled with the downstreamGWAS package.
#'
#' Secondly, the config.yml file which contains the local configuaration paramerers,
#' such as the path to the downstreamGWAS data folder, and how to call apptainer/singularity.
#' The config.yml file needs to be setup locally.
#'
#'
#'
#' @return a nested list of filepaths
#' @export
#'
#' @examples \dontrun{
#' get_system_paths()
#' }
get_system_paths <- function() {
  params <- parse_params()
  config <- parse_config()

  c(config, params)
}

parse_params <- function() {
  yaml::read_yaml(fs::path(fs::path_package("downstreamGWAS"), "extdata/params.yml"))
}

parse_config <- function() {

  yaml::read_yaml(
    fs::path(Sys.getenv("HOME"), ".config/downstreamGWAS/config.yml"),
    readLines.warn = FALSE
    )

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
    mbat_combo = fs::path(dir, "analysis/mbat-combo"),
    sbayes = fs::path(dir, "analysis/sbayes"),
    sbayesrc = sbayesrc,
    ma_file = fs::path(sbayesrc, "sumstats.ma"),
    imp_ma_file = fs::path(sbayesrc, "sumstats.imputed.ma"),
    clumping = clumping,
    clump_temp = fs::path(clumping, "temp.tsv")

  )

  # -------------------------------------------------------------------------

  out
}



write_script_to_disk <- function(script, path) {
    writeLines(script, path)
    return(path)
}


check_dependency <- function(file, dir = c("reference", "container")) {
  syspaths <- get_system_paths()
  dir <- rlang::arg_match(dir)

  if(dir == "reference") {
    prefix <- fs::path(syspaths$downstreamGWAS_folder, dir)
    full_file <- fs::path(
      prefix,
      file
      )
  } else {
    full_file <- fs::path(
      fs::path(syspaths$downstreamGWAS_folder, syspaths$default_params$container_dir),
      file
    )
  }




  cli::cli_h2("Checking if required files exist on local system...")
  cli::cli_alert_info("Looking for {.path {file}}")
  if(!fs::file_exists(full_file)) {
    cli::cli_alert_danger("file {.path {full_file}} does not exist")
    cli::cli_inform("Expected to find the file {.path {file}} to exist within the downstreamGWAS directory")
    cli::cli_inform("DownstreamGWAS directory: {.path {syspaths$downstreamGWAS_folder}}")
    cli::cli_inform("full path: {.path {full_file}}")
    return(FALSE)

  } else {
    cli::cli_alert_success("file {.path {file}} exists inside local downstreamGWAS folder")
    return(TRUE)
  }

}
