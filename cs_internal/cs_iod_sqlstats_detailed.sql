-- cs_iod_sqlstats_detailed.sql: called by cs_sqlstat_report_iod.sql
@@&&cs_set_container_to_cdb_root.
@@cs_sqlstat_cols.sql
@@cs_sqlstat_compute.sql
PRO 
PRO SQL STATS - HISTORY DETAILED (iod_sqlstats_t) &&cs_scope_1.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH 
FUNCTION /* cs_iod_sqlstats_detailed */ get_pdb_name (p_con_id IN VARCHAR2)
RETURN VARCHAR2
IS
  l_pdb_name VARCHAR2(4000);
BEGIN
  SELECT name
    INTO l_pdb_name
    FROM v$containers
   WHERE con_id = TO_NUMBER(p_con_id);
  --
  RETURN l_pdb_name;
END get_pdb_name;
/****************************************************************************************/
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
BEGIN
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN p_sqltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(p_sqltext, '\[([[:digit:]]{4})\] ') ELSE p_sqltext END),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sqlstats_deltas AS (
SELECT LAG(s.snap_timestamp) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp) AS begin_timestamp,
       s.snap_timestamp AS end_timestamp,
       (86400 * EXTRACT(DAY FROM (s.snap_timestamp - LAG(s.snap_timestamp) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp)))) + (3600 * EXTRACT(HOUR FROM (s.snap_timestamp - LAG(s.snap_timestamp) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp)))) + (60 * EXTRACT(MINUTE FROM (s.snap_timestamp - LAG(s.snap_timestamp) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp)))) + EXTRACT(SECOND FROM (s.snap_timestamp - LAG(s.snap_timestamp) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp))) AS seconds,
       s.con_id,
       s.sql_id,
      --  s.exact_matching_signature,
      --  s.force_matching_signature,
       s.plan_hash_value,
      --  &&cs_tools_schema..iod_spm.application_category(s.sql_text, 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0') AS sqlid,
       get_sql_hv(sql_fulltext) AS sqlid,
       s.sql_text,
       s.sql_fulltext,
       GREATEST(s.executions - LAG(s.executions) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_execution_count,
       GREATEST(s.elapsed_time - LAG(s.elapsed_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_elapsed_time,
       GREATEST(s.cpu_time - LAG(s.cpu_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_cpu_time,
       GREATEST(s.user_io_wait_time - LAG(s.user_io_wait_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_user_io_wait_time,
       GREATEST(s.application_wait_time - LAG(s.application_wait_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_application_wait_time,
       GREATEST(s.concurrency_wait_time - LAG(s.concurrency_wait_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_concurrency_time,
       GREATEST(s.plsql_exec_time - LAG(s.plsql_exec_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_plsql_exec_time,
       GREATEST(s.cluster_wait_time - LAG(s.cluster_wait_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_cluster_wait_time,
       GREATEST(s.java_exec_time - LAG(s.java_exec_time) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_java_exec_time,
       GREATEST(s.px_servers_executions - LAG(s.px_servers_executions) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_px_servers_executions,
       GREATEST(s.avoided_executions - LAG(s.avoided_executions) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_avoided_executions,
       GREATEST(s.end_of_fetch_count - LAG(s.end_of_fetch_count) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_end_of_fetch_count,
       GREATEST(s.parse_calls - LAG(s.parse_calls) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_parse_calls,
       GREATEST(s.invalidations - LAG(s.invalidations) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_invalidations,
       GREATEST(s.loads - LAG(s.loads) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_loads,
       GREATEST(s.buffer_gets - LAG(s.buffer_gets) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_buffer_gets,
       GREATEST(s.disk_reads - LAG(s.disk_reads) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_disk_reads,
       GREATEST(s.direct_reads - LAG(s.direct_reads) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_direct_reads,
       GREATEST(s.direct_writes - LAG(s.direct_writes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_direct_writes,
       GREATEST(s.physical_read_requests - LAG(s.physical_read_requests) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_physical_read_requests,
       GREATEST(s.physical_read_bytes - LAG(s.physical_read_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_physical_read_bytes,
       GREATEST(s.physical_write_requests - LAG(s.physical_write_requests) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_physical_write_requests,
       GREATEST(s.physical_write_bytes - LAG(s.physical_write_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_physical_write_bytes,
       GREATEST(s.fetches - LAG(s.fetches) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_fetch_count,
       GREATEST(s.sorts - LAG(s.sorts) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_sorts,
       GREATEST(s.rows_processed - LAG(s.rows_processed) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_rows_processed,
       GREATEST(s.io_interconnect_bytes - LAG(s.io_interconnect_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_io_interconnect_bytes,
       GREATEST(s.io_cell_offload_eligible_bytes - LAG(s.io_cell_offload_eligible_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_cell_offload_elig_bytes,
       GREATEST(s.io_cell_uncompressed_bytes - LAG(s.io_cell_uncompressed_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_cell_uncompressed_bytes,
       GREATEST(s.io_cell_offload_returned_bytes - LAG(s.io_cell_offload_returned_bytes) OVER (PARTITION BY s.snap_type, s.sid, s.con_id, s.sql_id ORDER BY s.snap_timestamp), 0) AS delta_cell_offload_retrn_bytes,
       s.version_count,
       s.sharable_mem,
       s.total_sharable_mem,
       s.avg_hard_parse_time,
       s.obsolete_count,
       s.serializable_aborts,
       s.last_active_time
  FROM &&cs_tools_schema..iod_sqlstats_t s
 WHERE s.snap_timestamp >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') - INTERVAL '2' MINUTE
   AND s.snap_timestamp <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND s.snap_type = 'AUTO'
   AND s.sid = -666
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%')
   AND &&cs_filter_1.
   AND &&cs_filter_2.
),
/****************************************************************************************/
sqlstats_metrics AS (
SELECT d.begin_timestamp,
       d.end_timestamp,
       SUM(d.seconds) AS seconds,
       SUM(d.delta_elapsed_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS et_ms_per_exec,
       SUM(d.delta_cpu_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS cpu_ms_per_exec,
       SUM(d.delta_user_io_wait_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS io_ms_per_exec,
       SUM(d.delta_application_wait_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS appl_ms_per_exec,
       SUM(d.delta_concurrency_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS conc_ms_per_exec,
       SUM(d.delta_plsql_exec_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS plsql_ms_per_exec,
       SUM(d.delta_cluster_wait_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS cluster_ms_per_exec,
       SUM(d.delta_java_exec_time)/NULLIF(SUM(d.delta_execution_count),0)/1e3 AS java_ms_per_exec,
       SUM(d.delta_elapsed_time)/NULLIF(SUM(d.seconds),0)/1e6 AS et_aas,
       SUM(d.delta_cpu_time)/NULLIF(SUM(d.seconds),0)/1e6 AS cpu_aas,
       SUM(d.delta_user_io_wait_time)/NULLIF(SUM(d.seconds),0)/1e6 AS io_aas,
       SUM(d.delta_application_wait_time)/NULLIF(SUM(d.seconds),0)/1e6 AS appl_aas,
       SUM(d.delta_concurrency_time)/NULLIF(SUM(d.seconds),0)/1e6 AS conc_aas,
       SUM(d.delta_plsql_exec_time)/NULLIF(SUM(d.seconds),0)/1e6 AS plsql_aas,
       SUM(d.delta_cluster_wait_time)/NULLIF(SUM(d.seconds),0)/1e6 AS cluster_aas,
       SUM(d.delta_java_exec_time)/NULLIF(SUM(d.seconds),0)/1e6 AS java_aas,
       SUM(d.delta_execution_count) AS execs_delta,
       SUM(d.delta_execution_count)/NULLIF(SUM(d.seconds),0) AS execs_per_sec,
       SUM(d.delta_px_servers_executions)/NULLIF(SUM(d.seconds),0) AS px_execs_per_sec,
       SUM(d.delta_end_of_fetch_count)/NULLIF(SUM(d.seconds),0) AS end_of_fetch_per_sec,
       SUM(d.delta_parse_calls)/NULLIF(SUM(d.seconds),0) AS parses_per_sec,
       SUM(d.delta_invalidations)/NULLIF(SUM(d.seconds),0) AS inval_per_sec,
       SUM(d.delta_loads)/NULLIF(SUM(d.seconds),0) AS loads_per_sec,
       SUM(d.delta_buffer_gets)/NULLIF(SUM(d.delta_execution_count),0) AS gets_per_exec,
       SUM(d.delta_disk_reads)/NULLIF(SUM(d.delta_execution_count),0) AS reads_per_exec,
       SUM(d.delta_direct_writes)/NULLIF(SUM(d.delta_execution_count),0) AS direct_writes_per_exec,
       SUM(d.delta_physical_read_requests)/NULLIF(SUM(d.delta_execution_count),0) AS phy_read_req_per_exec,
       SUM(d.delta_physical_read_bytes)/NULLIF(SUM(d.delta_execution_count),0)/1e6 AS phy_read_mb_per_exec,
       SUM(d.delta_physical_write_requests)/NULLIF(SUM(d.delta_execution_count),0) AS phy_write_req_per_exec,
       SUM(d.delta_physical_write_bytes)/NULLIF(SUM(d.delta_execution_count),0)/1e6 AS phy_write_mb_per_exec,
       SUM(d.delta_fetch_count)/NULLIF(SUM(d.delta_execution_count),0) AS fetches_per_exec,
       SUM(d.delta_sorts)/NULLIF(SUM(d.delta_execution_count),0) AS sorts_per_exec,
       SUM(d.delta_rows_processed)/NULLIF(SUM(d.delta_execution_count),0) AS rows_per_exec,
       SUM(d.delta_elapsed_time)/NULLIF(GREATEST(SUM(d.delta_rows_processed),SUM(d.delta_execution_count)),0)/1e3 AS et_ms_per_row,
       SUM(d.delta_cpu_time)/NULLIF(GREATEST(SUM(d.delta_rows_processed),SUM(d.delta_execution_count)),0)/1e3 AS cpu_ms_per_row,
       SUM(d.delta_user_io_wait_time)/NULLIF(GREATEST(SUM(d.delta_rows_processed),SUM(d.delta_execution_count)),0)/1e3 AS io_ms_per_row,
       SUM(d.delta_buffer_gets)/NULLIF(GREATEST(SUM(d.delta_rows_processed),SUM(d.delta_execution_count)),0) AS gets_per_row,
       SUM(d.delta_disk_reads)/NULLIF(GREATEST(SUM(d.delta_rows_processed),SUM(d.delta_execution_count)),0) AS reads_per_row,
       d.con_id,
       SUBSTR(get_pdb_name(d.con_id), 1, 30) AS pdb_name,
       d.sqlid,
       d.sql_id,
      --  d.exact_matching_signature,
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
      --  d.parsing_schema_name,
      --  d.module,
      --  d.action,
       d.plan_hash_value,
      --  d.sql_type,
       d.sql_text,
      --  d.sql_fulltext, -- not a GROUP BY column (CLOB)
       SUM(d.delta_execution_count) AS delta_execution_count,
       SUM(d.delta_elapsed_time)/1e6 AS delta_elapsed_time,
       SUM(d.delta_cpu_time)/1e6 AS delta_cpu_time,
       SUM(d.delta_user_io_wait_time)/1e6 AS delta_user_io_wait_time,
       SUM(d.delta_application_wait_time)/1e6 AS delta_application_wait_time,
       SUM(d.delta_concurrency_time)/1e6 AS delta_concurrency_time,
       SUM(d.delta_plsql_exec_time)/1e6 AS delta_plsql_exec_time,
       SUM(d.delta_cluster_wait_time)/1e6 AS delta_cluster_wait_time,
       SUM(d.delta_java_exec_time)/1e6 AS delta_java_exec_time,
       SUM(d.delta_px_servers_executions) AS delta_px_servers_executions,
       SUM(d.delta_end_of_fetch_count) AS delta_end_of_fetch_count,
       SUM(d.delta_parse_calls) AS delta_parse_calls,
       SUM(d.delta_invalidations) AS delta_invalidations,
       SUM(d.delta_loads) AS delta_loads,
       SUM(d.delta_buffer_gets) AS delta_buffer_gets,
       SUM(d.delta_disk_reads) AS delta_disk_reads,
       SUM(d.delta_direct_writes) AS delta_direct_writes,
       SUM(d.delta_physical_read_requests) AS delta_physical_read_requests,
       SUM(d.delta_physical_read_bytes)/1e6 AS delta_physical_read_mb,
       SUM(d.delta_physical_write_requests) AS delta_physical_write_requests,
       SUM(d.delta_physical_write_bytes)/1e6 AS delta_physical_write_mb,
       SUM(d.delta_fetch_count) AS delta_fetch_count,
       SUM(d.delta_sorts) AS delta_sorts,
       SUM(d.delta_rows_processed) AS delta_rows_processed,
       SUM(d.delta_io_interconnect_bytes)/1e6 AS delta_io_interconnect_mb,
       SUM(d.delta_cell_offload_elig_bytes)/1e6 AS delta_cell_offload_elig_mb,
       SUM(d.delta_cell_uncompressed_bytes)/1e6 AS delta_cell_uncompressed_mb,
       SUM(d.delta_cell_offload_retrn_bytes)/1e6 AS delta_cell_offload_retrn_mb,
       SUM(d.version_count) AS version_count,
       AVG(d.avg_hard_parse_time) AS avg_hard_parse_time,
       MAX(d.sharable_mem)/1e6 AS sharable_mem_mb,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE d.seconds > 1 -- avoid snaps less than 1 sec appart
   AND d.end_timestamp >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND d.end_timestamp <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       d.begin_timestamp,
       d.end_timestamp,
       d.con_id,
       d.sqlid,
       d.sql_id,
      --  d.exact_matching_signature,
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
      --  d.parsing_schema_name,
      --  d.module,
      --  d.action,
       d.plan_hash_value,
      --  d.sql_type,
       d.sql_text
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       '!' AS sep0,
      --  LPAD(s.snap_id, 7, '0') AS snap_id,
       s.begin_timestamp,
       s.end_timestamp,
       s.seconds,
       s.sqlid,
       s.sql_id,
      --  s.instance_number,
       s.plan_hash_value,
       '!' AS sep1,
       s.et_aas,
       s.cpu_aas,
       s.io_aas,
       s.appl_aas,
       s.conc_aas,
       s.plsql_aas,
       s.cluster_aas,
       s.java_aas,
       '!' AS sep2,
       s.delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.avg_hard_parse_time,
       s.inval_per_sec,
       s.loads_per_sec,
       '!' AS sep3,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       '!' AS sep4,
       s.gets_per_exec,
       s.reads_per_exec,
       s.direct_writes_per_exec,
       s.phy_read_req_per_exec,
       s.phy_read_mb_per_exec,
       s.phy_write_req_per_exec,
       s.phy_write_mb_per_exec,
       s.fetches_per_exec,
       s.sorts_per_exec,
       '!' AS sep5,
       s.delta_rows_processed,
       s.rows_per_exec,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
       '!' AS sep6,
       s.delta_elapsed_time,
       s.delta_cpu_time,
       s.delta_user_io_wait_time,
       s.delta_application_wait_time,
       s.delta_concurrency_time,
       s.delta_plsql_exec_time,
       s.delta_cluster_wait_time,
       s.delta_java_exec_time,
       '!' AS sep7,
       s.delta_px_servers_executions,
       s.delta_end_of_fetch_count,
       s.delta_parse_calls,
       s.delta_buffer_gets,
       s.delta_disk_reads,
       s.delta_direct_writes,
       s.delta_physical_read_requests,
       s.delta_physical_read_mb,
       s.delta_physical_write_requests,
       s.delta_physical_write_mb,
       s.delta_fetch_count,
       s.delta_sorts,
       s.delta_io_interconnect_mb,
       s.delta_cell_offload_elig_mb,
       s.delta_cell_uncompressed_mb,
       s.delta_cell_offload_retrn_mb,
       '!' AS sep8,
       s.version_count,
    --    s.obsolete_count,
       s.delta_loads,
       s.delta_invalidations,
       s.sharable_mem_mb,
       '!' AS sep9,
       s.sql_text,
      --  s.module,
       CASE '&&cs_con_id.' WHEN '1' THEN get_pdb_name(s.con_id) /*ELSE s.parsing_schema_name*/ ELSE 'UNKNOWN' END AS pdb_or_parsing_schema_name
      --  s.optimizer_cost
  FROM sqlstats_metrics s
 ORDER BY
      --  s.snap_id,
       s.begin_timestamp,
       s.end_timestamp,
       s.sqlid,
       s.sql_id,
      --  s.instance_number,
       s.plan_hash_value,
       CASE '&&cs_con_id.' WHEN '1' THEN get_pdb_name(s.con_id) /*ELSE s.parsing_schema_name*/ ELSE 'UNKNOWN' END
      --  s.module
/
--
@@cs_sqlstat_clear.sql
@@cs_sqlstat_foot.sql
@@&&cs_set_container_to_curr_pdb.