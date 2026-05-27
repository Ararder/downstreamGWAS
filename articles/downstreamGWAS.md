# Getting started with downstreamGWAS

## What is downstreamGWAS?

downstreamGWAS automates downstream analysis of GWAS summary statistics
on HPC systems. Given the output of
[tidyGWAS](https://arvidharder.com/tidyGWAS), it generates ready-to-run
bash scripts for methods like SBayesRC, SBayesS, LD-clumping, and more —
handling input conversion, container execution, and SLURM scheduling.

### The problem

Running a method like SBayesRC on summary statistics typically requires:

1.  **Munging** — reformatting columns, filtering variants, computing
    effective N
2.  **Reference data** — LD matrices, annotation files, gene lists
3.  **Software** — installing tools that may conflict with your HPC
    environment
4.  **Scheduling** — writing SLURM scripts with correct paths and
    resource requests

Each step is error-prone and rarely reusable across methods or datasets.

### How downstreamGWAS solves it

downstreamGWAS assumes your summary statistics have already been cleaned
by
[`tidyGWAS::tidyGWAS()`](https://ararder.github.io/tidyGWAS/reference/tidyGWAS.html).
From that standardized starting point, every `pipeline_*()` function:

- **Converts** the tidyGWAS dataset to the method’s required format
  (`.ma`, `.tsv`, etc.) inside the generated script, so it runs on the
  compute node
- **Resolves** paths to containers and reference data from a single
  config file
- **Generates** a self-contained bash script with optional SLURM headers
- **Optionally executes** the script locally or submits it via `sbatch`

All external software runs inside [Apptainer](https://apptainer.org)
containers, so you never need to install PLINK, GCTB, LDSC, or R
packages on your cluster.

## Setup

### 1. Install the package

``` r

remotes::install_github("ararder/downstreamGWAS")
```

### 2. Configure paths

Tell downstreamGWAS where your reference data and containers live. This
only needs to be done once per machine:

``` r

library(downstreamGWAS)

setup_dsg(
  storage_root = "/projappl/my_project/downstreamGWAS",
  container_dependency = "ml apptainer"
)
```

This creates `~/.config/downstreamGWAS/config.yml` and the directory
structure:

    /projappl/my_project/downstreamGWAS/
    ├── reference/    # LD matrices, annotations, gene lists
    └── containers/   # .sif container images

### 3. Place reference data and containers

Download the required `.sif` files and reference data into the
directories created above. The specific files needed depend on which
pipelines you want to run (see each pipeline’s documentation for
details).

## Usage

Every `pipeline_*()` function follows the same interface:

``` r

result <- pipeline_sbayesrc(
  parent_dir   = "/path/to/tidyGWAS_output",
  write_script = TRUE,    # write the bash script to disk
  execute      = FALSE    # don't run yet — just generate
)

# Inspect the generated script
cat(result$script, sep = "\n")
```

### Running with SLURM

Pass a
[`schedule_slurm()`](http://arvidharder.com/downstreamGWAS/reference/schedule_slurm.md)
object to add SLURM headers and submit via `sbatch`:

``` r

result <- pipeline_sbayesrc(
  parent_dir     = "/path/to/tidyGWAS_output",
  execute        = TRUE,
  prepare_inputs = TRUE,
  thread_rc      = 16,
  thread_imp     = 8,
  use_effective_n = TRUE,
  schedule = schedule_slurm(
    account  = "my-project-id",
    mem      = "100gb",
    partition = "shared",
    cpus_per_task = 16
  )
)

# SLURM job ID
result$job_id
```

### Available pipelines

| Function | Method | Container |
|----|----|----|
| [`pipeline_clumping()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_clumping.md) | LD clumping (PLINK) + locus merging (bedtools) | `genetics_latest.sif` |
| [`pipeline_sbayesrc()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_sbayesrc.md) | SBayesRC polygenic scoring | `sbayesrc_latest.sif` |
| [`pipeline_sbayess()`](http://arvidharder.com/downstreamGWAS/reference/pipeline_sbayess.md) | SBayesS (selection/polygenicity) | `genetics_latest.sif` |

### Output

Each pipeline writes its results to `<parent_dir>/analysis/<method>/` by
default (override with `output_dir`). The return value is a list with:

- `script` — the generated bash script as a character vector
- `script_path` — path to the written `.sh` file
- `output_dir` — where results will be written
- `executed` — whether the script was run
- `job_id` — SLURM job ID (if submitted via sbatch)
