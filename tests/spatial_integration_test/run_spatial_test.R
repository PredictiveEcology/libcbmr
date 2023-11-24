library(libcbmr)

spatial_inventory <- base::readRDS("spatialDT.rds")
gc_hash <- base::readRDS("gcHash.rds")
times <- list(start = 1998, end = 2000)

disturbance_rasters <- {
  rasts <- terra::rast(
    file.path(paste0("SaskDist_", times$start:times$end, ".grd"))
  )
  names(rasts) <- times$start:times$end
  rasts
}

ldsp_test_area <- terra::rast("ldSp_TestArea.tif")

#extract the growth increments from the nested environments
gc_df <- NULL
for (gcid in ls(gc_hash)){
  gc <- gc_hash[[gcid]]
  for (age in ls(gc)){
    row <- gc[[age]]
    row <- c(as.integer(gcid), as.integer(age), row)
    gc_df <- rbind(gc_df, row)
  }
}
gc_df <- data.frame(gc_df)
rownames(gc_df) <- NULL
colnames(gc_df) <- c(
  "gcid",
  "age",
  "sw_merch_inc",
  "sw_foliage_inc",
  "sw_other_inc",
  "hw_merch_inc",
  "hw_foliage_inc",
  "hw_other_inc"
)

# map the gcids to the correct values corresponding to the inventory
gc_df$gcid <- structure(
  gc_df$gcid,
  levels = c("49", "50", "52", "58", "61"),
  class = "factor"
)
gc_df$gcid <- as.integer(as.character(gc_df$gcid))

# need to figure out which increment entries are hw and which are sw due to the
# structuring in `libcbm.cbm_exn`
gc_df_sw_summed <- aggregate(
  gc_df$sw_merch_inc, b = list(gcid = gc_df$gcid), FUN = sum
)

gcid_is_sw_hw <- data.frame(
  gcid = gc_df_sw_summed$gcid,
  is_sw = gc_df_sw_summed$x > 0
)

# merge the growth curve sw/hw df onto the spatial inventory
spatial_inv_gc_merge <- merge(
  spatial_inventory,
  gcid_is_sw_hw,
  by.x = "growth_curve_id",
  by.y = "gcid"
)

# construct the spinup input, using a combination of the above spatial data, and
# some constant values, this is done along the pixel group ids
spinup_parameters <- data.frame(
  pixelGroup = spatial_inv_gc_merge$pixelGroup,
  age = spatial_inv_gc_merge$ages,
  area = 1.0,
  delay = 0L,
  return_interval = 125L,
  min_rotations = 10L,
  max_rotations = 30L,
  spatial_unit_id = spatial_inv_gc_merge$spatial_unit_id,
  sw_hw = as.integer(spatial_inv_gc_merge$is_sw),
  species = ifelse(spatial_inv_gc_merge$is_sw, 1, 62),
  mean_annual_temperature = 2.55,
  historical_disturbance_type = 1L,
  last_pass_disturbance_type = 1L
)

spinup_data_cols <- c(
  "age",
  "spatial_unit_id",
  "delay",
  "return_interval",
  "min_rotations",
  "max_rotations",
  "spatial_unit_id",
  "sw_hw",
  "species",
  "mean_annual_temperature",
  "historical_disturbance_type",
  "last_pass_disturbance_type"
)

# drop duplicated spinup records
spinup_parameters_dedup <- spinup_parameters[
  !duplicated(
    spinup_parameters[, c("pixelGroup", spinup_data_cols)]
  ),
]

rownames(spinup_parameters_dedup) <- NULL
spinup_parameters_dedup$spinup_record_idx <- as.integer(
  rownames(spinup_parameters_dedup)
)


# creates a dataframe look-up table for expanding the de-duplicated spinup
# results back to space
spinup_parameter_redup <- merge(
  spinup_parameters_dedup,
  spinup_parameters,
  by = spinup_data_cols
)[c("spinup_record_idx", "pixelGroup.y")]
colnames(spinup_parameter_redup) <- c("spinup_record_idx", "pixelGroup")


growth_increment_pre_merge <- data.frame(
  pixelGroup = spatial_inv_gc_merge$pixelGroup,
  gcid = spatial_inv_gc_merge$growth_curve_id,
  sw_hw = as.integer(spatial_inv_gc_merge$is_sw)
)
growth_increment_pre_merge <- growth_increment_pre_merge[
  !duplicated(growth_increment_pre_merge$pixelGroup),
]

