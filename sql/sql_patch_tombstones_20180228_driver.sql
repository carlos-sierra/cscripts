----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_tombstones_20180228.sql
--
-- Purpose:     SQL Patch first_rows hint into queries on tombstones table(s).
--
-- Author:      Carlos Sierra
--
-- Version:     2018/02/28
--
-- Usage:       Execute connected into the CDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_patch_tombstones.sql
--
-- Notes:       Executes on each PDB driven by sql_patch_tombstones_20180228_driver.sql
--
--              Compatible with SQL Plan Baselines.
--
--              Only acts on SQL decorated with search string below, executed over
--              100 times, with no prior SPB, Profile or Patch, and with performance
--              worse than 100ms per execution.
--
--              Use fs.sql script passing same search string to validate sql performance
--              before and after.
--             
---------------------------------------------------------------------------------------
--
SET HEA OFF FEED OFF ECHO OFF VER OFF;
SET LIN 300 SERVEROUT ON;
--
DEF search_string = 'tombstones,HashRange';
DEF search_string = '/* performScanQuery(%tombstones,HashRange%) */%SELECT sequenceNumber, KievTxnID, ROW_NUMBER%ORDER BY sequenceNumber DESC%';
DEF cbo_hints = 'FIRST_ROWS(1)';
DEF report_only = 'Y';
--
ALTER SESSION SET container = CDB$ROOT;
SPO dynamic_sql_patch_tombstones_20180228.sql
--
SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       '@sql_patch_tombstones_20180228.sql'
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
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
SPO dynamic_sql_patch_tombstones_20180228.txt
--
SPO sql_patch_tombstones_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO SEARCH_STRING: &&search_string.
PRO CBO_HINTS: &&cbo_hints.
PRO
--
@dynamic_sql_patch_tombstones_20180228.sql
--
SPO OFF;
--
ALTER SESSION SET container = CDB$ROOT;