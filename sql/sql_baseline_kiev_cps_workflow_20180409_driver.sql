----------------------------------------------------------------------------------------
--
-- File name:   sql_baseline_kiev_cps_workflow_20180409_driver.sql
--
-- Purpose:     Disable SQL Plan Baselines on SQL matching some signature and metrics
--
-- Author:      Carlos Sierra
--
-- Version:     2018/04/09
--
-- Usage:       Execute connected into the CDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_baseline_kiev_cps_workflow_20180409_driver.sql
--
-- Notes:       Executes sql_baseline_kiev_cps_workflow_20180409.sql on each PDB 
--              driven by sql_baseline_kiev_cps_workflow_20180409_driver.sql
--
--              Only acts on SQL that matches:
--              1. Search String
--              2. Has an active SQL Plan Baseline
--              3. Takes more than 1s per Execution
--              4. Burns over 100K Buffer Gets per Execution
--
--              Use fs.sql script passing same search string to validate sql performance
--              before and after.
--             
---------------------------------------------------------------------------------------
DEF report_only = 'N';
--
SET HEA OFF FEED OFF ECHO OFF VER OFF;
SET LIN 300 SERVEROUT ON;
--
-- tags /* populateBucketGCWorkspace */ and /* Populate workspace in KTK GC */ where table name is KIEV_CPS_WORKFLOW.KievGCTempTable and Buffer Gets per Second > 1000
DEF search_string = '/* populate%workspace%*/%KIEV_CPS_WORKFLOW.KievGCTempTable';
--
ALTER SESSION SET container = CDB$ROOT;
SPO dynamic_sql_baseline_kiev_cps_workflow_20180409.sql
--
SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       '@sql_baseline_kiev_cps_workflow_20180409.sql'
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
   AND con_id > 2 -- exclue CDB$ROOT
 ORDER BY
       con_id
/
--
SPO OFF;
--
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
--
SPO dynamic_sql_baseline_kiev_cps_workflow_20180409.txt
--
SPO sql_baseline_kiev_cps_workflow_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO SEARCH_STRING: &&search_string.
PRO
--
@dynamic_sql_baseline_kiev_cps_workflow_20180409.sql
--
SPO OFF;
--
ALTER SESSION SET container = CDB$ROOT;