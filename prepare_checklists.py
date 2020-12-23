import sys
import pandas as pd


protocols = ["Traveling", "Stationary", "Area", "Traveling - Property Specific"]
max_distance_travelled = 3  # In km
max_area_searched = 900  # In hectares; divide by 100 to get km^2

sampling_csv = sys.argv[1]
target_file = sys.argv[2]

# Load the sampling information
sampling_df = pd.read_csv(sampling_csv, index_col=0)

rel_protocols_only = sampling_df[sampling_df["protocol_type"].isin(protocols)]

distance_ok = ~(
    (rel_protocols_only["protocol_type"] == "Traveling")
    & (rel_protocols_only["effort_distance_km"] > max_distance_travelled)
)

area_ok = ~(
    (rel_protocols_only["protocol_type"] == "Area")
    & (rel_protocols_only["effort_area_ha"] > max_area_searched)
)

# We discard the breeding bird survey records so that we can make sure that our
# evaluation set is independently collected
# TODO: Could actually just use those BBS counts as evaluation?
# not_bbs = ~(rel_protocols_only["locality"].str.contains("BBS"))

remaining = rel_protocols_only[distance_ok & area_ok]

remaining.to_csv(target_file)
