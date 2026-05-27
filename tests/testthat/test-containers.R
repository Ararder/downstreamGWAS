test_that("With_container works", {
  mock_setup()

  expect_no_error(
    ls <- with_container(
      code = glue::glue("R -e \"print('hello')\""),
      image = "gcta",
      workdir = tempdir()
    )
  )

  expect_no_error(
    ls <- with_container(
      code = glue::glue("R -e \"print('hello')\""),
      image = "gcta",
      workdir = tempdir(),
      setup_exists = TRUE
    )
  )

})
