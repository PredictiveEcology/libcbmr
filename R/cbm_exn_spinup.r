
#' Run the cbm_exn spinup routine
#' 
#' @param spinup_input A number.
#' @param parameters A number.
#' @returns A numeric vector.
#' @examples
#' add(1, 1)
#' add(10, 1)
#' @export
spinup <- function(spinup_input, parameters, spinup_debug_output_dir = NULL) {

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
