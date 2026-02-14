# Pipeline SBayesS

Pipeline SBayesS

## Usage

``` r
pipeline_sbayess(
  parent_dir,
  output_dir = NULL,
  write_script = TRUE,
  execute = FALSE,
  pi = "0.01",
  hsq = "0.5",
  num_chains = "4",
  chain_length = "25000",
  burn_in = "5000",
  seed = "2023",
  thread = "8",
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
  `<parent_dir>/analysis/sbayess`.

- write_script:

  Should script be written to disk?

- execute:

  Should generated script be executed via `system2("bash", ...)`?

- pi:

  Passed to GCTB `--pi`.

- hsq:

  Passed to GCTB `--hsq`.

- num_chains:

  Passed to GCTB `--num-chains`.

- chain_length:

  Passed to GCTB `--chain-length`.

- burn_in:

  Passed to GCTB `--burn-in`.

- seed:

  Passed to GCTB `--seed`.

- thread:

  Passed to GCTB `--thread`.

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
