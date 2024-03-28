#' Setup required filepaths for downstreamGWAS
#'
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' setup()
#' }
setup <- function() {

  # read in dummy yaml from package
  yml <- yaml::read_yaml(fs::path(fs::path_package("downstreamGWAS"), "extdata/filepaths.yml"))

  # Save the config file in $HOME/.config
  outpath <- fs::path(Sys.getenv("HOME"), ".config/downstreamGWAS/config.yml")


  if(file.exists(outpath)) {
    cli::cli_alert_warning("the downstreamGWAS config file already exists: {.file {outpath}}")
    cli::cli_alert_info("If you want to reset the config file, please delete it first: {.code file.delete(\"{outpath}\")}")
    return(NULL)
  }

  example_container <- fs::path(Sys.getenv("HOME"), "containers")
  # make sure directory exists
  fs::dir_create(fs::path_dir(outpath), recurse = TRUE)


  yaml::write_yaml(yml, outpath)
  cli::cli_alert_success("Wrote the downstreamGWAS config file to {.file {outpath}}")
  cli::cli_alert("downstreamGWAS needs to know three things to get started: ")
  cli::cli_alert_info("Please edit {.file {outpath}} and provide the filepaths for containers and reference, and code to make singularity available")
  cli::cli_alert("1) the folder with the singularity containers")
  cli::cli_alert("2) the folder with the reference data")
  cli::cli_alert("3) if any code needs to called before running singularity. On many HPCs, you often need to run ml singularity, or something similar")

}


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
    cli::cli_alert_warning("The downstreamGWAS config file does not exist. Please run setup() first")
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
