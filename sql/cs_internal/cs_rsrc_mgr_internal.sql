--
COL resource_manager_plan NEW_V resource_manager_plan FOR A30;
SELECT REPLACE(value, 'FORCE:') resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';
--
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;
COL end_date FOR A19;
--
CLEAR BREAK COMPUTE;
BREAK ON mandatory SKIP PAGE DUP;
COMPUTE SUM OF utilization_limit ON mandatory;
COL mandatory NOPRI;
--
PRO
PRO PDBs Directives
PRO ~~~~~~~~~~~~~~~
SELECT pluggable_database, 
       utilization_limit,
       shares, 
       parallel_server_limit,
       comments,
       mandatory,
       directive_type
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = '&&resource_manager_plan.'
 ORDER BY
       mandatory DESC,
       pluggable_database
/
--
CLEAR BREAK COMPUTE;
COL mandatory PRI;
--
PRO
PRO PDBs Configuration
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       TO_CHAR(end_date, '&&cs_datetime_full_format.') end_date
  FROM c##iod.rsrc_mgr_pdb_config
 WHERE plan = '&&resource_manager_plan.'
 ORDER BY
       pdb_name
/
--
CLEAR BREAK COMPUTE;
BREAK ON pluggable_database SKIP 1;
--
PRO
PRO PDBs Directives History
PRO ~~~~~~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       snap_time,
       utilization_limit,
       shares,
       parallel_server_limit,
       aas_p99,
       aas_p95
  FROM c##iod.rsrc_mgr_pdb_hist
 WHERE plan = '&&resource_manager_plan.'
 ORDER BY
       pdb_name,
       snap_time
/
--
