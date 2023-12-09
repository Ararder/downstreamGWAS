
call_container <- function(root,program, workdir) {

  paths <- get_system_paths()
  container <- fs::path(paths$containers, paths[[program]]$container)

  ref  <- paths$reference
  binds <- glue::glue("--bind {workdir}:/mnt --bind {ref}:/src ")
  glue::glue("bind_mnt='--bind {workdir}:/mnt")
  glue::glue("bind_src ='--bind {ref}:/src'")

  singularity_start <- glue::glue(
    "singularity exec --cleanenv "
  )

  glue::glue("{singularity_start}{binds}{container} {root}")
}

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

