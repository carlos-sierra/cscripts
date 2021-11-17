----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_transactions_aggregate_chart.sql
--
-- Purpose:     KIEV Transactions Aggregate (Latency|TPS|Count) Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/07
--
-- Usage:       Execute connected to PDB
--
--              Enter range of dates, KIEV owner and granularity when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_transactions_aggregate_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_transactions_aggregate_chart';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVDATASTOREMETADATA') > 0
 ORDER BY u.username
/
PRO
COL kiev_owner NEW_V kiev_owner FOR A30 NOPRI;
PRO 3. Enter Owner
DEF kiev_owner = '&3.';
UNDEF 3;
SELECT UPPER(NVL('&&kiev_owner.', '&&username.')) kiev_owner FROM DUAL
/
--
PRO
PRO 4. Granularity: [{5MI}|SS|MI|15MI|HH|DD]
DEF cs2_granularity = '&4.';
UNDEF 4;
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_granularity.')), '5MI') cs2_granularity FROM DUAL;
SELECT CASE WHEN '&&cs2_granularity.' IN ('SS', 'MI', '5MI', '15MI', 'HH', 'DD') THEN '&&cs2_granularity.' ELSE '5MI' END cs2_granularity FROM DUAL;
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN 'SS' THEN '(1/24/3600)' -- 1 second
         WHEN 'MI' THEN '(1/24/60)' -- 1 minute
         WHEN '5MI' THEN '(5/24/60)' -- 5 minutes
         WHEN '15MI' THEN '(15/24/60)' -- 15 minutes
         WHEN 'HH' THEN '(1/24)' -- 1 hour
         WHEN 'DD' THEN '1' -- 1 day
         ELSE '(5/24/60)' -- default of 5 minutes
       END cs2_plus_days 
  FROM DUAL
/
--
PRO
PRO 5. Metric: [{latency}|tps|count]
DEF cs2_metric = '&5.';
UNDEF 5;
COL cs2_metric NEW_V cs2_metric NOPRI;
SELECT NVL(LOWER(TRIM('&&cs2_metric.')), 'latency') cs2_metric FROM DUAL;
SELECT CASE WHEN '&&cs2_metric.' IN ('latency', 'tps', 'count') THEN '&&cs2_metric.' ELSE 'latency' END cs2_metric FROM DUAL;
--
COL cs2_latency NEW_V cs2_latency NOPRI;
COL cs2_tps NEW_V cs2_tps NOPRI;
COL cs2_count NEW_V cs2_count NOPRI;
COL cs2_latency2 NEW_V cs2_latency2 NOPRI;
COL cs2_tps2 NEW_V cs2_tps2 NOPRI;
COL cs2_count2 NEW_V cs2_count2 NOPRI;
COL cs2_unit NEW_V cs2_unit NOPRI;
SELECT NULL cs2_latency, NULL cs2_latency2, '--' cs2_tps, '//' cs2_tps2, '--' cs2_count, '//' cs2_count2, 'Milliseconds (ms)' cs2_unit FROM DUAL WHERE '&&cs2_metric.' = 'latency';
SELECT '--' cs2_latency, '//' cs2_latency2, NULL cs2_tps,  NULL cs2_tps2, '--' cs2_count, '//' cs2_count2, 'Transactions per Second (TPS)' cs2_unit FROM DUAL WHERE '&&cs2_metric.' = 'tps';
SELECT '--' cs2_latency, '//' cs2_latency2, '--' cs2_tps, '//' cs2_tps2, NULL cs2_count, NULL cs2_count2, 'Transactions Count' cs2_unit FROM DUAL WHERE '&&cs2_metric.' = 'count';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'KIEV Transactions ending between &&cs_sample_time_from. and &&cs_sample_time_to. UTC (aggregated by &&cs2_granularity.)';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'metric:"&&cs2_metric."';
DEF vaxis_title = '&&cs2_unit.';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{5MI}|SS|MI|15MI|HH|DD]";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_owner." "&&cs2_granularity." "&&cs2_metric."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO &&cs2_latency2.,{label:'MAX Latency', id:'7', type:'number'}        
PRO &&cs2_latency2.,{label:'99.9th PCTL Latency', id:'6', type:'number'}      
PRO &&cs2_latency2.,{label:'99th PCTL Latency', id:'5', type:'number'}      
PRO &&cs2_latency2.,{label:'95th PCTL Latency', id:'4', type:'number'}      
PRO &&cs2_latency2.,{label:'90th PCTL Latency', id:'3', type:'number'}      
PRO &&cs2_latency2.,{label:'50th PCTL Latency', id:'2', type:'number'}      
PRO &&cs2_latency2.,{label:'AVG Latency', id:'1', type:'number'}        
PRO &&cs2_tps2.,{label:'Transactions per Second (TPS)', id:'8', type:'number'}       
PRO &&cs2_count2.,{label:'Transactions Count', id:'9', type:'number'}        
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
FUNCTION ceil_timestamp (p_timestamp IN TIMESTAMP)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = 'SS' THEN
    RETURN CAST(p_timestamp AS DATE) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '5MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSE
    RETURN TRUNC(CAST(p_timestamp AS DATE) + &&cs2_plus_days., '&&cs2_granularity.');
  END IF;
