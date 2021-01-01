COL snap_id FOR 999999 HEA 'Snap|ID';
COL begin_time FOR A19 HEA 'Begin Interval Time';
COL end_time FOR A19 HEA 'End Interval Time';
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL aas_db FOR 999,990.000 HEA 'Avg Active|Sessions|On Database';
COL aas_cpu FOR 999,990.000 HEA 'Avg Active|Sessions|On CPU';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_io_ms FOR 99,999,990.000 HEA 'Avg User IO|Time (ms)';
COL avg_appl_ms FOR 99,999,990.000 HEA 'Avg Appl|Time (ms)';
COL avg_conc_ms FOR 99,999,990.000 HEA 'Avg Conc|Time (ms)';
COL avg_bg FOR 999,999,999,990 HEA 'Avg|Buffer Gets';
COL avg_disk FOR 999,999,999,990 HEA 'Avg|Disk Reads';
COL avg_read_bytes FOR 999,999,999,990 HEA 'Avg Physical|Read Bytes';
COL avg_write_bytes FOR 999,999,999,990 HEA 'Avg Physical|Write Bytes';
COL avg_row FOR 999,999,990.000 HEA 'Avg Rows|Processed';
COL executions_delta FOR 999,999,999,990 HEA 'Executions|Delta';
COL fetches_delta FOR 999,999,999,990 HEA 'Fetches|Delta';
COL fetch_size FOR 999,990 HEA 'Fetch|Size';
COL delta_et_secs FOR 999,999,990 HEA 'ET Delta|(secs)';
COL delta_cpu_secs FOR 999,999,990 HEA 'CPU Delta|(secs)';
COL delta_io_secs FOR 999,999,990 HEA 'IO Delta|(secs)';
COL delta_appl_secs FOR 999,999,990 HEA 'Appl Delta|(secs)';
COL delta_conc_secs FOR 999,999,990 HEA 'Conc Delta|(secs)';
COL delta_buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets|Delta';
COL delta_disk_reads FOR 999,999,999,990 HEA 'Disk Reads|Delta';
COL delta_physical_read_bytes FOR 999,999,999,999,990 HEA 'Physical Read Bytes|Delta';
COL delta_physical_write_bytes  FOR 999,999,999,999,990 HEA 'Physical Write Bytes|Delta';
COL delta_rows_processed FOR 999,999,999,990 HEA 'Rows Processed|Delta';
COL optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost';
COL optimizer_env_hash_value FOR 9999999999 HEA 'Optimizer|Hash Value';
COL sharable_mem FOR 99,999,999,990 HEA 'Sharable Mem|(bytes)';
COL version_count FOR 999,990 HEA 'Version|Count';
COL loads_delta FOR 999,990 HEA 'Loads|Delta';
COL invalidations_delta FOR 999,990 HEA 'Inval|Delta';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';
COL module FOR A40 HEA 'Module' TRUNC;
--
BRE ON snap_id ON begin_time ON end_time;
--
PRO
PRO SQL STATS DELTA (cdb_hist_sqlstat)
PRO ~~~~~~~~~~~~~~~
SELECT h.snap_id,
       TO_CHAR(s.begin_interval_time, '&&cs_datetime_full_format.') AS begin_time,
       TO_CHAR(s.end_interval_time, '&&cs_datetime_full_format.') AS end_time,
       h.con_id,
       c.name AS pdb_name,
       h.plan_hash_value,
       h.elapsed_time_delta/1e6/(24*3600*(CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE))) AS aas_db,
       h.cpu_time_delta/1e6/(24*3600*(CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE))) AS aas_cpu,
       h.elapsed_time_delta/NULLIF(h.executions_delta, 0)/1e3 AS avg_et_ms,
       h.cpu_time_delta/NULLIF(h.executions_delta, 0)/1e3 AS avg_cpu_ms,
       h.iowait_delta/NULLIF(h.executions_delta, 0)/1e3 AS avg_io_ms,
       h.apwait_delta/NULLIF(h.executions_delta, 0)/1e3 AS avg_appl_ms,
       h.ccwait_delta/NULLIF(h.executions_delta, 0)/1e3 AS avg_conc_ms,
       h.buffer_gets_delta/NULLIF(h.executions_delta, 0) AS avg_bg,
       h.disk_reads_delta/NULLIF(h.executions_delta, 0) AS avg_disk,
       h.physical_read_bytes_delta/NULLIF(h.executions_delta, 0) AS avg_read_bytes,
       h.physical_write_bytes_delta/NULLIF(h.executions_delta, 0) AS avg_write_bytes,
       h.rows_processed_delta/NULLIF(h.executions_delta, 0) AS avg_row,
       h.executions_delta,
       h.fetches_delta,
       h.rows_processed_delta/NULLIF(h.fetches_delta, 0) AS fetch_size,
       h.elapsed_time_delta/1e6 AS delta_et_secs,
       h.cpu_time_delta/1e6 AS delta_cpu_secs,
       h.iowait_delta/1e6 AS delta_io_secs,
       h.apwait_delta/1e6 AS delta_appl_secs,
       h.ccwait_delta/1e6 AS delta_conc_secs,
       h.buffer_gets_delta AS delta_buffer_gets,
       h.disk_reads_delta AS delta_disk_reads,
       h.physical_read_bytes_delta AS delta_physical_read_bytes,
       h.physical_write_bytes_delta AS delta_physical_write_bytes,
       h.rows_processed_delta AS delta_rows_processed,
       h.optimizer_cost,
       h.optimizer_env_hash_value,
       h.sharable_mem,
       h.version_count,
       h.loads_delta,
       h.invalidations_delta,
       h.parsing_schema_name,
       h.module
  FROM cdb_hist_sqlstat h,
       dba_hist_snapshot s,
       v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND s.end_interval_time > SYSDATE - &&cs_sqlstat_days.
   AND (h.elapsed_time_delta > 0 OR h.buffer_gets_delta > 0 OR h.executions_delta > 0)
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND c.con_id = h.con_id
 ORDER BY
       h.snap_id,
       h.plan_hash_value,
       h.con_id,
       h.plan_hash_value,
       h.parsing_schema_name
/       
--
CL BRE;
--
