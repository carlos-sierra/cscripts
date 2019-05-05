----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_capture.sql
--
-- Purpose:     Capture SQL Monitor Reports for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/28
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlmon_capture.sql
--
-- Notes:       *** Requires Oracle Tuning Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlmon_capture';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
PRO
PRO Drop SQL Patch(es) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = &&cs_signature.)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch(name => i.name); 
  END LOOP;
END;
/
-- gets some hash on hints to allow multiple patches
COL hash NEW_V hash;
SELECT TO_CHAR(ORA_HASH(q'[GATHER_PLAN_STATISTICS MONITOR]',9999)) hash FROM DUAL;
-- create patch
PRO
PRO Create name: "spch_&&cs_sql_id._&&hash.."
EXEC DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => :cs_sql_text, hint_text => q'[GATHER_PLAN_STATISTICS MONITOR]', name => 'spch_&&cs_sql_id._&&hash.', description => q'[cs_sqlmon_capture.sql /*+ GATHER_PLAN_STATISTICS MONITOR */ &&cs_reference_sanitized.]');
--
PRO
PAUSE Capturing SQL Monitor reports for &&cs_sql_id.. Press RETURN to stop capturing them.
PRO
--
PRO
PRO Drop SQL Patch(es) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = &&cs_signature.)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch(name => i.name); 
  END LOOP;
END;
/
--
--
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL pdb_name FOR A30 TRUNC;
COL sql_exec_id NEW_V sql_exec_id FOR A12;
--
WITH 
reports AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       r.sql_exec_start,
       MAX(r.last_refresh_time) last_refresh_time,
       TO_CHAR(r.sql_exec_id) sql_exec_id,
       SUM(r.elapsed_time)/1e6 seconds,
       c.name pdb_name,
       ROW_NUMBER() OVER (ORDER BY r.sql_exec_start) row_number_by_date,
       ROW_NUMBER() OVER (ORDER BY SUM(r.elapsed_time)) row_number_by_seconds
  FROM v$sql_monitor r,
       v$containers c
 WHERE r.sql_id = '&&cs_sql_id.'
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
 GROUP BY
       c.name,
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT r1.sql_exec_start,
       r1.last_refresh_time,
       r1.seconds,
       r1.sql_exec_id,
       r1.pdb_name,
       '|' "+",
       r2.seconds,
       r2.sql_exec_start,
       r2.last_refresh_time,
       r2.sql_exec_id,
       r2.pdb_name
  FROM reports r1, reports r2
 WHERE r1.row_number_by_date = r2.row_number_by_seconds
 ORDER BY
       r1.row_number_by_date
/
--
PRO
PRO Get reports with cs_sqlmon_mem.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--