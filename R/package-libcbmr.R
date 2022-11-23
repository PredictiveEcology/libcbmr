#' Interface to the Carbon Budget Model Library Based on CBM-CFS3
#'
#' DESCRIPTION NEEDED
#'
#' @docType package
#' @import reticulate
#' @name libcbmr
NULL

.globals <- new.env(parent = emptyenv())
.globals$libcbm <- NULL

.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)

  py_path <- system.file("python", package = "libcbmr")
  .globals$libcbm <<- reticulate::import_from_path("libcbm", path = py_path, delay_load = TRUE)
}
