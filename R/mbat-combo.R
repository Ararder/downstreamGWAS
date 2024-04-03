# run_mbat_combo <- function(parent_folder, outfolder, outprefix = "mBat-combo", thread_num = 10) {
#   paths <- tidyGWAS_paths(parent_folder)
#   dset <- arrow::open_dataset(paths$hivestyle)
#
#   check_required_cols(c("EAF", "N"), dset)
#
#   if(missing(outfolder)) {
#     outfolder <- paths$mbat_combo
#   }
#
#   # make sure output folder exists
#   fs::dir_create(paths$mbat_combo)
#
#   # filepaths needed to run through container
#   container_exe <- call_container(root = "gcta", program = "gctb", workdir = outfolder)
#   ld_ref <- paths$system_paths$plink$genome_ref
#   mbat_gene_list <- paths$system_paths$plink$gene_ref
#
#   ma_file <- "/mnt/tmp.ma"
#   to_ma(parent_folder, fs::path(outfolder, "tmp.ma"))
#   job <- glue::glue("{container_exe} --bfile /src/{ld_ref} --mBAT-combo {ma_file} --mBAT-gene-list /src/{mbat_gene_list} --out /mnt/scz2022_eur --thread-num 10")
#
#   header <- slurm_header(cpus_per_task = 10, mem = "50gb")
#   writeLines(c(header,job), fs::path(outfolder, "mbat-job.sh"))
#
#
#
# }
#
#
# check_required_cols <- function(required_columns, dset) {
#   stopifnot(
#     "All the required columns are not present" =
#     all(required_columns %in% names(dset))
#     )
# }
