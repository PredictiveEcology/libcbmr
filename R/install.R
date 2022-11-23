#' Install `libcbm` python package
#'
#' @inheritParams reticulate::py_install
#'
#' @export
install_libcbm <- function(method = "auto", conda = "auto") {
  reticulate::py_install("libcbm", method = method, conda = conda) ## TODO: install from path!
}
