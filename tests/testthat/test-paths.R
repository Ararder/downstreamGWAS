test_that("multiplication works", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")

  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(dsg_folder)
    )

  expect_true(all(c(c("reference", "containers") %in% fs::path_file(fs::dir_ls(dsg_folder)))))




})
