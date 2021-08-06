# eBird preprocessing

This repository contains scripts to process eBird data.

Steps:

1. Download the eBird basic dataset.
2. Download the Breeding Bird Survey (BBS) dataset. Use the [processing
   script](https://github.com/martiningram/bbs_parsing/blob/master/extract_route_pa.py)
   to extract route-level presence/absence.
3. Then, run `fetch_relevant_data.R`, which uses `auk` to subset to the relevant
   data. Please make sure to change the paths as necessary on your machine.
4. Next, run `fetch_species_of_interest.sh`, which subsets the eBird data to
   only the species used in the paper, and splits the data into one file per
   species. Again, please make sure to adjust paths as necessary.
5. Finally, run the Makefile, ensuring the paths at the top of the document
   match the locations of the BBS and eBird files.
