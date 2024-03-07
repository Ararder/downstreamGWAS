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
