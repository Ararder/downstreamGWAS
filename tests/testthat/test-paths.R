test_that("multiplication works", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")

  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(dsg_folder)
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
