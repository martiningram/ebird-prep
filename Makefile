SAMPLING_FILE=/home/martin/data/ebird-basic-dataset/june_2019/all_june_2019_zero_filled_sampling.txt
SPECIES_FOLDER=/home/martin/data/ebird-basic-dataset/june_2019/species_separated/
BBS_FILE=/home/martin/data/bbs_2020_release/processing/route_pa_2019.csv
US_SHAPEFILE=./us-shapefile/us_mainland.shp

all: bbs_with_folds.csv checklists_with_folds.csv

checklists_filtered.csv: $(SAMPLING_FILE) prepare_checklists.py
	python prepare_checklists.py $(SAMPLING_FILE) $@

checklists_us_only.csv: checklists_filtered.csv drop_points_outside_boundary.R
	Rscript drop_points_outside_boundary.R \
		checklists_filtered.csv \
		$(US_SHAPEFILE) \
		latitude \
		longitude \
		0 \
		$@

bbs_us_only.csv: $(BBS_FILE) drop_points_outside_boundary.R
	Rscript drop_points_outside_boundary.R \
		$(BBS_FILE) \
		$(US_SHAPEFILE) \
		Latitude \
		Longitude \
		1 \
		$@

bbs_with_folds.csv checklists_with_folds.csv &: checklists_us_only.csv bbs_us_only.csv make_spatial_split.R
	Rscript make_spatial_split.R \
		bbs_us_only.csv \
		checklists_us_only.csv \
		bbs_with_folds.csv \
		checklists_with_folds.csv \
		raster_cell_covs.csv

all_pa.csv: create_pa_df.py $(SPECIES_FOLDER)
	python create_pa_df.py $(SPECIES_FOLDER)
