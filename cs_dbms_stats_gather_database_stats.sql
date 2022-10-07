----------------------------------------------------------------------------------------
--
-- File name:   cs_dbms_stats_gather_database_stats.sql
--
-- Purpose:     Execute DBMS_STATS.GATHER_DATABASE_STATS
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/27
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dbms_stats_gather_database_stats.sql
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
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
DEF cs_script_name = 'cs_dbms_stats_gather_database_stats';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
SET HEA OFF PAGES 0;
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
/
PRO SET ECHO OFF TIMI OFF TIM OFF;
SPO OFF;
--
SET HEA ON PAGES 100;
SPO &&cs_file_name..txt APP;
--
@&&cs_file_name._driver.sql
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
