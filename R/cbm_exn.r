

#' Get the default parameters bundled with libcbm for running the cbm_exn
#' package
#' @export
cbm_exn_get_default_parameters <- function() {
  box::use(reticulate[reticulate_import = import, dict])
  box::use(utils[read.csv])
  cbm_exn_parameters <- reticulate_import(
    "libcbm.model.cbm_exn.cbm_exn_parameters"
  )
  libcbm_resources <- reticulate_import("libcbm.resources")
  param_path <- libcbm_resources$get_cbm_exn_parameters_dir()

  params <- dict(
    # TODO: need a solution for loading json that works correctly
    # for pools and flux configs
    slow_mixing_rate = read.csv(
      file.path(param_path, "slow_mixing_rate.csv")
    ),
    turnover_parameters = read.csv(
      file.path(param_path, "turnover_parameters.csv")
    ),
    species = read.csv(
      file.path(param_path, "species.csv")
    ),
    root_parameters = read.csv(
      file.path(param_path, "root_parameters.csv")
    ),
    decay_parameters = read.csv(
      file.path(param_path, "decay_parameters.csv")
    ),
    disturbance_matrix_value = read.csv(
      file.path(param_path, "disturbance_matrix_value.csv")
    ),
    disturbance_matrix_association = read.csv(
      file.path(param_path, "disturbance_matrix_association.csv")
    )
  )

  return(params)
}

#' Get the default spinup ops
#' @export
cbm_exn_spinup_ops <- function(spinup_input, parameters){
  box::use(reticulate[reticulate_import = import])
  cbm_exn_spinup <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_spinup")
  cbm_exn_parameters <- reticulate_import(
    "libcbm.model.cbm_exn.cbm_exn_parameters"
  )
  model_variables <- reticulate_import(
    "libcbm.model.model_definition.model_variables"
  )
  libcbm_resources <- reticulate_import("libcbm.resources")
  param_object <- cbm_exn_parameters$parameters_factory(
    dir = libcbm_resources$get_cbm_exn_parameters_dir(),
    data = parameters
  )
  spinup_ops <- cbm_exn_spinup$get_default_ops(
    param_object,
    model_variables$ModelVariables$from_pandas(spinup_input)
  )
  return(spinup_ops)
}

#' get the default spinup op sequence names
#' @return list of strings - list of the names of the default spinup ops
#' @export
cbm_exn_get_spinup_op_sequence <- function(){
  box::use(reticulate[reticulate_import = import])
  cbm_exn_spinup <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_spinup")

  spinup_ops_sequence <- cbm_exn_spinup$get_default_op_list()
  return(spinup_ops_sequence)
}

#' Run the cbm_exn spinup routine which initializes
#' C pools and state for simulations
#'
#' @param spinup_input a dictionary of spinup_parameters, spinup_increments
#' @param spinup_ops the formatted matrix operations to apply
#' @param spinup_op_list list of operation names to apply in spinup stepping
#' (references spinup ops)
#' @param parameters named list of default parameters for model initilization
#' @param spinup_debug_output_dir optional path which defaults to NULL.
#' If specified, the path is used to write debugging CSV files with full
#' model state and variable details about spinup timesteps.
#' @returns cbm_vars - a collection of simulation state and variables for
#' time-stepping with subsequent cbm processes
#' @export
cbm_exn_spinup <- function(
  spinup_input,
  spinup_ops,
  spinup_op_list,
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
  cbm_exn_parameters <- reticulate_import(
    "libcbm.model.cbm_exn.cbm_exn_parameters"
  )
  param_object <- cbm_exn_parameters$parameters_factory(
    dir = libcbm_resources$get_cbm_exn_parameters_dir(),
    data = parameters
  )
  do_spinup_debug <- !is.null(spinup_debug_output_dir)

  with(cbm_exn_model$initialize(
    parameters, include_spinup_debug = do_spinup_debug
  ) %as% cbm, {

    cbm_vars <- cbm$spinup(
      spinup_input,
      ops = spinup_ops,
      op_sequence = spinup_op_list
    )

    if (do_spinup_debug) {
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

#' get the default step op sequence names
#' @return list of strings - list of the names of the default step ops
#' @export
cbm_exn_get_step_ops_sequence <- function(){
  box::use(reticulate[reticulate_import = import])
  cbm_exn_step <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_step")
  step_ops_sequence <- cbm_exn_step$get_default_annual_process_op_sequence()
  return(step_ops_sequence)
}

#' get the default step op sequence names for disturbances
#' @return list of strings - list of the names of the default disturbance step ops
#' @export
cbm_exn_get_step_disturbance_ops_sequence <- function(){
  box::use(reticulate[reticulate_import = import])
  cbm_exn_step <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_step")
  step_disturbance_ops_sequence  <- (
    cbm_exn_step$get_default_disturbance_op_sequence()
  )
  # list() is required for single element lists
  # https://rstudio.github.io/reticulate/articles/calling_python.html#lists-tuples-and-dictionaries
  return(list(step_disturbance_ops_sequence))
}

#' Get the default matrix operations for cbm_exn stepping as a list of matrices
#' @param cbm_vars named list of dataframes containing
#' the simulation state and variables for computing the
#' default operations
#' @param parameters named list of default parameters. For
#' default value see the `cbm_exn_get_default_parameters`
#' function.
#' @return list - list of structured matrix operations
#' @export
cbm_exn_step_ops <- function(cbm_vars, parameters) {

  box::use(reticulate[reticulate_import = import, `%as%`])
  cbm_exn_parameters <- reticulate_import(
    "libcbm.model.cbm_exn.cbm_exn_parameters"
  )
  model_variables <- reticulate_import(
    "libcbm.model.model_definition.model_variables"
  )
  libcbm_resources <- reticulate_import("libcbm.resources")
  param_object <- cbm_exn_parameters$parameters_factory(
    dir = libcbm_resources$get_cbm_exn_parameters_dir(),
    data = parameters
  )
  cbm_exn_step <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_step")
  step_ops <- cbm_exn_step$get_default_ops(
    param_object,
    model_variables$ModelVariables$from_pandas(cbm_vars)
  )
  return (step_ops)
}

#' Run all C dynamics for one timestep
#' @param cbm_vars named list of dataframes containing
#' the simulation state and variables for the timestep
#' @param operations list of formatted matrix operations
#' to apply to the pools.
#' @param disturbance_op_sequence list of named disturbance
#' operations to apply to the pools referencing the
#' values in the specified `operations`
#' @param step_op_sequence list of named annual process
#' operations to apply to the pools referencing the
#' values in the specified `operations`
#' @param parameters named list of default parameter for model
#' initialization
#' @export
cbm_exn_step <- function(
  cbm_vars,
  operations,
  disturbance_op_sequence,
  step_op_sequence,
  parameters
) {
  box::use(reticulate[reticulate_import = import, `%as%`])

  # import python packages
  cbm_exn_model <- reticulate_import("libcbm.model.cbm_exn.cbm_exn_model")
  print(step_op_sequence)
  print(disturbance_op_sequence)
  with(cbm_exn_model$initialize(parameters = parameters) %as% cbm, {
    cbm_vars <- cbm$step(
      cbm_vars, operations, disturbance_op_sequence, step_op_sequence
    )
    return(cbm_vars)
  })
}
