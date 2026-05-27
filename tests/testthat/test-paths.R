test_that("setup_dsg creates reference and containers dirs", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")

  withr::with_envvar(
    list("HOME" = tempdir()),
    setup_dsg(dsg_folder, force = TRUE)
    )

  expect_true(all(c(c("reference", "containers") %in% fs::path_file(fs::dir_ls(dsg_folder)))))




})



test_that("check_dependency works", {
  mock_setup()
  sp <- get_system_paths()
  dsg_folder <- sp$downstreamGWAS_folder



  sp <- get_system_paths()
  info <- paste0(sp$gctb$ldm_s, ".info")
  bin <- paste0(sp$gctb$ldm_s,".bin")


  expect_false(check_dependency(info, "reference"))

  temp_path <- fs::path(dsg_folder, "reference", bin)
  fs::dir_create(fs::path_dir(temp_path), recurse = TRUE)
  fs::file_touch(fs::path(dsg_folder, "reference", bin))
  expect_true(check_dependency(bin, "reference"))

})


test_that("check_setup detects missing then present sbayesrc assets", {
  withr::local_envvar(c(HOME = tempdir()))
  storage_root <- fs::path(tempdir(), "dsg-checksetup")
  setup_dsg(storage_root, force = TRUE)

  # reference data not yet in place
  expect_false(check_setup("sbayesrc"))

  params <- parse_params()
  ref <- fs::path(storage_root, "reference")
  con <- fs::path(storage_root, "containers")

  fs::dir_create(fs::path(ref, params$sbayesrc$ldm), recurse = TRUE)
  fs::dir_create(fs::path_dir(fs::path(ref, params$sbayesrc$annot)), recurse = TRUE)
  fs::file_touch(fs::path(ref, params$sbayesrc$annot))
  fs::file_touch(fs::path(con, params$sbayesrc$container))

  expect_true(check_setup("sbayesrc"))
})


test_that("check_setup errors on unknown method", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-checksetup2"), force = TRUE)

  expect_error(check_setup("not_a_method"), "Unknown method")
})
