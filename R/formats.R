sumstat <- "~/arvhar/update_gwas_sumstats/sumstats/accumbens/tidyGWAS_hivestyle/"

dir <- "~/arvhar/update_gwas_sumstats/sumstats/accumbens"

setup_paths <- function(dir) {

    base <- dir
  name <- fs::path_dir(dir)




  # ldsc --------------------------------------------------------------------

  ldsc <- list(
    ldsc_start = "ldsc_temp.csv"
    ldsc_munged = name

  )




  list(
    base = dir,
    name = fs::path_file(dir),
    hivestyle = fs::path(dir, "tidyGWAS_hivestyle"),
    analysis  = fs::path(dir, "analysis"),
    ldsc = fs::path(dir, "analysis/ldsc"),
    magma = fs::path(dir, "analysis/magma"),
    clumping = fs::path(dir, "analysis/clumping")
  )
}


write_existing_columns <- function(paths) {
  #
  outfile <- fs::path(fs::path_dir(paths$hivestyle), "existing_columns.txt")

  # connnect to dataframe and get column names
  dset <- arrow::open_dataset(paths$hivestyle)

  # save them to existing_columns.txt
  writeLines(dset$schema$names, outfile)


}

parse_input_format <- function(sumstat) {

  # tidyGWAS hivestyle
  if(fs::is_dir(sumstat) & fs::path_file(sumstat) == "tidyGWAS_hivestyle") {

    df <- arrow::open_dataset(sumstat) |>
      colnames() |>
      dplyr::collect()

  } else if(fs::path_ext(sumstat) == "parquet" & fs::is_file(sumstat)){
    df <- arrow::read_parquet(sumstat)

  }

  df
}

to_ldsc <- function(paths, system_paths) {
  hm3 <- arrow::read_tsv_arrow(system_paths$ldsc$hm3)
  dset <- arrow::open_dataset(paths$hivestyle)
  dplyr::filter(dset, RSID %in% hm3) |>
    dplyr::collect() |>
    arrow::write_csv_arrow()


}
