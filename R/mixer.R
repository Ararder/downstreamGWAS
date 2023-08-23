#
#
# name <- "iq"
# write_mixer <- function(name) {
#   dset <- arrow::open_dataset("~/arvhar/update_gwas_sumstats/sumstats/{name}")
#
#   sumstat <- dplyr::select(
#     dset, SNP = "RSID", CHR = "CHR_37", BP = "POS_37",
#     A1 = "EffectAllele", A2 = "OtherAllele", N, Z) |>
#     dplyr::filter(!(BP >= 26e6 & BP <= 34e6 & CHR == "6")) |>
#     dplyr::collect()
#
# }
