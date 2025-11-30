utils::globalVariables(c("CHR", "X1", "X2","X3", "X4", "X5", "X6", "id"))

#' Run two-sample mendelian randomisation using the TwoSampleMR package
#'
#' @param exposure_dir path to tidyGWAS directory of the exposure
#' @param outcome_dir path to tidyGWAS directory of the outcome
#' @param exposure_bed Use a custom bed file to define lead SNPs? Default is NULL,
#'  and downstreamGWAS will run [run_clumping()] if no bed file exists.
#' @param bidirectional run with outcome as exposure and exposure as outcome as well?
#' @param r2 r2 to pass to plink2 clumping
#'
#' @returns a list
#' @export
#'
#' @examples \dontrun{
#' mr_on_tidyGWAS("exp_dir/trait1", "outcomes/trait2")
#' }
mr_on_tidyGWAS <- function(exposure_dir, outcome_dir, exposure_bed = NULL, bidirectional = FALSE,r2 = 0.01) {

  if(is.null(exposure_bed)) {
    check_clumping(exposure_dir, r2 = r2)
  }


  outcome_data <- to_2smr(exposure_dir = exposure_dir, outcome_dir = outcome_dir,exposure_bed = exposure_bed)


  results <- dplyr::mutate(
    TwoSampleMR::mr(outcome_data),
    exposure = fs::path_file(fs::path_file(exposure_dir)),
    outcome = fs::path_file(fs::path_file(outcome_dir))
  )

  if(isTRUE(bidirectional)) {
    as_exp <- TwoSampleMR::mr(to_2smr(
      exposure_dir = outcome_dir,
      outcome_dir = exposure_dir
    )) |>
      dplyr::mutate(exposure = fs::path_file(fs::path_file(outcome_dir)),outcome = fs::path_file(fs::path_file(exposure_dir)))

    results <-dplyr::bind_rows(results, as_exp)

  }

  pleiotropy <- TwoSampleMR::mr_pleiotropy_test(outcome_data)
  list("results" = results, "outcome_data" = outcome_data, "pleiotropy" = pleiotropy)

}

to_2smr <- function(exposure_dir, outcome_dir, exposure_bed = NULL, ...) {
  if(!is.null(exposure_bed)) {
    bed_path <- exposure_bed
  } else {
    bed_path <- fs::path(exposure_dir, "analysis/clumping/merged_loci.bed")
  }

  variants <- readr::read_table(bed_path, col_names = FALSE) |>
    dplyr::mutate(id = paste0(X1, ":", X2, "-", X3)) |>
    tidyr::separate_longer_delim(c(X5, X6), delim = ",") |>
    dplyr::mutate(X5 = as.numeric(X5)) |>
    dplyr::slice_min(X5, n = 1, by = id) |>
    dplyr::select(X1, X6) |>
    dplyr::mutate(X1 = stringr::str_remove(X1, "chr"))

  exposure_data <- purrr::imap(split(variants, variants$X1), \(x, CHROM) {
    s <- arrow::open_dataset(fs::path(exposure_dir, "tidyGWAS_hivestyle"))$schema
    s$CHR <- arrow::field("CHR", arrow::string())

    arrow::open_dataset(fs::path(exposure_dir, "tidyGWAS_hivestyle"), schema = s) |>
      dplyr::filter(CHR == CHROM) |>
      dplyr::filter(RSID %in% x$X6) |>
      dplyr::select(
        SNP = RSID,
        beta = B,
        se = SE,
        effect_allele = EffectAllele,
        other_allele = OtherAllele,
        eaf = EAF,
      ) |>
      dplyr::collect()
  }) |>
    purrr::list_rbind() |>
    TwoSampleMR::format_data(dat = _, type = "exposure")


  outcome_data <- purrr::imap(split(variants, variants$X1), \(x, CHROM) {
    s <- arrow::open_dataset(fs::path(outcome_dir, "tidyGWAS_hivestyle"))$schema
    s$CHR <- arrow::field("CHR", arrow::string())


    arrow::open_dataset(fs::path(outcome_dir, "tidyGWAS_hivestyle"), schema = s) |>
      dplyr::filter(CHR == CHROM) |>
      dplyr::filter(RSID %in% x$X6) |>
      dplyr::select(
        SNP = RSID,
        beta = B,
        se = SE,
        effect_allele = EffectAllele,
        other_allele = OtherAllele,
        eaf = EAF,

      ) |>
      dplyr::collect()
  }) |>
    purrr::list_rbind() |>
    TwoSampleMR::format_data(dat = _, type = "outcome")

  TwoSampleMR::harmonise_data(
    exposure_dat = exposure_data,
    outcome_dat = outcome_data
  )
}

check_clumping <- function(parent_dir, r2 = 0.01) {
  exists <- fs::path(parent_dir, "analysis/clumping/merged_loci.bed") |> fs::file_exists()
  if(!exists) {
    cli::cli_alert_warning("Running clumping for {parent_dir}")
    system(paste0("sh ", run_clumping(parent_dir, r2 = 0.01)))
  } else {
    message("Clumping already done for ", parent_dir)
  }
}



