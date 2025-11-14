# Construct a slurm header

Construct a slurm header

## Usage

``` r
slurm_header(
  time = "24:00:00",
  mem = "8gb",
  output = NULL,
  account = NULL,
  partition = NULL,
  cpus_per_task = NULL
)
```

## Arguments

- time:

  time allocated to job

- mem:

  memory allocated to job (remember to use 'gb' ending)

- output:

  filepath to output slurm log file

- account:

  account

- partition:

  partition

- cpus_per_task:

  cpus per task

## Value

A character vector with the slurm header

## Examples

``` r
slurm_header()
#> [1] "#!/bin/bash"             "#SBATCH --mem=8gb"      
#> [3] "#SBATCH --time=24:00:00"
```
