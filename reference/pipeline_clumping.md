# Pipeline clumping

Pipeline clumping

## Usage

``` r
pipeline_clumping(
  parent_dir,
  output_dir = NULL,
  write_script = TRUE,
  execute = FALSE,
  p1 = "5e-08",
  p2 = "5e-06",
  r2 = 0.1,
  kb = 3000,
  schedule = NULL,
  prepare_inputs = execute,
  check_paths = TRUE
)
```

## Arguments

- parent_dir:

  Path to
  [`tidyGWAS::tidyGWAS()`](https://ararder.github.io/tidyGWAS/reference/tidyGWAS.html)
  output directory.

- output_dir:

  Optional custom output directory. Defaults to
  `<parent_dir>/analysis/clumping`.

- write_script:

  Should script be written to disk?

- execute:

  Should generated script be executed via `system2("bash", ...)`?

- p1:

  Passed to PLINK `--clump-p1`.

- p2:

  Passed to PLINK `--clump-p2`.

- r2:

  Passed to PLINK `--clump-r2`.

- kb:

  Passed to PLINK `--clump-kb`.

- schedule:

  Optional schedule object (e.g. from
  [`schedule_slurm()`](http://arvidharder.com/downstreamGWAS/reference/schedule_slurm.md)).
  If `NULL`, no scheduler header is written and local bash execution is
  used.

- prepare_inputs:

  Should an input preparation step (e.g.
  [`to_ma()`](http://arvidharder.com/downstreamGWAS/reference/to_ma.md),
  [`to_clumping()`](http://arvidharder.com/downstreamGWAS/reference/to_clumping.md))
  be included in the generated script? Defaults to `execute`.

- check_paths:

  Should required files and directories be validated before
  execution/submission? Defaults to `TRUE`.

## Value

A list with script metadata.
