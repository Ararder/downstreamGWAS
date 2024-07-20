test_that("multiplication works", {
  df <- arrow::read_tsv_arrow("~/Downloads/ldsc.sumstats.gz")
  df$INFO <- runif(nrow(df), 0.6, 1)
  df2 <- df |> dplyr::slice_head(n=100000)
  df2$INFO <- runif(nrow(df2), 0.6, 1)
  
  df
  df2
  
})
