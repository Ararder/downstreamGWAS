# Run two-sample mendelian randomisation using the TwoSampleMR package

Run two-sample mendelian randomisation using the TwoSampleMR package

## Usage

``` r
mr_on_tidyGWAS(
  exposure_dir,
  outcome_dir,
  exposure_bed = NULL,
  bidirectional = FALSE,
  r2 = 0.01
)
```

## Arguments

- exposure_dir:

  path to tidyGWAS directory of the exposure

- outcome_dir:

  path to tidyGWAS directory of the outcome

- exposure_bed:

  Use a custom bed file to define lead SNPs? Default is NULL, and
  downstreamGWAS will run
  [`run_clumping()`](http://arvidharder.com/downstreamGWAS/reference/run_clumping.md)
  if no bed file exists.

- bidirectional:

  run with outcome as exposure and exposure as outcome as well?

- r2:

  r2 to pass to plink2 clumping

## Value

a list

## Examples

``` r
if (FALSE) { # \dontrun{
mr_on_tidyGWAS("exp_dir/trait1", "outcomes/trait2")
} # }
```
