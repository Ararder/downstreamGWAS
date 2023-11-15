#' Export tidyGWAS format to LDSC format
#'
#' @param parent_folder filepath to tidyGWAS folder
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' to_ldsc("my_sumstats/tidygwas/height2022")
#' }
to_ldsc <- function(parent_folder) {


  paths <- tidyGWAS_paths(parent_folder)
  hm3_path <- fs::path(paths$system_paths$reference, paths$system_paths$ldsc$hm3)
  hm3 <- arrow::read_tsv_arrow(hm3_path)
  dset <- arrow::open_dataset(paths$hivestyle)

  if("B" %in% dset$schema$names)  {
    effect <- "B"
  } else if("Z" %in% dset$schema$names) {
    effect <- "Z"
  } else {
    stop("Both B and Z is missing from sumstats. Cannot create LDSC format")
  }


  dset |>
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N"))) |>
    dplyr::filter(RSID %in% hm3$SNP) |>
    dplyr::collect() |>
    readr::write_tsv(paths$ldsc_temp)


}
