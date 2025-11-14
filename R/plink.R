utils::globalVariables(c("POS", "tmp", "chr", "start", "end", "N", "P", "SNP"))


#' Run a clumping pipeline on a tidyGWAS sumstats
#'
#' @param path filepath to tidyGWAS folder
#' @param output_dir directory to write clumping results
#'
#' @return bed file with clumps
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("/path/to/tidyGWAS")
#' }
run_clumping <- function(path, output_dir=NULL, ...) {

  paths <- tidyGWAS_paths(path)

  if(!is.null(output_dir)) {
    paths$clumping <- output_dir
  }
  workdir <- fs::dir_create(paths$clumping)


  sumstat <- in_work_dir("sumstats.tsv")
  genome_ref <- in_ref_dir(paths$system_paths$genome_refs$deep_1kg)
  gene_list <- in_ref_dir("plink/glist-hg38")

  code <- clump_plink(
    sumstat = sumstat,
    ref = genome_ref,
    range = gene_list,
    ...
  )


  script <- with_container(
    code,
    image = "plink",
    workdir = workdir
  )

  setup_file <- glue::glue("R -e \"downstreamGWAS::to_clumping('{paths$hivestyle}','{paths$clumping}')\"")
  format <- glue::glue("R -e \"downstreamGWAS::ranges_to_bed('{paths$clumping}')\"")
  bedtools_code <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container /bin/bash -c \"bedtools merge -d 50000 -i /mnt/clumps.bed -c 4,5,6 -o sum,collapse,collapse > /mnt/merged_loci.bed\"")
  cleanup <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container rm /mnt/sumstats.tsv")
  script  <- c(setup_file, script,"\n", format,"\n", bedtools_code, cleanup)



  script_path <- fs::path(workdir, "clumping_job.sh")
  writeLines(script, script_path)
  script_path

}


#' Convert the output of plink clumping ranges to a flat file
#'
#' @param clump_dir directory where plink clumping output is stored
#'
#' @returns NULL
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("/path/to/clumping/dir")
#' }
ranges_to_bed <- function(clump_dir){

  out <- fs::path(clump_dir, "clumps.bed")

  readr::read_table(fs::path(clump_dir, "clumps.clumped.ranges"))  |>
    dplyr::mutate(
      chr = stringr::word(POS, 1, sep = stringr::fixed(":")),
      tmp = stringr::word(POS, 2, sep = stringr::fixed(":")),
      start = as.integer(stringr::word(tmp, 1, sep = stringr::fixed(".."))),
      end = as.integer(stringr::word(tmp, 2, sep = stringr::fixed("..")))
    )  |>
    dplyr::arrange(chr, start, end)  |>
    dplyr::select(chr, start, end, N, P, SNP)  |>
    readr::write_tsv(out, col_names = FALSE)
}



#' Prepare tidyGWAS sumstats for PLINK clumping
#'
#' @param hivestyle_path path to tidyGWAS hivestyle dataset
#' @param output_dir directory to write sumstats.tsv
#'
#' @returns NULL
#' @export
#'
#' @examples \dontrun{
#' to_clumping("/path/to/hivestyle/dataset", "/path/to/output/dir")
#' }
to_clumping <- function(hivestyle_path, output_dir) {

  arrow::open_dataset(hivestyle_path) |>
    dplyr::select(RSID, P) |>
    dplyr::filter(!is.na(RSID)) |>
    dplyr::collect() |>
    readr::write_tsv(fs::path(output_dir, "sumstats.tsv"))

}





clump_plink <- function(
    sumstat,
    p1 = "5e-08",
    p2 = "5e-06",
    r2 = 0.1,
    kb = 3000,
    snp_field = "RSID" ,
    p_field = "P",
    ref,
    range
) {
  glue::glue(
    "plink --bfile {ref} ",
    "--clump {sumstat} ",
    "--out /mnt/clumps ",
    "--clump-p1 {p1} ",
    "--clump-p2 {p2} ",
    "--clump-r2 {r2} ",
    "--clump-kb {kb} ",
    "--clump-snp-field {snp_field} ",
    "--clump-range {range} ",
    "--clump-field {p_field} "
  )

}



