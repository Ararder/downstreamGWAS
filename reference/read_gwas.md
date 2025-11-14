# Read in a tidyGWAS formatted summary statistics file

Read in a tidyGWAS formatted summary statistics file

## Usage

``` r
read_gwas(parent_folder, columns)
```

## Arguments

- parent_folder:

  filepath to the parent_folder of tidyGWAS_hivestyle

- columns:

  character vector of columns names, passed to
  `dplyr::select(dplyr::any_of(columns))`

## Value

a [`data.frame()`](https://rdrr.io/r/base/data.frame.html)

## Examples

``` r
if (FALSE) { # \dontrun{
read_gwas("/tidyGWAS_files/mdd2019")
# or if you have saved the summary statistics filepath in the config.yaml file
# see [tidyGWAS_paths()]
read_gwas("mdd2019")
} # }
```
