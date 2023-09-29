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


    cbm_exn_parameters <- dict(
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
    cbm_vars <- cbm_exn_variables$init_cbm_vars(
      n_stands, pools, flux_names, backends$BackendType$pandas
    )

    # convert to the dict[str: pd.DataFrame] format expected by cbm_exn
    # step by default
    cbm_vars <- cbm_vars$to_pandas()

    testthat::expect_equal(nrow(cbm_vars$pools), n_stands)
    cbm_vars <- cbm_exn$cbm_exn_step(cbm_vars, cbm_exn_parameters)
    testthat::expect_equal(nrow(cbm_vars$pools), n_stands)
  }
)