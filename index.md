# downstreamGWAS

downstreamGWAS is a companion package to
[tidyGWAS](http://arvidharder.com/downstreamGWAS/www.arvidharder.com/tidyGWAS).
downstreamGWAS provides functions to run standardize genetic pipelines
using summary statistics as input. External software is packaged through
docker files available at
[dockerhub](https://hub.docker.com/repository/docker/arvhar/genetics/general).

In addition to this, reference files needed for pipelines bundled into
the containers are available through zenodo. Link TBD.

DownstreamGWAS utilises three factors to make genetic analysis much
simplified: 1. Harmonized GWAS format through
[tidyGWAS](http://arvidharder.com/downstreamGWAS/www.arvidharder.com/tidyGWAS)
2. External software packaged into docker images, that can be run on
HPCs with singularity/apptainer 3. References files collected and
available for download, with harmonized filepaths

## Installation

``` r
remotes::install_github("ararder/downstreamGWAS")
devtools::install_github("ararder/downstreamGWAS")
```

downstreamGWAS requires a filepaths.yml file to be created, and for you
to add some information to it.

\`\`\`{r} dir_to_store_yaml_in =
“/nas/depts/007/sullilab/shared/gwas_sumstats”
setup_filepaths_yml(dir_to_store_yaml_in) \# get script to download
singularity images sif_script()

\`\`\`

## Download singularity images
