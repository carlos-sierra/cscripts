----------------------------------------------------------------------------------------
--
-- File name:   cs_active_sessions_time_series.sql
--
-- Purpose:     Active Sessions Time Series per Hour, Day and Month
--
-- Author:      Carlos Sierra
--
-- Version:     2020/04/29
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_active_sessions_time_series.sql
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
DEF cs_script_name = 'cs_active_sessions_time_series';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL hour FOR A13;
COL day FOR A10;
COL month FOR A7;
COL max_sessions FOR 99,990 HEA 'MAX|SESSIONS';
COL pctl_p999 FOR 99,990 HEA '99.9th|PCTL';
COL pctl_p99 FOR 99,990 HEA '99th|PCTL';
COL pctl_p97 FOR 99,990 HEA '97th|PCTL';
COL pctl_p95 FOR 99,990 HEA '95th|PCTL';
COL pctl_p90 FOR 99,990 HEA '90th|PCTL';
COL med_sessions FOR 99,990 HEA 'MED|SESSIONS';
COL servers FOR 99,990;
COL on_cpu_pct FOR 990.0 HEA 'ON CPU|PERC %';
COL scheduler_pct FOR 990.0 HEA 'SCHED|PERC %';
COL appl_lock_pct FOR 990.0 HEA 'LOCK|PERC %';
COL conc_pct FOR 990.0 HEA 'CONC|PERC %';
COL user_io_pct FOR 990.0 HEA 'IO|PERC %';
--
PRO
PRO Active Sessions per Hour
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH
by_sample_time AS (
SELECT CAST(sample_time AS DATE) sample_time,
       COUNT(*) samples,
       COUNT(DISTINCT machine) servers,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
       SUM(CASE wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) scheduler,
       SUM(CASE wait_class WHEN 'Application' THEN 1 ELSE 0 END) appl_lock,
       SUM(CASE wait_class WHEN 'Concurrency' THEN 1 ELSE 0 END) conc,
       SUM(CASE wait_class WHEN 'User I/O' THEN 1 ELSE 0 END) user_io
  FROM dba_hist_active_sess_history
 --WHERE sample_time > SYSTIMESTAMP - 1
 GROUP BY
       sample_time
)
SELECT TO_CHAR(TRUNC(sample_time, 'HH24'), 'YYYY-MM-DD"T"HH24') hour,
       MAX(samples) max_sessions,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY samples) pctl_p999,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY samples) pctl_p99,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY samples) pctl_p97,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY samples) pctl_p95,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY samples) pctl_p90,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY samples) med_sessions,
       MAX(servers) servers,
       ROUND(100*SUM(on_cpu)/SUM(samples),1) on_cpu_pct,
       ROUND(100*SUM(scheduler)/SUM(samples),1) scheduler_pct,
       ROUND(100*SUM(appl_lock)/SUM(samples),1) appl_lock_pct,
       ROUND(100*SUM(conc)/SUM(samples),1) conc_pct,
       ROUND(100*SUM(user_io)/SUM(samples),1) user_io_pct
  FROM by_sample_time
 GROUP BY
       TRUNC(sample_time, 'HH24')
 ORDER BY 
       TRUNC(sample_time, 'HH24')
/
--
PRO
PRO Active Sessions per Day
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH
by_sample_time AS (
SELECT CAST(sample_time AS DATE) sample_time,
       COUNT(*) samples,
       COUNT(DISTINCT machine) servers,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
       SUM(CASE wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) scheduler,
       SUM(CASE wait_class WHEN 'Application' THEN 1 ELSE 0 END) appl_lock,
       SUM(CASE wait_class WHEN 'Concurrency' THEN 1 ELSE 0 END) conc,
       SUM(CASE wait_class WHEN 'User I/O' THEN 1 ELSE 0 END) user_io
  FROM dba_hist_active_sess_history
 --WHERE sample_time > SYSTIMESTAMP - 1
 GROUP BY
       sample_time
)
SELECT TO_CHAR(TRUNC(sample_time, 'DD'), 'YYYY-MM-DD') day,
       MAX(samples) max_sessions,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY samples) pctl_p999,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY samples) pctl_p99,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY samples) pctl_p97,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY samples) pctl_p95,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY samples) pctl_p90,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY samples) med_sessions,
       MAX(servers) servers,
       ROUND(100*SUM(on_cpu)/SUM(samples),1) on_cpu_pct,
       ROUND(100*SUM(scheduler)/SUM(samples),1) scheduler_pct,
       ROUND(100*SUM(appl_lock)/SUM(samples),1) appl_lock_pct,
       ROUND(100*SUM(conc)/SUM(samples),1) conc_pct,
       ROUND(100*SUM(user_io)/SUM(samples),1) user_io_pct
  FROM by_sample_time
 GROUP BY
       TRUNC(sample_time, 'DD')
 ORDER BY 
       TRUNC(sample_time, 'DD')
/
--
PRO
PRO Active Sessions per Month
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH
by_sample_time AS (
SELECT CAST(sample_time AS DATE) sample_time,
       COUNT(*) samples,
       COUNT(DISTINCT machine) servers,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) on_cpu,
       SUM(CASE wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) scheduler,
       SUM(CASE wait_class WHEN 'Application' THEN 1 ELSE 0 END) appl_lock,
       SUM(CASE wait_class WHEN 'Concurrency' THEN 1 ELSE 0 END) conc,
       SUM(CASE wait_class WHEN 'User I/O' THEN 1 ELSE 0 END) user_io
  FROM dba_hist_active_sess_history
 --WHERE sample_time > SYSTIMESTAMP - 1
 GROUP BY
       sample_time
)
SELECT TO_CHAR(TRUNC(sample_time, 'MM'), 'YYYY-MM') month,
       MAX(samples) max_sessions,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY samples) pctl_p999,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY samples) pctl_p99,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY samples) pctl_p97,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY samples) pctl_p95,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY samples) pctl_p90,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY samples) med_sessions,
       MAX(servers) servers,
       ROUND(100*SUM(on_cpu)/SUM(samples),1) on_cpu_pct,
       ROUND(100*SUM(scheduler)/SUM(samples),1) scheduler_pct,
       ROUND(100*SUM(appl_lock)/SUM(samples),1) appl_lock_pct,
       ROUND(100*SUM(conc)/SUM(samples),1) conc_pct,
       ROUND(100*SUM(user_io)/SUM(samples),1) user_io_pct
  FROM by_sample_time
 GROUP BY
       TRUNC(sample_time, 'MM')
 ORDER BY 
       TRUNC(sample_time, 'MM')
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
