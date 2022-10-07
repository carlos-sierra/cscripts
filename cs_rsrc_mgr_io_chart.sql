----------------------------------------------------------------------------------------
--
-- File name:   dbrmi.sql | cs_rsrc_mgr_io_chart.sql
--
-- Purpose:     Database Resource Manager (DBRM) IO (MBPS and IOPS) Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2022/01/18
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and level when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_io_chart.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_rsrc_mgr_io_chart';
DEF cs_script_acronym = 'dbrmi.sql | ';
--
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_granularity_list NEW_V cs2_granularity_list NOPRI;
COL cs2_default_granularity NEW_V cs2_default_granularity NOPRI;
SELECT CASE 
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 12  THEN '[{1m}|1m|5m|15m|1h|1d|m|h|d]'  -- < 12h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 60  THEN '[{5m}|1m|5m|15m|1h|1d|m|h|d]'  -- < 60h (2.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 180 THEN '[{15m}|1m|5m|15m|1h|1d|m|h|d]' -- < 180h (7.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 720 THEN '[{1h}|1m|5m|15m|1h|1d|m|h|d]'  -- < 720h (30d) (up to 720 samples)
         ELSE '[{1d}|1m|5m|15m|1h|1d|m|h|d]'
       END AS cs2_granularity_list,
       CASE 
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 12  THEN '1m'  -- < 12h (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 60  THEN '5m'  -- < 60h (2.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 180 THEN '15m' -- < 180h (7.5d) (up to 720 samples)
         WHEN TO_NUMBER('&&cs_from_to_seconds.') / 3600 <= 720 THEN '1h'  -- < 720h (30d) (up to 720 samples)
         ELSE '1d'
       END AS cs2_default_granularity
  FROM DUAL
/
PRO
PRO 3. Granularity: &&cs2_granularity_list.
DEF cs2_granularity = '&3.';
UNDEF 3;
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(LOWER(TRIM('&&cs2_granularity.')), '&&cs2_default_granularity.') cs2_granularity FROM DUAL;
SELECT CASE 
         WHEN '&&cs2_granularity.' = 'm' THEN '1m'
         WHEN '&&cs2_granularity.' = 'h' THEN '1h'
         WHEN '&&cs2_granularity.' = 'd' THEN '1d'
         WHEN '&&cs2_granularity.' IN ('1m', '5m', '15m', '1h', '1d') THEN '&&cs2_granularity.' 
         ELSE '&&cs2_default_granularity.' 
       END cs2_granularity 
  FROM DUAL
/
--
COL cs2_fmt NEW_V cs2_fmt NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN '1m'  THEN 'MI' -- (1/24/60) 1 minute
         WHEN '5m'  THEN 'MI' -- (5/24/60) 5 minutes
         WHEN '15m' THEN 'MI' -- (15/24/60) 15 minutes
         WHEN '1h'  THEN 'HH' -- (1/24) 1 hour
         WHEN '1d'  THEN 'DD' -- 1 day
         ELSE 'XX' -- error
       END cs2_fmt 
  FROM DUAL
/
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN '1m'  THEN '(1/24/60)' -- (1/24/60) 1 minute
         WHEN '5m'  THEN '(5/24/60)' -- (5/24/60) 5 minutes
         WHEN '15m' THEN '(15/24/60)' -- (15/24/60) 15 minutes
         WHEN '1h'  THEN '(1/24)' -- (1/24) 1 hour
         WHEN '1d'  THEN '1' -- 1 day
         ELSE 'XX' -- error
       END cs2_plus_days 
  FROM DUAL
/
--
COL cs2_samples NEW_V cs2_samples NOPRI;
SELECT TO_CHAR(CEIL((TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')) / &&cs2_plus_days.)) AS cs2_samples FROM DUAL
/
--
PRO 
PRO 4. Level: [{PDB}|CDB]
DEF cs2_level = '&4.';
UNDEF 4;
COL cs2_level NEW_V cs2_level NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs2_level.')) IN ('PDB', 'CDB') THEN UPPER(TRIM('&&cs2_level.')) ELSE 'PDB' END cs2_level FROM DUAL;
--
PRO 
PRO 5. Metric: [{MBPS}|IOPS]
DEF cs2_metric = '&5.';
UNDEF 5;
COL cs2_metric NEW_V cs2_metric NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs2_metric.')) IN ('MBPS', 'IOPS') THEN UPPER(TRIM('&&cs2_metric.')) ELSE 'MBPS' END cs2_metric FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = '&&cs2_metric. for "&&cs2_level." between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = '&&cs2_metric.';
DEF xaxis_title = '';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = '<br>2)';
DEF chart_foot_note_3 = '';
DEF chart_foot_note_4 = '';
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_level." "&&cs2_metric."';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&cs2_metric.', id:'01', type:'number'}
PRO ]
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
FUNCTION num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
FUNCTION ceil_timestamp (p_timestamp IN TIMESTAMP)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = '5m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15m' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), '&&cs2_fmt.')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSE -- 1m, 1h, 1d
    RETURN TRUNC(CAST(p_timestamp AS DATE) + &&cs2_plus_days., '&&cs2_fmt.');
  END IF;
END ceil_timestamp;
/****************************************************************************************/
sample AS (
SELECT ceil_timestamp(TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') + ((LEVEL - 1) * &&cs2_plus_days.)) AS time FROM DUAL CONNECT BY LEVEL <= TO_NUMBER('&&cs2_samples.')
),
/****************************************************************************************/
rsrc_mgr_metric_history AS (
SELECT v.begin_time, v.end_time, 
       MAX(v.num_cpus) AS num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.running_sessions_limit ELSE 0 END), 6) AS pdb_running_sessions_limit,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_running_sessions ELSE 0 END), 6) AS pdb_avg_running_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_waiting_sessions ELSE 0 END), 6) AS pdb_avg_waiting_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_requests ELSE 0 END), 6) AS pdb_io_requests,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_megabytes ELSE 0 END), 6) AS pdb_io_megabytes,
       ROUND(SUM(v.running_sessions_limit), 6) AS cdb_running_sessions_limit,
       ROUND(SUM(v.avg_running_sessions), 6) AS cdb_avg_running_sessions,
       ROUND(SUM(v.avg_waiting_sessions), 6) AS cdb_avg_waiting_sessions,
       ROUND(SUM(v.io_requests), 6) AS cdb_io_requests,
       ROUND(SUM(v.io_megabytes), 6) AS cdb_io_megabytes
  FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') < SYSDATE - (1/24) -- get history from dbc table iff time_fromm is older than 1h
   AND v.end_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND v.begin_time <= TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       v.begin_time, v.end_time
