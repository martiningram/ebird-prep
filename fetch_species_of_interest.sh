SIGHTINGS=/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/june_2019_only/all_june_2019_zero_filled.txt

SPECIES_LIST=/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/june_2019_only/species_to_look_for.csv

TARGET_DIR=/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/june_2019_only/species_separated/

mkdir -p "$TARGET_DIR"

while read cur_species; do
  echo "Fetching $cur_species"
  bash fetch_single_species.sh "$SIGHTINGS" "$cur_species" "$TARGET_DIR"
done <"$SPECIES_LIST"

