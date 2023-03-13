#' Use conda or virtual environment
#'
#' Will try to guess whether to use `use_condaenv()` or `use_virtualenv`.
#'
#' @param envname Either the name of, or the path to, a Python virtual or conda environment.
#'
#' @export
py_use_env <- function(envname = NULL) {
  cfg <- py_discover_config(use_environment = envname)

  if (any(cfg$anaconda, cfg$conda)) {
    use_condaenv(envname)
  } else {
    use_virtualenv(envname)
  }
}

#' Install `libcbm` python package
#'
#' @inheritParams reticulate::py_install
#'
#' @export
#' @importFrom utils read.delim
install_libcbm <- function(method = "auto", conda = "auto", envname = NULL) {
  cfg <- py_discover_config(use_environment = envname)
  py_use_env(envname)
  py_install("libcbm", method = method, conda = conda, pip = TRUE) ## NOTE: conda repos inaccessible at PFC
}
