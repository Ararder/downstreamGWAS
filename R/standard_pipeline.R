#
# standard_cleaning <- function(file) {
#   run_tidyGWAS <-
#     glue::glue("R -e 'tidyGWAS(commandArgs(trailingOnly = TRUE)[1],commandArgs(trailingOnly=TRUE)[2])'") |>
#       paste0(" --args", " ", fs::path(paths$clumping, "clumps.clumped.ranges"), " ", fs::path(paths$clumping, "clumps.bed"))
#
#   glue::glue("R -e 'args <- commandArgs(trailingOnly = TRUE)'", " -e 'tidyGWAS(args[1], args[2], args[3], args[4], args[5]")
#
#   R -e "args <- commandArgs(trailingOnly=TRUE)" -e "args" --args "hello" "pop" "world"
#
# }
