utils::globalVariables(c("POS", "tmp", "chr", "start", "end", "N", "P", "SNP"))


#' Run a clumping pipeline on a tidyGWAS sumstats
#'
#' @param path filepath to tidyGWAS folder
#'
#' @return bed file with clumps
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("/path/to/tidyGWAS")
#' }
run_clumping <- function(path) {

    paths <- tidyGWAS_paths(path)

    workdir <- paths$clumping
    fs::dir_create(workdir)


    sumstat <- in_work_dir("sumstats.tsv")
    genome_ref <- in_ref_dir(paths$system_paths$genome_refs$merged_1kg)
    gene_list <- in_ref_dir("plink/glist-hg19")

    code <- clump_plink(
        sumstat = sumstat,
        ref = genome_ref,
        range = gene_list,
        outdir = "/mnt"
    )


   script <- with_container(
        code,
        image = "plink",
        workdir = workdir
    )

    setup_file <- glue::glue("R -e \"downstreamGWAS::to_clumping('{path}')\"")
    format <- glue::glue("R -e \"downstreamGWAS::ranges_to_bed('{path}')\"")
    bedtools_code <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container /bin/bash -c \"bedtools merge -d 50000 -i /mnt/clumps.bed -c 4,5 -o sum,min > /mnt/merged_loci.bed\"")
    cleanup <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container rm /mnt/sumstats.tsv")
    script  <- c(setup_file, script,"\n", format,"\n", bedtools_code, cleanup)



    script_path <- fs::path(workdir, "clumping_job.sh")
    writeLines(script, script_path)
    script_path

}


#' Convert plink ranges file to bed
#'
#' @param path filepath to tidyGWAS folder
#'
#' @return bed file with clumps
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("/path/to/tidyGWAS")
#' }
ranges_to_bed <- function(path){

  paths <- tidyGWAS_paths(path)
  out <- fs::path(paths$clumping, "clumps.bed")

  readr::read_table(fs::path(paths$clumping, "clumps.clumped.ranges"))  |>
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




clump_plink <- function(
    sumstat,
    p1 = "5e-08",
    p2 = "5e-06",
    r2 = 0.1,
    kb = 3000,
    snp_field = "RSID" ,
    p_field = "P",
    outdir,
    ref,
    range
) {
  glue::glue(
    "plink --bfile {ref} ",
    "--clump {sumstat} ",
    "--out {outdir}/clumps ",
    "--clump-p1 {p1} ",
    "--clump-p2 {p2} ",
    "--clump-r2 {r2} ",
    "--clump-kb {kb} ",
    "--clump-snp-field {snp_field} ",
    "--clump-range {range} ",
    "--clump-field {p_field} "
  )

}

#' Convert tidyGWAS to file with RSID and P for clumping
#'
#' @param path filepath to tidyGWAS folder
#'
#' @return writes out a tsv.gz file
#' @export
#'
#' @examples \dontrun{
#' to_clumping("/path/to/tidyGWAS")
#' }
to_clumping <- function(path) {
  paths <- tidyGWAS_paths(path)
  workdir <- paths$clumping
  fs::dir_create(workdir)
  arrow::open_dataset(paths$hivestyle) |>
    dplyr::select(RSID, P) |>
    dplyr::filter(!is.na(RSID)) |>
    dplyr::collect() |>
    readr::write_tsv(fs::path(workdir, "sumstats.tsv"))

}


