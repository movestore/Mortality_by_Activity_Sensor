# Mortality by Activity Sensor*

MoveApps

Github repository: *github.com/movestore/Mortality_by_Activity_Sensor*

## Description
Evaluate possibility of tag/animal mortality by activity sensor `activity_count`. Provides indication of voltage decrease, maximum change of activity count and derives an alert attribute.

## Documentation
This App has been developed to extract mortality alert attributes from the activity_count and voltage measurement of the "accessory measurements" files provided by some tags.

From the user indicated tag voltage attribute, the last voltage measurement as well as a linear slope of all values in the defined time interval (estimated voltage change rate) are calculated for each track (individual_local_identifier). The number of measurements included for each track are indicated.

In a next step, the user defined activity count variable of the defined final time interval is evaluated for maximum circular difference considering the user provided circularity (see below). As indicators of the activity, the new attributes maximum activity timestamp (final timestamp of the max activity difference pair of measures), maximum activity time difference (between the pair of timestamps of the max activity difference measures pair), the actual maximum activity difference and an activity alert that is set to `1` if the maximum activity difference is below the use defined threshold.

All additional attributes are returned as a csv table, as well as appended to the track attributes of the move2 nonlocation object. Where appropriate, the new attriutes are provided with a unit.


### Input data
move2 non-location object in Movebank format

### Output data
move2 non-location object in Movebank format

### Artefacts
`Mortality_Alert_Infos.csv`: csv-file with Table of all calculated mortality indication attributes by track ID (individual_local_identifier).

### Settings 
**`Minimum activity change` (min_act_change):** Defined minimum change value of activity measure that is required (within the below defined time interval). If the activity measure does not change by at least this value, the activity alert will be set to 1.

**`Time interval to check for mortality` (time_itv):** Value of the time interval length which shall be checked for mortality indications of each track. Note that the interval timing can differ by track according to the timestamp of last available measurement. Unit: see below

**`Time unit for interval` (time_unit):** Time unit to use for the above defined time interval. Note that this unit will be used as divisor unit for the estimated rate of change of voltage. Only possible options are `hours`, `days` and `weeks`.

**`Range of circular activity measures` (circ):** Defined number of different activity measures. Default: 256 (for values between 0 and 255)

**`Name of voltage attribute` (volt.name):** Provided name of the tag voltage attribute in the input data. Correct spelling to be checked in the summary view's track attributes section of the preceding App. Default: `tag_voltage`.

**`Name of activity count attribute` (activity.name):** Provided name of the activity count attribute in the input data. Correct spelling to be checked in the summary view's track attributes section of the preceding App. Default: `activity_count`.

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