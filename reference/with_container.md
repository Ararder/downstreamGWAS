# Run arbitrary code inside a container

Run arbitrary code inside a container

## Usage

``` r
with_container(
  code,
  image,
  workdir,
  env = NULL,
  setup_exists = FALSE,
  R_code = FALSE
)
```

## Arguments

- code:

  code to be executed inside a container.

- image:

  which container should be used? Used to index into params.yml

- workdir:

  filepath to a directory. Will be used as the working directory inside
  the container

- env:

  pass environmental variables to the container, in format: "KEY=VALUE"
  Currently only supports passing one variable

- setup_exists:

  logical. If TRUE, the workdir, reference_dir and container_dependecy
  paths are assumed to exist. bind paths and code to load
  apptainer/singularity will not be written out to the script

- R_code:

  Running R Code using the format: R -e "\$code" is challening due to
  escaping of quotes and special characters. If TRUE, the code will be
  run using R -e "\$code"

## Value

a character vector of captured code

## Examples

``` r
with_container(
 code = "echo hello",
 image = "R",
 workdir = tempdir()
 )
#> Warning: cannot open file '/home/runner/.config/downstreamGWAS/config.yml': No such file or directory
#> Error in file(file, "rt", encoding = fileEncoding): cannot open the connection
```
