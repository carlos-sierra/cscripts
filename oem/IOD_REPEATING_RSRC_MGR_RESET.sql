----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_RSRC_MGR_RESET
--
-- Purpose:     Set a CDB Resource Manager (RSRC MGR)
--
-- Frequency:   Daily at 6PM UTC
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/04
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_RSRC_MGR_RESET.sql
--
-- Notes:       CPU Utilization Limit and Shares are computed based on historical
--              average active sessions on CPU, using some percentiles.
--
---------------------------------------------------------------------------------------
--
DEF report_only = 'N';
DEF switch_plan = 'Y';
-- to use these parameters below, uncomment also the call to c##iod.iod_rsrc_mgr.reset that references them
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
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'casper'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'omr'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'oem'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'telemetry'||CHR(37)
  THEN
    raise_application_error(-20000, '*** Excluded host: "'||l_host_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on unapproved database
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_db_name VARCHAR2(9);
BEGIN
  SELECT name INTO l_db_name FROM v$database;
  IF UPPER(l_db_name) LIKE 'DBE'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'DBTEST'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'IOD'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'KIEV'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'LCS'||CHR(37)
  THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** Unapproved database: "'||l_db_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on a PDB
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Within PDB "'||SYS_CONTEXT('USERENV', 'CON_NAME')||'" ***');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_rsrc_mgr';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_rsrc_mgr_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, '"d"d"_h"hh24') output_file_name FROM DUAL;
COL trace_file NEW_V trace_file;
--
SPO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
--EXEC c##iod.iod_rsrc_mgr.reset(p_report_only => '&&report_only.', p_plan => '&&plan.', p_include_pdb_directives => '&&include_pdb_directives.', p_switch_plan => '&&switch_plan.');
EXEC c##iod.iod_rsrc_mgr.reset(p_report_only => '&&report_only.', p_switch_plan => '&&switch_plan.');
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
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
--
--HOS tkprof &&trace_file. &&output_file_name._tkprof_nosort.txt
HOS tkprof &&trace_file. &&output_file_name._tkprof_sort.txt sort=exeela,fchela
HOS zip -mj &&zip_file_name..zip &&output_file_name.*.txt
HOS unzip -l &&zip_file_name..zip
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
--
---------------------------------------------------------------------------------------