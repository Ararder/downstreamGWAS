# meta-analysis

``` r
library(downstreamGWAS)
library(fs)
library(dplyr)
library(tictoc)
```

## Meta-analysis

downstreamGWAS has implemented a inverse-variance-weighted fixed-effects
meta-analysis equal to “StdErr” in
[metal](https://genome.sph.umich.edu/wiki/METAL_Documentation).
Sample-size weighted meta-analysis has not yet been implemented, but is
a planned feature.

To illustrate the `downstreamGWAS::meta_analyze()` function, we will
utilize our summary statistics repository on our local HPC cluster (128
summary statistics).

Each summary statistic cleaned can be combined into a multi-dataset by
creating a symlink to the tidyGWAS_hivestyle folder for each summary
statistic.

This is what the format looks like.

``` r
multi_dataset <- function(dir, new_dir) {
  symlink <- dplyr::tibble(
    basedir = fs::dir_ls(dir),
    old_path = fs::path(basedir, "tidyGWAS_hivestyle"),
    dataset_name = fs::path_file(basedir),
    new_path = fs::path(new_dir, paste0("dataset_name=", dataset_name))
  ) |> 
    dplyr::select(old_path, new_path)
  
  fs::link_create(symlink$old_path, symlink$new_path)
}
fs::dir_create("/work/users/a/r/arvhar/multi_dataset")
multi_dataset("/work/users/a/r/arvhar/tidyGWAS_stuff/output2", "/work/users/a/r/arvhar/multi_dataset")

dir_ls("/work/users/a/r/arvhar/multi_dataset") |> 
  head()
```

#### Working with a multi-dataset

It’s useful to read up on how arrow interacts with dplyr
[here](https://arrow.apache.org/docs/r/articles/data_wrangling.html) for
the next part.

We can open this multi-dataset with
[`arrow::open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.html).

We can use standard dplyr commands like
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
and
[`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).

``` r
ds <- arrow::open_dataset("/work/users/a/r/arvhar/multi_dataset")

sumstats <- ds |> 
  dplyr::filter(dataset_name %in% c("scz2014","scz2018_clozuk", "scz2022"))
```

As an example, let’s meta-analyze three waves of schizophrenia GWASes
(Even though this is nonsensical).

Meta-analyzing three summary statistics took 70 seconds, while
meta-analyzing 76 summary statistics took ~15 minutes on our compute
cluster with 3 cores and 25gb memory.

CaseN, ControlN and INFO are all kept is they exist in all input summary
statistics.

``` r
tic("Meta-analyze three traits for chromosome 1")
res <- ds |> 
  dplyr::filter(dataset_name %in% c("scz2014","scz2018_clozuk", "scz2022")) |> 
  downstreamGWAS::meta_analyze(by = c("CHR", "POS", "EffectAllele","OtherAllele", "RSID"))
toc()
```
