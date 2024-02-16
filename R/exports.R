utils::globalVariables(c("CaseN", "ControlN", "multi_allelic", "EffectAllele","OtherAllele",
                         "EAF", "B", "SE", "se", "p"))
#' Export tidyGWAS format to LDSC format
#'
#' @param parent_folder filepath to tidyGWAS folder
#' @param sample_size Should an attempt be made to calculate effective N and use that as N?
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' to_ldsc("my_sumstats/tidygwas/height2022")
#' }
to_ldsc <- function(parent_folder, sample_size = c("Effective", "N")) {

  sample_size <- rlang::arg_match(sample_size)
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


  df <- dset |>
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N", "CaseN", "ControlN"))) |>
    dplyr::filter(RSID %in% hm3$SNP) |>
    dplyr::collect()

  # use Effective N as N?
  has_ncas <- all(c("CaseN", "ControlN") %in% dset$schema$names)

  if(!has_ncas & sample_size == "Effective") {
    cli::cli_alert_danger("Tried to calculate effective sample, but the required columns are missing: CaseN or ControlN")
  }

  if(sample_size == "Effective" & has_ncas) {
    cli::cli_alert_success("OBS: Using Effective N as N!")
    df <- dplyr::mutate(df, N = effective_n(CaseN, ControlN))
  }

  # write out
  df |>
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N"))) |>
    readr::write_tsv(paths$ldsc_temp)


}


#' Convert tidyGWAS hivestyle partitioning to compatible format for plink clumping
#'
#' @param parent_folder filepath to tidyGWAS folder
#'
#' @return writes a file to disk
#' @export
#'
#' @examples \dontrun{
#' paths <- tidyGWAS_paths("/my_sumstat/cleaned/")
#' to_plink_clumping(paths)
#' }
to_plink_clumping <- function(parent_folder) {

  paths <- tidyGWAS_paths(parent_folder)
  dset <- arrow::open_dataset(paths$hivestyle)
  fs::dir_create(paths$clumping)

  dplyr::select(dset, RSID, P) |>
    dplyr::collect() |>
    readr::write_tsv(paths$clump_temp)

}

#' Convert tidyGWAS to COJO .ma format
#'
#' @param parent_folder filepath to tidyGWAS folder
#' @param out output for .ma file. Default value is [tidyGWAS_paths()$ma_file]
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' to_ma("/path/tidyGWAS_sumstats/a_sumstat")
#' }
to_ma <- function(parent_folder, out) {

  paths <- tidyGWAS_paths(parent_folder)
  if(missing(out)) out <- paths$ma_file
  fs::dir_create(fs::path_dir(out))


  arrow::open_dataset(paths$hivestyle) |>
    dplyr::filter(!multi_allelic) |>
    dplyr::select(SNP = RSID, A1 = EffectAllele, A2 = OtherAllele, freq=EAF, b=B, se=SE, p=P, N) |>
    dplyr::collect() |>
    readr::write_tsv(out)

}
