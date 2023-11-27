
# keeping track of containers
# -------------------------------------------------------------------------
get_dependencies <- function() {
  # update later: for now only gives dependencies on Dardel
  get_system_paths()[["container_dependency"]]
}

singularity_mount <- function(workdir) {
  paths <- get_system_paths()
  ref  <- paths$reference

  glue::glue("singularity exec --bind {workdir}:/mnt --bind {ref}:/src ")
}

singularity_call <- function(cmd, sif, workdir) {
  glue::glue(singularity_mount(workdir), " {paths$system_paths$containers}/{sif} {command}")
}

singularity_call2 <- function(cmd, workdir, program) {
  paths <- get_system_paths()
  glue::glue(singularity_mount(workdir), "{paths$containers}/{paths[[program]]$container} {cmd}")

}

