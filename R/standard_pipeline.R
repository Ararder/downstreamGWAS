


# run_defaults <- function(parent_folder, steps = c("ldsc", "clumping", "sbayesrc")) {
#
#     paths <- tidyGWAS_paths(parent_folder)
#
#     ldsc_code <- run_ldsc(parent_folder, write_script = "no")
#     clumping_code <- run_clumping(parent_folder, write_script = "no")
#
#
#
#     sbayesr_code <- run_sbayesrc(parent_folder,
#                                  mem = paths$system_paths$sbayesrc$mem,
#                                  cpus_per_task = paths$system_paths$sbayesrc$cpus_per_task,
#                                  account = paths$system_paths$slurm$account,
#                                  partition = paths$system_paths$slurm$partition,
#                                  write_script = "yes",
#                                  )
#
#     glue::glue(
#       "sbatch --time=1:00:00 --mem=8gb --wrap='sh {ldsc_code}'",
#       "\n",
#       "sbatch --time=1:00:00 --mem=8gb --wrap='sh {clumping_code}'",
#       "\n",
#       "sbatch {sbayesr_code}"
#     ) |>
#       writeLines()
#
#
#
#
# }
#
#
#
#
