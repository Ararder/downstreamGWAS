# run mBAT-combo gene-test in GCTB

run mBAT-combo gene-test in GCTB

## Usage

``` r
run_mbat_combo(
  parent_folder,
  ...,
  write_script = TRUE,
  outfolder = NULL,
  thread_num = 10
)
```

## Arguments

- parent_folder:

  filepath to a tidyGWAS folder

- ...:

  arguments to slurm

- write_script:

  should the code be written to disk?

- outfolder:

  Where to write the output

- thread_num:

  number of threads to use

## Value

a character vector with the script or a filepath

## Examples

``` r
if (FALSE) { # \dontrun{
mbat_combo("path_to_tidyGWAS/folder/sumstat1")
} # }
```
