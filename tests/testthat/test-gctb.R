test_that("... can pass arguments to slurm", {
  expect_no_error(
    code <- run_sbayess(
      parent_folder = tempdir(),
      mem="1000gb",
      write_script = FALSE
    )
  )
})




test_that("can run .sbayess", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")
  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(
      dsg_folder,
    )
  )

  f <- run_sbayess(
    tempdir()
  )
})