growth_increments_merge_1 <- merge(
  growth_increment_pre_merge,
  spinup_parameters_dedup,
  by = "pixelGroup",
)

growth_increments_merge_2 <- merge(
  growth_increments_merge_1[, c("spinup_record_idx", "gcid", "sw_hw.x")],
  gc_df,
  by = "gcid"
)

growth_increments <- data.frame(
  "row_idx" = growth_increments_merge_2$spinup_record_idx,
  "age" = growth_increments_merge_2$age,
  "merch_inc" = ifelse(
    growth_increments_merge_2$sw_hw.x,
    growth_increments_merge_2$sw_merch_inc,
    growth_increments_merge_2$hw_merch_inc
  ),
  "foliage_inc" = ifelse(
    growth_increments_merge_2$sw_hw.x,
    growth_increments_merge_2$sw_foliage_inc,
    growth_increments_merge_2$hw_foliage_inc
  ),
  "other_inc" = ifelse(
    growth_increments_merge_2$sw_hw.x,
    growth_increments_merge_2$sw_other_inc,
    growth_increments_merge_2$hw_other_inc
  )
)

#remove the 0th increments as `cbm_exn_spinup_ops` doesn't want them
growth_increments <- growth_increments[growth_increments$age > 0, ]

spinup_input <- list(
  parameters = spinup_parameters_dedup,
  increments = growth_increments
)

libcbm_default_model_config <- libcbmr::cbm_exn_get_default_parameters()
spinup_op_seq <- libcbmr::cbm_exn_get_spinup_op_sequence()
spinup_ops <- libcbmr::cbm_exn_spinup_ops(
  spinup_input, libcbm_default_model_config
)

# run spinup
cbm_vars <- libcbmr::cbm_exn_spinup(
  spinup_input,
  spinup_ops,
  spinup_op_seq,
  libcbm_default_model_config
)

# create a multi layer matrix of the input spatial layers
spatial_data <- cbind(
  as.matrix(ldsp_test_area),
  as.matrix(disturbance_rasters)
)

# drop the row-wise duplicates of the above, so that we only simulate the
# unique combinations
spatial_data_dedup <- spatial_data[
  !duplicated(spatial_data),
]

# merge the de-duplicated spatial data with the pixel group inventory
cbm_simulation_records <- merge(
  spatial_data_dedup,
  spinup_parameters_dedup,
  by.x = "ldSp_TestArea",
  by.y = "pixelGroup"
)

# maintain a row identifier since subsequent merges may scramble the order
cbm_simulation_records$cbm_record_id <- as.integer(
  rownames(cbm_simulation_records)
)

cbm_simulation_records <- cbm_simulation_records[
  c(
    "ldSp_TestArea",
    "1998",
    "1999",
    "2000",
    "cbm_record_id",
    "spinup_record_idx"
  )
]

# add an order field for sorting post-merge
spatial_data_merge <- cbind(order = 1:nrow(spatial_data), spatial_data)

# create an array that can be used to expand the CBM simulation state and
# variables to the raster space
cbm_simulation_records_expand <- merge(
  cbm_simulation_records,
  spatial_data_merge,
  by = c(
    "ldSp_TestArea",
    "1998",
    "1999",
    "2000"
  ),
  all.y = TRUE
)

# sort by order field
cbm_simulation_records_expand <- cbm_simulation_records_expand[
  order(cbm_simulation_records_expand$order),
]

#expand the simulation storage
state <- cbm_vars$state[cbm_simulation_records$spinup_record_idx, ]

pools <- cbm_vars$pools[cbm_simulation_records$spinup_record_idx, ]
flux <- cbm_vars$flux[cbm_simulation_records$spinup_record_idx, ]
parameters <- cbm_vars$parameters[cbm_simulation_records$spinup_record_idx, ]

rownames(state) <- NULL
state$record_idx <- as.integer(rownames(state))
rownames(pools) <- NULL
rownames(flux) <- NULL
rownames(parameters) <- NULL

cbm_vars <- list(
  state = state,
  pools = pools,
  flux = flux,
  parameters = parameters
)

cbm_increments <- merge(
  cbm_simulation_records[c("cbm_record_id", "spinup_record_idx")],
  growth_increments,
  by.x = "spinup_record_idx",
  by.y = "row_idx"
)

