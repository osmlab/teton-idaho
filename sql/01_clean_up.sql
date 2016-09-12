remark new data received.

/*
 * Look at all the city state and zipcodes in the new list.
 */
select count(*) as zip_cnt, community, state, zipcode
  from teton.tetoncountyaddresses_8_11_16
group by state, zipcode, community
order by state, zipcode, community;


/*
1;"Driggs";"iD";"83422"
3814;"Driggs";"ID";"83422"
156;"Felt";"ID";"83424"
1;"Tetonia";"ID";"83424"
14;"Newdale";"ID";"83436"
2530;"Tetonia";"ID";"83452"
1;"Driggs";"ID";"83455"
4234;"Victor";"ID";"83455"
1;"Tetonia";"ID";"83542"
246;"Alta";"WY";"83414"
3;"Driggs";"";"83422"
1;"Tetonia";"";"83452"
1;"Tetonia";"";""

Perform these updates based on the missing data or issues.
First fix the iD code.
The next updates are for missing state codes. We still have one missing zipcode.
*/
update tetoncountyaddresses_8_11_16
     set state = 'ID'
 where state = 'iD';

 update tetoncountyaddresses_8_11_16
     set state = 'ID'
 where zipcode = '83422'
    and state is null;

update tetoncountyaddresses_8_11_16
     set state = 'ID'
 where zipcode = '83452'
    and state is null;

update tetoncountyaddresses_8_11_16
     set state = 'ID'
 where zipcode is null
    and state is null;

/*
 * make sure that the one state code is uppercased. then file in the
 * other values are set based on community or zipcode.
 */


select distinct addressjur, community, state, zipcode
  from teton.tetoncountyaddresses_8_11_16;

/*
 * Add the OSM country column for future addr:country key.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_country character varying (256);
update teton.tetoncountyaddresses_8_11_16
   set addr_country = 'US';

/*
 * Add the OSM state column for future addr:state key.
 * First set everything to ID, Idaho.
 * Second update the addr_state to WY, Wyoming for the one Postal area.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_state character varying (256);
update teton.tetoncountyaddresses_8_11_16
   set addr_state  = 'ID';
update teton.tetoncountyaddresses_8_11_16
   set addr_state  = 'WY'
 where zipcode = '83414';
 
/*
 * Add the OSM postcode column for future addr:postcode key.
 * Use all the cleaned up zipcodes.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_postcode character varying (256);
update teton.tetoncountyaddresses_8_11_16
   set addr_postcode  = zipcode;

/*
 * Add the OSM city column for future addr:city key.
 * Use all the cleaned up zipcodes.
 */
alter table teton.tetoncountyaddresses_8_11_16
  add column addr_city character varying (256);
update teton.tetoncountyaddresses_8_11_16
   set addr_city = community;

/*
 * Update not required for the 8/11/2016 data.
select *
  from teton.tetoncountyaddresses_8_11_16
 where addr_city is null;
update teton.tetoncountyaddresses_8_11_16
     set addr_city = 'Bates'
 where addr_postcode = '83422';
select *
  from teton.tetoncountyaddresses_8_11_16
 where addr_city is null;
update teton.tetoncountyaddresses_8_11_16
   set addr_city = 'Bates'
 where addr_postcode = '83422';
update teton.tetoncountyaddresses_8_11_16
   set addr_city = 'Victor'
 where addressid = 138806;
*/


alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_pass_1 character varying (256);

update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_1 = labelname;

select length(housenumbe::text) as len_trim,
         substring( labelname::text from 1::int
                        for length(housenumbe::text) ) as house_num_trim,
         substring( labelname::text
                        from length(housenumbe::text)
                           + 1::int ) as addr_street_pass,
         trim(both ' ' from
                substring( labelname::text from length(housenumbe::text)
                      + 1::int ))  as addr_street_pass_1
  from teton.tetoncountyaddresses_8_5_16;

update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_1   = 
            trim(both ' ' from
                substring( labelname::text from length(housenumbe::text)
                      + 1::int ));
/*
 * Now it is time to start the prefix expansion.
 * We will use a holding cell until the final addr_street
 * value is assembled.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_pass_2 character varying (256);
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_prefix character varying (256);

/*
 * Set pass three to all the values that will not fall out in the parsing.
 */
update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_2 = addr_street_pass_1;

