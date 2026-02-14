test_that("setup_dsg writes config and storage dirs", {
  withr::local_envvar(c(HOME = tempdir()))

  storage_root <- fs::path(tempdir(), "dsg-local")
  cfg_path <- setup_dsg(storage_root, force = TRUE)

  expect_true(fs::file_exists(cfg_path))
  expect_true(fs::dir_exists(fs::path(storage_root, "reference")))
  expect_true(fs::dir_exists(fs::path(storage_root, "containers")))
})


test_that("pipeline_clumping returns script without writing when write_script is FALSE", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_a")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_clumping(parent_dir, write_script = FALSE, execute = FALSE)

  expect_type(res, "list")
  expect_null(res$script_path)
  expect_true(length(res$script) > 0)
  expect_false(res$executed)
  expect_true(fs::path_file(res$output_dir) == "clumping")
})


test_that("pipeline_clumping respects custom output_dir", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_b")
  custom_out <- fs::path(tempdir(), "sweeps", "clump", "p1_5e-8")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_clumping(parent_dir, output_dir = custom_out, write_script = FALSE)
  expect_equal(fs::path_abs(custom_out), res$output_dir)
})


test_that("pipeline_sbayesrc returns script without execution", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_c")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayesrc(parent_dir, write_script = FALSE, execute = FALSE)

  expect_type(res, "list")
  expect_null(res$script_path)
  expect_true(length(res$script) > 0)
  expect_false(res$executed)
  expect_true(fs::path_file(res$output_dir) == "sbayesrc")
})


test_that("pipeline scripts include container dependency when configured", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(
    fs::path(tempdir(), "dsg-local"),
    container_dependency = "ml apptainer",
    force = TRUE
  )

  parent_dir <- fs::path(tempdir(), "trait_d")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  clump <- pipeline_clumping(parent_dir, write_script = FALSE, execute = FALSE)
  sbrc <- pipeline_sbayesrc(parent_dir, write_script = FALSE, execute = FALSE)

  expect_true("ml apptainer" %in% clump$script)
  expect_true("ml apptainer" %in% sbrc$script)
})


test_that("pipeline scripts include slurm header when scheduler is slurm", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_e")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayesrc(
    parent_dir,
    write_script = FALSE,
    schedule = schedule_slurm(mem = "32gb", time = "12:00:00", cpus_per_task = 8)
  )

  expect_true(any(grepl("^#SBATCH --mem=32gb$", res$script)))
  expect_true(any(grepl("^#SBATCH --time=12:00:00$", res$script)))
  expect_true(any(grepl("^#SBATCH --cpus-per-task=8$", res$script)))
  expect_true(any(grepl("^#SBATCH --output=", res$script)))
})


test_that("pipeline controls slurm output path from output_dir", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_f")
  outdir <- fs::path(tempdir(), "custom-out", "sbayesrc")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayesrc(
    parent_dir = parent_dir,
    output_dir = outdir,
    write_script = FALSE,
    schedule = {
      s <- schedule_slurm()
      s$args$output <- "ignored.log"
      s
    }
  )

  expected_output_line <- paste0("#SBATCH --output=", fs::path_abs(outdir), "/slurm-%j.out")
  expect_true(expected_output_line %in% res$script)
  expect_false("#SBATCH --output=ignored.log" %in% res$script)
})


test_that("pipeline_sbayesrc includes cleanup commands", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_cleanup")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayesrc(parent_dir, write_script = FALSE, execute = FALSE)
  script <- paste(res$script, collapse = "\n")

  expect_true(grepl("rm -f.*\\.rds", script))
  expect_true(grepl("rm -f.*sumstats\\.ma", script))
  expect_true(grepl("rm -f.*sbrc_tune", script))
  expect_true(grepl("rm -f.*sbrc\\.mcmcsamples", script))
})


test_that("pipeline_sbayesrc includes to_ma in script when prepare_inputs is TRUE", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_munge")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayesrc(parent_dir, write_script = FALSE, execute = FALSE, prepare_inputs = TRUE)
  script <- paste(res$script, collapse = "\n")
  expect_true(grepl("downstreamGWAS::to_ma", script))

  res2 <- pipeline_sbayesrc(parent_dir, write_script = FALSE, execute = FALSE, prepare_inputs = FALSE)
  script2 <- paste(res2$script, collapse = "\n")
  expect_false(grepl("downstreamGWAS::to_ma", script2))
})


test_that("pipeline_sbayess returns script without execution", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_sbayess")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayess(parent_dir, write_script = FALSE, execute = FALSE)

  expect_type(res, "list")
  expect_null(res$script_path)
  expect_true(length(res$script) > 0)
  expect_false(res$executed)
  expect_true(fs::path_file(res$output_dir) == "sbayess")
})


test_that("pipeline_sbayess includes gctb sbayes S command", {
  withr::local_envvar(c(HOME = tempdir()))
  setup_dsg(fs::path(tempdir(), "dsg-local"), force = TRUE)

  parent_dir <- fs::path(tempdir(), "trait_sbayess2")
  fs::dir_create(fs::path(parent_dir, "tidyGWAS_hivestyle"), recurse = TRUE)

  res <- pipeline_sbayess(parent_dir, write_script = FALSE, execute = FALSE, prepare_inputs = TRUE)
  script <- paste(res$script, collapse = "\n")

  expect_true(grepl("gctb --sbayes S", script))
  expect_true(grepl("--no-mcmc-bin", script))
  expect_true(grepl("downstreamGWAS::to_ma", script))
})
