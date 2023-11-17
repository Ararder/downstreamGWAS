
# keeping track of containers
# -------------------------------------------------------------------------
get_dependencies <- function() {
  # update later: for now only gives dependencies on Dardel
  get_system_paths()[["container_dependency"]]
}

singularity_mount <- function(workdir) {
  paths <- get_system_paths()
  ref  <- paths$reference

  glue::glue("singularity exec --home {workdir}:/home --bind {ref}:/src ")
}

singularity_call <- function(command, sif, workdir) {
  glue::glue(singularity_mount(workdir), " {paths$system_paths$containers}/{sif} {command}")
}