select substring( addr_street_pass_1::text from 3::int) as addr_street_pass_2,
         substring( addr_street_pass_1::text from 1::int for 2::int) as addr_street_prefix,
         case when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'W ' then 'West'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'E ' then 'East'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'N ' then 'North'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'S ' then 'South'
          end as addr_street_prefix_final
  from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'W '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'E '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'N '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'S ';

update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_2   = substring( addr_street_pass_1::text from 3::int),
   addr_street_prefix = case when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'W ' then 'West'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'E ' then 'East'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'N ' then 'North'
              when substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'S ' then 'South'
          end
  where substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'W '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'E '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'N '
    or  substring( upper(addr_street_pass_1::text) from 1::int for 2::int) = 'S ';




/*
 * Now it is time to start the units or flats expansion.
 * OSM has a field for this.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_pass_3 character varying (256);
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_flats character varying (256);

/*
 * Set pass three to all the values that will not fall out in the parsing.
 */
update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_3   = addr_street_pass_2;

/*
 * First up we need to trim off the unit.
 */
select position( 'UNIT' in upper(addr_street_pass_3::text)) as unit_pos,
      addr_street_pass_3,
      trim(both ' ' from substring( addr_street_pass_3::text from position( 'UNIT' in upper(addr_street_pass_3::text))::int)) as addr_flats,
      trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( 'UNIT' in upper(addr_street_pass_3::text))::int - 1::int)) as addr_street_pass_3_final
  from teton.tetoncountyaddresses_8_11_16
  where upper(addr_street_pass_3::text) like '%UNIT%';

update teton.tetoncountyaddresses_8_11_16
   set addr_flats = trim(both ' ' from substring( addr_street_pass_3::text from position( 'UNIT' in upper(addr_street_pass_3::text))::int)),
      addr_street_pass_3 = trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( 'UNIT' in upper(addr_street_pass_3::text))::int - 1::int))
  where upper(addr_street_pass_3::text) like '%UNIT%';

/*
 * Second in order, we need to trim off the apartment tags.
 */
select position( 'APT' in upper(addr_street_pass_3::text)) as unit_pos,
      addr_street_pass_3,
      trim(both ' ' from substring( addr_street_pass_3::text from position( 'APT' in upper(addr_street_pass_3::text))::int)) as addr_flats,
      trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( 'APT' in upper(addr_street_pass_3::text))::int - 1::int)) as addr_street_pass_3_final
  from teton.tetoncountyaddresses_8_11_16
  where upper(addr_street_pass_3::text) like '%APT%';

update teton.tetoncountyaddresses_8_11_16
   set addr_flats = trim(both ' ' from substring( addr_street_pass_3::text from position( 'APT' in upper(addr_street_pass_3::text))::int)),
      addr_street_pass_3 = trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( 'APT' in upper(addr_street_pass_3::text))::int - 1::int))
  where upper(addr_street_pass_3::text) like '%APT%';


/*
 * Finally in order, we need to trim off the pound, hash, or #.
 */
select position( '#' in upper(addr_street_pass_3::text)) as unit_pos,
      addr_street_pass_3,
      trim(both ' ' from substring( addr_street_pass_3::text from position( '#' in upper(addr_street_pass_3::text))::int)) as addr_flats,
      trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( '#' in upper(addr_street_pass_3::text))::int - 1::int)) as addr_street_pass_3_final
  from teton.tetoncountyaddresses_8_11_16
  where upper(addr_street_pass_3::text) like '%#%';

update teton.tetoncountyaddresses_8_11_16
   set addr_flats = trim(both ' ' from substring( addr_street_pass_3::text from position( '#' in upper(addr_street_pass_3::text))::int)),
      addr_street_pass_3 = trim(both ' ' from substring( addr_street_pass_3::text from 1::int for position( '#' in upper(addr_street_pass_3::text))::int - 1::int))
  where upper(addr_street_pass_3::text) like '%#%';

/*
 * Now it is time to start the suffix expansion.
 * We will use a holding cell until the final addr_street
 * value is assembled.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_pass_4 character varying (256);
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_suffix character varying (256);

/*
 * Set pass four to all the values that will not fall out in the parsing.
 */
update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_4 = addr_street_pass_3;


select addr_street_pass_4,
         substring( addr_street_pass_4::text from 1::int for length(addr_street_pass_4::text) - 1::int) as addr_street_pass_5,
         substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) as addr_street_suffix,
         case when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' W' then 'West'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' E' then 'East'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' N' then 'North'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' S' then 'South'
          end as addr_street_suffix_final
  from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' W'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' E'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' N'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' S';
    
