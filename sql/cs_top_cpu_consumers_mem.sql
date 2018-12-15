----------------------------------------------------------------------------------------
--
-- File name:   cs_top_cpu_consumers_mem.sql
--
-- Purpose:     Top CPU Consumers for past N hours (as per ASH on MEM)
--
-- Author:      Carlos Sierra
--
-- Version:     2018/10/31
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter number of hours of history to consider (last N hours).
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_cpu_consumers_mem.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
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
DEF cs_script_name = 'cs_top_cpu_consumers_mem';
--
PRO 1. HOURS: [{3}|1-6]
DEF cs_hours = '&1.';
COL cs_hours NEW_V cs_hours;
SELECT NVL('&&cs_hours.', '3') cs_hours FROM DUAL;
--
SELECT '&&cs_file_prefix._last_&&cs_hours._hours_&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_hours."
@@cs_internal/cs_spool_id.sql
--
PRO HOURS        : "&&cs_hours." [{3}|1-6]
--
SET LONGC 240;
--
COL percent FOR 990.000;
COL sql_text_2400 FOR A240 HEA 'SQL_TEXT';
--
BREAK ON REPORT SKIP 1 ON sql_id SKIP PAGE;
COMPUTE SUM OF percent ON REPORT; 
--
PRO
PRO TOP CPU CONSUMERS (over 1% of load)
PRO ~~~~~~~~~~~~~~~~~
WITH
a AS (
SELECT /*+ NO_MERGE */
       sql_id, COUNT(*) samples
  FROM v$active_session_history
 WHERE session_state = 'ON CPU'
   AND sql_id IS NOT NULL
   AND sample_time > CAST(SYSDATE - &&cs_hours./24 AS TIMESTAMP)
 GROUP BY
       sql_id
),
s AS (
SELECT /*+ NO_MERGE */
       DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 2400) sql_text_2400
  FROM dba_hist_sqltext
),
top AS (
SELECT 100 * SUM(a.samples) / SUM(SUM(a.samples)) OVER () percent,
       a.sql_id,
       s.sql_text_2400
  FROM a, s
 WHERE s.sql_id(+) = a.sql_id
 GROUP BY
       a.sql_id,
       s.sql_text_2400
)
SELECT percent,
       sql_id,
       sql_text_2400
  FROM top
 WHERE percent > 1
 ORDER BY
       1 DESC, 2
/
--
CLEAR BREAK COMPUTE;
--
SET LONGC 2400;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_hours."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--