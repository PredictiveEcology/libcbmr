
#' get_cbm_exn_parameters_dir
#'
#' Get path of the parameters directory for `libcbm.cbm_exn.cbm_exn_model`.
#' This will be the path to the packaged default parameters
#' or a path set with the option `libcbmr.cbm_exn_parameters_dir`.
#'
#' @export
get_cbm_exn_parameters_dir <- function() {
  cbm_exn_dir <- getOption("libcbmr.cbm_exn_parameters_dir")
  if (is.null(cbm_exn_dir)){
    box::use(reticulate[reticulate_import = import])
    libcbm_resources <- reticulate_import("libcbm.resources")
    cbm_exn_dir <- libcbm_resources$get_cbm_exn_parameters_dir()
  }
  return(cbm_exn_dir)
}

#' get_cbm_defaults_path
#'
#' Get path of the CBM defaults SQLite database.
#' This will be the path to the packaged default database
#' or a path set with the option `libcbmr.cbm_defaults_path`.
#'
#' @export
get_cbm_defaults_path <- function() {
  cbm_defaults_path <- getOption("libcbmr.cbm_defaults_path")
  if (is.null(cbm_defaults_path)){
    box::use(reticulate[reticulate_import = import])
    libcbm_resources <- reticulate_import("libcbm.resources")
    cbm_defaults_path <- libcbm_resources$get_cbm_defaults_path()
  }
  return(cbm_defaults_path)
}

