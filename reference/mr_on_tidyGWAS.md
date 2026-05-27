# Run two-sample Mendelian randomisation on tidyGWAS data

Uses the TwoSampleMR package to run MR with instruments derived from
LD-clumped loci. Requires
[`pipeline_clumping()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_clumping.md)
to have been run on the exposure, or set `auto_clump = TRUE`.

## Usage

``` r
mr_on_tidyGWAS(
  exposure_dir,
  outcome_dir,
  exposure_bed = NULL,
  auto_clump = FALSE,
  r2 = 0.01
)
```

## Arguments

- exposure_dir:

  Path to tidyGWAS directory for the exposure trait.

- outcome_dir:

  Path to tidyGWAS directory for the outcome trait.

- exposure_bed:

  Path to a custom BED file defining lead SNPs. If `NULL` (default),
  uses `<exposure_dir>/analysis/clumping/merged_loci.bed`.

- auto_clump:

  If `TRUE` and no clumping output exists, automatically run
  [`pipeline_clumping()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_clumping.md)
  with local execution. Default `FALSE`.

- r2:

  Passed to
  [`pipeline_clumping()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_clumping.md)
  when `auto_clump = TRUE`.

## Value

A list with `results` (MR estimates), `outcome_data` (harmonised data),
and `pleiotropy` (MR-Egger intercept test).

## Examples

``` r
if (FALSE) { # \dontrun{
mr_on_tidyGWAS("exposure/trait1", "outcome/trait2")
} # }
```
