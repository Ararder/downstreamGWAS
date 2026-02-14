# Construct a SLURM schedule object

Construct a SLURM schedule object

## Usage

``` r
schedule_slurm(
  time = "24:00:00",
  mem = "8gb",
  cpus_per_task = NULL,
  account = NULL,
  partition = NULL
)
```

## Arguments

- time:

  SLURM time limit.

- mem:

  SLURM memory request.

- cpus_per_task:

  SLURM CPUs per task.

- account:

  Optional SLURM account.

- partition:

  Optional SLURM partition.

## Value

A schedule object that can be passed to `pipeline_*()` functions.
