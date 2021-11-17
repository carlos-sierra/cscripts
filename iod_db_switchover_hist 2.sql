-- iod_db_switchover_hist - History of CDB switchovers
col region for a20
col switchover_cm for a15
col db_name for a10
col db_domain for a18
col new_prim_db for a11
col new_primary_db_host for a45 trunc
col pdb# for a4 JUSTIFY RIGHT
col switchover_start_time for a22
col switchover_end_time for a22
set lin 300 head on feed on time off tab off timing off trimspool on
select 
   SUBSTR(host_name,INSTR(host_name,'.',-1)+1) region,
   switchover_cm,
   db_name,
   db_domain,
   to_char(switchover_start_time, 'yyyy/mm/dd hh24:mi:ss') switchover_start_time,
   to_char(switchover_end_time, 'yyyy/mm/dd hh24:mi:ss') switchover_end_time,
   to_char(pdb_count) pdb#,
   to_char(switchover_down_second) db_down_sec
from C##IOD.DB_SWITCHOVER_HIST, v$instance i
order by switchover_start_time desc;