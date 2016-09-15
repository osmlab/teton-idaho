Teton County Import
===========

## Background

[Martijn van Exel was aproached by Teton County in Idaho](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016610.html "Hey all you Idaho mappers!") about providing the county's data to OpenStreetMap, OSM. The offer was to use locally produced, surveyed, and public domain data to improve the same area in OSM. It is believed that the data will reduce complaints from folks getting lost using apps / sites based on OSM data.  A review of the area data in OSM shows an area that was largely unretouched from the [original dave-hansen TIGER import and the balrog-kun street name expansion](http://www.openstreetmap.org/way/13915681/history "a street in the import area").

## Strategy

The US OpenStreetMap community is using two efforts to enhance the area.  The [first effort](https://lists.openstreetmap.org/pipermail/talk-us/2016-August/016630.html) was created by Clifford Snow via [the OSM Tasking Manager project #58 - Clean up Roads in Teton County, ID](http://tasks.openstreetmap.us/project/58 "Clean up Roads in Teton County, ID").  The first effort is a standard [TIGER](http://wiki.openstreetmap.org/wiki/TIGER "main TIGER wiki page") [fixup effort](http://wiki.openstreetmap.org/wiki/TIGER_fixup "TIGER fixup wiki page").

The second effort is through this OSMLab github repository and corresponding [OSM wiki import page](http://wiki.openstreetmap.org/wiki/Idaho/Teton_County/imports "Teton County import page").  Another goal of the second effort is to provide a step by step guide showing one way of preparing data for import into OSM.  The OSM Tasking Manager provides a nice context of where the data is located.

![County of Teton Idaho as seen in the OSM Tasking Manager](assets/Teton-County-Location.png?raw=true "County of Teton Idaho as seen in the OSM Tasking Manager")


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

The [.prj](http://www.spatialreference.org/ref/epsg/2241/prj/ "Spatial Reference .org .prj link") file from [Spatial Reference .org](http://www.spatialreference.org/ref/epsg/2241/ "Spatial Reference .org EPSG code 2241") and the [.prj of the address source](data/TetonAddressRevised_9_12_2016?raw=true "Spatial Reference .org .prj link") data have been reformatted to show the minor differences between the two files.

- We can ignore the descriptive text field spelling varations.
- We can raise our eyebrows in concern over some of the numerical variations.

The variations are rounding as such small increments of measure that the differences should not impact the data accuracy. Consider `0.0174532925199433 verses 0.017453292519943295` and the fact that OSM only stores seven places after the decimal point.  These minuscule differences will not impact the quality of the import.  The small differences show that we have located the correct [EPSG code of 2241](http://www.spatialreference.org/ref/epsg/2241/ "Spatial Reference .org EPSG code 2241").

Finally, Teton County provided a screen shot of the spatial properties that they use.

![Teton County spatial reference screen shot.](assets/teton_spatial_properties.png?raw=true "Teton County spatial reference screen shot.")

In the picture that was provided the EPSG number is in the "Current coordinate system:" box.  The "Authority" is the European Petroleum Survey Group, EPSG.  The "WKID", Well Known ID, or Spatial Reference ID is 2241.  A person can spend a life time of GIS editing without noticing this kind-of data, if someone else set up the system of editing and transforming data in and out of the system is not required.  The nice thing about this picture is that it also confirms the selection of the SRID for PostGIS.

Locating and using the correct SRID is an important step. Otherwise, data transformations will send your data to an entirely different place on the planet.  One of the locations that you might find your data without the correct SRID is at [Null Island](https://en.wikipedia.org/wiki/Null_Island).  The reason that the data would move to Null Island without the correct SRID is that the origin of the data would move from -112.1666666666667 degrees west, 41.66666666666666 degrees north to 0 degrees east, 0 degrees north. 0, 0 are coordinates of Null Island.

## PostGIS Shapefile Importer

The primary point of the Determine Spatial Reference section was to figure out what would be the spatial reference ID, SRID, for the PostGIS shapefile importer.  The other step that was not shown was the [creation of the teton schema](sql/00_schema.sql?raw=true "create teton schema SQL script"). The schema provides you one way to organize the data that you will be processing.  The GUI version of the Shapefile Importer is located on the puzzle piece drop down list.  The schema and SRID are used to import the data.

![PostGIS Shapefile Importer](assets/run_pg_shape_loader.png?raw=true "start gui shapefile importer")

- You can choose to select one file or all of the files to perform the import in one step.
- The Shapefile column is used to provide the file name and location of the file in your operating system of choice.
- Note the teton schema reference.
- Note that the Importer lowercased the name.
- The geom column name is the default used by PostGIS.
- The 2241 SRID is required for all the files so that the data can be transformed into OSM data.
- Create was selected for all these files since the shapefiles have not been imported before now.

| Shapefile | Schema | Table | Geo Column | SRID | Mode   | Rm |
|-----------|--------|-------|------------|------|--------|----|
| TetonAddressRevised_9_12_2016 | teton | tetonaddressrevised_9_12_2016 | geom | 2241 | Create | | 
| TetonCountyBuildingFootprints_8_5_16 | teton | tetoncountybuildingfootprints_8_5_16 | geom | 2241 | Create | | 
| TetonCountyCityBoundaries_8_5_16 | teton | tetoncountycityboundaries_8_5_16 | geom | 2241 | Create | | 
| TetonCountyRoads_8_5_16 | teton | tetoncountyroads_8_5_16 | geom | 2241 | Create | | 
| TetonCoZIP | teton | tetoncountyzip | geom | 2241 | Create | | 

## OpenStreetMap Key Value Mapping

The processing of mapping data source columns to OSM key/value pairs can start.  The other part of the attribute mapping step is to actually figure out the extent of the data that is usable in OSM. 

Note that all the column names are 10 characters or less. The [.dbf](https://en.wikipedia.org/wiki/.dbf) file is actually a [dBaseIII](https://en.wikipedia.org/wiki/DBase) formatted database file.  The dBase system originated in the late 1970's when storage space was limited. The constrained column names hail back to that time period.  The bright side to this [.dbf](https://en.wikipedia.org/wiki/.dbf) file format in the shape file system of files is that you can open the [.dbf](https://en.wikipedia.org/wiki/.dbf) file with OpenOffice or the more active [LibreOffice](https://www.libreoffice.org/) office productivity suite project.  The file formats presented are after the [.dbf](https://en.wikipedia.org/wiki/.dbf) file has been loaded into a PostGIS enabled PostgreSQL database.  The gid and geom columns are added by the loader.  You will not see thse columns if you look at the [.dbf](https://en.wikipedia.org/wiki/.dbf) file in [LibreOffice](https://www.libreoffice.org/).

### Address Keys

| Source Column | OSM Equivalent | Use? | Comments |
|---------------|--------------------|------|----------------------------------------------------------------------|
| gid | | no | Primary key column created by the PostGIS Shapefile and DBF loader. |
| objectid | | no | Primary key from the shapefile. |
| created | | no | The created column is just a date column tracking the creation process. |
| addressid | | no | The objectid is the shape file primary key.  The addressid is the actual business system key id column. The column may be useful if Teton County were to actuall maintain the OSM data too. |
| housenumbe | `addr:housenumber` | yes | |
| fk_roadid | | no | The fk, or foreign key roadid can be used to compare address street names with the road names. |
| labelname | `addr:street` | yes | Both the OSM `addr:housenumber` and `addr:street` data are in this column. That means we'll have to extract the two OSM attributes and clean the data up before it can be imported into OSM. |
| addressjur | | | |
| community | | | |
| oldaddress | | | |
| zipcode | `addr:postcode` | | |
| state | `addr:state` | | |
| sub_unit | | | |
| geom | `lat` `lon` | yes | The geometry column will be used to create the final longitude and latitude columns used by OSM. |

### Building Foot Print Keys

| Source Column | OSM Equivalent | Use? | Comments |
|---------------|--------------------|------|----------------------------------------------------------------------|
| gid | | no | Primary key column created by the PostGIS Shapefile and DBF loader. |
| objectid_1 | | no | Primary key from the shapefile. |
| name | | | |
| state | `addr:state` | yes | |
| verified | | | |
| shape_star | | | |
| shape_stle | | | |
| comments | | | |
| structure_ | | | |
| essential_ | | | |
| fema_const | | | |
| building_c | | | |
| shape_st_1 | | | |
| shape_st_2 | | | |
| geom | `lat` `lon` | yes | The geometry column will be used to create the final longitude and latitude columns used by OSM. |

### City Boundary Keys

| Source Column | OSM Equivalent | Use? | Comments |
|---------------|--------------------|------|----------------------------------------------------------------------|
| gid | | no | Primary key column created by the PostGIS Shapefile and DBF loader. |
| objectid | | no | Primary key from the shapefile. |
| shape_star | | | |
| shape_stle | | | |
| juris_name | | | |
| juris_type | | | |
| geom | `lat` `lon` | yes | The geometry column will be used to create the final longitude and latitude columns used by OSM. |

### County Road Keys

| Source Column | OSM Equivalent | Use? | Comments |
|---------------|--------------------|------|----------------------------------------------------------------------|
| left_from     | `addr:housenumber` | 
| gid | | no | Primary key column created by the PostGIS Shapefile and DBF loader. |
| objectid | | no | Primary key from the shapefile. |
| labelname | `addr:street`  | yes | The values may help with parsing of the street name components before they are merged into the final OSM  `addr:street` value.  |
| surfacetyp | `surface` | yes | There's the chance of translating Idaho's surface value to a corresponding OSM value. |
| carto_type | | | |
| classifica | | | |
| roadjurisd | | | |
| nameid | | | |
| openstatus | | | |
| left_from | `addr:housenumber` | yes | The values may help with parsing of the street number components as a validation `addr:housenumber` value. |
| right_from | `addr:housenumber` | yes | The values may help with parsing of the street number components as a validation `addr:housenumber` value. |
| left_to | `addr:housenumber` | yes | The values may help with parsing of the street number components as a validation `addr:housenumber` value. |
| right_to | `addr:housenumber` | yes | The values may help with parsing of the street number components as a validation `addr:housenumber` value. |
| shape_stle | | | |
| geom | `lat` `lon` | yes | The geometry column will be used to create the final longitude and latitude columns used by OSM. |

### County Zipcode Keys

| Source Column | OSM Equivalent | Use? | Comments |
|---------------|--------------------|------|----------------------------------------------------------------------|
| gid | | no | Primary key column created by the PostGIS Shapefile and DBF loader. |
| objectid | | no | Primary key from the shapefile. |
| zipcode | `addr:postcode` | | |
| name | | | |
| shape_star | | | |
| shape_stle | | | |
| geom | `lat` `lon` | yes | The geometry column will be used to create the final longitude and latitude columns used by OSM. |

### Poke at the data

One of the processes that you will have to go through is evaluating the data.  For example, the fk_roadid provides a clue that we may be able to parse the road table labelname and use this as way to expand the address data name.  The reason for all this effort is that OSM prefers the expanded street name over the abbreviated name.

    select addr.gid as agid, addr.objectid as aoid,
           roads.gid as rgid, roads.objectid as roid,
           addr.created, addr.addressid,
           roads.left_from, roads.left_to,
           roads.right_from, roads.right_to,
           addr.housenumbe,
           roads.nameid, addr.fk_roadid,
           addr.labelname as alabelname, roads.labelname as rdlabelname,
           addr.zipcode, addr.state,
           addr.addressjur, addr.community, addr.oldaddress,
           addr.sub_unit, roads.surfacetyp,
           roads.carto_type, roads.classifica, roads.roadjurisd,
           roads.openstatus, roads.shape_stle,
           addr.geom as ageom, roads.geom as rdgeom
      from teton.tetonaddressrevised_9_12_2016 as addr
      join teton.tetoncountyroads_8_5_16 as roads on nameid = fk_roadid;

Examining the result set shows that this approach will not pan out in the end.  For some reason an address like Grizzly Lane is mapped to Ski Hill Road.

| ... | nameid | fk_roadid | alabelname | rdlablename | ... |
|-----|--------|-----------|----------------|----------------|-----|
| ... | 334 | 334 | 948 Grizzly Ln | Ski Hill Rd | ... |

What we do see in some of this review is that we will need to expand the street names so that we can map the `surfacetyp` column to the OSM `surface` tag in addition to the street name expansion of the address data.

Teton County came back with, "Joining the addresses to the road name table (via FKROADID>NAMEID) will likely bring a bunch of errors to light as well. The county readdressed almost everybody about 8 years ago, and they also got in the bad habit of pre-assigning addresses before structures went in, meaning that often the physical road access for completed structures differed from the originally assigned address (especially for houses on a corner). In the process of changing the address, techs sometimes neglected to update the FKROAD ID field in the address layer. I did correct the Grizzly Lane address record. Yes, it should be married to Grizzly Lane. That's an example of an address that was once based on Ski Hill Rd, but when a second home went in, the driveway became a named road (Grizzly Ln) and the association should have changed from Ski Hill Road to Grizzly."

[The 01_teton_name_diffs.sql](sql/01_teton_name_diffs.sql?raw=true "name difference SQL script") script was used to assist Teton County with these update anomalies.

## Prepare Data For OpenStreetMap

Teton County covers many of the U.S. addressing traits.  The table provides an examination of some of the data.  The table reveals our strategy:  we need to nibble off pieces of information on each side of the address string.  Just as an ornithologist becomes an ornithologist by learning bird after bird, we'll trim off data piece by piece.  Once the address data is ready, then we can worry about conflating the address data with the building data.

| labelname | OSM Label | Comments |
|---------------------------------------|-----------------------------------------|------------------------------------------------------------|
| 9948 S 1000 W | 9948 South 1000 West | The address requires expansion of both the prefix direction and postfix direction. |
| 10220 Woolstenhulme Way | 10220 Woolstenhulme Way | The address will be untouched other than separation of the number from the address name. |
| 1950 Leigh Creek Estates Rd | 1950 Leigh Creek Estates Road | The address type, Rd, needs to be expanded.  The main address name, Leigh Creek Estates, has multiple spaces in the name. |
| 3031 Central Ave  Unit #1 | 3031 Central Avenue Unit 1 | The address type, Ave, needs to be expanded.  The address also contains a suite/flat number that will be put in a separate field. |
| 253 Warbird Ln  #2-1 | 253 Warbird Lane 2-1 | The address type, Ln, needs to be expanded.  The address also contains a suite/flat number that will be put in a separate field. This version of the suite/flat number does not have a Unit or Apartment designation in front of the number. |
