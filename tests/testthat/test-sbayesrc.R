test_that("run_sbayesRC works", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")
  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(
      dsg_folder,
    )
  )

  expect_no_error(
    test <- run_sbayesrc(
      parent_folder = tempdir(),
      write_script = TRUE
    )
  )

})


