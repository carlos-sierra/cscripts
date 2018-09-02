-- IOD_REPEATING_RSRC_MGR_RESET
-- CDB Resource Manager - Setup 
-- set p_report_only to N to update plan
--
DEF report_only = 'N';
DEF switch_plan = 'Y';
DEF plan = 'IOD_CDB_PLAN';
DEF include_pdb_directives = 'Y';
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON SIZE UNLIMITED;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_rsrc_mgr';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_rsrc_mgr_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
EXEC c##iod.iod_rsrc_mgr.reset(p_report_only => '&&report_only.', p_plan => '&&plan.', p_include_pdb_directives => '&&include_pdb_directives.', p_switch_plan => '&&switch_plan.');
--
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF utilization_limit ON REPORT;
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
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY 
       pluggable_database
/
--
CLEAR BREAK COMPUTE;
--
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
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name,
       snap_time
/
--
PRO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
WHENEVER SQLERROR CONTINUE;
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
