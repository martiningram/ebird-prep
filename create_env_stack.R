library(raster)


split_classifications <- function(full_raster) {

  deciduous_forest <- full_raster == 41
  evergreen_forest <- full_raster == 42
  mixed_forest <- full_raster == 43
  grassland <- full_raster == 71
  
  stack(list(deciduous_forest=deciduous_forest,
             evergreen_forest=evergreen_forest,
             mixed_forest=mixed_forest,
             grassland=grassland))
}


split_all_classifications <- function(full_raster) {

    unique_vals <- unique(full_raster)

    all_results <- list()

    for (cur_val in unique_vals) {
        all_results[[as.character(cur_val)]] <- (full_raster == cur_val)
    }

    stack(all_results)

}


reproject_crop_and_merge <- function(raster_1, raster_2, method = 'ngb') {
  
  # Reproject
  raster_2_adjusted <- projectRaster(raster_2, raster_1, method = method)
  
  # Sum to find shared extent
  combined <- raster_1 + raster_2_adjusted
  
  # Crop both to this extent
  r1_cropped <- crop(raster_1, combined)
  r2_cropped <- crop(raster_2_adjusted, combined)
  
  # Stack result
  stack(r1_cropped, r2_cropped)
  
}


args <- commandArgs(trailingOnly = TRUE)


classification_raster <- raster(args[1])
target_file <- args[2]

split_class <- split_all_classifications(classification_raster)

worldclim <- getData("worldclim", var="bio", res=10.)
full_data <- reproject_crop_and_merge(worldclim, split_class, method = 'bilinear')

# Store the raster
writeRaster(full_data, filename=target_file, options="INTERLEAVE=BAND",
            overwrite=TRUE)

# Store the names
write.csv(names(full_data), paste0(tools::file_path_sans_ext(target_file), 
                                   '_names.csv'))
