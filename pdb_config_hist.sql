set lin 400 pages 200
col pdb_name format a30
col CONFIG_GROUP format a20
col config_name format a40
col STATUS format a50
col pdb_class format a15
col START_TIME format a30
col END_TIME format a30 
break on CONFIG_SET_ID skip page
select
  h.config_set_id,
  h.pdb_name,
  s.config_group,
  s.config_version,
  s.config_name,
  s.pdb_class,
  s.run_order,
  start_time,
  end_time,
  ( CAST( end_time AS DATE ) - CAST( start_time AS DATE ) ) * 86400 as elap_time,
  decode(h.status,'OK','OK',decode(h.status,'OK','OK',substr(status,1,500)  )) status
  --h.status
from
  c##iod.pdb_config_hist h
  ,c##iod.pdb_config_scripts s
--  v$containers p
where h.config_id = s.config_id
--and upper(h.pdb_name) = p.name
--and h.config_set_id = (select max(config_set_id) from c##iod.pdb_config_hist where upper(pdb_name) = p.name)
and h.config_set_id in (select config_set_id from c##iod.pdb_config_hist where start_time > sysdate - 21)
--and h.pdb_name='ocewfaas_wf'
order by start_time
;