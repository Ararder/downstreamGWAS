# Run a clumping pipeline on a tidyGWAS sumstats

Run a clumping pipeline on a tidyGWAS sumstats

## Usage

``` r
run_clumping(path, output_dir = NULL, ...)
```

## Arguments

- path:

  filepath to tidyGWAS folder

- output_dir:

  directory to write clumping results

- ...:

  arguments to pass to the plink2 call

## Value

bed file with clumps

## Examples

``` r
if (FALSE) { # \dontrun{
ranges_to_bed("/path/to/tidyGWAS")
} # }
```
