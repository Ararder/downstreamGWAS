# Pipeline SBayesRC

Pipeline SBayesRC

## Usage

``` r
pipeline_sbayesrc(
  parent_dir,
  output_dir = NULL,
  write_script = TRUE,
  execute = FALSE,
  thread_rc = 8,
  thread_imp = 4,
  use_effective_n = FALSE,
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
  `<parent_dir>/analysis/sbayesrc`.

- write_script:

  Should script be written to disk?

- execute:

  Should generated script be executed via `system2("bash", ...)`?

- thread_rc:

  Number of OMP threads for `SBayesRC::sbayesrc`.

- thread_imp:

  Number of OMP threads for `SBayesRC::impute`.

- use_effective_n:

  Passed to
  [`to_ma()`](http://arvidharder.com/downstreamGWAS/reference/to_ma.md).

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
