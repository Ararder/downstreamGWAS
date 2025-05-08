utils::globalVariables(c("CaseN", "ControlN", "multi_allelic", "EffectAllele","OtherAllele","EffectiveN",
                         "EAF", "B", "SE", "se", "p"))
#' Export tidyGWAS format to LDSC format
#'
#' @param parent_folder filepath to tidyGWAS folder
#' @param use_effective_n Should an attempt be made to calculate effective N and use that as N?
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' to_ldsc("my_sumstats/tidygwas/height2022")
#' }
to_ldsc <- function(parent_folder, use_effective_n = TRUE) {


  paths <- tidyGWAS_paths(parent_folder)
  hm3_path <- fs::path(paths$system_paths$downstreamGWAS_folder, "reference", paths$system_paths$ldsc$hm3)
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
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N", "CaseN", "ControlN", "INFO", "EAF"))) |>
    dplyr::filter(RSID %in% hm3$SNP) |>
    dplyr::collect()

  # use Effective N as N?
  has_ncas <- all(c("CaseN", "ControlN") %in% dset$schema$names)

  if(!has_ncas & use_effective_n == "Effective") {
    cli::cli_alert_danger("Tried to calculate effective sample, but the required columns are missing: CaseN or ControlN")
  }

  if(use_effective_n & has_ncas) {
    cli::cli_alert_success("OBS: Using Effective N as N!")
    df <- dplyr::mutate(df, N = effective_n(CaseN, ControlN))
  }

  # write out
  df |>
    dplyr::select(dplyr::any_of(c("RSID", "EffectAllele", "OtherAllele", effect,"SE", "P", "N", "EAF", "INFO"))) |>
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
#' @param out output for .ma file. Default value is `tidyGWAS_paths()[["ma_file]]`
#' @param use_effective_n Should N be converted to effective sample size? Requires CaseN and ControlN in column names
#'
#' @return NULL
#' @export
#'
#' @examples \dontrun{
#' to_ma("/path/tidyGWAS_sumstats/a_sumstat")
#' }
to_ma <- function(parent_folder, out = NULL, use_effective_n = FALSE) {

  paths <- tidyGWAS_paths(parent_folder)
  out <- if(is.null(out)) paths$ma_file else out
  fs::dir_create(fs::path_dir(out))

  # dataset: ds
  ds <- arrow::open_dataset(paths$hivestyle)
  column_names <- names(ds$schema)


  stopifnot(all(c("RSID", "EffectAllele", "OtherAllele", "EAF", "B", "SE", "P") %in% column_names))

  # dataset query: dsq
  dsq <- ds |>
    dplyr::filter(!multi_allelic)

  if(isTRUE(use_effective_n)) {
    stopifnot(
      "EffectiveN" %in% column_names |
        all(c("CaseN", "ControlN") %in% column_names)
    )

    if("EffectiveN" %in% column_names) {
      dsq <- dplyr::mutate(N = EffectiveN)

    } else if(all(c("CaseN", "ControlN") %in% column_names)) {
      dsq <- dsq |>
        dplyr::mutate(N = 4 * ( CaseN / (CaseN+ControlN)) * (1 - CaseN / (CaseN+ControlN)) * (CaseN + ControlN))
    }

  }

  dplyr::select(dsq, SNP = RSID, A1 = EffectAllele, A2 = OtherAllele, freq=EAF, b=B, se=SE, p=P, N) |>
    readr::write_tsv(out)

}
