
# downstreamGWAS

<!-- badges: start -->
<!-- badges: end -->

downstreamGWAS automates downstream analysis of GWAS summary statistics on HPC
systems. Given the output of [tidyGWAS](https://arvidharder.com/tidyGWAS), it
generates ready-to-run bash scripts for methods like SBayesRC, SBayesS,
LD-clumping, and more — handling input conversion, container execution, and
SLURM scheduling.

## How it works

1. Clean your summary statistics with `tidyGWAS::tidyGWAS()`
2. Point a `pipeline_*()` function at the output directory
3. Get a self-contained bash script that converts the data, runs the method
   inside an [Apptainer](https://apptainer.org) container, and cleans up

All external software (PLINK, GCTB, LDSC, SBayesRC) runs inside containers —
nothing needs to be installed on your cluster beyond Apptainer itself.

## Installation

```r
remotes::install_github("ararder/downstreamGWAS")
```

## Quick start

```r
library(downstreamGWAS)

# One-time setup: tell downstreamGWAS where reference data and containers live
setup_dsg(
  storage_root = "/projappl/my_project/downstreamGWAS",
  container_dependency = "ml apptainer"
)

# Generate and submit an SBayesRC job
pipeline_sbayesrc(
  parent_dir = "/path/to/tidyGWAS_output",
  execute = TRUE,
  prepare_inputs = TRUE,
  schedule = schedule_slurm(
    account = "my-project-id",
    mem = "100gb",
    partition = "shared",
    cpus_per_task = 16
  )
)
```

## Available pipelines

| Function | Method | Container |
|----------|--------|-----------|
| `pipeline_clumping()` | LD clumping (PLINK) + locus merging (bedtools) | `genetics_latest.sif` |
| `pipeline_sbayesrc()` | SBayesRC polygenic scoring | `sbayesrc_latest.sif` |
| `pipeline_sbayess()` | SBayesS (selection/polygenicity) | `genetics_latest.sif` |

See the [getting started guide](https://arvidharder.com/downstreamGWAS/articles/downstreamGWAS.html) for full documentation.
