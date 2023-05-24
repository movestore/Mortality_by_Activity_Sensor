# Mortality by Activity Sensor*

MoveApps

Github repository: *github.com/movestore/Mortality_by_Activity_Sensor*

## Description
Evaluate the possibility of tag/animal mortality by activity sensor `activity_count` and low voltage. Provides indication of voltage decrease, maximum change of activity count and derives two alert attributes.

## Documentation
This App has been developed to extract mortality alert attributes from the activity_count and voltage measurement of the "accessory measurements" files provided by some tags (e.g. Microwave Telemetry).

The App evaluates voltage and acitivty in a time interval of user-defined length, but for each loaded track this interval is selected from the end of the track, i.e. the intervals are not synchronous.

From the user indicated tag voltage attribute, the last voltage measurement as well as a linear slope of all values in the defined time interval (estimated voltage change rate) are calculated for each track (individual_local_identifier). The number of measurements included for each track are indicated. If the last voltage measurement for a track is below a user given threshold, the voltage alert attribute is set to `1`.

In a next step, the user defined activity count variable of the defined final time interval is evaluated for maximum circular difference considering the user provided circularity (see below). As indicators of the activity, the new attributes maximum activity timestamp (final timestamp of the max activity difference pair of measures), maximum activity time difference (between the pair of timestamps of the max activity difference measures pair), the actual maximum activity difference and an activity alert that is set to `1` if the maximum activity difference is below the use defined threshold.

All additional attributes are returned as a csv table, as well as appended to the track attributes of the move2 nonlocation object. Where appropriate, the new attriutes are provided with a unit. The track attributes can be extracted from the move2 object by `mt_track_data(result)`.

#### The derived attributes are defined as follows:

-  `number_of_measuremens`: number of measurement that were in the selected time interval and considered in the performed calculations. If this number is `1`, activity differences could not be derived and the activity alert is set to NA.

- `timestamp_end`: timestamp of the last location of the selected time interval (and total track), which can differ by track.

- `voltage_end [mV]`: voltage of the last voltage measurement of each track/animal, unit as provided in name (might differ from example here).

- `est_voltage_change_rate [mV/h]`: estimated voltage change rate in the unit as provided in the name, the divisor is the same as selected for `max_activity_dt` below. Unit might differ from the example here. If the value of this attribute is negative with relatively large absolute value, the voltage is decreasing in a way to indicate that the tag is not loading properly and the animal or tag likely dead.

- `voltage_alert`: If the `voltage_end` above is below the provided setting `volt_thr` this measure is set to `1`, indicating too low voltage and possible mortality. Else it is `0`. As there is always at least one measurement per track these are the only two options of this attribute.

- `max_activity_timestamp`: Second/later timestamp of the pair of measurements with the largest activity difference. If there are more than one pair with the same, largest activity difference, the last one in time is selected.

- `max_activity_dt [hours]`: Time difference of the two measurments that have the largest activity difference (last one in time, if there are more than one pair). Unit as provided in the name, might differ from example here.

- `max_activity_difference`: Value of the actual maximum acitvity difference between all pairs of measurements in each of the tracks during the selected time interval.

- `activity_alert`: Alert attribute indicating if none of the pairs of activity measurments had a difference of at least the user set `minimum activity change` (see below). In that case, this attribute is set to `1`, else `0`. In case that there is only one activity measurement for a track in the selected time interval, this alert attribute is set to `NA` (not available).


### Input data
move2 non-location object in Movebank format

### Output data
move2 non-location object in Movebank format

### Artefacts
`Mortality_Alert_Infos.csv`: csv-file with Table of all calculated mortality indication attributes by track ID (individual_local_identifier).

### Settings 
**`Time interval to check for mortality` (time_itv):** Value of the time interval length which shall be checked for mortality indications of each track. Note that the interval timing can differ by track according to the timestamp of last available measurement. Unit: see below

**`Time unit for interval` (time_unit):** Time unit to use for the above defined time interval. Note that this unit will be used as divisor unit for the estimated rate of change of voltage. Only possible options are `hours`, `days` and `weeks`. Default: `hours`.

**`Name of activity count attribute` (activity.name):** Provided name of the activity count attribute in the input data. Correct spelling to be checked in the summary view's track attributes section of the preceding App. Default: `activity_count`.

**`Range of circular activity measures` (circ):** Defined number of different activity measures. Default: 256 (for values between 0 and 255)

**`Minimum activity change` (min_act_change):** Defined minimum change value of activity measure that is required (within the below defined time interval). If the activity measure does not change by at least this value, the activity alert will be set to 1.

**`Name of voltage attribute` (volt.name):** Provided name of the tag voltage attribute in the input data. Correct spelling to be checked in the summary view's track attributes section of the preceding App. Default: `tag_voltage`.

**`Minimum voltage threshold` (volt_thr):** Minimum voltage that the user considers 'healthy' for the tag/transmitter. If the last measurement of a track has recorded a voltage below this threshold value, the voltage alert will be set to 1.

### Most common errors
none, yet.

### Null or error handling
**Setting `min_act_change`:** This value needs to fit with the defined time interval and the data resolution. If it is set too high, tag stationarity might not be detected. If it is set too low, erroneous mortality can be indicated.

**Setting `time_itv`:** This value needs to fit with the defined minimum activity change and the data resolution. If it is set too high, mortality at the end of the track might not be detected. If it is set too low, erroneous mortality can be indicated. If it is set so low that only one location remains per track, mortality indication is not possible and NA is returned for most attributes.

**Setting `time_unit`:** Can only be set to hours, days or weeks.

**Setting `circ`:** The App was developed to detect if a circularly defined activity measure is changing. If the activity measure works differently, this measure does not make sense and the App will give wrong results or fail. Please, make sure that you are using this App only for data that include `activity_count` as an attribute that ranges between e.g. 0 and 255 (default).

**Setting `volt.name`:** Correct spelling must be checked in the summary view's track attributes section of the preceding App. If the provided (or default `tag_voltage` attribute) does not exist, the voltage indicator attributes will not be calculated.

**Setting `activity.name`:** Correct spelling must be checked in the summary view's track attributes section of the preceding App. If the provided (or default `activity_count` attribute) does not exist, the activity indicator attributes and alert will not be calculated.

**data:** If there are less than two activity measures in a track in the defined interval, the activity alert measures are not possible to calcualte and NA is returned for the track. 