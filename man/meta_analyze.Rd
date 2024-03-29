% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/meta-analysis.R
\name{meta_analyze}
\alias{meta_analyze}
\title{Perform meta-analysis of GWAS summary statistics datasets in [tidyGWAS::tidyGWAS()] hive-style format.}
\usage{
meta_analyze(dset, method = c("ivw"))
}
\arguments{
\item{dset}{an [arrow::open_dataset()] object}

\item{method}{method to use for performing meta-analysis. Currently, only IVW (based on standard errors) is supported.}
}
\value{
a [dplyr::tibble()]
}
\description{
Perform meta-analysis of GWAS summary statistics datasets in [tidyGWAS::tidyGWAS()] hive-style format.
}
\examples{
\dontrun{
dset <- arrow::open_dataset("path_to/sumstats/")
res <- meta_analyze(dset)
}

}
