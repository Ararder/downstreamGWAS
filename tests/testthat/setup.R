temp_sumstat_repo <- function(name = NULL) {
  name <- name %||% "type_1_diabetes"
  dir <- withr::local_tempdir()
  sumstat <- dir.create(file.path(dir, name))

  analysis <- dir.create(file.path(dir, name, "analysis"))
  sbayes <- dir.create(file.path(dir, name, "analysis", "sbayes"))



}

mock_setup <- function() {
  withr::local_envvar(
    list("HOME" = tempdir()),
    .local_envir = parent.frame()
  )
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")
  setup(dsg_folder)
  fs::dir_create(fs::path(dsg_folder, "reference"))
  fs::dir_create(fs::path(dsg_folder, "containers"))
}