dir.create("output", showWarnings = FALSE)
for (year in times[[1]]:times[[2]]){
  annual_increments <- merge(
    cbm_increments,
    cbm_vars$state,
    by.x = c("cbm_record_id", "age"),
    by.y = c("record_idx", "age")
  )

  cbm_vars$parameters$mean_annual_temperature <- 1.0
  cbm_vars$parameters$disturbance_type <- unlist(
    unname(
      cbm_simulation_records[as.character(year)]
    )
  )

  cbm_vars$parameters$merch_inc <- annual_increments$merch_inc
  cbm_vars$parameters$foliage_inc <- annual_increments$foliage_inc
  cbm_vars$parameters$other_inc <- annual_increments$other_inc

  # set increments to 0 if the age ended up not being defined in the increments
  # due to the age being out-of-range
  cbm_vars$parameters$merch_inc[is.na(cbm_vars$parameters$merch_inc)] <- 0.0
  cbm_vars$parameters$foliage_inc[is.na(cbm_vars$parameters$foliage_inc)] <- 0.0
  cbm_vars$parameters$other_inc[is.na(cbm_vars$parameters$other_inc)] <- 0.0

  step_ops <- libcbmr::cbm_exn_step_ops(cbm_vars, libcbm_default_model_config)

  cbm_vars <- libcbmr::cbm_exn_step(
    cbm_vars,
    step_ops,
    libcbmr::cbm_exn_get_step_disturbance_ops_sequence(),
    libcbmr::cbm_exn_get_step_ops_sequence(),
    libcbm_default_model_config
  )

  total_eco_stocks_tC_per_ha <- (
    cbm_vars$pools$Merch
    + cbm_vars$pools$Foliage
    + cbm_vars$pools$Other
    + cbm_vars$pools$CoarseRoots
    + cbm_vars$pools$FineRoots
    + cbm_vars$pools$AboveGroundVeryFastSoil
    + cbm_vars$pools$BelowGroundVeryFastSoil
    + cbm_vars$pools$AboveGroundFastSoil
    + cbm_vars$pools$BelowGroundFastSoil
    + cbm_vars$pools$MediumSoil
    + cbm_vars$pools$AboveGroundSlowSoil
    + cbm_vars$pools$BelowGroundSlowSoil
    + cbm_vars$pools$StemSnag
    + cbm_vars$pools$BranchSnag
  )

  npp_tC_per_ha <- (
    cbm_vars$flux$DeltaBiomass_AG
    + cbm_vars$flux$DeltaBiomass_BG
    + cbm_vars$flux$TurnoverMerchLitterInput
    + cbm_vars$flux$TurnoverFolLitterInput
    + cbm_vars$flux$TurnoverOthLitterInput
    + cbm_vars$flux$TurnoverCoarseLitterInput
    + cbm_vars$flux$TurnoverFineLitterInput
  )

  write.csv(
    cbm_vars$pools,
    file.path("output", paste("pools_", as.character(year), ".csv", sep = ""))
  )
  write.csv(
    cbm_vars$flux,
    file.path("output", paste("flux_", as.character(year), ".csv", sep = ""))
  )
  write.csv(
    cbm_vars$state,
    file.path("output", paste("state_", as.character(year), ".csv", sep = ""))
  )
  write.csv(
    cbm_vars$parameters,
    file.path(
      "output",
      paste("parameters_", as.character(year), ".csv", sep = "")
    )
  )
  spatial_age <- cbm_vars$state$age[
    cbm_simulation_records_expand$cbm_record_id
  ]
  terra::writeRaster(
    terra::rast(
      matrix(spatial_age, nrow = 1900, byrow = TRUE)
    ),
    file.path("output", paste("age_", as.character(year), ".tif", sep = "")),
    overwrite = TRUE
  )
  npp_tC_per_ha_spatial <- npp_tC_per_ha[
    cbm_simulation_records_expand$cbm_record_id
  ]
  terra::writeRaster(
    terra::rast(
      matrix(npp_tC_per_ha_spatial, nrow = 1900, byrow = TRUE)
    ),
    file.path(
      "output",
      paste("npp_tC_per_ha_", as.character(year), ".tif", sep="")
    ),
    overwrite = TRUE
  )
  total_eco_stocks_tC_per_ha_spatial <- total_eco_stocks_tC_per_ha[
    cbm_simulation_records_expand$cbm_record_id
  ]
  terra::writeRaster(
    terra::rast(
      matrix(total_eco_stocks_tC_per_ha_spatial, nrow = 1900, byrow = TRUE)
    ),
    file.path(
      "output",
      paste("total_eco_stocks_tC_per_ha_", as.character(year), ".tif", sep = "")
    ),
    overwrite = TRUE
  )
}

terra::plot(
  terra::rast(file.path("output", "npp_tC_per_ha_1998.tif"))
)
