library(blockCV)
library(sf)
library(raster)

args <- commandArgs(trailingOnly = TRUE)

bbs_csv <- args[1]
ebird_csv <- args[2]

higher_res_land_cover_raster <- args[3]

bbs_csv_target <- args[4]
ebird_csv_target <- args[5]

cov_csv_target <- args[6]

set.seed(2)

                                        # Load the ebird data
ebird_df <- read.csv(ebird_csv, row.names = 1)
bbs_df <- read.csv(bbs_csv, row.names = 1, check.names = FALSE)

                                        # Convert bbs_df to the right coordinate system
# bbs_df <- st_as_sf(bbs_df, coords=c('X', 'Y'), crs=3968)
# bbs_df <- st_transform(bbs_df, crs=4326)
# bbs_coords <- st_coordinates(bbs_df)
# bbs_df <- st_drop_geometry(bbs_df)
# bbs_df[, c('X', 'Y')] <- bbs_coords[, c('X', 'Y')]

ebird_coord_names <- c('X', 'Y')
bbs_coord_names <- c('X', 'Y')

ebird_xy <- ebird_df[, ebird_coord_names]
bbs_xy <- bbs_df[, bbs_coord_names]

all_lat <- c(ebird_xy$Y, bbs_xy$Y)
all_lon <- c(ebird_xy$X, bbs_xy$X)

combined <- cbind(all_lon, all_lat)
combined <- as.data.frame(combined)
colnames(combined) <- c('longitude', 'latitude')

combined$data_type <- c(
    rep('PO', nrow(ebird_xy)),
    rep('PA', nrow(bbs_xy))
)

combined_sf <- st_as_sf(combined, coords=c('longitude', 'latitude'), crs=3968)

sb <- spatialBlock(speciesData = combined_sf, # sf or SpatialPoints
                   theRange = 400000, # size of the blocks
                   k = 4, # the number of folds
                   selection = "random",
                   iteration = 100, # find evenly dispersed folds
                   biomod2Format = TRUE)

fold_ids <- sb$foldID

pa_fold_ids <- fold_ids[combined$data_type == 'PA']
po_fold_ids <- fold_ids[combined$data_type == 'PO']

# Take the opportunity to also fetch the covariates
combined_latlon <- st_transform(combined_sf, crs=4326)

# covs <- getData("worldclim", var="bio", res=10)
covs <- stack('./env_raster_stack.tif')
cov_names <- read.csv('./env_raster_stack_names.csv', stringsAsFactors = FALSE)$x
names(covs) <- cov_names

cell_nums <- cellFromXY(covs, st_coordinates(combined_latlon))
unique_nums <- unique(cell_nums)
unique_covs <- raster::extract(covs, unique_nums)
cov_df <- data.frame(unique_covs)
cov_df$cell <- unique_nums

land_cover <- raster(higher_res_land_cover_raster)
new_proj_str <- '+proj=lcc +lat_1=37 +lat_2=39.5 +lat_0=36 +lon_0=-79.5 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
land_cover_projected <- projectRaster(land_cover, crs = new_proj_str, method = 'ngb')
higher_res_land_cover <- raster::extract(land_cover_projected, ebird_xy[, c('X', 'Y')])

ebird_df$land_cover <- higher_res_land_cover

cell_lat_lon <- xyFromCell(covs, unique_nums)
cov_df <- cbind(cov_df, cell_lat_lon)

pa_cell_ids <- cell_nums[combined$data_type == 'PA']
po_cell_ids <- cell_nums[combined$data_type == 'PO']

ebird_df$fold_id <- po_fold_ids
bbs_df$fold_id <- pa_fold_ids

ebird_df$cell_id <- po_cell_ids
bbs_df$cell_id <- pa_cell_ids

write.csv(ebird_df, ebird_csv_target)
write.csv(bbs_df, bbs_csv_target)
write.csv(cov_df, cov_csv_target)
