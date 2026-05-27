# Check that downstreamGWAS is set up and reference data is in place

Verifies that the config file exists, the storage directories
(`reference_dir`, `container_dir`) exist, and that the
reference/container assets each pipeline needs are present at the paths
declared in `params.yml`. Use this to confirm downloaded reference data
has been placed correctly.

## Usage

``` r
check_setup(method = NULL)
```

## Arguments

- method:

  Optional method to check: one of `"sbayesrc"`, `"sbayess"`, or
  `"clumping"`. When `NULL` (default), all methods are checked.

## Value

Invisibly, `TRUE` if everything checked is present, otherwise `FALSE`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_setup()             # check everything
check_setup("sbayesrc")   # only the SBayesRC reference data
} # }
```
