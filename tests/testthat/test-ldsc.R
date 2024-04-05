




test_that("run_sldsc_cts works", {
  pfolder <- tempdir()
  ct <- "silleti_Test"
  expect_no_error(
    test <- run_sldsc_cts(pfolder, ct, write_script = FALSE, mem= "80gb")
  )

})



