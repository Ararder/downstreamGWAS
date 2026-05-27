test_that("run_sbayesRC works", {
  mock_setup()

  expect_no_error(
    test <- run_sbayesrc(
      parent_folder = tempdir(),
      write_script = TRUE
    )
  )

})


