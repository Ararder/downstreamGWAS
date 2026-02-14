# Resolve downstreamGWAS pipeline output directory

Resolve downstreamGWAS pipeline output directory

## Usage

``` r
dsg_method_output_dir(parent_dir, method_name, output_dir = NULL)
```

## Arguments

- parent_dir:

  Path to
  [`tidyGWAS::tidyGWAS()`](https://ararder.github.io/tidyGWAS/reference/tidyGWAS.html)
  output directory.

- method_name:

  Method identifier, e.g. `clumping`.

- output_dir:

  Optional custom output directory.

## Value

Absolute path to the output directory.
