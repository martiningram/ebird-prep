library(sf)


args <- commandArgs(trailingOnly = TRUE)
dataset_path <- args[1]
shapefile <- args[2]
latitude_col <- args[3]
longitude_col <- args[4]
omit_nas <- args[5] == '1'
target_file <- args[6]

print('Loading shapefile...')
shp <- st_read(shapefile)

print('Transforming shapefile')
subset_better_coords <- st_transform(shp, crs = 3968)
geom <- st_geometry(subset_better_coords)

print('Reading CSV...')
full_dataset <- read.csv(dataset_path, stringsAsFactors = FALSE, row.names = 1,
                         check.names = FALSE)

print('Converting dataset to sf...')
test_sf <- st_as_sf(full_dataset, coords = c(longitude_col, latitude_col),
                    crs = 4326)
test_m <- st_transform(test_sf, crs = 3968)

print('Computing intersection and filtering by it...')
intersects <- st_intersects(geom, test_m, sparse = FALSE)
# Note that here we need to do this to allow it to match _any_ of the states
intersects <- apply(intersects, 2, any)
filtered <- test_m[intersects, ]

print('Stripping data...')
data <- st_drop_geometry(filtered)
coords <- st_coordinates(filtered)
combined <- cbind(data, coords)

if (omit_nas) {
    combined <- na.omit(combined)
}

print('Saving results...')
write.csv(combined, target_file)
