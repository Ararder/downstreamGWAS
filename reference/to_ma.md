# Convert tidyGWAS to COJO .ma format

Convert tidyGWAS to COJO .ma format

## Usage

``` r
to_ma(parent_folder, out = NULL, use_effective_n = FALSE)
```

## Arguments

- parent_folder:

  filepath to tidyGWAS folder

- out:

  output for .ma file. Default value is `tidyGWAS_paths()[["ma_file]]`

- use_effective_n:

  Should N be converted to effective sample size? Requires CaseN and
  ControlN in column names

## Examples

``` r
if (FALSE) { # \dontrun{
to_ma("/path/tidyGWAS_sumstats/a_sumstat")
} # }
```
