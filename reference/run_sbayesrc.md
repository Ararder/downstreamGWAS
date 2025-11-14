# Run sbayerc with tidyGWAS structure

Run sbayerc with tidyGWAS structure

## Usage

``` r
run_sbayesrc(
  parent_folder,
  ...,
  write_script = TRUE,
  thread_rc = 8,
  thread_imp = 4,
  use_effective_n = FALSE,
  repair_EAF = NULL
)
```

## Arguments

- parent_folder:

  path to tidyGWAS folder

- ...:

  pass arguments to
  [`slurm_header()`](http://arvidharder.com/downstreamGWAS/reference/slurm_header.md)

- write_script:

  Should the script be written to a file on disk?

- thread_rc:

  threads for rescaling

- thread_imp:

  threads for imputing

- use_effective_n:

  Should an attempt be made to calculate effective N

- repair_EAF:

  Should EAF be repaired? If so, provide a path to a file with columns
  RSID, EffectAllele, OtherAllele, EAF

## Value

a filepath or character vector

## Examples

``` r
if (FALSE) { # \dontrun{
run_sbayesrc()
} # }
```
