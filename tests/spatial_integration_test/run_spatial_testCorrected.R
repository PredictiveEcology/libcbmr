## NOTES: adjustments to Scott Morken's test running a small raster provided by
## CBoisvenue and EMcIntire using paired down inputs from spadesCBM. Scott calls
## libcbm (Python version 2.6.0) to complete the simulations. This is the
## strating point from which CBoisvenue will rebuild spadesCBM to run with
## libcbm instead of the C++ scripts in CBM_core.


## It is important to set the virtual environment when calling Python scripts
## from R. This does it:
library(reticulate)
#virtualenv_list()
#[1] "r-reticulate"
#reticulate::use_virtualenv("r-reticulate")
reticulate::import("sys")$executable
#[1] "C:\\Users\\cboisven\\DOCUME~1\\VIRTUA~1\\R-RETI~1\\Scripts\\python.exe"

## This imports the libcbm Python scripts maintained by Scott Morken for the
## CAT and checks the version.
libcbm <- reticulate::import("libcbm")
print(reticulate::py_get_attr(libcbm, "__version__"))
#'2.6.0'

## Scott modified a version of libcbmr that also needs to be loaded. This does
## it.
install.packages("remotes")
remotes::install_github("smorken/libcbmr")
library(libcbmr)
###CELINE: we need the data table package
install.packages("data.table")
library(data.table)
## Modifications to find inputs to the stand alone version CBM_core provided to
## Scott from CBoisvenue
inputsScott <- file.path(getwd(),"tests","Spatial_integration_test")
spatial_inventory <- base::readRDS(file.path(inputsScott,"spatialDT.rds"))
gc_hash <- base::readRDS(file.path(inputsScott,"gcHash.rds"))

times <- list(start = 1998, end = 2000)

disturbance_rasters <- {
  rasts <- terra::rast(
    file.path(inputsScott,paste0("SaskDist_", times$start:times$end, ".grd"))
  )
  names(rasts) <- times$start:times$end
  rasts
}

ldsp_test_area <- terra::rast(file.path(inputsScott,"ldSp_TestArea.tif"))

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
###CELINE: this is the wrong merge, $level3DT is what you want to merge with as
###it has all the 41 pixelGroups for the spinup
ages <-  c(100, 100, 100, 100, 101, 101, 101, 102, 102, 109, 109, 11,
         110, 12, 12, 128, 129, 13, 13, 130, 14, 79, 81, 81, 82, 88, 89,
         89, 9, 90, 90, 91, 91, 92, 92, 93, 93, 94, 99, 99, 99)
nStands <-  length(ages)
spatialUnits <-  rep(28, nStands)
ecozones <-  rep(9, nStands)
gcids <-  structure(c(1L, 2L, 3L, 5L, 1L, 2L, 5L, 1L, 2L, 1L, 2L, 3L, 2L,
                    1L, 3L, 2L, 2L, 1L, 3L, 2L, 1L, 4L, 1L, 2L, 2L, 1L, 1L, 2L, 3L,
                    1L, 2L, 1L, 2L, 1L, 2L, 1L, 2L, 2L, 1L, 2L, 5L),
                  levels = c("49", "50", "52", "58", "61"), class = "factor")

level3DT <-  {
  df <- data.table(ages, spatialUnits, gcids, gcids,
                   ecozones, pixelGroup = seq(nStands), gcids)
  colnames(df) <- c("ages", "spatial_unit_id", "growth_curve_component_id",
                    "growth_curve_id", "ecozones", "pixelGroup", "gcids")
  df
}
# spatial_inv_gc_merge <- merge(
#   level3DT,#spatial_inventory,
#   gcid_is_sw_hw,
#   by.x = "growth_curve_id",
#   by.y = "gcid"
# )

gcid_is_sw_hw$gcid <- factor(gcid_is_sw_hw$gcid, levels(level3DT$gcids))

spatial_inv_gc_merge <- level3DT[gcid_is_sw_hw, on = c("gcids" = "gcid")]

# construct the spinup input, using a combination of the above spatial data, and
# some constant values, this is done along the pixel group ids
##CELINE: made this a data table
spinup_parameters <- data.table(
  pixelGroup = spatial_inv_gc_merge$pixelGroup,
  age = spatial_inv_gc_merge$ages,
  area = 1.0,
  delay = 0L,
  return_interval = 75L, ##to match stanAloneCore.R
  min_rotations = 10L,
  max_rotations = 30L,
  spatial_unit_id = spatial_inv_gc_merge$spatial_unit_id,
  sw_hw = as.integer(spatial_inv_gc_merge$is_sw),
  species = ifelse(spatial_inv_gc_merge$is_sw, 1, 62),
  ##TODO what is this used for? why chose these species? the species are
  ##attached to the growth curves:
  ##  gcid is_sw
  ##1   49  TRUE Black Spruce
  ##2   50  TRUE Black Spruce
  ##3   52  TRUE Jack Pine
  ##4   58 FALSE White Birch
  ##5   61  TRUE White Spruce
  ## in spadesCBM this information is provided with the growth curves by the
  ## user (in CBM_vol2biomass $gcMeta)
  mean_annual_temperature = -0.02307,
  historical_disturbance_type = 1L,
  last_pass_disturbance_type = 1L
)
##CELINE: this takes out area - why?
spinup_data_cols <- c(
  "pixelGroup",
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
###CELINE: not more duplications because the level3DT was used
spinup_parameters_dedup <-  spinup_parameters[, "area" := NULL]
# spinup_parameters_dedup <- spinup_parameters[
#   !duplicated(
#     spinup_parameters[, c("pixelGroup", spinup_data_cols)]
#   ),
# ]

rownames(spinup_parameters_dedup) <- NULL
spinup_parameters_dedup$spinup_record_idx <- as.integer(
  rownames(spinup_parameters_dedup)
)
##CELINE: no need for this anymore.
# # creates a dataframe look-up table for expanding the de-duplicated spinup
# # results back to space
# spinup_parameter_redup <- merge(
#   spinup_parameters_dedup,
#   spinup_parameters,
#   by = spinup_data_cols
# )[c("spinup_record_idx", "pixelGroup.y")]
# colnames(spinup_parameter_redup) <- c("spinup_record_idx", "pixelGroup")

###HERE
growth_increment_pre_merge <- data.frame(
  pixelGroup = spatial_inv_gc_merge$pixelGroup,
  gcid = spatial_inv_gc_merge$growth_curve_id,
  sw_hw = as.integer(spatial_inv_gc_merge$is_sw)
)
# growth_increment_pre_merge <- growth_increment_pre_merge[
#   !duplicated(growth_increment_pre_merge$pixelGroup),
# ]

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
install.packages("box")
#library(box)
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
#####STOPPED HERE ERROR###############################
