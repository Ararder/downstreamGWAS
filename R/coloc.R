utils::globalVariables(c("snp", "position", "SNP.PP.H4", "POS_38", "ancestry"))

# run_coloc is not yet ready for export; the implementation is kept here
# commented out until it is finished.
# run_coloc <- function(
#     parent_dir,
#     parent_dir2,
#     chrom,
#     start,
#     end,
#     min_pval = 5e-08,
#     trait_type1 = c("guess", "cc", "quant"),
#     trait_type2 = c("guess", "cc", "quant"),
#     p1 = 1e-4,
#     p2 = 1e-4,
#     p12 = 1e-5
# ) {
#   trait_type1 <- rlang::arg_match(trait_type1)
#   trait_type2 <- rlang::arg_match(trait_type2)
#   chrom <- as.character(chrom)
#
#   ds1 <- open_tidygwas(parent_dir)
#   ds2 <- open_tidygwas(parent_dir2)
#
#   if (trait_type1 == "guess") {
#     trait_type1 <- if ("CaseN" %in% names(ds1$schema)) "cc" else "quant"
#   }
#   if (trait_type2 == "guess") {
#     trait_type2 <- if ("CaseN" %in% names(ds2$schema)) "cc" else "quant"
#   }
#
#   cli::cli_alert_info("Trait type 1: {trait_type1}, Trait type 2: {trait_type2}")
#
#   t1 <- extract_coloc_region(ds1, trait_type = trait_type1, chrom = chrom, start = start, end = end)
#   t2 <- extract_coloc_region(ds2, trait_type = trait_type2, chrom = chrom, start = start, end = end)
#
#   t1 <- dplyr::filter(t1, !is.na(EAF))
#   t2 <- dplyr::filter(t2, !is.na(EAF))
#
#   if (nrow(t2) == 0 || min(t2$P) > min_pval) {
#     return(NULL)
#   }
#
#   shared_rsids <- intersect(t1$RSID, t2$RSID)
#
#   cli::cli_alert_info("Region: chr{chrom}:{start}-{end}")
#   cli::cli_alert_info("Variants in dataset 1: {nrow(t1)}")
#   cli::cli_alert_info("Variants in dataset 2: {nrow(t2)}")
#   cli::cli_alert_info("Variants in common: {length(shared_rsids)}")
#   cli::cli_alert_info("Min p-value in dataset 1: {min(t1$P)}")
#   cli::cli_alert_info("Min p-value in dataset 2: {min(t2$P)}")
#
#   t1 <- dplyr::filter(t1, RSID %in% shared_rsids) |> as_coloc_dataset(trait_type = trait_type1)
#   t2 <- dplyr::filter(t2, RSID %in% shared_rsids) |> as_coloc_dataset(trait_type = trait_type2)
#
#   coloc::check_dataset(t1)
#   coloc::check_dataset(t2)
#
#   coloc::coloc.abf(t1, t2, p1 = p1, p2 = p2, p12 = p12)
# }


#' Format coloc::coloc.abf output into a tidy tibble
#'
#' @param coloc_obj Output of [coloc::coloc.abf()].
#' @param name Label for this coloc test (e.g. trait pair or locus name).
#'
#' @returns A [dplyr::tibble()] with columns: `name`, `n_snps`, `PP.H4`,
#'   and `top_snps` (comma-separated RSIDs with highest PP.H4).
#' @export
#'
#' @examples \dontrun{
#' format_coloc(result, "scz_vs_bip_chr7")
#' }
format_coloc <- function(coloc_obj, name) {
  s <- coloc_obj$summary

  top_snps <- coloc_obj$results |>
    dplyr::tibble() |>
    dplyr::arrange(dplyr::desc(SNP.PP.H4)) |>
    dplyr::slice_head(n = 10) |>
    dplyr::pull(snp) |>
    stringr::str_flatten(collapse = ",")

  dplyr::tibble(
    name = name,
    n_snps = s[["nsnps"]],
    PP.H4 = s[["PP.H4.abf"]],
    top_snps = top_snps
  )
}


# internal helpers ---------------------------------------------------------

as_coloc_dataset <- function(df, trait_type) {
  list(
    beta     = df$B,
    varbeta  = df$SE^2,
    MAF      = ifelse(df$EAF > 0.5, 1 - df$EAF, df$EAF),
    N        = df$N,
    snp      = df$RSID,
    position = df$POS_38,
    type     = trait_type
  )
}
open_tidygwas <- function(path) {

}


extract_coloc_region <- function(dataset, trait_type, chrom, start, end) {
  df <- dataset |>
    dplyr::filter(CHR == chrom) |>
    dplyr::filter(POS_38 >= start & POS_38 <= end) |>
    dplyr::filter(!is.na(RSID)) |>
    dplyr::filter(!multi_allelic) |>
    dplyr::select(
      POS_38, RSID, B, SE, P,
      dplyr::any_of(c("EAF", "EffectiveN", "N")),
      "EffectAllele", "OtherAllele"
    ) |>
    dplyr::collect()

  if (!"EAF" %in% colnames(df)) {
    df <- impute_eaf_from_1kg(df, chrom, start, end)
  }

  if (trait_type == "cc" && "EffectiveN" %in% colnames(df)) {
    df <- dplyr::mutate(df, N = EffectiveN) |>
      dplyr::select(-EffectiveN)
  }

  df
}


impute_eaf_from_1kg <- function(df, chrom, start, end) {
  cfg <- dsg_get_config()
  params <- parse_params()
  dbsnp_path <- fs::path(cfg$reference_dir, params$tidyGWAS$ref)

  if (!fs::dir_exists(dbsnp_path)) {
    cli::cli_warn("EAF is missing and dbSNP reference not found at {.path {dbsnp_path}}. Cannot impute EAF.")
    df$EAF <- NA_real_
    return(df)
  }

  freq <- arrow::open_dataset(fs::path(dbsnp_path, "EAF_REF_1KG")) |>
    dplyr::filter(ancestry == "EUR") |>
    dplyr::filter(CHR == chrom) |>
    dplyr::select(-ancestry, -CHR) |>
    dplyr::filter(POS >= start & POS <= end) |>
    dplyr::collect()

  matched_same <- dplyr::inner_join(
    df, freq,
    by = c("POS_38" = "POS", "EffectAllele", "OtherAllele")
  )
  matched_flip <- dplyr::inner_join(
    df, freq,
    by = c("POS_38" = "POS", "EffectAllele" = "OtherAllele", "OtherAllele" = "EffectAllele")
  ) |>
    dplyr::mutate(EAF = 1 - EAF)

  dplyr::bind_rows(matched_same, matched_flip) |>
    dplyr::distinct(RSID, .keep_all = TRUE)
}
