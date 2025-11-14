# Run Sbayes-S with tidyGWAS structure

Run Sbayes-S with tidyGWAS structure

## Usage

``` r
run_sbayess(
  parent_folder,
  ...,
  write_script = TRUE,
  pi = "0.01",
  hsq = "0.5",
  num_chains = "4",
  chain_length = "25000",
  burn_in = "5000",
  seed = "2023",
  thread = "8"
)
```

## Arguments

- parent_folder:

  filepath to a
  [`tidyGWAS::tidyGWAS()`](https://ararder.github.io/tidyGWAS/reference/tidyGWAS.html)
  folder

- ...:

  pass arguments to
  [`slurm_header()`](http://arvidharder.com/downstreamGWAS/reference/slurm_header.md)

- write_script:

  should the captured code be written to disk in a .sh file?

- pi:

  argument passed to sbayes

- hsq:

  argument passed to sbayes

- num_chains:

  argument passed to sbayes

- chain_length:

  argument passed to sbayes

- burn_in:

  argument passed to sbayes

- seed:

  argument passed to sbayes

- thread:

  argument passed to sbayes

## Value

a filepath or character vector

## Examples

``` r
if (FALSE) { # \dontrun{
run_sbayess()
} # }
```
