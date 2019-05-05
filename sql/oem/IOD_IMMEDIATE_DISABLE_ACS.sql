----------------------------------------------------------------------------------------
--
-- File name:   disable_acs_and_adaptive_plans.sql IOD_IMMEDIATE_DISABLE_ACS
--
-- Purpose:     Disables Adaptive Cursor Sharing (ACS) and Adaptive Plans for entire CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/19
--
-- Usage:       Connecting into CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @disable_acs_and_adaptive_plans.sql
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
-- Exclusions and Inclusions
---------------------------------------------------------------------------------------
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR 
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
     UPPER(l_db_name) LIKE 'CASP'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'TENANT'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'LCS'||CHR(37)
  THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** Unapproved database: "'||l_db_name||'" ***');
  END IF;
END;
/
---------------------------------------------------------------------------------------
-- PRIMARY and STANDBY
---------------------------------------------------------------------------------------
SET ECHO ON FEED ON VER ON;
-- connect to root
ALTER SESSION SET container = CDB$ROOT;
-- dba_hist_sqlstat only preserves sql with less than 200 child cursors by default
ALTER SYSTEM SET "_awr_sql_child_limit" = 2000 scope=both;
-- disable adaptive plans. for optimizer_adaptive_statistics, FALSE is the dafault
ALTER SYSTEM SET optimizer_adaptive_plans = FALSE scope=both;
ALTER SYSTEM SET optimizer_adaptive_statistics = FALSE scope=both;
-- disable acs
ALTER SYSTEM SET "_optimizer_adaptive_cursor_sharing" = FALSE scope=both;
ALTER SYSTEM SET "_optimizer_extended_cursor_sharing" = "NONE" scope=both;
ALTER SYSTEM SET "_optimizer_extended_cursor_sharing_rel" = "NONE" scope=both;
--
---------------------------------------------------------------------------------------
-- PRIMARY 
---------------------------------------------------------------------------------------
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
-- exit if any error
WHENEVER SQLERROR EXIT FAILURE;
-- how many weeks we preserve plans on spm
EXEC DBMS_SPM.CONFIGURE('plan_retention_weeks', 13);
-- awr captures only 30 sql per top category. some applications need more than that
--EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(topnsql=>300);
---------------------------------------------------------------------------------------
-- dinamic sql to disable adaptive plans and acs in all pdbs
---------------------------------------------------------------------------------------
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT ON;
SET HEA OFF;
SPO /tmp/disable_acs_and_adaptive_plans_dynamic.sql
-- scope is memory and not both, since on next instance startup all pdbs will inherit values from root
SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       'ALTER SYSTEM SET optimizer_adaptive_plans = FALSE scope=memory;'||CHR(10)||
       'ALTER SYSTEM SET optimizer_adaptive_statistics = FALSE scope=memory;'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_adaptive_cursor_sharing" = FALSE scope=memory;'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing" = "NONE" scope=memory;'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing_rel" = "NONE" scope=memory;'||CHR(10)||
       -- needs to be specified at pdb level
       q'[EXEC DBMS_SPM.CONFIGURE('plan_retention_weeks', 13);]'||CHR(10)
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
 ORDER BY
       con_id
/
-- closes dynamic script
SPO OFF;
-- needed for log filename
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
-- executes dynamic script and creates log
SET HEA ON ECHO ON VER ON FEED ON;
SPO /tmp/disable_acs_and_adaptive_plans_&&current_time..txt
@/tmp/disable_acs_and_adaptive_plans_dynamic.sql
SPO OFF;
-- resets back to root
ALTER SESSION SET container = CDB$ROOT;
-- end
