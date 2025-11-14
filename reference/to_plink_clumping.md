# Convert tidyGWAS hivestyle partitioning to compatible format for plink clumping

Convert tidyGWAS hivestyle partitioning to compatible format for plink
clumping

## Usage

``` r
to_plink_clumping(parent_folder)
```

## Arguments

- parent_folder:

  filepath to tidyGWAS folder

## Value

writes a file to disk

## Examples

``` r
if (FALSE) { # \dontrun{
paths <- tidyGWAS_paths("/my_sumstat/cleaned/")
to_plink_clumping(paths)
} # }
```
