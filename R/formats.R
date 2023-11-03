get_system_paths <- function() {
  yaml::read_yaml("~/shared/gwas_sumstats/filepaths.yml")
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

parse_input_format <- function(sumstat) {

  # tidyGWAS hivestyle
  if(fs::is_dir(sumstat) & fs::path_file(sumstat) == "tidyGWAS_hivestyle") {

    df <- arrow::open_dataset(sumstat) |>
      colnames() |>
      dplyr::collect()

  } else if(fs::path_ext(sumstat) == "parquet" & fs::is_file(sumstat)){
    df <- arrow::read_parquet(sumstat)

  }

  df
}


to_csv <- function(filepath, out) {
  arrow::open_dataset(filepath) |>
    arrow::write_csv_arrow(out)
}
