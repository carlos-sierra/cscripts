COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
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
SELECT s.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       s.executions,
       s.fetches,
       '|' AS "|",
       s.elapsed_time/NULLIF(s.executions, 0)/1e3 AS avg_et_ms,
       s.cpu_time/NULLIF(s.executions, 0)/1e3 AS avg_cpu_ms,
       s.user_io_wait_time/NULLIF(s.executions, 0)/1e3 AS avg_io_ms,
       s.application_wait_time/NULLIF(s.executions, 0)/1e3 AS avg_appl_ms,
       s.concurrency_wait_time/NULLIF(s.executions, 0)/1e3 AS avg_conc_ms,
       s.buffer_gets/NULLIF(s.executions, 0) AS avg_bg,
       s.disk_reads/NULLIF(s.executions, 0) AS avg_disk,
       s.physical_read_bytes/NULLIF(s.executions, 0) AS avg_read_bytes,
       s.physical_write_bytes/NULLIF(s.executions, 0) AS avg_write_bytes,
       s.rows_processed/NULLIF(s.executions, 0) AS avg_row,
       '|' AS "|",
       s.elapsed_time/1e6 AS tot_et_secs,
       s.cpu_time/1e6 AS tot_cpu_secs,
       s.user_io_wait_time/1e6 AS tot_io_secs,
       s.application_wait_time/1e6 AS tot_appl_secs,
       s.concurrency_wait_time/1e6 AS tot_conc_secs,
       s.buffer_gets AS tot_buffer_gets,
       s.disk_reads AS tot_disk_reads,
       s.physical_read_bytes AS total_read_bytes,
       s.physical_write_bytes AS total_write_bytes,
       s.rows_processed AS tot_rows_processed
  FROM v$sqlstats s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id
/
--
PRO
PRO SQL STATS (v$sqlstats since last AWR snapshot on &&cs_max_snap_end_time., &&cs_last_snap_mins. mins ago)
PRO ~~~~~~~~~
SELECT s.con_id,
       c.name AS pdb_name,
       '|' AS "|",
       s.delta_execution_count AS executions,
       s.delta_fetch_count AS fetches,
       '|' AS "|",
       s.delta_elapsed_time/NULLIF(s.delta_execution_count, 0)/1e3 AS avg_et_ms,
       s.delta_cpu_time/NULLIF(s.delta_execution_count, 0)/1e3 AS avg_cpu_ms,
       s.delta_user_io_wait_time/NULLIF(s.delta_execution_count, 0)/1e3 AS avg_io_ms,
       s.delta_application_wait_time/NULLIF(s.delta_execution_count, 0)/1e3 AS avg_appl_ms,
       s.delta_concurrency_time/NULLIF(s.delta_execution_count, 0)/1e3 AS avg_conc_ms,
       s.delta_buffer_gets/NULLIF(s.delta_execution_count, 0) AS avg_bg,
       s.delta_disk_reads/NULLIF(s.delta_execution_count, 0) AS avg_disk,
       s.delta_physical_read_bytes/NULLIF(s.delta_execution_count, 0) AS avg_read_bytes,
       s.delta_physical_write_bytes/NULLIF(s.delta_execution_count, 0) AS avg_write_bytes,
       s.delta_rows_processed/NULLIF(s.delta_execution_count, 0) AS avg_row,
       '|' AS "|",
       s.delta_elapsed_time/1e6 AS tot_et_secs,
       s.delta_cpu_time/1e6 AS tot_cpu_secs,
       s.delta_user_io_wait_time/1e6 AS tot_io_secs,
       s.delta_application_wait_time/1e6 AS tot_appl_secs,
       s.delta_concurrency_time/1e6 AS tot_conc_secs,
       s.delta_buffer_gets AS tot_buffer_gets,
       s.delta_disk_reads AS tot_disk_reads,
       s.delta_physical_read_bytes AS total_read_bytes,
       s.delta_physical_write_bytes AS total_write_bytes,
       s.delta_rows_processed AS tot_rows_processed
  FROM v$sqlstats s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id
/
--
