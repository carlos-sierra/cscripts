----------------------------------------------------------------------------------------
--
-- File name:   core_util_report.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Report for CPU Cores Utilization 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/30
--
-- Usage:       Execute connected into the CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @core_util_report.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--

DEF days_of_history_default = '60';
DEF forecast_days_default = '15';

PRO
PRO 1. Days of History: [{&&days_of_history_default.}|<1-60>]
DEF days_of_history = '&1.';

COL days_of_history NEW_V days_of_history NOPRI;
SELECT NVL('&&days_of_history.', '&&days_of_history_default.') days_of_history FROM DUAL
/

PRO
PRO 2. Forecast Days: [{&&forecast_days_default.}|<1-60>]
DEF forecast_days = '&2.';

COL forecast_days NEW_V forecast_days NOPRI;
SELECT NVL('&&forecast_days.', '&&forecast_days_default.') forecast_days FROM DUAL
/

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';

COL dbid NEW_V dbid NOPRI;
COL db_name NEW_V db_name NOPRI;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number NOPRI;
COL host_name NEW_V host_name NOPRI;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'core_util_&&locale._&&db_name._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM DUAL
/

SPO &&output_file_name..txt;
PRO
PRO SQL> @core_util_report.sql "&&days_of_history." "&&forecast_days." 
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO HOST     : &&host_name.
PRO

COL end_date_time HEA 'Date and Time';
COL y1 HEA 'CPU Cores|Utilization|Percent';
COL y2 HEA 'Moving|1d Window';
COL y8 HEA 'Linear|Regression';
COL y9 HEA 'Forecast';

WITH 
snaps_per_day AS (
SELECT 24 * 60 / (
       -- awr_snap_interval_minutes
       24 * 60 * EXTRACT(day FROM snap_interval) + 
       60 * EXTRACT(hour FROM snap_interval) + 
       EXTRACT(minute FROM snap_interval) 
       )
       value 
  FROM dba_hist_wr_control
),
threads_per_core AS (
SELECT (t.value / c.value) value
  FROM v$osstat c, v$osstat t
 WHERE c.con_id = 0
   AND c.stat_name = 'NUM_CPU_CORES' 
   AND t.con_id = c.con_id
   AND t.stat_name = 'NUM_CPUS'
),
busy_time_ts AS (
SELECT o.snap_id,
       CAST(s.end_interval_time AS DATE) end_date_time,
       ROW_NUMBER() OVER (ORDER BY o.snap_id DESC) row_number_desc,
       CAST(s.startup_time AS DATE) - (LAG(CAST(s.startup_time AS DATE)) OVER (ORDER BY o.snap_id)) startup_gap,
       ((o.value - LAG(o.value) OVER (ORDER BY o.snap_id)) / 100) /
       ((CAST(s.end_interval_time AS DATE) - CAST(LAG(s.end_interval_time) OVER (ORDER BY o.snap_id) AS DATE)) * 24 * 60 * 60)
       cpu_utilization
  FROM dba_hist_osstat o,
       dba_hist_snapshot s
 WHERE o.dbid = (SELECT dbid FROM v$database)
   AND o.instance_number = SYS_CONTEXT('USERENV', 'INSTANCE')
   AND o.stat_name = 'BUSY_TIME'
   AND s.snap_id = o.snap_id
   AND s.dbid = o.dbid
   AND s.instance_number = o.instance_number
),
cpu_util_ts1 AS (
SELECT u.snap_id,
       u.end_date_time,
       u.row_number_desc,
       ROW_NUMBER() OVER (ORDER BY u.end_date_time ASC) row_number_asc,
       u.cpu_utilization * t.value y1,
       AVG(u.cpu_utilization * t.value) OVER (ORDER BY u.snap_id ROWS BETWEEN ROUND(s.value) PRECEDING AND CURRENT ROW) y2
  FROM busy_time_ts u,
       threads_per_core t,
       snaps_per_day s
 WHERE 1 = 1
   AND u.startup_gap = 0
   AND u.row_number_desc <= NVL(GREATEST(&&days_of_history. * s.value, 1), 1)
),
lower_bound AS (
SELECT end_date_time, y1, y2
  FROM cpu_util_ts1
 WHERE row_number_asc = 1
),
upper_bound AS (
SELECT end_date_time, y1, y2
  FROM cpu_util_ts1
 WHERE row_number_desc = 1
),
cpu_util_ts2 AS (
SELECT u.snap_id,
       u.end_date_time,
       u.row_number_desc,
       u.row_number_asc,
       (u.end_date_time - b.end_date_time) x,
       u.y1, u.y2 
  FROM cpu_util_ts1 u,
       lower_bound b
),
linear_regr_ts AS (
SELECT snap_id,
       end_date_time, 
       row_number_desc,
       row_number_asc,
       x,
       y1, y2,
       REGR_SLOPE(y1, x) OVER () m,
       REGR_INTERCEPT(y1, x) OVER () b
  FROM cpu_util_ts2
),
linear_regr AS (
SELECT m, -- slope
       b -- intercept
  FROM linear_regr_ts
 WHERE row_number_desc = 1 -- it does not matter which row we get (first, last, or anything in between)
),
cpu_util_ts3 AS (
SELECT u.end_date_time,
       u.x,
       u.y1, u.y2,
       (r.m * u.x) + r.b y8 /* y8 = (m * x) + b */
  FROM cpu_util_ts2 u,
       linear_regr r
),
cpu_util_ts4 AS (
SELECT q.end_date_time,
       q.x,
       q.y1, 
       q.y2,
       q.y8,
       CASE WHEN q.end_date_time = u.end_date_time THEN u.y2 ELSE TO_NUMBER(NULL) END y9
  FROM cpu_util_ts3 q, upper_bound u
 UNION ALL
SELECT (u.end_date_time + LEVEL) end_date_time,
       LEVEL x,
       TO_NUMBER(NULL) y1,
       TO_NUMBER(NULL) y2,
       TO_NUMBER(NULL) y8,
       (r.m * LEVEL + u.y2) y9
  FROM upper_bound u, linear_regr r
CONNECT BY LEVEL <= &&forecast_days.
)
SELECT q.end_date_time,
       --q.x,
       q.y1, 
       q.y2,
       q.y8,
       q.y9
  FROM cpu_util_ts4 q
 ORDER BY
       q.end_date_time
/

SPO OFF;
PRO
PRO &&output_file_name..txt
PRO
CL COL;
UNDEF 1 2;