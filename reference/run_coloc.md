# Run coloc::coloc.abf on tidyGWAS data

Run coloc::coloc.abf on tidyGWAS data

## Usage

``` r
run_coloc(
  parent_dir,
  parent_dir2,
  chr,
  start,
  end,
  min_pval = 5e-08,
  trait_type1 = c("guess", "cc", "quant"),
  trait_type2 = c("guess", "cc", "quant"),
  p1 = 1e-04,
  p2 = 1e-04,
  p12 = 1e-05
)
```

## Arguments

- parent_dir:

  tidyGWAS directory of GWAS

- parent_dir2:

  tidyGWAS directory of GWAS

- chr:

  chromosome

- start:

  start of region

- end:

  end of region

- min_pval:

  minimum pval required to proceed with coloc in trait2

- trait_type1:

  quantitative or case-control?

- trait_type2:

  quantitative or case-control?

- p1:

  prior for colof.abf

- p2:

  prior for colof.abf

- p12:

  prior for colof.abf

## Value

output of
[`coloc::coloc.abf()`](https://rdrr.io/pkg/coloc/man/coloc.abf.html)

## Examples

``` r
if (FALSE) { # \dontrun{
run_coloc("path/trait1", "path/trait2")
} # }
```
