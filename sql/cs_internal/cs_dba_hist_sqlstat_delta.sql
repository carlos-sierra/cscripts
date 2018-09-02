COL snap_id FOR 999999 HEA 'Snap|ID';
COL begin_time FOR A19 HEA 'Begin Interval Time';
COL end_time FOR A19 HEA 'End Interval Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_io_ms FOR 99,999,990.000 HEA 'Avg User IO|Time (ms)';
COL avg_appl_ms FOR 99,999,990.000 HEA 'Avg Appl|Time (ms)';
COL avg_conc_ms FOR 99,999,990.000 HEA 'Avg Conc|Time (ms)';
COL avg_bg FOR 9,999,999,990 HEA 'Avg|Buffer Gets';
COL avg_disk FOR 999,999,990 HEA 'Avg|Disk Reads';
COL avg_row FOR 999,990.000 HEA 'Avg Rows|Processed';
COL executions_delta FOR 999,999,999,990 HEA 'Executions|Delta';
COL fetches_delta FOR 999,999,999,990 HEA 'Fetches|Delta';
COL delta_et_secs FOR 999,999,990 HEA 'ET Delta|(secs)';
COL delta_cpu_secs FOR 999,999,990 HEA 'CPU Delta|(secs)';
COL delta_io_secs FOR 999,999,990 HEA 'IO Delta|(secs)';
COL delta_appl_secs FOR 999,999,990 HEA 'Appl Delta|(secs)';
COL delta_conc_secs FOR 999,999,990 HEA 'Conc Delta|(secs)';
COL delta_buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets|Delta';
COL delta_disk_reads FOR 999,999,999,990 HEA 'Disk Reads|Delta';
COL delta_rows_processed FOR 999,999,999,990 HEA 'Rows Processed|Delta';
COL optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost';
COL optimizer_env_hash_value FOR 9999999999 HEA 'Optimizer|Hash Value';
COL sharable_mem FOR 99,999,999,990 HEA 'Sharable Mem|(bytes)';
COL version_count FOR 999,990 HEA 'Version|Count';
COL loads_delta FOR 999,990 HEA 'Loads|Delta';
COL invalidations_delta FOR 999,990 HEA 'Inval|Delta';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';
COL module FOR A30 HEA 'Module';
--
BRE ON snap_id ON begin_time ON end_time;
--
PRO
PRO SQL STATS DELTA (dba_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~
SELECT h.snap_id,
       TO_CHAR(s.begin_interval_time, '&&cs_datetime_full_format.') begin_time,
       TO_CHAR(s.end_interval_time, '&&cs_datetime_full_format.') end_time,
       h.plan_hash_value,
       h.elapsed_time_delta/GREATEST(h.executions_delta, 1)/1e3 avg_et_ms,
       h.cpu_time_delta/GREATEST(h.executions_delta, 1)/1e3 avg_cpu_ms,
       h.iowait_delta/GREATEST(h.executions_delta, 1)/1e3 avg_io_ms,
       h.apwait_delta/GREATEST(h.executions_delta, 1)/1e3 avg_appl_ms,
       h.ccwait_delta/GREATEST(h.executions_delta, 1)/1e3 avg_conc_ms,
       h.buffer_gets_delta/GREATEST(h.executions_delta, 1) avg_bg,
       h.disk_reads_delta/GREATEST(h.executions_delta, 1) avg_disk,
       h.rows_processed_delta/GREATEST(h.executions_delta, 1) avg_row,
       h.executions_delta,
       h.fetches_delta,
       h.elapsed_time_delta/1e6 delta_et_secs,
       h.cpu_time_delta/1e6 delta_cpu_secs,
       h.iowait_delta/1e6 delta_io_secs,
       h.apwait_delta/1e6 delta_appl_secs,
       h.ccwait_delta/1e6 delta_conc_secs,
       h.buffer_gets_delta delta_buffer_gets,
       h.disk_reads_delta delta_disk_reads,
       h.rows_processed_delta delta_rows_processed,
       h.optimizer_cost,
       h.optimizer_env_hash_value,
       h.sharable_mem,
       h.version_count,
       h.loads_delta,
       h.invalidations_delta,
       h.parsing_schema_name,
       h.module
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND (h.elapsed_time_delta > 0 OR h.buffer_gets_delta > 0 OR h.executions_delta > 0)
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 ORDER BY
       h.snap_id,
       h.plan_hash_value,
       h.parsing_schema_name
/       
--
CL BRE;
--
