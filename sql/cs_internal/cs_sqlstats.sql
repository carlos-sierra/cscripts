COL con_id FOR 999 HEA 'Con|ID';
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
COL executions FOR 999,999,999,990 HEA 'Executions';
COL fetches FOR 999,999,999,990 HEA 'Fetches';
COL tot_et_secs FOR 999,999,990 HEA 'Total ET|(secs)';
COL tot_cpu_secs FOR 999,999,990 HEA 'Total CPU|(secs)';
COL tot_io_secs FOR 999,999,990 HEA 'Total IO|(secs)';
COL tot_appl_secs FOR 999,999,990 HEA 'Total Appl|(secs)';
COL tot_conc_secs FOR 999,999,990 HEA 'Total Conc|(secs)';
COL tot_buffer_gets FOR 999,999,999,990 HEA 'Total|Buffer Gets';
COL tot_disk_reads FOR 999,999,999,990 HEA 'Total|Disk Reads';
COL total_read_bytes FOR 999,999,999,999,990 HEA 'Physical Read Bytes|Total';
COL total_write_bytes FOR 999,999,999,999,990 HEA 'Physical Write Bytes|Total';
COL tot_rows_processed FOR 999,999,999,990 HEA 'Total Rows|Processed';
--
PRO
PRO SQL STATS (v$sqlstats since instance startup on &&cs_startup_time., &&cs_startup_days. days ago, or since SQL was first loaded into cursor cache)
PRO ~~~~~~~~~
SELECT con_id,
       elapsed_time/NULLIF(executions, 0)/1e3 avg_et_ms,
       cpu_time/NULLIF(executions, 0)/1e3 avg_cpu_ms,
       user_io_wait_time/NULLIF(executions, 0)/1e3 avg_io_ms,
       application_wait_time/NULLIF(executions, 0)/1e3 avg_appl_ms,
       concurrency_wait_time/NULLIF(executions, 0)/1e3 avg_conc_ms,
       buffer_gets/NULLIF(executions, 0) avg_bg,
       disk_reads/NULLIF(executions, 0) avg_disk,
       physical_read_bytes/NULLIF(executions, 0) avg_read_bytes,
       physical_write_bytes/NULLIF(executions, 0) avg_write_bytes,
       rows_processed/NULLIF(executions, 0) avg_row,
       executions,
       fetches,
       elapsed_time/1e6 tot_et_secs,
       cpu_time/1e6 tot_cpu_secs,
       user_io_wait_time/1e6 tot_io_secs,
       application_wait_time/1e6 tot_appl_secs,
       concurrency_wait_time/1e6 tot_conc_secs,
       buffer_gets tot_buffer_gets,
       disk_reads tot_disk_reads,
       physical_read_bytes total_read_bytes,
       physical_write_bytes total_write_bytes,
       rows_processed tot_rows_processed
  FROM v$sqlstats
 WHERE sql_id = '&&cs_sql_id.'
 ORDER BY
       con_id
/
--
PRO
PRO SQL STATS (v$sqlstats since last AWR snapshot on &&cs_max_snap_end_time., &&cs_last_snap_mins. mins ago)
PRO ~~~~~~~~~
SELECT con_id,
       delta_elapsed_time/NULLIF(delta_execution_count, 0)/1e3 avg_et_ms,
       delta_cpu_time/NULLIF(delta_execution_count, 0)/1e3 avg_cpu_ms,
       delta_user_io_wait_time/NULLIF(delta_execution_count, 0)/1e3 avg_io_ms,
       delta_application_wait_time/NULLIF(delta_execution_count, 0)/1e3 avg_appl_ms,
       delta_concurrency_time/NULLIF(delta_execution_count, 0)/1e3 avg_conc_ms,
       delta_buffer_gets/NULLIF(delta_execution_count, 0) avg_bg,
       delta_disk_reads/NULLIF(delta_execution_count, 0) avg_disk,
       delta_physical_read_bytes/NULLIF(delta_execution_count, 0) avg_read_bytes,
       delta_physical_write_bytes/NULLIF(delta_execution_count, 0) avg_write_bytes,
       delta_rows_processed/NULLIF(delta_execution_count, 0) avg_row,
       delta_execution_count executions,
       delta_fetch_count fetches,
       delta_elapsed_time/1e6 tot_et_secs,
       delta_cpu_time/1e6 tot_cpu_secs,
       delta_user_io_wait_time/1e6 tot_io_secs,
       delta_application_wait_time/1e6 tot_appl_secs,
       delta_concurrency_time/1e6 tot_conc_secs,
       delta_buffer_gets tot_buffer_gets,
       delta_disk_reads tot_disk_reads,
       delta_physical_read_bytes total_read_bytes,
       delta_physical_write_bytes total_write_bytes,
       delta_rows_processed tot_rows_processed
  FROM v$sqlstats
 WHERE sql_id = '&&cs_sql_id.'
 ORDER BY
       con_id
/
--
