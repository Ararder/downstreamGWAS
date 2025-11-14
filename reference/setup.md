# Setup required filepaths for downstreamGWAS

Setup required filepaths for downstreamGWAS

## Usage

``` r
setup(
  downstreamGWAS_folder,
  container_dependency = "",
  container_software = c("apptainer", "singularity")
)
```

## Arguments

- downstreamGWAS_folder:

  Local filepath to where the downstreamGWAS data is stored

- container_dependency:

  Do you need to load singularity/apptainer on your HPC? For example:
  "ml apptainer"

- container_software:

  Which container software do you use? "apptainer" or "singularity"

## Examples

``` r
if (FALSE) { # \dontrun{
setup()
} # }
```
