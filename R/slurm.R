

#' Construct a slurm header
#'
#' @param time time allocated to job
#' @param mem memory allocated to job (remember to use 'gb' ending)
#' @param output filepath to output slurm log file
#' @param account account
#' @param partition partition
#' @param cpus_per_task cpus per task
#'
#' @return A character vector with the slurm header
#' @export
#'
#' @examples
#' slurm_header()
slurm_header <- function(time="24:00:00", mem="8gb", output=NULL, account=NULL, partition=NULL, cpus_per_task=NULL) {
  c(
    glue::glue("#!/bin/bash"),
    glue::glue("#SBATCH --mem={mem}"),
    glue::glue("#SBATCH --time={time}"),
    glue::glue("#SBATCH --cpus-per-task={cpus_per_task}"),
    glue::glue("#SBATCH --account={account}"),
    glue::glue("#SBATCH --partition={partition}"),
    glue::glue("#SBATCH --output={output}")
  )

}
