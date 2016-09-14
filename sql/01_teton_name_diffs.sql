create table teton.name_diffs as
  select nameid, fk_roadid, housenumbe, len_trim, house_num_trim,
         addr_street_pass, addr_street_pass_1, rdlabelname
    from (
           select roads.nameid, addr.fk_roadid,
                  addr.housenumbe,
                  length(addr.housenumbe::text) as len_trim,
                  substring( addr.labelname::text from 1::int
                        for length(addr.housenumbe::text) ) as house_num_trim,
                  substring( addr.labelname::text
                        from length(housenumbe::text)
                           + 1::int ) as addr_street_pass,
                  replace( replace( replace( trim(both ' ' from
                         substring( addr.labelname::text from length(addr.housenumbe::text)
                      + 1::int )), 'Lp', 'Loop'), 'Wy', 'Way'), 'Cir', 'Circle')   as addr_street_pass_1,
                   replace(replace( replace( roads.labelname, 'Wy', 'Way'), 'Cir', 'Circle'), 'Lp', 'Loop') as rdlabelname
             from teton.tetonaddressrevised_9_12_2016 as addr
             join teton.tetoncountyroads_8_5_16 as roads on nameid = fk_roadid
         ) as hn_data
   where addr_street_pass_1 != rdlabelname
  order by rdlabelname;


alter table teton.name_diffs
  add column addr_street_pass_3 character varying (256);


update teton.name_diffs
   set addr_street_pass_3   = addr_street_pass_1;

update teton.name_diffs
   set addr_street_pass_3 =
       trim(both ' ' from substring(
            addr_street_pass_3::text from 1::int for position(
                'UNIT' in upper(addr_street_pass_3::text))::int - 1::int))
 where upper(addr_street_pass_3::text) like '%UNIT%';

update teton.name_diffs
   set addr_street_pass_3 =
       trim(both ' ' from substring(
            addr_street_pass_3::text from 1::int for position(
                'APT' in upper(addr_street_pass_3::text))::int - 1::int))
 where upper(addr_street_pass_3::text) like '%APT%';


update teton.name_diffs
   set addr_street_pass_3 =
       trim(both ' ' from substring(
            addr_street_pass_3::text from 1::int for position(
                '#' in upper(addr_street_pass_3::text))::int - 1::int))
 where upper(addr_street_pass_3::text) like '%#%';


select * from teton.name_diffs;

select *
  from teton.name_diffs
 where rdlabelname != addr_street_pass_3
 order by rdlabelname;


