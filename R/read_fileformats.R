#' read the output of LDSC --h2
#'
#' @param path to log file
#'
#' @return a tibble
#' @export
#'
#' @examples \dontrun{
#' parse_ldsc_h2("ldsc_h2.log")
#' }
read_ldsc_h2 <- function(path) {

  dataset_name <- fs::path_file(fs::path_dir(fs::path_dir(fs::path_dir(path))))
  df <- readLines(path)

  if(length(df) != 32){
    return(dplyr::tibble(dataset_name=dataset_name, obs_h2=NA_real_,
                         obs_se=NA_real_, lambda=NA_real_,
                         mean_chi2=NA_real_, intercept=NA_real_,
                         intercept_se=NA_real_, ratio=NA_real_))
  }

  obs_h2 <- as.numeric(stringr::str_extract(df[26], "\\d{1}\\.\\d{1,5}"))

  obs_se <- stringr::str_extract(df[26], "\\(\\d{1}\\.\\d{1,5}") |>
    stringr::str_remove(string = _, pattern = "\\(") |>
    as.numeric()

  lambda <- stringr::str_extract(df[27], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  mean_chi2 <- stringr::str_extract(df[28], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  intercept <- stringr::str_extract(string = df[29], pattern = " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  intercept_se <- stringr::str_extract(string = df[29],pattern =  "\\(\\d{1}\\.\\d{1,5}") |>
    stringr::str_remove(string = _, pattern =  "\\(") |>
    as.numeric()
  ratio <- stringr::str_extract(df[30], " \\d{1}\\.\\d{1,5}") |>
    as.numeric()

  dplyr::tibble(dataset_name, obs_h2, obs_se, lambda, mean_chi2, intercept, intercept_se, ratio)
}
