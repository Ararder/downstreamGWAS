temp_sumstat_repo <- function(name = NULL) {
  name <- name %||% "type_1_diabetes"
  dir <- withr::local_tempdir()
  sumstat <- dir.create(file.path(dir, name))

  analysis <- dir.create(file.path(dir, name, "analysis"))
  sbayes <- dir.create(file.path(dir, name, "analysis", "sbayes"))



}


tmp_config_file <- function() {
  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(dsg_folder)
  )

}



