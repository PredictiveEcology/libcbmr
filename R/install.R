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
  py_install(reqs, method = method, conda = conda)

  ## TODO: install via pip; can't install from path
  # py_install("libcbm", method = method, conda = conda)
  cwd <- setwd(system.file("python/libcbm", package = "libcbmr"))
  on.exit(setwd(cwd), add = TRUE)
  system(paste(Sys.which("pip3"), "install ."), intern = TRUE)
}
