REM Dummy line to avoid "usage: r_sql_exec" when executed using iodcli
----------------------------------------------------------------------------------------
--
-- File name:   cs_dbms_stats_gather_database_stats_job.sql
--
-- Purpose:     Execute DBMS_STATS.GATHER_DATABASE_STATS (stand-alone)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/27
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dbms_stats_gather_database_stats_job.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
-- https://docs.oracle.com/cd/B19306_01/server.102/b14211/stats.htm#i41282
-- The GATHER_STATS_JOB job gathers optimizer statistics by calling the DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC procedure. 
-- The GATHER_DATABASE_STATS_JOB_PROC procedure collects statistics on database objects when the object has no previously gathered statistics or the existing statistics are stale because the underlying object has been modified significantly (more than 10% of the rows).
-- The DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC is an internal procedure, but its operates in a very similar fashion to the DBMS_STATS.GATHER_DATABASE_STATS procedure using the GATHER AUTO option. 
-- The primary difference is that the DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC procedure prioritizes the database objects that require statistics, so that those objects which most need updated statistics are processed first. 
-- This ensures that the most-needed statistics are gathered before the maintenance window closes.
--
---------------------------------------------------------------------------------------
--
WHENEVER OSERROR CONTINUE;
WHENEVER SQLERROR EXIT FAILURE;
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_is_primary VARCHAR2(5);
BEGIN
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
  IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, 'Not PRIMARY'); END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET container = CDB$ROOT;
--
DEF cs_file_name = '/tmp/cs_dbms_stats_gather_database_stats_job';
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0 SERVEROUT ON;
COL lin FOR A300;
PRO
SELECT 
'ALTER SESSION SET CONTAINER = '||name||';'||CHR(10)||
'SET ECHO ON TIMI ON TIM ON SERVEROUT ON;'||CHR(10)||
'BEGIN'||CHR(10)||
'FOR i IN (SELECT DBMS_STATS.GET_PREFS(''STALE_PERCENT'') AS stale_percent FROM DUAL)'||CHR(10)||
'LOOP'||CHR(10)||
'IF i.stale_percent <> ''5'' THEN'||CHR(10)||
'DBMS_OUTPUT.PUT_LINE(''STALE_PERCENT was: ''||i.stale_percent);'||CHR(10)||
'DBMS_STATS.SET_GLOBAL_PREFS(''STALE_PERCENT'', ''5'');'||CHR(10)||
'END IF;'||CHR(10)||
'END LOOP;'||CHR(10)||
'DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC;'||CHR(10)||
'END;'||CHR(10)||
'/' AS lin
  FROM v$containers 
 WHERE con_id <> 2
   AND open_mode = 'READ WRITE'
   AND restricted = 'NO'
 ORDER BY
       DBMS_RANDOM.value
/
--
SPO &&cs_file_name._driver.sql
PRO SET ECHO ON TIMI ON TIM ON;
PRO SPO &&cs_file_name..log
/
PRO SPO OFF;
PRO SET ECHO OFF TIMI OFF TIM OFF;
SPO OFF;
--
@@&&cs_file_name._driver.sql
--
ALTER SESSION SET container = CDB$ROOT;
--