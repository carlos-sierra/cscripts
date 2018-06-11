-- dba_cdb_rsrc_plan_directives.sql
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';

COL current_resource_manager_plan FOR A128;
SELECT value current_resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';

COL plan FOR A30;
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;

PRO
PRO Plans
PRO ~~~~~
SELECT plan,
       comments,
       mandatory,
       status
  FROM dba_cdb_rsrc_plans
 ORDER BY
       plan
/

PRO 1. Enter plan:
DEF plan = '&1.';

COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;

CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF utilization_limit ON REPORT;

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
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY 
       pluggable_database
/

CLEAR BREAK COMPUTE;

PRO
PRO PDBs Configuration
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       end_date
  FROM c##iod.rsrc_mgr_pdb_config
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name
/

CLEAR BREAK COMPUTE;
BREAK ON pluggable_database SKIP 1;

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
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name,
       snap_time
/

UNDEF 1

 