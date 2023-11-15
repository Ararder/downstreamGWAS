#' Read downstreamGWAS filepaths from yaml file
#'
#' @return a nested list of filepaths
#' @export
#'
#' @examples \dontrun{
#' get_system_paths()
#' }
get_system_paths <- function() {
  yaml::read_yaml(Sys.getenv("sys_paths"), readLines.warn = FALSE)
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
    imp_ma_file = fs::path(sbayesrc, "imp_sumstats.ma"),
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

parse_tidyGWAS <- function(parent_folder) {

  #fs::path(parent_folder, "cleaned_GRCh38.csv")
  fs::path(parent_folder, "tidyGWAS_hivestyle")


}



