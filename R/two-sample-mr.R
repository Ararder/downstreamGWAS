utils::globalVariables(c("CHR", "locus_id", "lead_snp", "pval", "CHROM"))

#' Run two-sample Mendelian randomisation on tidyGWAS data
#'
#' Uses the TwoSampleMR package to run MR with instruments derived from
#' LD-clumped loci. Requires `pipeline_clumping()` to have been run on the
#' exposure, or set `auto_clump = TRUE`.
#'
#' @param exposure_dir Path to tidyGWAS directory for the exposure trait.
#' @param outcome_dir Path to tidyGWAS directory for the outcome trait.
#' @param exposure_bed Path to a custom BED file defining lead SNPs. If `NULL`
#'   (default), uses `<exposure_dir>/analysis/clumping/merged_loci.bed`.
#' @param auto_clump If `TRUE` and no clumping output exists, automatically run
#'   `pipeline_clumping()` with local execution. Default `FALSE`.
#' @param r2 Passed to `pipeline_clumping()` when `auto_clump = TRUE`.
#'
#' @returns A list with `results` (MR estimates), `outcome_data` (harmonised
#'   data), and `pleiotropy` (MR-Egger intercept test).
#' @export
#'
#' @examples \dontrun{
#' mr_on_tidyGWAS("exposure/trait1", "outcome/trait2")
#' }
mr_on_tidyGWAS <- function(
    exposure_dir,
    outcome_dir,
    exposure_bed = NULL,
    auto_clump = FALSE,
    r2 = 0.01
) {
  bed_path <- exposure_bed %||% fs::path(exposure_dir, "analysis", "clumping", "merged_loci.bed")

  if (!fs::file_exists(bed_path)) {
    if (isTRUE(auto_clump)) {
      cli::cli_alert_warning("No clumping output found. Running pipeline_clumping() for {.path {exposure_dir}}")
      pipeline_clumping(exposure_dir, execute = TRUE, prepare_inputs = TRUE, r2 = r2)
      bed_path <- fs::path(exposure_dir, "analysis", "clumping", "merged_loci.bed")
    } else {
      stop(
        "No clumping output found at ", bed_path,
        ". Run pipeline_clumping() first, or set auto_clump = TRUE.",
        call. = FALSE
      )
    }
  }

  outcome_data <- harmonise_tidygwas(exposure_dir, outcome_dir, bed_path)

  results <- TwoSampleMR::mr(outcome_data) |>
    dplyr::mutate(
      exposure = fs::path_file(exposure_dir),
      outcome = fs::path_file(outcome_dir)
    )

  pleiotropy <- TwoSampleMR::mr_pleiotropy_test(outcome_data)

  list(results = results, outcome_data = outcome_data, pleiotropy = pleiotropy)
}


# internal helpers ---------------------------------------------------------

harmonise_tidygwas <- function(exposure_dir, outcome_dir, bed_path) {
  loci <- readr::read_tsv(
    bed_path,
    col_names = c("chr", "start", "end", "n_snps", "pval", "lead_snp"),
    col_types = "ciiccc",
    show_col_types = FALSE
  )

  # pick the most significant lead SNP per locus
  instruments <- loci |>
    dplyr::mutate(locus_id = paste0(chr, ":", start, "-", end)) |>
    tidyr::separate_longer_delim(c(pval, lead_snp), delim = ",") |>
    dplyr::mutate(pval = as.numeric(pval)) |>
    dplyr::slice_min(pval, n = 1, by = locus_id) |>
    dplyr::mutate(chr = stringr::str_remove(chr, "chr"))

  exposure_data <- extract_instruments_from_tidygwas(exposure_dir, instruments) |>
    TwoSampleMR::format_data(type = "exposure")

  outcome_data <- extract_instruments_from_tidygwas(outcome_dir, instruments) |>
    TwoSampleMR::format_data(type = "outcome")

  TwoSampleMR::harmonise_data(
    exposure_dat = exposure_data,
    outcome_dat = outcome_data
  )
}


extract_instruments_from_tidygwas <- function(parent_dir, instruments) {
  ds <- arrow::open_dataset(fs::path(parent_dir, "tidyGWAS_hivestyle"))

  purrr::imap(split(instruments, instruments$chr), \(x, chrom) {
    ds |>
      dplyr::filter(CHR == chrom) |>
      dplyr::filter(RSID %in% x$lead_snp) |>
      dplyr::select(
        SNP = RSID,
        beta = B,
        se = SE,
        effect_allele = EffectAllele,
        other_allele = OtherAllele,
        eaf = EAF
      ) |>
      dplyr::collect()
  }) |>
    purrr::list_rbind()
}
