----------------------------------------------------------------------------------------
--
-- File name:   core_util_forecast.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Forecast when a System would reach Capacity 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/30
--
-- Usage:       Execute connected into the CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @core_util_forecast.sql
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
-- core_util_forecast.sql
-- same as c##iod.iod_rsrc_mgr.core_util_forecast_date and c##iod.iod_rsrc_mgr.core_util_forecast_days
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_date(85,60) forecast_date FROM DUAL;
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_date(100) forecast_date FROM DUAL;
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_date forecast_date FROM DUAL;
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_days(85,60) forecast_days FROM DUAL;
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_days(100) forecast_days FROM DUAL;
-- SELECT c##iod.iod_rsrc_mgr.core_util_forecast_days forecast_days FROM DUAL;

DEF p_history_days_default. = '60';
DEF p_core_util_perc_default. = '100';

PRO
PRO 1. Days of History: [{&&p_history_days_default.}|<1-60>]
DEF p_history_days = '&1.';

COL p_history_days NEW_V p_history_days NOPRI;
SELECT NVL('&&p_history_days.', '&&p_history_days_default.') p_history_days FROM DUAL
/

PRO
PRO 2. CPU Cores Utilization Percent: [{&&p_core_util_perc_default.}|<1-200>]
DEF p_core_util_perc = '&2.';

COL p_core_util_perc NEW_V p_core_util_perc NOPRI;
SELECT NVL('&&p_core_util_perc.', '&&p_core_util_perc_default.') p_core_util_perc FROM DUAL
/

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
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
   AND u.row_number_desc <= NVL(GREATEST(&&p_history_days. * s.value, 1), 1)
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
)
SELECT (u.end_date_time + ((&&p_core_util_perc. - u.y2) / r.m)) forecast_date, /* y = (m * x) + b. then x = (y - b) / m */
       (u.end_date_time + ((&&p_core_util_perc. - u.y2) / r.m)) - SYSDATE forecast_days
  FROM upper_bound u, linear_regr r
/

UNDEF 1 2