#' Run arbitrary code inside a container
#'
#' @param code code to be executed inside a container.
#' @param image which container should be used? Used to index into params.yml
#' @param workdir filepath to a directory. Will be used as the working directory inside the container
#' @param setup_exists logical. If TRUE, the workdir, reference_dir and container_dependecy paths are assumed to exist.
#' bind paths and code to load apptainer/singularity will not be written out to the script
#' @param env pass environmental variables to the container, in format:
#'   "KEY=VALUE"
#'   Currently only supports passing one variable
#' @param R_code
#'  Running R Code using the format: R -e "$code" is challening due to escaping of
#'  quotes and special characters. If TRUE, the code will be run using R -e "$code"
#' @return a character vector of captured code
#' @export
#'
#' @examples
#'
#' with_container(
#'  code = "echo hello",
#'  image = "R",
#'  workdir = tempdir()
#'  )
#'
with_container <- function(code, image, workdir, env = NULL, setup_exists=FALSE, R_code=FALSE) {

  #
  rlang::check_required(code)
  rlang::check_required(image)
  rlang::check_required(workdir)


  if(!is.null(env)) {
    env <- glue::glue("--env '{env}' ")
  } else {
    env <- NULL
  }


  # Check input
  paths <- get_system_paths()
  # stopifnot(
  #   "The folder assumed to hold software containers does not exist locally" =
  #     fs::dir_exists(fs::path(paths$downstreamGWAS_folder, paths$default_params$container_dir))
  # )


  # -------------------------------------------------------------------------
  # setup paths in bash format, to make it more readable in the script

  ref  <- fs::path(
    paths$downstreamGWAS_folder,
    paths$default_params$reference_dir
    )

  container <- fs::path(
    paths$downstreamGWAS_folder,
    paths$default_params$container_dir,
    paths[[image]][["container"]]
    )


# -------------------------------------------------------------------------


  wd <- glue::glue("workdir='{workdir}:/mnt'")
  ref_data <- glue::glue("reference_dir='{ref}:/src'")
  container <- glue::glue("container='{container}'")
  assign_code <- glue::glue("code='{code}'")
  dep <- container_dependency(paths)

  container_call <- glue::glue(
    "apptainer exec --cleanenv {env}--bind $workdir,$reference_dir $container $code",
    .null = ""
  )

  if(isTRUE(R_code)) {
    assign_code <- glue::glue("code={code}")
    container_call <- glue::glue(
      "apptainer exec --cleanenv {env}--bind $workdir,$reference_dir $container R -e \"$code\"",
      .null = ""
    )

  }


  # if multiple commands are using the same container and reference data,
  # no need to redefine those variables each time.
  # -------------------------------------------------------------------------

  if(isTRUE(setup_exists)) {
    c(
      container,
      assign_code,
      container_call
    )


  }  else {

    c(
      dep,
      wd,
      ref_data,
      container,
      assign_code,
      container_call
    )

  }


}




container_dependency <- function(paths) {
  if(rlang::is_empty(paths[["container_dependency"]])) {
    NULL
  } else {
    paths[["container_dependency"]]
  }
}


in_ref_dir <- function(filename, folder = NULL) {

  if(rlang::is_empty(fs::path("/src", folder))) {
    base <- "/src/"
  } else {
    base <- fs::path("/src", folder)
  }

  fs::path(base,filename)

}

in_work_dir <- function(filename) {
  fs::path("/mnt", filename)
}
