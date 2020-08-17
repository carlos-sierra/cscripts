----------------------------------------------------------------------------------------
--
-- File name:   cs_top_cpu_consumers_awr.sql
--
-- Purpose:     Top CPU Consumers for past N days (as per ASH on AWR)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter number of days of history to consider (last N days).
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_cpu_consumers_awr.sql
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
DEF cs_script_name = 'cs_top_cpu_consumers_awr';
--
PRO 1. DAYS: [{60}|1-60]
DEF cs_days = '&1.';
UNDEF 1;
COL cs_days NEW_V cs_days;
SELECT NVL('&&cs_days.', '60') cs_days FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._last_&&cs_days._days' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_days."
@@cs_internal/cs_spool_id.sql
--
PRO DAYS         : "&&cs_days." [{60}|1-60]
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
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, COUNT(*) samples
  FROM dba_hist_active_sess_history
 WHERE session_state = 'ON CPU'
   AND sql_id IS NOT NULL
   AND sample_time > CAST(SYSDATE - &&cs_days. AS TIMESTAMP)
 GROUP BY
       sql_id
),
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
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
PRO SQL> @&&cs_script_name..sql "&&cs_days."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--