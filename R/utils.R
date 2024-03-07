effective_n <- function(cases, controls) {
  proportion <- cases/(cases + controls)
  neff <- 4 * proportion * ((1 - proportion) * (cases + controls))

  round(neff)
}

#' Read in a tidyGWAS formatted summary statistics file
#'
#' @param parent_folder filepath to the parent_folder of tidyGWAS_hivestyle
#' @param columns character vector of columns names, passed to [dplyr::select(dplyr::any_of(columns))]
#'
#' @return a [data.frame()]
#' @export
#'
#' @examples \dontrun{
#' read_gwas("/tidyGWAS_files/mdd2019")
#' # or if you have saved the summary statistics filepath in the config.yaml file
#' # see [tidyGWAS_paths()]
#' read_gwas("mdd2019")
#' }
read_gwas <- function(parent_folder, columns) {
  paths <- tidyGWAS_paths(parent_folder)
  arrow::open_dataset(paths$hivestyle) |>
    dplyr::select(dplyr::any_of(columns)) |>
    dplyr::collect()

}


#' List the available sumstats
#'
#' @param folder can be used to specify where the summary statistics are.
#' Default value is NULL, and the sumstats_folder parameter will be used from the
#' config.yaml file
#'
#' @return a [dplyr::tibble()]
#' @export
#'
#' @examples \dontrun{
#' ls_sumstats()
#' }
#'
ls_sumstats <- function(folder = NULL) {

  f <- get_system_paths()$sumstats_folder
  if(!is.null(folder)) f <- folder

  sumstats <- fs::dir_ls(f, type = "dir")
  dplyr::tibble(dataset_name = fs::path_file(sumstats),filepath = sumstats)


}

