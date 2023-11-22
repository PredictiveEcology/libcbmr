box::use(testthat[test_that, expect_equal])
box::use(reticulate[reticulate_import = import, dict])
box::use(cbm_exn = ../../R/cbm_exn)

test_that(
  "cbm_exn step basic integration test works", {
    json <- reticulate_import("json")
    cbm_exn_variables <- reticulate_import(
      "libcbm.model.cbm_exn.cbm_exn_variables"
    )
    libcbm_resources <- reticulate_import("libcbm.resources")
    backends <- reticulate_import("libcbm.storage.backends")
    param_path <- libcbm_resources$get_cbm_exn_parameters_dir()
    pools <- json$loads(
      paste(readLines(file.path(param_path, "pools.json")), collapse = " ")
    )
    flux <- json$loads(
      paste(readLines(file.path(param_path, "flux.json")), collapse = " ")
    )
    flux_names <- lapply(flux, function(x) x["name"])
    n_stands <- 2L

    default_params <- cbm_exn$cbm_exn_get_default_parameters()
    cbm_vars <- cbm_exn_variables$init_cbm_vars(
      n_stands, pools, flux_names, backends$BackendType$pandas
    )

    # convert to the dict[str: pd.DataFrame] format expected by cbm_exn
    # step by default
    cbm_vars <- cbm_vars$to_pandas()
    # set some reasonable values
    cbm_vars$pools[, ] <- 1.0
    cbm_vars$flux[, ] <- 0.0

    cbm_vars$parameters[, "mean_annual_temperature"] <- -1.0
    cbm_vars$parameters[, "disturbance_type"] <- 0L
    cbm_vars$parameters[, "merch_inc"] <- 0.1
    cbm_vars$parameters[, "foliage_inc"] <- 0.01
    cbm_vars$parameters[, "other_inc"] <- 0.05

    cbm_vars$state[, "area"] <- 1.0
    cbm_vars$state[, "spatial_unit_id"] <- 3L
    cbm_vars$state[, "land_class_id"] <- 0L
    cbm_vars$state[, "age"] <- 100L
    cbm_vars$state[, "species"] <- 6L
    cbm_vars$state[, "sw_hw"] <- 0L
    cbm_vars$state[, "time_since_last_disturbance"] <- 0L
    cbm_vars$state[, "time_since_land_use_change"] <- 0L
    cbm_vars$state[, "last_disturbance_type"] <- 0L
    cbm_vars$state[, "enabled"] <- 1L

    step_ops <- cbm_exn$cbm_exn_step_ops(cbm_vars, default_params)
    step_ops_sequence <- cbm_exn$cbm_exn_get_step_ops_sequence()
    step_dist_ops_sequence <- (
      cbm_exn$cbm_exn_get_step_disturbance_ops_sequence()
    )
    testthat::expect_equal(nrow(cbm_vars$pools), n_stands)
    cbm_vars <- cbm_exn$cbm_exn_step(
      cbm_vars,
      step_ops,
      step_dist_ops_sequence,
      step_ops_sequence,
      default_params
    )
    testthat::expect_equal(nrow(cbm_vars$pools), n_stands)
  }
)