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
  genome_ref <- in_ref_dir(paths$system_paths$genome_refs$deep_1kg)
  gene_list <- in_ref_dir("plink/glist-hg38")

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
  bedtools_code <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container /bin/bash -c \"bedtools merge -d 50000 -i /mnt/clumps.bed -c 4,5,6 -o sum,collapse,collapse > /mnt/merged_loci.bed\"")
  cleanup <- glue::glue("apptainer exec --cleanenv --bind $workdir,$reference_dir $container rm /mnt/sumstats.tsv")
  script  <- c(setup_file, script,"\n", format,"\n", bedtools_code, cleanup)



  script_path <- fs::path(workdir, "clumping_job.sh")
  writeLines(script, script_path)
  script_path

}
