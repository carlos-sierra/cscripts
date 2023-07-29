----------------------------------------------------------------------------------------
--
-- File name:   cs_dbms_stats_age.sql
--
-- Purpose:     DBMS_STATS Age as per "auto optimizer stats collection"
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/23
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dbms_stats_age.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_dbms_stats_age';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
PRO
PRO Latest Window Start Time (dba_autotask_job_history)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
COL con_id FOR 999999;
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20;
COL window_start_time FOR A35;
COL window_duration FOR A30;
COL job_start_time FOR A35;
COL job_duration FOR A20;
COL job_info FOR A80;
--
WITH
hist AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
con_id, window_name, window_start_time, window_duration, job_start_time, job_duration, 
EXTRACT(DAY FROM (job_start_time - window_start_time) * 24 * 60) AS delay_mins,
ROW_NUMBER() OVER (PARTITION BY con_id ORDER BY window_start_time DESC) AS rn,
job_error, job_status, job_info
FROM cdb_autotask_job_history
WHERE client_name = 'auto optimizer stats collection'
)
SELECT '|' AS "|",
       h.con_id, c.name AS pdb_name,
       h.window_name, h.window_start_time, h.window_duration, h.job_start_time, h.job_duration, h.delay_mins,
       h.job_error, h.job_status, h.job_info
  FROM hist h, v$containers c
 WHERE h.rn = 1
   AND c.con_id = h.con_id
ORDER BY h.con_id, h.window_start_time
/
--
COL con_id FOR 9999990;
COL pdb_name FOR A30 TRUNC;
COL last_good_date FOR A19;
COL days FOR 9,990.00;
--
PRO
PRO DBMS_STATS AGE (dba_autotask_task)
PRO ~~~~~~~~~~~~~~
WITH
last_exec AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       t.con_id,
       CAST(t.last_good_date AS DATE) AS last_good_date
  FROM cdb_autotask_task t 
 WHERE t.client_name = 'auto optimizer stats collection'
)
SELECT '|' AS "|",
       e.con_id, c.name AS pdb_name, 
       TO_CHAR(e.last_good_date, 'YYYY-MM-DD"T"HH24:MI:SS') AS last_good_date,
       ROUND(SYSDATE - e.last_good_date, 2) AS days
  FROM last_exec e, v$containers c 
 WHERE c.con_id = e.con_id
 ORDER BY
       e.con_id
/
--
COL con_id FOR 999990;
COL pdb_name FOR A30 TRUNC;
COL tables FOR 99,990;
COL days1 FOR 9,990.00;
COL days2 FOR 9,990.00;
COL max_last_analyzed FOR A19;
COL p90th_percentile FOR A19;
--
PRO
PRO DBMS_STATS AGE (dba_tables)
PRO ~~~~~~~~~~~~~~
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       '|' AS "|",
       t.con_id,
       c.name AS pdb_name,
       MAX(t.last_analyzed) AS max_last_analyzed,
       ROUND(SYSDATE - MAX(t.last_analyzed), 2) AS days1,
       PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC) AS p90th_percentile,
       ROUND(SYSDATE - PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC), 2) AS days2,
       COUNT(*) AS tables
  FROM cdb_tables t, cdb_users u, v$containers c
 WHERE t.con_id <> 2
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
   AND c.con_id = t.con_id
 GROUP BY
       t.con_id, c.name
 ORDER BY
       t.con_id, c.name
/
--
COL con_id FOR 9999990;
COL pdb_name FOR A30 TRUNC;
COL last_good_date FOR A19;
COL days FOR 9,990.00;
COL tables FOR 99,990;
COL days1 FOR 9,990.00;
COL days2 FOR 9,990.00;
COL max_last_analyzed FOR A19;
COL p90th_percentile FOR A19;
PRO
PRO DBMS_STATS AGE (dba_autotask_task and dba_tables)
PRO ~~~~~~~~~~~~~~
WITH
autotask_task AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       t.con_id,
       TO_CHAR(t.last_good_date, 'YYYY-MM-DD"T"HH24:MI:SS') AS last_good_date,
       ROUND(SYSDATE - CAST(t.last_good_date AS DATE), 2) AS days
  FROM cdb_autotask_task t 
 WHERE t.client_name = 'auto optimizer stats collection'
),
tables AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       t.con_id,
       MAX(t.last_analyzed) AS max_last_analyzed,
       ROUND(SYSDATE - MAX(t.last_analyzed), 2) AS days1,
       PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC) AS p90th_percentile,
       ROUND(SYSDATE - PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC), 2) AS days2,
       COUNT(*) AS tables
  FROM cdb_tables t, cdb_users u
 WHERE t.con_id <> 2
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
 GROUP BY
       t.con_id
)
SELECT '|' AS "|",
       a.con_id,
       c.name AS pdb_name,
       a.last_good_date,
       a.days,
       '|' AS "|",
       t.max_last_analyzed,
       t.days1,
       t.p90th_percentile,
       t.days2,
       t.tables
  FROM autotask_task a, tables t, v$containers c
 WHERE t.con_id = a.con_id
   AND c.con_id = a.con_id
 ORDER BY
       a.con_id
/
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
