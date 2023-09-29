box::use(testthat[test_that, expect_equal])
box::use(reticulate[reticulate_import = import, dict])
box::use(cbm_exn = ../../R/cbm_exn)

test_that(
  "cbm_exn spinup basic integration test works", {
    libcbm_resources <- reticulate_import("libcbm.resources")
    net_increments <- read.csv(
      file.path(
        libcbm_resources$get_test_resources_dir(),
        "cbm_exn_net_increments",
        "net_increments.csv"
      )
    )

    colnames(net_increments) <- c(
      "age", "merch_inc", "foliage_inc", "other_inc"
    )
    stand_increments <- NULL
    n_stands <- 2
    for (i in 0:(n_stands - 1)) {
      copied_increments <- data.frame(net_increments)
      copied_increments <- cbind(data.frame(row_idx = i), copied_increments)
      stand_increments <- rbind(
        stand_increments, copied_increments
      )
    }

    spinup_parameters <- data.frame(
      age = sample(0L:60L, n_stands, replace = TRUE),
      area = rep(1.0, n_stands),
      delay = rep(0L, n_stands),
      return_interval = rep(125L, n_stands),
      min_rotations = rep(10L, n_stands),
      max_rotations = rep(30L, n_stands),
      spatial_unit_id = rep(17L, n_stands), # Ontario/Mixedwood plains
      species = rep(20L, n_stands), # red pine
      mean_annual_temperature = rep(2.55, n_stands),
      historical_disturbance_type = rep(1L, n_stands),
      last_pass_disturbance_type = rep(1L, n_stands)
    )
    param_path <- libcbm_resources$get_cbm_exn_parameters_dir()

    cbm_exn_parameters <- dict(
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
    out_dir <- tempdir()
    cbm_vars <- cbm_exn$cbm_exn_spinup(
      dict(
        parameters = spinup_parameters,
        increments = stand_increments
      ),
      cbm_exn_parameters,
      spinup_debug_output_dir = out_dir
    )
    pool_out_exists <- file.exists(file.path(out_dir, "pools.csv"))
    testthat::expect_true(pool_out_exists)
    testthat::expect_equal(nrow(cbm_vars$parameters), n_stands)
    testthat::expect_equal(nrow(cbm_vars$pools), n_stands)
  }
)