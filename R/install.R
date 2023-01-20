#' Install `libcbm` python package
#'
#' @inheritParams reticulate::py_install
#'
#' @export
#' @importFrom utils read.delim
install_libcbm <- function(method = "auto", conda = "auto") {
  reqs <- read.delim(system.file("python/libcbm/requirements.txt", package = "libcbmr"), header = FALSE)[[1]]

  #use_python(Sys.which("python3"))
  use_condaenv("r-reticulate")
  lapply(reqs, py_install, method = method, conda = conda)

  ## TODO: install via pip; can't install from path
  # py_install("libcbm", method = method, conda = conda)
  system(paste("cd", system.file("python/libcbm", package = "libcbmr"), "&&",
               Sys.which("pip3"), "install ."),
         intern = TRUE)
}
