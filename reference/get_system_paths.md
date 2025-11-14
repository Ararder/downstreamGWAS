# Read downstreamGWAS filepaths from yaml file downstreamGWAS manages external filepaths through two files:

The param.yml file which contains filepaths to reference data and
software containers all filepaths start at reference/ or containers/
respectively. The param.yml file is bundled with the downstreamGWAS
package.

## Usage

``` r
get_system_paths()
```

## Value

a nested list of filepaths

## Details

Secondly, the config.yml file which contains the local configuaration
paramerers, such as the path to the downstreamGWAS data folder, and how
to call apptainer/singularity. The config.yml file needs to be setup
locally.

## Examples

``` r
if (FALSE) { # \dontrun{
get_system_paths()
} # }
```
