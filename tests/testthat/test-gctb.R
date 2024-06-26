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
  mock_setup()

  f <- run_sbayess(
    tempdir()
  )
})




test_that("can run sbayesrc", {

  mock_setup()
  expect_no_error(
    f <- run_sbayesrc(
      tempdir()
    )
  )
})


test_that("can run mbat-combo", {

  mock_setup()
  expect_no_error(
    f <- run_mbat_combo(
      tempdir()
    )
  )
})
