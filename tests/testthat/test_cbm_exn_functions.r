box::use(testthat[test_that, expect_equal])
box::use(reticulate[reticulate_import = import, dict])
box::use(cbm_exn = ../../R/cbm_exn)

test_that(
  "get_default_parameters integration runs", {
    result <- cbm_exn$cbm_exn_get_default_parameters()
    testthat::expect_true(length(result) > 0)
  }
)