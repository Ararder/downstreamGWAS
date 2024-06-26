% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{read_gwas}
\alias{read_gwas}
\title{Read in a tidyGWAS formatted summary statistics file}
\usage{
read_gwas(parent_folder, columns)
}
\arguments{
\item{parent_folder}{filepath to the parent_folder of tidyGWAS_hivestyle}

\item{columns}{character vector of columns names, passed to \code{dplyr::select(dplyr::any_of(columns))}}
}
\value{
a \code{\link[=data.frame]{data.frame()}}
}
\description{
Read in a tidyGWAS formatted summary statistics file
}
\examples{
\dontrun{
read_gwas("/tidyGWAS_files/mdd2019")
# or if you have saved the summary statistics filepath in the config.yaml file
# see [tidyGWAS_paths()]
read_gwas("mdd2019")
}
}
