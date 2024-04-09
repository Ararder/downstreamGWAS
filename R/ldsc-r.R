utils::globalVariables(c("Z","L2", "N", "chi2"))
get_weights <- function(prediction, w_ld) {
  1 / (prediction^2 * w_ld)
}

crossprod2 <- function(x, y) drop(base::crossprod(x, y))

# equivalent to stats::lm.wfit(cbind(1, x), y, w) - weighted regression
.wlm <- function(x,y,w, return_blocks = FALSE) {
  stopifnot(rlang::is_bool(return_blocks))


  X <- cbind(1,x)
  wx <- w*X

  XtX <- drop(base::crossprod(wx, X))
  Xy <- drop(base::crossprod(wx, y))
  solution <- solve(XtX, Xy)

  list(
    intercept = solution[1],
    beta = solution[2],
    pred = solution[1] + solution[2]*x
  )
}

.wlm_no_int <- function(x, y, w) {
  wx <- w * x
  XtX <- drop(crossprod(wx, x))
  Xy <- drop(crossprod(wx, y))
  solution <- solve(XtX, Xy)

  list(beta = solution[1], pred = x * solution[2])
}

wlm <- function(x, y, w) {
  wx <- w * x
  W   <- sum(w)
  WX  <- sum(wx)
  WY  <- crossprod2(w,  y)
  WXX <- crossprod2(wx, x)
  WXY <- crossprod2(wx, y)
  alpha <- (WXX * WY - WX * WXY) / (W * WXX - WX^2)
  beta  <- (WXY * W  - WX * WY)  / (W * WXX - WX^2)
  list(intercept = alpha, slope = beta, pred = x * beta + alpha)
}

# equivalent to stats::lm.wfit(as.matrix(x), y, w) - weighted regression without intercept
wlm_no_int <- function(x, y, w) {
  wx <- w * x
  WXX <- crossprod2(wx, x)
  WXY <- crossprod2(wx, y)
  beta  <- WXY / WXX
  list(slope = beta, pred = x * beta)
}



#' Run LDscore regression --h2 flag.
#'
#' @param df a data.frame containing three columns: c("Z", "N", "L2")
#'  Z: Z score of association per snp
#'  Z: sample size of variant
#'  L2: LD score of variant
#' @param ld_size number of variants used to calculate LD score (Typically MAF > 0.05)
#' @param step1_chi2 chi2 threshold for step 1 filter
#' @param step2_chi2 chi2 threshold for step 2 filter: max(0.001 * max(ld_df$N), 80)
#' @param blocks number of blocks to use in the jackknife regression. NOT YET IMPLEMENTED
#'
#' @return a [dplyr::tibble()] with two columns: "int" and "obs_h2"
#' @export
#'
#' @examples \dontrun{
#' irwl_ldsc(df, ld_size = ld_size)
#' }
irwl_ldsc <- function(df, ld_size, step1_chi2 = 30, step2_chi2=NULL, blocks = 200) {
  req_cols <- c("Z", "N","L2")
  stopifnot("data.frame" %in% class(df))
  stopifnot(is.numeric(ld_size))
  stopifnot(
    all(
      req_cols %in% colnames(df)
    )
  )
  df <- dplyr::select(df, dplyr::any_of(req_cols))

  # add small value to chi2, and set minimum weight value to 1
  ld_df <- dplyr::mutate(
    df,
    chi2 = (Z^2) + 1e-8,
    w_ld = pmax(L2, 1)
  ) |>
    tidyr::drop_na()



  # Step 1 ------------------------------------------------------------------
  # use chi2 <= 30 by default
  step1 <- dplyr::filter(ld_df, chi2 < step1_chi2)


  # design matrix and dependent variable
  x <- (step1$L2 / ld_size) * step1$N
  y <- step1$chi2
  w_ld <- step1$w_ld

  # find the correct weights by iterative attempts
  pred0 <- y

  for (i in 1:100) {
    weights <- get_weights(prediction =  pred0 , w_ld = w_ld)
    pred <- wlm(x, y, w = weights)$pred
    if(max(abs(pred - pred0)) < 1e-6) break
    pred0 <- pred
  }

  # fit model with updated weights to get the intercept
  step1_intercept <- wlm(x, y, w = get_weights(pred0, w_ld))$intercept


  # Step 2 ------------------------------------------------------------------
  # apply step 2 filter
  if(is.null(step2_chi2)) step2_chi2 <- max(0.001 * max(ld_df$N), 80)
  step2 <- dplyr::filter(ld_df, chi2 < step2_chi2)

  w_ld <- step2$L2
  X <- (step2$L2 / ld_size) * step2$N
  y <- step2$chi2 - step1_intercept

  pred0 <- y
  for (i in 1:100) {
    pred <- step1_intercept + wlm_no_int(X, y, w = get_weights(pred0, w_ld))$pred
    if (max(abs(pred - pred0)) < 1e-6) break
    pred0 <- pred
  }


  # -------------------------------------------------------------------------
  final_w <- get_weights(pred0, w_ld)


  step2_h2 <- wlm_no_int(X, y, w = get_weights(pred0, w_ld))$slope

  dplyr::tibble(int = step1_intercept, obs_h2 = step2_h2)


}
