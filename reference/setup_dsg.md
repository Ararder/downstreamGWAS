# Setup downstreamGWAS config

Setup downstreamGWAS config

## Usage

``` r
setup_dsg(
  storage_root,
  sumstats_folder = NULL,
  container_dependency = "",
  force = FALSE
)
```

## Arguments

- storage_root:

  Long-term storage root for references and containers.

- sumstats_folder:

  Optional default folder containing tidyGWAS datasets.

- container_dependency:

  Optional shell command to load runtime dependencies on HPC (e.g.
  `"ml apptainer"`).

- force:

  Overwrite existing config file?

## Value

Path to written config file.
