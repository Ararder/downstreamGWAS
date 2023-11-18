utils::globalVariables(c("POS", "tmp", "chr", "start", "end", "N", "P", "SNP"))



#' Construct genetic loci from GWAS
#'
#' @inheritParams run_ldsc
#'
#' @return a filepath to a clumping script
#' @export
#'
#' @examples \dontrun{
#' run_clumping("/my_sumstat/cleaned/")
#' }
run_clumping <- function(parent_folder, write_script = c("no", "yes")) {

  # get paths & make sure output folder exists
  paths <- tidyGWAS_paths(parent_folder)
  fs::dir_create(paths$clumping)
  write_script = rlang::arg_match(write_script)

  # -------------------------------------------------------------------------


  # create code to run plink
  plink_code <- clump_plink(paths)

  # code to convert tidyGWAS to tsv
  format_tidyGWAS <- glue::glue("R -e 'downstreamGWAS::to_plink_clumping(commandArgs(trailingOnly = TRUE)[1])'")|>
    paste0(" --args ", paths$base)

  # to merge nearby loci with bedtools, we need to change format of outputfile
  format_to_bed <- glue::glue("R -e 'downstreamGWAS::ranges_to_bed(commandArgs(trailingOnly = TRUE)[1],commandArgs(trailingOnly=TRUE)[2])'") |>
    paste0(" --args", " ", fs::path(paths$clumping, "clumps.clumped.ranges"), " ", fs::path(paths$clumping, "clumps.bed"))

  # create bedtools merge command to merge loci that close to each other
  bedtools_merge <- glue::glue("{call_bedtools(paths$clumping)} sh -c \"bedtools merge -d 50000 -i clumps.bed -c 4,5,6 -o sum,collapse,collapse > genome_wide_sig_loci.bed\"")
  
  # clean up tmp files
  remove_temp_file <- glue::glue("rm {paths$clump_temp}")

  # make a script path
  script_path <- fs::path(paths$clumping, "clump_script.sh")

  # write merge parts and write script to disk
  job <- c(get_dependencies(), format_tidyGWAS, plink_code, format_to_bed, bedtools_merge, remove_temp_file)


  # return path to script ---------------------------------------------------

  if(write_script == "yes") {
    writeLines(job, script_path)
    system(glue::glue("chmod +x {script_path}"))
    return(script_path)
  } else if(write_script == "no") {
    return(job)
  }


}

call_plink <- function(workdir) {

  # get paths
  paths <- get_system_paths()


  # -------------------------------------------------------------------------

  # construct full path to container, and mount directories
  plink_path <- fs::path(paths$containers, paths$plink$container)
  singularity_start <- singularity_mount(workdir)

  # return command
  glue::glue("{singularity_start} {plink_path} plink")

}

call_bedtools <- function(workdir) {

  # get paths
  paths <- get_system_paths()


  # -------------------------------------------------------------------------

  # construct full path to container, and mount directories
  bed_path <- fs::path(paths$containers, "genomics.sif")
  singularity_start <- singularity_mount(workdir)

  # return command
  glue::glue("{singularity_start}{bed_path}")

}


clump_plink <- function(paths, p1 = "5e-08", p2 = "5e-06", r2 = 0.1, kb = 3000, snp_field = "RSID") {

  glue::glue(
    "{call_plink(paths$clumping)} --bfile /src/{paths$system_paths$plink$genome_ref} ",
    "--clump {fs::path_file(paths$clump_temp)} ",
    "--out clumps ",
    "--clump-p1 {p1} ",
    "--clump-p2 {p2} ",
    "--clump-r2 {r2} ",
    "--clump-kb {kb} ",
    "--clump-snp-field {snp_field} ",
    "--clump-field P ",
    "--clump-range /src/{paths$system_paths$plink$gene_ref} "
  )

}


#' Convert clumped.ranges output from Plink to bed format
#'
#' @param infile *.clumped.ranges file
#' @param out filename of bed file that is created
#'
#' @return a bedfile
#' @export
#'
#' @examples \dontrun{
#' ranges_to_bed("/my_sumstat/cleaned/clumps.clumped.ranges", "/my_sumstat/cleaned/clumps.bed")
#' }
ranges_to_bed <- function(infile, out){

  dplyr::tibble(utils::read.table(infile,header=TRUE )) |>
    dplyr::mutate(
      chr = stringr::word(POS, 1, sep = stringr::fixed(":")),
      tmp = stringr::word(POS, 2, sep = stringr::fixed(":")),
      start = as.integer(stringr::word(tmp, 1, sep = stringr::fixed(".."))),
      end = as.integer(stringr::word(tmp, 2, sep = stringr::fixed("..")))
    ) |>
    dplyr::arrange(chr, start, end) |>
    dplyr::select(chr, start, end, N, P, SNP) |>
    readr::write_tsv(out, col_names = FALSE)
}
