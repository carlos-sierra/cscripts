----------------------------------------------------------------------------------------
--
-- File name:   cs_osstat_cpu_util_perc_chart_iod.sql
--
-- Purpose:     CPU Utilization Percent Chart (IOD) - 1m Granularity 
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/03
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_osstat_cpu_util_perc_chart_iod.sql
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
DEF cs_script_name = 'cs_osstat_cpu_util_perc_chart_iod';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'CPU Utilization Percent between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = '';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) SEV2 (critical state, engage IOD)";
DEF chart_foot_note_3 = "<br>3) SEV3 (migrate out some PDBs)";
DEF chart_foot_note_4 = "<br>4) SEV4 (suspend new PDB allocation)<br>";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'SEV2', id:'1', type:'number'}
PRO ,{label:'SEV3', id:'2', type:'number'}
PRO ,{label:'SEV4', id:'3', type:'number'}
PRO ,{label:'CPU Util Perc', id:'4', type:'number'}
PRO ]
--
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
osstat_filtered AS (
SELECT o.snap_timestamp AS end_interval_time,
      v.stat_name,
      CASE
        WHEN v.stat_name = 'NUM_CPUS' THEN o.value
        WHEN v.stat_name IN ('BUSY_TIME', 'IDLE_TIME') THEN o.value - LAG(o.value) OVER (PARTITION BY v.stat_name ORDER BY o.snap_timestamp) 
      END AS value
  FROM &&cs_tools_schema..iod_osstat_t o,
       v$osstat v
 WHERE v.osstat_id = o.osstat_id
   AND o.snap_timestamp BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') - (2/24) AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND v.stat_name IN ('BUSY_TIME', 'IDLE_TIME', 'NUM_CPUS')
),
osstat_aggregated AS (
SELECT end_interval_time,
      SUM(CASE stat_name WHEN 'BUSY_TIME' THEN value ELSE 0 END) AS busy_time,
      SUM(CASE stat_name WHEN 'IDLE_TIME' THEN value ELSE 0 END) AS idle_time,
      SUM(CASE stat_name WHEN 'NUM_CPUS' THEN value ELSE 0 END) AS num_cpus
  FROM osstat_filtered
WHERE value IS NOT NULL
  AND end_interval_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
GROUP BY
      end_interval_time
),
my_query AS (
SELECT end_interval_time AS time,
      -- 0.7 * num_cpus AS sev2,
      -- 0.6 * num_cpus AS sev3,
      -- 0.5 * num_cpus AS sev4,
      70 AS sev2,
      60 AS sev3,
      50 AS sev4,
      100 * busy_time / (busy_time + idle_time) AS cpu_util_perc
  FROM osstat_aggregated 
WHERE busy_time + idle_time > 0
)
/****************************************************************************************/
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.sev2)|| 
       ','||num_format(q.sev3)|| 
       ','||num_format(q.sev4)|| 
       ','||num_format(q.cpu_util_perc, 1)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Line';
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