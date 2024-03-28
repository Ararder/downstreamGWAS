

#' Construct a slurm header
#'
#' @param time maximum run time for the job
#' @param mem amount of memory to allocate
#' @param output filepath to slurm output file
#' @param account slurm account to debit cost
#' @param partition slurm partition to use
#' @param cpus_per_task number of cpus per task
#'
#' @return a character vector
#' @export
#'
#' @examples \dontrun{
#' slurm_header(time = "30:00:00", mem = "8gb", output = "output.txt",
#' account = "myaccount", partition = "my_partition", cpus_per_task = 10)
#' }
slurm_header <- function(time="30:00:00", mem="8gb", output=NULL, account=NULL, partition=NULL, cpus_per_task=NULL) {
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
