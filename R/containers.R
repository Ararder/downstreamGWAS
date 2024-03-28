
#' Construct the code to call a container using a specific program
#'
#' call_container uses three arguments to construct a call to a container:
#'
#'
#' @param cmd command to execute in the container
#' @param config_key yml key in the config.yml file. The path to the container
#' will be constructed using config[[config_key]]$container
#' @param workdir workfolder to bind to the container
#'
#' @return a character vector of captured code
#' @export
#'
#' @examples \dontrun{
#' call_container()
#' }
call_container <- function(cmd, config_key, workdir) {

  paths <- get_system_paths()



  container <- fs::path(paths$containers, paths[[config_key]][["container"]])

  ref  <- paths$reference
  binds <- glue::glue("--bind {workdir}:/mnt --bind {ref}:/src ")
  glue::glue("bind_mnt='--bind {workdir}:/mnt")
  glue::glue("bind_src ='--bind {ref}:/src'")

  singularity_start <- glue::glue(
    "singularity exec --cleanenv "
  )

  glue::glue("{singularity_start}{binds}{container} {cmd}")
}

with_container <- function(exe_path, code, config_key, workdir) {

  # Check input
  paths <- get_system_paths()
  stopifnot(
    "The 'containers' parameter in the config.yml file is required, and has not been provided.
    To remove this error, set the 'containers' parameter in the config.yml file to the folder where the singularity containers exist." =
      !rlang::is_empty(paths$containers)
  )


  # -------------------------------------------------------------------------
  # setup paths in bash format, to make it more readable in the script

  ref  <- paths$reference
  container <- fs::path(paths$containers, paths[[config_key]][["container"]])

  wd <- glue::glue("wd='{workdir}:/mnt'")
  ref_data <- glue::glue("ref='{ref}:/src'")
  container <- glue::glue("container='{container}'")
  assign_code <- glue::glue("code='{code}'")
  # check if a commamnd needs to be run to load apptainer
  dep <- if(rlang::is_empty(p[["container_dependency"]])) "# no apptainer dependency in config file" else p[["container_dependency"]]


  container_call <- glue::glue(
    "singularity exec --cleanenv --bind $wd,$ref $container {exe_path} $code"
  )


  container_call <- glue::glue(
      "singularity exec --cleanenv --bind $wd,$ref $container {exe_path} $code"
    )

  c(
    dep,
    wd,
    ref_data,
    container,
    assign_code,
    container_call
  )
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

