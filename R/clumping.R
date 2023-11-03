utils::globalVariables(c("POS", "tmp", "chr", "start", "end", "N", "P", "SNP"))


#' Construct genetic loci from GWAS
#'
#' @param path
#'
#' @return a filepath to a slurm job
#' @export
#'
#' @examples
run_clumping <- function(path) {

  paths <- tidyGWAS_paths(path)
  plink <- clump_plink(paths)
  fs::dir_create(paths$clumping)
  out_slurm <- fs::path(fs::path_real(paths$clumping), "slurm-%j.out")

  slurm_header <- c(
    "#!/bin/bash",
    "#SBATCH --mem=10gb",
    "#SBATCH --time=1:00:00",
    glue::glue("#SBATCH --output={out_slurm}")
  )

  format_tidyGWAS <- glue::glue("R -e 'downstreamGWAS::to_plink_clumping(commandArgs(trailingOnly = TRUE)[1])'")|>
    paste0(" --args ", path)

  # to merge nearby loci with bedtools, we need to change format of outputfile
  format_munge <- glue::glue("R -e 'downstreamGWAS::ranges_to_bed(commandArgs(trailingOnly = TRUE)[1],commandArgs(trailingOnly=TRUE)[2])'") |>
    paste0(" --args", " ", fs::path(paths$clumping, "clumps.clumped.ranges"), " ", fs::path(paths$clumping, "clumps.bed"))

  # create the bedtools command
  bed_i <- fs::path(paths$clumping, "clumps.bed")
  bed_out <- fs::path(paths$clumping, "genome_wide_sig_loci.bed")
  bed <- glue::glue("bedtools merge -d 50000 -i {bed_i} -c 4,5,6 -o sum,collapse,collapse > {bed_out}")

  remove_temp_file <- glue::glue("rm {paths$clump_temp}")
  job <- c(slurm_header,"\n", "module load bedtools", "module load plink", format_tidyGWAS, plink, format_munge, bed, remove_temp_file)
  writeLines(job, fs::path(paths$clumping, "clump_job.sh"))
  fs::path(paths$clumping, "clump_job.sh")

}



#' Convert tidyGWAS hivestyle partitioning to compatible format for plink clumping
#'
#' @param dir filepath to tidyGWAS folder
#'
#' @return writes a file to disk
#' @export
#'
#' @examples \dontrun{
#' paths <- tidyGWAS_paths("/my_sumstat/cleaned/")
#' to_plink_clumping(paths)
#' }
to_plink_clumping <- function(dir) {
  dset <- arrow::open_dataset(paste0(dir, "/tidyGWAS_hivestyle"))
  paths <- tidyGWAS_paths(dir)

  dplyr::select(dset, RSID, P) |>
    dplyr::collect() |>
    data.table::fwrite(paths$clump_temp, sep = "\t")

}

clump_plink <- function(
    paths,
    p1 = "5e-08",
    p2 = "5e-06",
    r2 = 0.1,
    kb = 3000,
    snp_field = "RSID"
) {
  glue::glue(
    "plink --bfile {paths$system_paths$plink$genome_ref} ",
    "--clump {paths$clump_temp} ",
    "--out {paths$clumping}/clumps ",
    "--clump-p1 {p1} ",
    "--clump-p2 {p2} ",
    "--clump-r2 {r2} ",
    "--clump-kb {kb} ",
    "--clump-snp-field {snp_field} ",
    "--clump-field P ",
    "--clump-range {paths$system_paths$plink$gene_ref} "
  )

}


#' Convert the clumping.ranges format from plink --clump to bed compatible format
#'
#' @param infile a clumping.ranges file from plink --clump
#' @param out filename of output
#'
#' @return a character vector of commandline code
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("analysis/plink/clumping/scz2022.clumping.ranges", "scz2022_clumping/ranges.bed")
#' }
ranges_to_bed <- function(infile, out){

  data.table::fread(infile) |>
    dplyr::mutate(
      chr = stringr::word(POS, 1, sep = stringr::fixed(":")),
      tmp = stringr::word(POS, 2, sep = stringr::fixed(":")),
      start = as.integer(stringr::word(tmp, 1, sep = stringr::fixed(".."))),
      end = as.integer(stringr::word(tmp, 2, sep = stringr::fixed("..")))
    ) |>
    dplyr::arrange(chr, start, end) |>
    dplyr::select(chr, start, end, N, P, SNP) |>
    data.table::fwrite(out, col.names = FALSE, sep = "\t")
}
