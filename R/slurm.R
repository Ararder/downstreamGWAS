

slurm_header <- function(time="1:00:00", mem="8gb", output=NULL, account=NULL, partition=NULL, cpus_per_task=NULL) {
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
