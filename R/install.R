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
  reqs <- read.delim(system.file("python/libcbm/requirements.txt", package = "libcbmr"), header = FALSE)[[1]]

  cfg <- py_discover_config(use_environment = envname)

  py_use_env(envname)

  py_install(reqs, method = method, conda = conda, pip = TRUE) ## NOTE: conda repos inaccessible at PFC

  ## TODO: install via pip; can't install from path
  # py_install("libcbm", method = method, conda = conda)
  cwd <- setwd(system.file("python/libcbm", package = "libcbmr"))
  on.exit(setwd(cwd), add = TRUE)
  system(paste(shQuote(cfg$python), "-m pip install ."), intern = TRUE)
}
