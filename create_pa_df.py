import pandas as pd
from glob import glob
import numpy as np
from ml_tools.paths import base_name_from_path

species_files = glob("./species_separated/*.csv")
species_names = [base_name_from_path(x) for x in species_files]

# Load the checklist ids
checklist_ids = pd.read_csv(species_files[0])["checklist_id"].values


def load_species_data(species_file, checklist_ids):

    loaded = pd.read_csv(species_file, index_col=0)

    # Make sure they match
    assert np.all(loaded["checklist_id"].values == checklist_ids)

    return loaded["species_observed"].values


from tqdm import tqdm

species_data = {
    species_name: load_species_data(species_file, checklist_ids)
    for species_name, species_file in zip(species_names, tqdm(species_files))
}

pa_df = pd.DataFrame(species_data)
pa_df.index = checklist_ids
pa_df.to_csv("all_pa.csv")
