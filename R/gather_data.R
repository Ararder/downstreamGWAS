
collect_ldsc <- function(sumstat_repo) {
  ldsc <- fs::dir_ls(sumstat_repo, recurse=TRUE, glob="*ldsc/ldsc_h2.log")
  purrr::map(ldsc, parse_ldsc_h2) |>
    list_rbind()
}

collect_n_loci <- function(sumstat_repo) {
  loci <- dir_ls(sumstat_repo, recurse=TRUE, glob="*genome_wide_sig_loci.bed")

  purrr::map(loci, \(x) length(readLines(x))) |>
    purrr::imap(\(val, path)
                dplyr::tibble(
                  dataset_name = fs::path_file(fs::path_dir(fs::path_dir(fs::path_dir(path)))),
                  sig_loci = val
                )) |>
    purrr::list_rbind()



}

collect_n_snps <- function(sumstat_repo) {
  dset <- arrow::open_dataset(sumstat_repo)
}


n_snps_in_raw <- function(dir) {
  arrow::ParquetFileReader$create(paste0(dir, "/raw_sumstats.parquet"))$num_rows
}


n_snps_in_hivestyle <- function(dir) {

 fs::dir_ls(dir, glob = "*part-0.parquet", recurse = TRUE) |>
   purrr::map(\(X) arrow::ParquetFileReader$create(X)) |>
   purrr::map_dbl("num_rows") |>
   purrr::reduce(sum)
}

n_snp_summary <- function(sumstat_dir) {
  all_sumstats <- fs::dir_ls(sumstat_dir, type = "dir")

  after <- purrr::map(all_sumstats, n_snps_in_hivestyle) |>
    purrr::imap(\(val, name) dplyr::tibble(dataset_name = name, n_after_qc = val)) |>
    purrr::list_rbind()

  before <- purrr::map(all_sumstats, n_snps_in_raw) |>
    purrr::imap(\(val, name) dplyr::tibble(dataset_name = name, n_before_qc = val)) |>
    purrr::list_rbind()

  dplyr::left_join(before, after) |>
    dplyr::mutate(removed_rows = n_before_qc - n_after_qc) |>
    tibble()
}



