# Format coloc::coloc.abf output into a tidy tibble

Format coloc::coloc.abf output into a tidy tibble

## Usage

``` r
format_coloc(coloc_obj, name)
```

## Arguments

- coloc_obj:

  Output of
  [`coloc::coloc.abf()`](https://rdrr.io/pkg/coloc/man/coloc.abf.html).

- name:

  Label for this coloc test (e.g. trait pair or locus name).

## Value

A
[`dplyr::tibble()`](https://dplyr.tidyverse.org/reference/reexports.html)
with columns: `name`, `n_snps`, `PP.H4`, and `top_snps` (comma-separated
RSIDs with highest PP.H4).

## Examples

``` r
if (FALSE) { # \dontrun{
format_coloc(result, "scz_vs_bip_chr7")
} # }
```
