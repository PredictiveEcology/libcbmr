
#' Run the cbm_exn spinup routine which initializes
#' C pools and state for simulations
#'
#' @param spinup_input a dictionary of spinup_parameters, spinup_increments
#' @param parameters a collection of parameters for libcbm cbm exn C
#' matrix routines
#' @param spinup_debug_output_dir optional path which defaults to NULL.
#' If specified, the path is used to write debugging CSV files with full
#' model state and variable details about spinup timesteps.
#' @returns cbm_vars - a collection of simulation state and variables for
#' time-stepping with subsequent cbm processes
#' @export
cbm_exn_spinup <- function(
  spinup_input,
  parameters,
  spinup_debug_output_dir = NULL
) {

  box::use(utils[write.csv])
  box::use(reticulate[reticulate_import = import, `%as%`])

  # import python packages
  cbm_exn_model <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_model")
  libcbm_resources <- reticulate_import("libcbm.resources")
  model_variables <- reticulate_import(
    "libcbm.model.model_definition.model_variables"
  )
  output_processor <- reticulate_import(
    "libcbm.model.model_definition.output_processor"
  )

  include_spinup_debug <- !is.null(spinup_debug_output_dir)
  with(cbm_exn_model$initialize(
    parameters=parameters,
    include_spinup_debug = include_spinup_debug
  ) %as% cbm, {
    cbm_vars <- cbm$spinup(spinup_input)
    if (include_spinup_debug) {
      spinup_debug_output <- cbm$get_spinup_output()$to_pandas()
      for (name in names(spinup_debug_output)) {
        out_path = file.path(
          spinup_debug_output_dir, paste(name, "csv", sep = ".")
        )
        write.csv(spinup_debug_output[[name]], out_path)
      }
    }
    return(cbm_vars)
  })
}