UNION
SELECT v.begin_time, v.end_time, 
       MAX(v.num_cpus) AS num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.running_sessions_limit ELSE 0 END), 6) AS pdb_running_sessions_limit,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_running_sessions ELSE 0 END), 6) AS pdb_avg_running_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_waiting_sessions ELSE 0 END), 6) AS pdb_avg_waiting_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_requests ELSE 0 END), 6) AS pdb_io_requests,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_megabytes ELSE 0 END), 6) AS pdb_io_megabytes,
       ROUND(SUM(v.running_sessions_limit), 6) AS cdb_running_sessions_limit,
       ROUND(SUM(v.avg_running_sessions), 6) AS cdb_avg_running_sessions,
       ROUND(SUM(v.avg_waiting_sessions), 6) AS cdb_avg_waiting_sessions,
       ROUND(SUM(v.io_requests), 6) AS cdb_io_requests,
       ROUND(SUM(v.io_megabytes), 6) AS cdb_io_megabytes
  FROM v$rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') > SYSDATE - (1/24) -- get history from memory iff time_to is within last 1h
 GROUP BY
       v.begin_time, v.end_time
),
rsrc_mgr_metric_history_ext AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.begin_time, h.end_time, h.num_cpus,
       h.pdb_running_sessions_limit, h.pdb_avg_running_sessions, h.pdb_avg_waiting_sessions,
       ROUND(GREATEST(h.pdb_running_sessions_limit - h.pdb_avg_running_sessions /* - h.pdb_avg_waiting_sessions */, 0), 6) AS pdb_headroom_sessions,
       ROUND(h.pdb_io_requests / h.seconds, 6) AS pdb_iops, ROUND(h.pdb_io_megabytes / h.seconds, 6) AS pdb_mbps,
       h.cdb_running_sessions_limit, h.cdb_avg_running_sessions, h.cdb_avg_waiting_sessions,
       ROUND(GREATEST(LEAST(h.num_cpus, h.cdb_running_sessions_limit) - h.cdb_avg_running_sessions /* - h.cdb_avg_waiting_sessions */, 0), 6) AS cdb_headroom_sessions,
       ROUND(h.cdb_io_requests / h.seconds, 6) AS cdb_iops, ROUND(h.cdb_io_megabytes / h.seconds, 6) AS cdb_mbps
  FROM rsrc_mgr_metric_history h
 WHERE h.seconds > 0
   AND ROWNUM >= 1
),
rsrc_mgr_metric_history_denorm AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ceil_timestamp(h.begin_time) AS time,
       AVG(h.num_cpus) AS num_cpus,
       AVG(&&cs2_level._running_sessions_limit) AS running_sessions_limit,
       AVG(&&cs2_level._avg_running_sessions) AS avg_running_sessions,
       AVG(&&cs2_level._avg_waiting_sessions) AS avg_waiting_sessions,
       AVG(&&cs2_level._headroom_sessions) AS headroom_sessions,
       AVG(&&cs2_level._iops) AS iops,
       AVG(&&cs2_level._mbps) AS mbps
  FROM rsrc_mgr_metric_history_ext h
 GROUP BY
       ceil_timestamp(h.begin_time)
),
/****************************************************************************************/
my_query AS (
SELECT s.time,
       h.num_cpus,
       h.running_sessions_limit,
       h.avg_running_sessions,
       h.avg_waiting_sessions,
       h.headroom_sessions,
       h.iops,
       h.mbps
  FROM sample s, rsrc_mgr_metric_history_denorm h
 WHERE h.time = s.time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.&&cs2_metric.)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Scatter';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--