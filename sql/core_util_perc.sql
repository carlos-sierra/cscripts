-- core_util_perc.sql
-- average core utilization percent past 7 days
-- same as: SELECT c##iod.iod_rsrc_mgr.core_util_perc(7) FROM DUAL;
-- same as: SELECT c##iod.iod_rsrc_mgr.core_util_perc FROM DUAL;
DEF days_of_history = '7';
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
       ROW_NUMBER() OVER (ORDER BY o.snap_id DESC) row_number,
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
avg_cpu_util AS (
SELECT AVG(cpu_utilization) value
  FROM busy_time_ts
 WHERE 1 = 1
   AND startup_gap = 0
   AND row_number <= NVL(GREATEST(&&days_of_history. * (SELECT value FROM snaps_per_day), 1), 1)
)
-- average core_util_perc
SELECT ROUND(u.value * t.value) core_util_perc
  FROM avg_cpu_util u, threads_per_core t
/
