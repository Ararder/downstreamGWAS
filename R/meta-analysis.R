

align_to_ref <- function(dset) {
  # EffectAllele is harmonized to be reference allele
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
meta_analyze_by_chrom <- function(dset) {
  # ids <-
  #   dset |>
  #   align_to_ref() |>
  #   dplyr::filter(!multi_allelic) |>
  #   dplyr::select(RSID, CHR, POS, EffectAllele, OtherAllele) |>
  #   dplyr::distinct() |>
  #   dplyr::collect()

  step1 <- dset |>
    dplyr::filter(!multi_allelic) |>
    align_to_ref() |>
    dplyr::select(dplyr::any_of(c("RSID","CHR", "POS", "EffectAllele","OtherAllele", "B", "SE", "EAF", "N", "CaseN", "ControlN","INFO"))) |>
    dplyr::mutate(
      w = 1 / (SE^2),
      B = B*w,
      EAF = EAF*N,
      INFO = INFO*N
    ) |>
    dplyr::group_by(RSID)


  if(all(c("CaseN", "ControlN") %in% names(dset$schema))) {

    step2 <- step1 |>
      dplyr::summarise(
        W = sum(w),
        n_contributions = dplyr::n(),
        B = sum(B),
        N = sum(N, na.rm = TRUE),
        EAF = sum(EAF, na.rm =TRUE),
        INFO = sum(INFO, na.rm = TRUE),
        CaseN = sum(CaseN),
        ControlN = sum(ControlN)
        )

  } else {

    step2 <- step1 |>
      dplyr::summarise(
        W = sum(w),
        n_contributions = dplyr::n(),
        B = sum(B),
        N = sum(N, na.rm = TRUE),
        EAF = sum(EAF, na.rm =TRUE),
        INFO = sum(INFO, na.rm = TRUE)
      )

  }

  step2 |>
    dplyr::mutate(
      B = B / W,
      SE = 1 / sqrt(W),
      EAF = EAF / N,
      INFO = INFO / N
    ) |>
    dplyr::select(-W) |>
    dplyr::collect() |>
    dplyr::mutate(P  = stats::pnorm(-abs(B/SE)) *2)

}

meta_analyze <- function(dset) {
  purrr::map(c(1:22), \(chrom) meta_analyze_by_chrom(dset, chrom = chrom)) |>
    purrr::list_rbind()
}

# meta_duckdb <- function(dset) {
#   dset |>
#     dplyr::filter(!multi_allelic) |>
#     align_to_ref() |>
#     dplyr::select(dplyr::any_of(c("RSID","CHR", "POS", "EffectAllele","OtherAllele", "B", "SE", "EAF", "N", "CaseN", "ControlN","INFO"))) |>
#     dplyr::mutate(
#       w = 1 / (SE^2),
#       B = B*w,
#       EAF = EAF*N,
#       INFO = INFO*N
#     ) |>
#     to_duckdb() |>
#     dplyr::group_by(RSID) |>
#     mutate(
#       W = sum(w),
#       N = sum(N, na.rm = TRUE)
#       ) |>
#     dplyr::mutate(
#       n_contributions = dplyr::n(),
#       B = sum(B) / W,
#       EAF = sum(EAF, na.rm =TRUE) / N,
#       INFO = sum(INFO, na.rm = TRUE) / N
#     ) |>
#   dplyr::slice_head(n=1) |>
#   dplyr::collect()
#   dplyr::mutate(P  = stats::pnorm(-abs(B/SE)) *2)
#
# }




