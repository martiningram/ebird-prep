library(auk)

auk_set_ebd_path('/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/',
                 overwrite=TRUE)

ebd_file <- '/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/dataset/ebd_US_relAug-2020.txt'
sampling_file <- '/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/sampling_info/ebd_sampling_relAug-2020.txt'

ebd <- auk_ebd(ebd_file, file_sampling = sampling_file)

output_file <- '/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/june_2019_only/all_june_2019_zero_filled.txt'
output_file_sampling <- '/data/gpfs/projects/punim0592/ebird-basic-dataset/parallel_download_attempt/full_dataset/june_2019_only/all_june_2019_zero_filled_sampling.txt'

ebd_filters <- ebd %>% 
  # country: codes and names can be mixed; case insensitive
  auk_country(country = c("US")) %>%
  # date: use standard ISO date format `"YYYY-MM-DD"`
  auk_date(date = c("2019-06-01", "2019-06-30")) %>%
  auk_complete() %>%
  auk_filter(file = output_file, file_sampling=output_file_sampling, overwrite = TRUE)

ebd_zf <- auk_zerofill(ebd_filters)

write.csv(ebd_zf$observations, output_file)
write.csv(ebd_zf$sampling_events, output_file_sampling)
