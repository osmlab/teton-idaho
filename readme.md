Teton County Import
===========

## Background

[Martijn van Exel was aproached by Teton County in Idaho](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016610.html "Hey all you Idaho mappers!") about providing the county's data to OpenStreetMap, OSM. The offer was to use locally produced, surveyed, and public domain data to improve the same area in OSM. It is believed that the data will reduce complaints from folks getting lost using apps / sites based on OSM data.  A review of the area data in OSM shows an area that was largely unretouched from the [original dave-hansen TIGER import and the balrog-kun street name expansion](http://www.openstreetmap.org/way/13915681/history "a street in the import area").

## Strategy

The US OpenStreetMap community is using two efforts to enhance the area.  The [first effort](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016630.html) was created by Clifford Snow via [the OSM Tasking Manager project #58 - Clean up Roads in Teton County, ID](http://tasks.openstreetmap.us/project/58 "Clean up Roads in Teton County, ID").  The first effort is a standard [TIGER](http://wiki.openstreetmap.org/wiki/TIGER "main TIGER wiki page") [fixup effort](http://wiki.openstreetmap.org/wiki/TIGER_fixup "TIGER fixup wiki page").

The second effort is through this OSMLab github repository and corresponding [OSM wiki import page](http://wiki.openstreetmap.org/wiki/Idaho/Teton_County/imports "Teton County import page").  Another goal of the second effort is to provide a step by step guide showing one way of preparing data for import into OSM.

## Review Data

One of the first steps of a data import project is to review the data that you will be importing.  [Elliott Plack](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016622.html) provided a great visual view of the data. A subset of the data is shown of [the entire PDF](assets/Idaho.pdf?raw=true "County of Teton Idaho data PDF") along with two views of the data provided in the shape files.  Here is what you need to consider.

- How will I map the column names of the source data to OSM keys and values?
- Will name expansion of the data be required?  For example, if the street names use abbreviations, then those abbreviated names need to be expanded.
- Will several data sources require conflation?  OSM mixes all the attribute and geometry data into one bucket. Other GIS systems create a layer for each feature of interest.  There may be an address point layer and a building foot print layer. A final step may be required to mix these source data values into one feature before they can be imported into OSM.
- What kinds-of existing OSM is available?  You may have to consider merging of the import into existing OSM data.  If the data is not extensive then you may perform a merge during the import.  This step would require human intervention.
- Does the spatial reference match the reference used by OSM?

![County of Teton Idaho data](assets/Idaho.png?raw=true "County of Teton Idaho data subset")

![County of Teton Idaho address data](assets/TetonCountyAddressesDataTable.png?raw=true "County of Teton Idaho address data")

![County of Teton Idaho road data](assets/TetonCountyRoadsDataTable.png?raw=true "County of Teton Idaho data road data")

## Determine Spatial Reference

[OSM uses EPSG:4326](http://www.spatialreference.org/ref/epsg/4326/ "EPSG:4326") for all the mapping data. EPSG:4326 matches the same reference data that is used in GPS devices. EPSG:4236 is a world wide reference system.  [OSM also uses EPSG:3857](http://www.spatialreference.org/ref/epsg/3857/ "EPSG:3857") during the rendering of the OSM data. [Spherical Mercator](http://wiki.openstreetmap.org/wiki/EPSG:3857 "Spherical Mercator") matches a flat map that you would use on a paper map. A [Directions Magazine Reprojecting Grids article](http://www.directionsmag.com/entry/reprojecting-grids/124167 "Reprojecting Grids") that is referenced in the Stack Overflow question, [What's the difference between a projection and a datum?](http://gis.stackexchange.com/questions/664/whats-the-difference-between-a-projection-and-a-datum "What's the difference between a projection and a datum?") provides some nice pictures of the technical details of these mathematical formulas.

All of these spatial reference systems attempt to reduce some sort of distortion of map data.  You will need to match the source data's refence system when you process the data.  The source data uses a shape file format.  There are many files in this format.  The main file of interest is the .prj file.  In addition, since this import will use PosgreSQL and the PostGIS extension, the PostGIS spatial_ref_sys table can be used to help locate the corect spatial refence system.

The first clue that we can use is the location of the data.  In the case of this import, the data is located in eastern Idaho US. The key part of the PostGIS SQL query is the where clause of `lower(srtext) like '%idaho%'`. 21 rows are returned because we made sure the text was in lower case.

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

The data table presented only shows the three relavant rows of the 21 rows returned from the query. These are the important rows because of the other hint from the .prj file.  The source data uses feet.

![County of Teton Idaho spatial reference](assets/determine_spatail_ref.png?raw=true "County of Teton Idaho spatial reference")

The [.prj](http://www.spatialreference.org/ref/epsg/2241/prj/ "Spatial Reference .org .prj link") file from [Spatial Reference .org](http://www.spatialreference.org/ref/epsg/2241/ "Spatial Reference .org EPSG code 2241") and the [.prj of the address source](data/TetonCountyAddresses_8_11_16?raw=true "Spatial Reference .org .prj link") data have been reformatted to show the minor differences between the two files.

- We can ignore the descriptive text field spelling varations.
- We can raise our eyebrows in concern over some of the numerical variations.

The variations are rounding as such small increments of measure that the differences should not impact the data accuracy. Consider `0.0174532925199433 verses 0.017453292519943295` and the fact that OSM only stores seven places after the decimal point.  These minuscule differences will not impact the quality of the import.  The small differences show that we have located the correct [EPSG code of 2241](http://www.spatialreference.org/ref/epsg/2241/ "Spatial Reference .org EPSG code 2241").

## PostGIS Shapefile Importer

The primary point of the Determine Spatial Reference section was to figure out what would be the spatial reference ID, SRID, for the PostGIS shapefile importer.  The other step that was not shown was the [creation of the teton schema](sql/00_schema.sql?raw=true "create teton schema SQL script"). The schema provides you one way to organize the data that you will be processing.  The GUI version of the Shapefile Importer is located on the puzzle piece drop down list.  The schema and SRID are used to import the data.

![PostGIS Shapefile Importer](assets/run_pg_shape_loader.png?raw=true "start gui shapefile importer")

- You can choose to select one file or all of the files at onece.
- The Shapefile column is name and location of the file in your operating system of choice.
- Note the teton schema reference.
- Note that the Importer lowercased the name.
- The geom column name is the default used by PostGIS.
- The 2241 SRID is required for all the files so that the data can be transformed into OSM data.
- Create was selected for all these files since the shapefiles have not been imported before now.

| Shapefile | Schema | Table | Geo Column | SRID | Mode   | Rm |
|-----------|--------|-------|------------|------|--------|----|
| TetonCountyAddresses_8_11_16 | teton | tetoncountyaddresses_8_11_16 | geom | 2241 | Create | | 
| TetonCountyBuildingFootprints_8_5_16 | teton | tetoncountybuildingfootprints_8_5_16 | geom | 2241 | Create | | 
| TetonCountyCityBoundaries_8_5_16 | teton | tetoncountycityboundaries_8_5_16 | geom | 2241 | Create | | 
| TetonCountyRoads_8_5_16 | teton | tetoncountyroads_8_5_16 | geom | 2241 | Create | | 
| TetonCoZIP | teton | tetoncountyzip | geom | 2241 | Create | | 
