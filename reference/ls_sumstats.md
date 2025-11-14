# List the available sumstats

List the available sumstats

## Usage

``` r
ls_sumstats(folder = NULL)
```

## Arguments

- folder:

  can be used to specify where the summary statistics are. Default value
  is NULL, and the sumstats_folder parameter will be used from the
  config.yaml file

## Value

a
[`dplyr::tibble()`](https://dplyr.tidyverse.org/reference/reexports.html)

## Examples

``` r
if (FALSE) { # \dontrun{
ls_sumstats()
} # }
```
