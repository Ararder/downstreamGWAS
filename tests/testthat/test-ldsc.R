




test_that("run_sldsc_cts works", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")
  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(
      dsg_folder,
      )
  )

  expect_no_error(
    test <- run_sldsc_cts(
      tempdir(),
      "silleti_Test",
      write_script = FALSE,
      mem= "80gb"
      )
  )

})



test_that("run_ldsc works", {
  dsg_folder <- fs::path(tempdir(), "downstreamGWAS")
  withr::with_envvar(
    list("HOME" = tempdir()),
    setup(
      dsg_folder,
    )
  )

  expect_no_error(
    test <- run_ldsc(
      parent_folder = tempdir(),
      write_script = FALSE
    )
  )

})


