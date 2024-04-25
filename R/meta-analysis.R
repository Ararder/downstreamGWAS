utils::globalVariables(
  c("REF", "EA_is_ref", "CHR", "ID", "W")
)

align_to_ref <- function(dset) {
  # EffectAllele is harmonized to always be the reference allele
  dset |>
    dplyr::mutate(
      EA_is_ref = dplyr::if_else(EffectAllele == REF, TRUE,FALSE),
      tmp = EffectAllele,
      EffectAllele = dplyr::if_else(EA_is_ref, EffectAllele, OtherAllele),
      OtherAllele = dplyr::if_else(EA_is_ref, OtherAllele, tmp),
      B = dplyr::if_else(EA_is_ref, B, B*-1),
      EAF = dplyr::if_else(EA_is_ref, EAF, 1-EAF)
    ) |>
    dplyr::select(-dplyr::all_of(c("EA_is_ref", "tmp")))

}
#' meta_analyze summary statistics, one chromosome at a time!
#'
#' @param dset an object created by [arrow::open_dataset()]
#' @param chrom chromosome to meta-analyse
#'
#' @return a [dplyr::tibble()]
#' @export
#'
#' @examples \dontrun{
#' meta_analyze_by_crom(dset, chrom = "22")
#' }
meta_analyze_by_chrom <- function(dset, chrom) {

  dset |>
    dplyr::filter(!is.na(ID)) |>
    dplyr::filter(CHR == {{ chrom }}) |>
    dplyr::filter(is.finite(B) & is.finite(SE)) |>
    align_to_ref() |>
    dplyr::select(dplyr::any_of(c("ID", "B", "SE", "EAF", "N", "CaseN", "ControlN","INFO"))) |>
    dplyr::mutate(
      W = 1 / (SE^2),
      B = B*W,
      dplyr::across(dplyr::any_of(c("EAF", "INFO")), ~.x * N)
    ) |>
    dplyr::group_by(ID) |>
    dplyr::summarise(
      n_contributions = dplyr::n(),
      dplyr::across(dplyr::any_of(c("W", "B")), sum),
      dplyr::across(dplyr::any_of(c("EAF", "INFO", "CaseN", "ControlN", "N")), ~sum(.x, na.rm=T))
    ) |>
    dplyr::mutate(
      B = B / W,
      SE = 1 / sqrt(W),
      dplyr::across(dplyr::any_of(c("EAF", "INFO")), ~.x / N)
    ) |>
    dplyr::select(-W) |>
    dplyr::collect() |>
    dplyr::mutate(P  = stats::pnorm(-abs(B/SE)) *2)

}




#' Perform meta-analysis of GWAS summary statistics datasets in [tidyGWAS::tidyGWAS()] hive-style format.
#'
#' @param dset an [arrow::open_dataset()] object
#' @param method method to use for performing meta-analysis. Currently, only IVW (based on standard errors) is supported.
#' @return a [dplyr::tibble()]
#' @export
#'
#' @examples \dontrun{
#' dset <- arrow::open_dataset("path_to/sumstats/")
#' res <- meta_analyze(dset)
#' }
#'
meta_analyze <- function(dset, method = c("ivw")) {
  method <- rlang::arg_match(method)
  purrr::map(c(1:22), \(chrom) meta_analyze_by_chrom(dset, chrom = chrom)) |>
    purrr::list_rbind()
}

#' Get the unique set of SNP, CHR, POS EffectAllele, OtherAllele, ID from a set of summary statistics
#'
#' @param dset a [arrow::open_dataset()] object
#'
#' @return a [dplyr::tibble()]
#' @export
#'
#' @examples \dontrun{
#' dset <- arrow::open_dataset("path_to_dsets")
#' snpids <- get_snp_ids(dset)
#' }
get_snp_ids <- function(dset) {
  purrr::map(c(1:22), \(chrom) get_snp_ids_chrom(dset, chrom = chrom)) |>
    purrr::list_rbind()
}

get_snp_ids_chrom <- function(dset, chrom) {

    dset |>
      dplyr::filter(CHR == chrom) |>
      dplyr::filter(!multi_allelic) |>
      align_to_ref() |>
      dplyr::select(RSID, CHR, POS, EffectAllele, OtherAllele, ID) |>
      dplyr::distinct() |>
      dplyr::collect()

}

# get_chr_pos_ea_oa <- function(df) {
#   stopifnot("ID" %in% colnames(df))
#   t <- stringi::stri_split_fixed(df$ID, ":", simplify = TRUE)
#
#   df$CHR <- t[,1]
#   df$POS <- t[,2]
#   df$EffectAllele <- t[,3]
#   df$OtherAllele <-  t[,4]
#
#   dplyr::select(df, CHR,POS, EffectAllele, OtherAllele, dplyr::everything())
#
# }



check_correct_cols <- function(dset) {
  colnames <- names(dset$schema)
  req_cols <- c("ID", "B", "SE", "CHR")
  stopifnot(
  "Missing either ID, B,SE or CHR" =
    all(req_cols %in% colnames))



}

