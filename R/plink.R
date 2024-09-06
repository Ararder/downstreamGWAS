utils::globalVariables(c("POS", "tmp", "chr", "start", "end", "N", "P", "SNP"))


# path <- "/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/wave1/scz2022_eur"
run_clumping <- function(path) {

    paths <- tidyGWAS_paths(path)

    workdir <- paths$clumping
    fs::dir_create(workdir)
    # arrow::open_dataset(paths$hivestyle) |>
    #     dplyr::select(RSID, P) |>
    #     dplyr::collect() |>
    #     readr::write_tsv(fs::path(workdir, "sumstats.tsv.gz"))


    sumstat <- in_work_dir("sumstats.tsv.gz")
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


    format <- glue::glue("R -e \"downstreamGWAS::ranges_to_bed('{path}')\"")
    bedtools_code <- with_container(
        glue::glue("bedtools merge -d 50000 -i clumps.bed -c 4,5 -o sum,min > merged_loci.bed"),
        image = "plink",
        setup_exists = TRUE,
        workdir = workdir
    )

    script  <- c(script,"\n", format,"\n", bedtools_code)




    writeLines(script, "test.sh")



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
