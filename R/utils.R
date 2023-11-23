effective_n <- function(cases, controls) {
  proportion <- cases/(cases + controls)
  neff <- 4 * proportion * ((1 - proportion) * (cases + controls))

  round(neff)
}
