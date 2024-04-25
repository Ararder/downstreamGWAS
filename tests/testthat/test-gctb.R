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
  expect_no_error(

  .sbayess(
    ldm = "xx",
    gwas_summary = "xx",
    out = "xx",
    pi = "0.1",
    hsq = "0.5",
    num_chains = "4",
    chain_length = "25000",
    burn_in = "5000",
    seed = "2023",
    thread = "4"
    )
  )
})