END ceil_timestamp;
/****************************************************************************************/
kt AS (
SELECT kt.transactionid,
       kt.applicationname,
       kt.transactionname,
       kt.status,
       kt.begintime,
       kt.endtime,
       1000 * ((86400 * EXTRACT(DAY FROM (kt.endtime - kt.begintime))) + (3600 * EXTRACT(HOUR FROM (kt.endtime - kt.begintime))) + (60 * EXTRACT(MINUTE FROM (kt.endtime - kt.begintime))) + EXTRACT(SECOND FROM (kt.endtime - kt.begintime))) AS latency_ms,
       kt.committransactionid,
       kt.gcpruned
  FROM &&kiev_owner..kievtransactions kt
 WHERE 1 = 1
  --  AND kt.status = 'COMMITTED'
   AND kt.endtime > kt.begintime
   AND kt.endtime > TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') - INTERVAL '1' HOUR
   AND kt.endtime < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.') + INTERVAL '1' HOUR
),
ktg AS (
SELECT LAG(ceil_timestamp(kt.endtime)) OVER (ORDER BY ceil_timestamp(kt.endtime)) AS endtime_from,
       ceil_timestamp(kt.endtime) AS endtime_to,
       COUNT(*) AS transactions,
       ROUND(AVG(latency_ms), 3) AS avg_latency_ms,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY latency_ms) AS pctl_50_latency_ms,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY latency_ms) AS pctl_90_latency_ms,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY latency_ms) AS pctl_95_latency_ms,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY latency_ms) AS pctl_99_latency_ms,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY latency_ms) AS pctl_999_latency_ms,
       MAX(latency_ms) AS max_latency_ms
  FROM kt
 GROUP BY
       ceil_timestamp(kt.endtime)
),
kte AS (
SELECT ktg.endtime_from,
       ktg.endtime_to,
       ktg.transactions,
       (ktg.endtime_to - ktg.endtime_from) * 24 * 3600 AS seconds,
       ROUND(ktg.transactions / ((ktg.endtime_to - ktg.endtime_from) * 24 * 3600), 3) AS tps,
       ktg.avg_latency_ms,
       ktg.pctl_50_latency_ms,
       ktg.pctl_90_latency_ms,
       ktg.pctl_95_latency_ms,
       ktg.pctl_99_latency_ms,
       ktg.pctl_999_latency_ms,
       ktg.max_latency_ms
  FROM ktg
 WHERE ktg.endtime_from >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND ktg.endtime_from <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ktg.endtime_to > ktg.endtime_from
)
SELECT ', [new Date('||
       TO_CHAR(q.endtime_to, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.endtime_to, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.endtime_to, 'DD')|| /* day */
       ','||TO_CHAR(q.endtime_to, 'HH24')|| /* hour */
       ','||TO_CHAR(q.endtime_to, 'MI')|| /* minute */
       ','||TO_CHAR(q.endtime_to, 'SS')|| /* second */
       ')'||
       &&cs2_latency.','||num_format(q.max_latency_ms)||
       &&cs2_latency.','||num_format(q.pctl_999_latency_ms)||
       &&cs2_latency.','||num_format(q.pctl_99_latency_ms)||
       &&cs2_latency.','||num_format(q.pctl_95_latency_ms)||
       &&cs2_latency.','||num_format(q.pctl_90_latency_ms)||
       &&cs2_latency.','||num_format(q.pctl_50_latency_ms)||
       &&cs2_latency.','||num_format(q.avg_latency_ms, 3)||
       &&cs2_tps.','||num_format(q.tps, 3)||
       &&cs2_count.','||num_format(q.transactions)||
       ']'
  FROM kte q
 ORDER BY
       q.endtime_to
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
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
