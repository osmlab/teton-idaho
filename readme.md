Teton County Import
===========

# Background

[Martijn van Exel was aproached by Teton County in Idaho](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016610.html) about providing the county's data to OpenStreetMap, OSM. The offer was to use locally produced, surveyed, and public domain data to improve the same area in OSM. It is believed that the data will reduce complaints from folks getting lost using apps / sites based on OSM data.  A review of the area data in OSM shows an area that was largely unretouched from the [original dave-hansen TIGER import and the balrog-kun street name expansion](http://www.openstreetmap.org/way/13915681/history).

# Strategy

The US OpenStreetMap community is using two efforts to enhance the area.  The [first effort](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016630.html) was created by Clifford Snow via [the OSM Tasking Manager project #58 - Clean up Roads in Teton County, ID](http://tasks.openstreetmap.us/project/58).  The first effort is a standard [TIGER](http://wiki.openstreetmap.org/wiki/TIGER) [fixup effort](http://wiki.openstreetmap.org/wiki/TIGER_fixup).

The second effort is through this OSMLab github repository and corresponding [OSM wiki import page](http://wiki.openstreetmap.org/wiki/Idaho/Teton_County/imports).  Another goal of the second effort is to provide a step by step guide showing one way of preparing data for import into OSM.

# Review Data

One of the first steps of a data import project is to review the data that you will be importing.  [Elliott Plack](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016622.html) provided a great visual view of the data. A subset of the data is shown of [the entire PDF](assets/Idaho.pdf?raw=true "County of Teton Idaho data PDF") along with two views of the data provided in the shape files.

![County of Teton Idaho data](assets/Idaho.png?raw=true "County of Teton Idaho data subset")

![County of Teton Idaho address data](assets/TetonCountyAddressesDataTable.png?raw=true "County of Teton Idaho address data")

![County of Teton Idaho road data](assets/TetonCountyRoadsDataTable.png?raw=true "County of Teton Idaho data road data")

# Determine Spatial Reference


    select srid, auth_name, auth_srid, srtext, proj4text
      from spatial_ref_sys
     where lower(srtext) like '%idaho%'
    order by srid;

| srid | auth_name | auth_srid | srtext | proj4text |
|------|-----------|-----------|--------|-----------|
| 2241 | EPSG | 2241 | PROJCS["NAD83 / Idaho East (ftUS)",GEOGCS["NAD83" ... | +proj=tmerc +lat_0=41.66666666666666 ... |
| 2242 | EPSG | 2242 | PROJCS["NAD83 / Idaho Central (ftUS)",GEOGCS["NAD83" ... | +proj=tmerc +lat_0=41.66666666666666 ... |
| 2243 | EPSG | 2243 | PROJCS["NAD83 / Idaho West (ftUS)",GEOGCS["NAD83" ... | +proj=tmerc +lat_0=41.66666666666666 ... |
| ... | ... | ... | ... | ... |

![County of Teton Idaho spatial reference](assets/determine_spatail_ref.png?raw=true "County of Teton Idaho spatial reference")