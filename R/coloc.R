utils::globalVariables(c("snp", "position", "SNP.PP.H4", "POS_38", "ancestry", ""))

#' Run coloc::coloc.abf on tidyGWAS data
#'
#' @param parent_dir tidyGWAS directory of GWAS
#' @param parent_dir2 tidyGWAS directory of GWAS
#' @param chr chromosome
#' @param start start of region
#' @param end end of region
#' @param trait_type1 quantitative or case-control?
#' @param trait_type2 quantitative or case-control?
#' @param p1 prior for colof.abf
#' @param p2 prior for colof.abf
#' @param p12 prior for colof.abf
#'
#' @returns output of [coloc::coloc.abf()]
#' @export
#'
#' @examples \dontrun{
#' run_coloc("path/trait1", "path/trait2")
#' }
run_coloc <- function(
    parent_dir, parent_dir2, chr,start,end,
    trait_type1=c("guess","cc", "quant"), trait_type2=c("guess","cc", "quant"),
    p1=1e-4, p2=1e-4, p12 = 1e-5
) {
  trait_type1 <- rlang::arg_match(trait_type1)
  trait_type2 <- rlang::arg_match(trait_type2)

  ds1 <- arrow::open_dataset(parent_dir)
  ds2 <- arrow::open_dataset(parent_dir2)

  if(trait_type1 == "guess") {
    trait_type1 <- ifelse("CaseN" %in% colnames(ds1), "cc", "quant")
  }

  if(trait_type2 == "guess") {
    trait_type2 <- ifelse("CaseN" %in% colnames(ds2), "cc", "quant")
  }

  cli::cli_alert_info("Trait type 1: {trait_type1}, Trait type 2: {trait_type2}")




  t1 <- tidyGWAS_to_coloc(tidygwas = ds1, trait_type = trait_type1, chr = chr, start = start, end = end) |> dplyr::filter(!is.na(EAF))
  t2 <- tidyGWAS_to_coloc(tidygwas = ds2, trait_type = trait_type2, chr = chr, start = start, end = end) |> dplyr::filter(!is.na(EAF))



  RSID_union <- intersect(t1$RSID, t2$RSID)
  # inform about region
  cli::cli_alert_info("Region: chr {chr} : {start} - {end}")
  # number of variants found in each dataset
  cli::cli_alert_info("Number of variants in dataset 1: {nrow(t1)}")
  cli::cli_alert_info("Number of variants in dataset 2: {nrow(t2)}")
  # largest smallest and largest p-value
  cli::cli_alert_info("Smallest p-value in dataset 1: {min(t1$P)}")
  cli::cli_alert_info("Smallest p-value in dataset 2: {min(t2$P)}")
  # number of variants in common
  cli::cli_alert_info("Number of variants in common: {length(RSID_union)}")

  t1 <- dplyr::filter(t1, RSID %in% RSID_union) |>
    coloc_dataset(tidydf = _, trait_type = trait_type1)
  t2 <- dplyr::filter(t2, RSID %in% RSID_union) |>
    coloc_dataset(tidydf = _, trait_type = trait_type2)

  coloc::check_dataset(t1)
  coloc::check_dataset(t2)

  coloc::coloc.abf(t1, t2, p1=p1, p2=p2, p12 = p12)
}

#' Format the output of [coloc::coloc.abf()]
#'
#' @param coloc_obj output of coloc call
#' @param name name of trait
#'
#' @returns a [dplyr::tibble()]
#' @export
#'
#' @examples \dontrun{
#' format_coloc(ob, "test-run")
#' }
format_coloc <- function(coloc_obj, name) {
  x <- coloc_obj$summary
  names(x) <- NULL


  topsnps <-
    coloc_obj[[2]] |>
    dplyr::tibble() |>
    dplyr::select(snp, position, SNP.PP.H4) |>
    dplyr::arrange(dplyr::desc(SNP.PP.H4)) |>
    dplyr::slice(1:10) |>
    dplyr::pull(snp) |>
    stringr::str_flatten(collapse = ",")


  dplyr::tibble(
    name = name,
    prob_coloc = x[6],
    n_snps = x[1],
    top_snps = topsnps,
  )
}


# helpers -----------------------------------------------------------------


# ----------------------------------------------------------------
# COLOCiSATION

coloc_dataset <- function(tidydf, sdY= NULL, trait_type = "quant") {
  list(
    beta     = tidydf$B,
    varbeta  = tidydf$SE^2,
    MAF      = ifelse(tidydf$EAF > 0.5, 1 - tidydf$EAF, tidydf$EAF),
    N        = tidydf$N,
    snp      = tidydf$RSID,
    position = tidydf$POS_38,
    type     = trait_type
    #    sdY      = sdY
  )           # keep NULL for most GWAS
}


tidyGWAS_to_coloc <- function(tidygwas, trait_type = "cc",chr,start, end) {
  t1 <- dplyr::filter(tidygwas, CHR == chr) |>
    dplyr::filter(POS_38 >= start & POS_38 <= end) |>
    dplyr::filter(!is.na(RSID)) |>
    dplyr::filter(!multi_allelic) |>
    dplyr::select(POS_38, RSID, B, SE, P, dplyr::any_of(c("EAF")), dplyr::any_of(c("EffectiveN", "N")), "EffectAllele", "OtherAllele") |>
    dplyr::collect()

  if(!"EAF" %in% colnames(t1)) {
    freq <- arrow::open_dataset(fs::path(Sys.getenv("dbsnp"),"EAF_REF_1KG")) |>
      dplyr::filter(ancestry == "EUR") |>
      dplyr::filter(CHR == chr) |>
      dplyr::select(-ancestry, -CHR) |>
      dplyr::filter(POS >= start & POS <= end) |>
      dplyr::collect()

    t1 <- dplyr::bind_rows(
      dplyr::inner_join(t1, freq, by = c("POS_38" = "POS", "EffectAllele", "OtherAllele")),
      dplyr::inner_join(t1, freq, by = c("POS_38" = "POS", "EffectAllele" = "OtherAllele", "OtherAllele" = "EffectAllele")) |> dplyr::mutate(EAF = 1 - EAF)
    )




  }

  if(trait_type == "cc" & "EffectiveN" %in% colnames(t1)) {
    t1 <- dplyr::select(t1, dplyr::everything(), N = EffectiveN, -dplyr::any_of("N"))
  }
  t1

}
