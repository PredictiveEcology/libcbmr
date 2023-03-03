#' Interface to the Carbon Budget Model Library Based on CBM-CFS3
#'
#' DESCRIPTION NEEDED
#'
#' @docType package
#' @import reticulate
#' @name libcbmr
NULL

#.globals <- new.env(parent = emptyenv())
# .globals$libcbm <- NULL
# .globals$cbm_exn_model <- NULL
# .globals$libcbm_resources <- NULL
# .globals$cbm_variables <- NULL
# .globals$model_variables <- NULL
# .globals$output_processor <- NULL

.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)

  # py_path <- system.file("python", package = "libcbmr")
  # .globals$libcbm <<- reticulate::import_from_path("libcbm", path = py_path, delay_load = TRUE)
  # .globals$cbm_exn_model <<- reticulate::import_from_path("libcbm.model.cbm_exn.cbm_exn_model", path = py_path, delay_load = TRUE)
  # .globals$libcbm_resources <<- reticulate::import_from_path("libcbm.resources", path = py_path, delay_load = TRUE)
  # .globals$cbm_variables <<- reticulate::import_from_path("libcbm.model.model_definition.cbm_variables", path = py_path, delay_load = TRUE)
  # .globals$output_processor <<- reticulate::import_from_path("libcbm.model.model_definition.output_processor", path = py_path, delay_load = TRUE)

  # .globals$libcbm <<- import("libcbm", delay_load = TRUE)
  # .globals$cbm_exn_model <<- import("libcbm.model.cbm_exn.cbm_exn_model", delay_load = TRUE)
  # .globals$libcbm_resources <<- import("libcbm.resources", delay_load = TRUE)
  # .globals$cbm_variables <<- import("libcbm.model.model_definition.cbm_variables", delay_load = TRUE)
  # .globals$model_variables <<- import("libcbm.model.model_definition.model_variables", delay_load = TRUE)
  # .globals$output_processor <<- import("libcbm.model.model_definition.output_processor", delay_load = TRUE)
}

#' cbm_exn_model
#'
#' DESCRIPTION NEEDED
#'
#' @export
libcbm_cbm_exn_model <- function() {
  import("libcbm.model.cbm_exn.cbm_exn_model")
}

#' libcbm_resources
#'
#' DESCRIPTION NEEDED
#'
#' @export
libcbm_libcbm_resources <- function() {
  import("libcbm.resources")
}

#' cbm_variables
#'
#' DESCRIPTION NEEDED
#'
#' @export
libcbm_cbm_variables <- function() {
  import("libcbm.model.model_definition.cbm_variables")
}

#' model_variables
#'
#' DESCRIPTION NEEDED
#'
#' @export
libcbm_model_variables <- function() {
  import("libcbm.model.model_definition.model_variables")
}

#' output_processor
#'
#' DESCRIPTION NEEDED
#'
#' @export
libcbm_output_processor <- function() {
  import("libcbm.model.model_definition.output_processor")
}