select *
from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' W'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' E'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' N'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' S';

update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_4   = substring( addr_street_pass_4::text from 1::int for length(addr_street_pass_4::text) - 1::int),
   addr_street_suffix = case when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' W' then 'West'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' E' then 'East'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' N' then 'North'
              when substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' S' then 'South'
          end
  where substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' W'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' E'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' N'
    or  substring( upper(addr_street_pass_4::text) from length(addr_street_pass_4::text) - 1::int for 2::int) = ' S';


/*
 * Now it is time expand the final street type i.e. ln to lane.
 */
alter table teton.tetoncountyaddresses_8_11_16
 add column addr_street_pass_5 character varying (256);

/*
 * Set pass five to all the values that will not fall out in the parsing.
 */
update teton.tetoncountyaddresses_8_11_16
   set addr_street_pass_5 = addr_street_pass_4;

/*
  The street types must be processed from largest to the smallest: 4, 3, 2.
 */
select addr_street_pass_5,
         substring( addr_street_pass_5::text from 1::int for length(addr_street_pass_5::text) - 4::int) as addr_street_pass_6,
         substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 4::int) as addr_street_type,
         case when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 4::int) = ' BLVD' then 'Boulevard'
               when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 4::int) = ' PKWY' then 'Parkway'
          end as addr_street_suffix_final
  from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int for 4::int) in ( 'BLVD', 'PKWY' )
  order by 3, 2;

select addr_street_pass_5,
         substring( addr_street_pass_5::text from 1::int for length(addr_street_pass_5::text) - 3::int) as addr_street_pass_6,
         substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int) as addr_street_type,
         case when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int) = ' TRL' then 'Trail'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int) = ' HWY' then 'Highway'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int) = ' CIR' then 'Circle'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 3::int) = ' AVE' then 'Avenue'
          end as addr_street_suffix_final
  from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int for 3::int) in ( 'TRL', 'HWY', 'CIR', 'AVE' )
  order by 3, 2;

select addr_street_pass_5,
         substring( addr_street_pass_5::text from 1::int for length(addr_street_pass_5::text) - 2::int) as addr_street_pass_6,
         substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) as addr_street_type,
         case when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' LN' then 'Lane'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' ST' then 'Street'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' DR' then 'Drive'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' LP' then 'Loop'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' CT' then 'Court'
              when substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 2::int) = ' WY' then 'Way'
          end as addr_street_suffix_final
  from teton.tetoncountyaddresses_8_11_16
  where substring( upper(addr_street_pass_5::text) from length(addr_street_pass_5::text) - 1::int for 2::int) in ( 'ST', 'LN', 'LP', 'DR', 'CT', 'WY')
  order by 3, 2;




/*
'TRL', 'HWY', 'CIR', 'AVE', 
'BLVD'
 */



remark original 8/5/2016 data updates.*****************************************
select distinct community, state, zipcode from teton.tetoncountyaddresses_8_5_16;

select distinct addressjur, community, state, zipcode from teton.tetoncountyaddresses_8_5_16;

alter table teton.tetoncountyaddresses_8_5_16 add column addr_country character varying (256);
update teton.tetoncountyaddresses_8_5_16 set addr_country = 'US';

alter table teton.tetoncountyaddresses_8_5_16 add column addr_state character varying (256);
update teton.tetoncountyaddresses_8_5_16 set addr_state  = 'ID';

update teton.tetoncountyaddresses_8_5_16 set addr_state  = 'WY' where zipcode = '83414';
alter table teton.tetoncountyaddresses_8_5_16 add column addr_postcode character varying (256);
update teton.tetoncountyaddresses_8_5_16 set addr_postcode  = zipcode;
alter table teton.tetoncountyaddresses_8_5_16 add column addr_city character varying (256);
update teton.tetoncountyaddresses_8_5_16 set addr_city = community;

select * from teton.teton.tetoncountyaddresses_8_5_16 where addr_city is null;
update teton.tetoncountyaddresses_8_5_16 set addr_city = 'Bates' where addr_postcode = '83422';
select * from teton.teton.tetoncountyaddresses_8_5_16 where addr_city is null;
update teton.tetoncountyaddresses_8_5_16 set addr_city = 'Bates' where addr_postcode = '83422';
update teton.tetoncountyaddresses_8_5_16 set addr_city = 'Victor' where addressid = 138806;


