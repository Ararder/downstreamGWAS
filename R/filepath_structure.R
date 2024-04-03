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
    mbat_combo = fs::path(dir, "analysis/mbat-combo"),
    sbayes = fs::path(dir, "analysis/sbayes"),
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



