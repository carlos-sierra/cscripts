COL snap_id FOR 999999 HEA 'Snap|ID';
COL begin_time FOR A19 HEA 'Begin Interval Time';
COL end_time FOR A19 HEA 'End Interval Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_io_ms FOR 99,999,990.000 HEA 'Avg User IO|Time (ms)';
COL avg_appl_ms FOR 99,999,990.000 HEA 'Avg Appl|Time (ms)';
COL avg_conc_ms FOR 99,999,990.000 HEA 'Avg Conc|Time (ms)';
COL avg_bg FOR 999,999,990 HEA 'Avg|Buffer Gets';
COL avg_disk FOR 999,999,990 HEA 'Avg|Disk Reads';
COL avg_row FOR 999,990.000 HEA 'Avg Rows|Processed';
COL executions_total FOR 999,999,999,990 HEA 'Executions|Total';
COL fetches_total FOR 999,999,999,990 HEA 'Fetches|Total';
COL total_et_secs FOR 999,999,990 HEA 'ET Total|(secs)';
COL total_cpu_secs FOR 999,999,990 HEA 'CPU Total|(secs)';
COL total_io_secs FOR 999,999,990 HEA 'IO Total|(secs)';
COL total_appl_secs FOR 999,999,990 HEA 'Appl Total|(secs)';
COL total_conc_secs FOR 999,999,990 HEA 'Conc Total|(secs)';
COL total_buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets|Total';
COL total_disk_reads FOR 999,999,999,990 HEA 'Disk Reads|Total';
COL total_rows_processed FOR 999,999,999,990 HEA 'Rows Processed|Total';
COL min_optimizer_cost FOR 9999999999 HEA 'Min|Optimizer|Cost';
COL max_optimizer_cost FOR 9999999999 HEA 'Max|Optimizer|Cost';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';
COL module FOR A30 HEA 'Module';
--
PRO
PRO SQL STATS DELTA SUM (dba_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT h.plan_hash_value,
       SUM(h.elapsed_time_delta)/SUM(h.executions_delta)/1e3 avg_et_ms,
       SUM(h.cpu_time_delta)/SUM(h.executions_delta)/1e3 avg_cpu_ms,
       SUM(h.iowait_delta)/SUM(h.executions_delta)/1e3 avg_io_ms,
       SUM(h.apwait_delta)/SUM(h.executions_delta)/1e3 avg_appl_ms,
       SUM(h.ccwait_delta)/SUM(h.executions_delta)/1e3 avg_conc_ms,
       SUM(h.buffer_gets_delta)/SUM(h.executions_delta) avg_bg,
       SUM(h.disk_reads_delta)/SUM(h.executions_delta) avg_disk,
       SUM(h.rows_processed_delta)/SUM(h.executions_delta) avg_row,
       SUM(h.executions_delta) executions_total,
       SUM(h.fetches_delta) fetches_total,
       SUM(h.elapsed_time_delta)/1e6 total_et_secs,
       SUM(h.cpu_time_delta)/1e6 total_cpu_secs,
       SUM(h.iowait_delta)/1e6 total_io_secs,
       SUM(h.apwait_delta)/1e6 total_appl_secs,
       SUM(h.ccwait_delta)/1e6 total_conc_secs,
       SUM(h.buffer_gets_delta)/SUM(h.executions_delta) total_buffer_gets,
       SUM(h.disk_reads_delta)/SUM(h.executions_delta) total_disk_reads,
       SUM(h.rows_processed_delta)/SUM(h.executions_delta) total_rows_processed,
       MIN(h.optimizer_cost) min_optimizer_cost,
       MAX(h.optimizer_cost) max_optimizer_cost,
       h.parsing_schema_name,
       h.module
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND h.executions_delta > 0
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 GROUP BY
       h.plan_hash_value,
       h.parsing_schema_name,
       h.module
 ORDER BY
       h.plan_hash_value,
       h.parsing_schema_name,
       h.module
/       
CL BRE;
--
