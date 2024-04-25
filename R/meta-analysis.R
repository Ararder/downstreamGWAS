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

meta_analyze_by_chrom <- function(dset, chrom, by) {
  stats <- c("B", "SE", "EAF", "N", "CaseN", "ControlN","INFO")
  cols <- c(by, stats)

  dset |>
    dplyr::filter(CHR == {{ chrom }}) |>
    dplyr::filter(!is.na(ID)) |>
    dplyr::filter(is.finite(B) & is.finite(SE)) |>
    align_to_ref() |>
    dplyr::select(dplyr::any_of(cols)) |>
    dplyr::mutate(
      W = 1 / (SE^2),
      B = B*W,
      dplyr::across(dplyr::any_of(c("EAF", "INFO")), ~.x * N)
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::summarise(
      n_contributions = dplyr::n(),
      dplyr::across(dplyr::any_of(c("W", "B")), sum),
      dplyr::across(dplyr::any_of(c("EAF", "INFO", "CaseN", "ControlN", "N")), ~sum(.x, na.rm=T))
    ) |>
    dplyr::ungroup() |>
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
meta_analyze <- function(dset, by = c("CHR", "POS", "RSID", "EffectAllele", "OtherAllele"), method = c("ivw")) {
  method <- rlang::arg_match(method)
  purrr::map(c(1:22), \(chrom) meta_analyze_by_chrom(dset, chrom = chrom, by = by)) |>
    purrr::list_rbind()
}





