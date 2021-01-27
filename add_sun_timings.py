from skyfield import api
from skyfield import almanac
import pandas as pd
import sys
from timezonefinder import TimezoneFinder
from tqdm import tqdm
from pyproj import Transformer

transformer = Transformer.from_crs("epsg:3968", "epsg:4326")

ts = api.load.timescale()
eph = api.load("de421.bsp")

obs_data = pd.read_csv(sys.argv[1], index_col=0)
obs_data["latitude"], obs_data["longitude"] = transformer.transform(
    obs_data["X"].values, obs_data["Y"].values
)

tf = TimezoneFinder()
tzs = [
    tf.timezone_at(lng=lon, lat=lat)
    for lon, lat in zip(tqdm(obs_data["longitude"].values), obs_data["latitude"].values)
]

dts = pd.to_datetime(
    obs_data["observation_date"] + " " + obs_data["time_observations_started"]
)

pandas_dates_utc = pd.Series(
    [cur_dt.tz_localize(cur_tz).astimezone("UTC") for cur_dt, cur_tz in zip(dts, tzs)]
)

import numpy as np

results = list()

for sample_date, row in zip(tqdm(pandas_dates_utc), obs_data.itertuples()):

    t0 = ts.utc(sample_date.year, sample_date.month, sample_date.day - 1)
    t1 = ts.utc(sample_date.year, sample_date.month, sample_date.day + 2)
    location = api.wgs84.latlon(row.latitude, row.longitude)
    t, y = almanac.find_discrete(t0, t1, almanac.sunrise_sunset(eph, location))
    f = almanac.sunrise_sunset(eph, location)

    is_up = f(
        ts.utc(
            sample_date.year,
            sample_date.month,
            sample_date.day,
            sample_date.hour,
            sample_date.minute,
        )
    )

    y_array = np.array(y)

    times = pd.to_datetime(pd.Series(t.utc_iso()))
    types = np.select([y == 0, y == 1], ["sunset", "sunrise"])

    if is_up:

        time_to_sunset = (times[types == "sunset"] - sample_date) / pd.Timedelta(
            "1 hour"
        )
        time_to_next_sunset = time_to_sunset[time_to_sunset > 0].sort_values().iloc[0]
        time_from_sunrise = (sample_date - times[types == "sunrise"]) / pd.Timedelta(
            "1 hour"
        )
        time_from_last_sunrise = (
            time_from_sunrise[time_from_sunrise > 0].sort_values().iloc[0]
        )

    else:

        # Just put in nones for nighttime
        time_to_next_sunset = None
        time_from_last_sunrise = None

    results.append(
        {
            "time_to_next_sunset": time_to_next_sunset,
            "time_from_last_sunrise": time_from_last_sunrise,
        }
    )

result_df = pd.DataFrame(results, index=obs_data.index)

obs_data["time_to_next_sunset"] = result_df["time_to_next_sunset"]
obs_data["time_from_last_sunrise"] = result_df["time_from_last_sunrise"]

obs_data.to_csv("checklists_with_sun_info.csv")
