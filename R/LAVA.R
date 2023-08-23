# # https://github.com/josefin-werme/LAVA
#
# sample_gwas <- arrow::open_dataset("~/arvhar/update_gwas_sumstats/sumstats/crohns/tidyGWAS_hivestyle/")
#
# dset2 <- arrow::open_dataset(glue::glue("~/arvhar/update_gwas_sumstats/sumstats/crohns/tidyGWAS_hivestyle/"))
#
# name <- "mdd2023"
# workdir <- paste(tempdir(), "lava-test", sep = "/")
# extract_gwas <- function(name, EAF_filter = 0.05, INFO_filter=0.9, workdir) {
#
#   dset <- arrow::open_dataset(glue::glue("~/arvhar/update_gwas_sumstats/sumstats/{name}/tidyGWAS_hivestyle/"))
#
#   existing_columns <- names(dset$schema)
#
#
#
#   # -------------------------------------------------------------------------
#   gwas_out <- fs::path(fs::dir_create(workdir), glue::glue("gwas_file.tsv"))
#   info_out <- fs::path(fs::dir_create(workdir), glue::glue("info_file.tsv"))
#
#
#   # collect GWAS data -------------------------------------------------------
#
#   query <- dplyr::select(dset, RSID, A1 = EffectAllele, A2 = OtherAllele, CHR = CHR_37, POS = POS_37, dplyr::any_of(c("EAF", "INFO", "Z", "N")))
#   if("INFO" %in% existing_columns) query <- dplyr::filter(query, INFO >= {{ INFO_filter }} )
#   if("EAF" %in% existing_columns) query <- dplyr::filter(query, EAF >= {{ EAF_filter }} & EAF <= (1- {{ EAF_filter }}))
#   df <- dplyr::compute(query)
#   # write oute
#
#   arrow::write_csv_arrow(x = df, file = gwas_out)
#
#
#   # create the info file ----------------------------------------------------
#
#   info <- dplyr::select(dset, CaseN, ControlN) |>
#     dplyr::summarise(cases = max(CaseN), controls = max(ControlN)) |>
#     dplyr::collect()
#   info$phenotype <- name
#   info$filename <- gwas_out
#
#
#   data.table::fwrite(x = info, file = info_out, col.names = TRUE, sep = "\t")
#
#   workdir
#
# }
#
#
#
# run_lava <- function(
#     lava_dir,
#     ref_genome = "/nas/depts/007/sullilab/shared/gwas_sumstats/reference/1000G_EUR_Phase3_plink/1000G_merged",
#     lava_blocks = "/nas/depts/007/sullilab/shared/gwas_sumstats/reference/LAVA/lava-partitioning/LAVA_s2500_m25_f1_w200.blocks"
#     ) {
#
#   sample_overlap_file <- fs::path(lava_dir, "sample_overlap.tsv")
#   if(fs::file_exists(sample_overlap_file)) sample_overlap <- sample_overlap_file else sample_overlap <- NULL
#
#   input = LAVA::process.input(
#     input.info.file = fs::path(lava_dir, "info_file.tsv"),
#     sample.overlap.file= NULL,
#     ref.prefix= ref_genome
#     )
#
#   loci = read.loci(lava_blocks)
#
#
#   locus = process.locus(loci[2,], input)
# }
#
#
#
#
# }
# lava_pipeline <- function(phenotypes, outdir, metadata) {
#
#
#
#   }
#   lava_info_file <- function(dataset_name, metadata) {
#     df <- filter(metadata, .data[["dataset_name"]] == {{ dataset_name }})
#
#     stopifnot(nrow(df) == 1)
#
#     if(df[["trait_type"]] == "binary") {
#       info <- dplyr::select(df, phenotype = "dataset_name", cases = "ncas",controls =  "ncon", prevalence = "pop_prev") |>
#         dplyr::mutate(filename = paste0(phenotype, ".gz")) |>
#         dplyr::select(phenotype, cases, controls, prevalence, filename)
#     } else if(df[["trait_type"]] == "continous") {
#
#       info <- dplyr::select(df, phenotype = "dataset_name") |>
#         dplyr::mutate(
#           filename = paste0(phenotype, ".gz"),
#           cases = NA_real_,
#           controls = NA_real_,
#           prevalence = NA_real_
#         ) |>
#         dplyr::select(phenotype, cases, controls, prevalence, filename)
#     }
#
#     info
#
#   }
#
#   # check that sumstats exist in metadata
#   stopifnot(all(phenotypes %in% metadata$dataset_name))
#
#   walk(phenotypes, \(pheno) setup_lava_gwas(dataset_name = pheno, outdir = outdir))
#
#   map_df(phenotypes, \(pheno) lava_info_file(dataset_name = pheno, metadata = metadata))
#
#

