-- cs_fs_internal_query_3.sql: called by cs_fs.sql
PRO 
PRO DB Latency (and DB Load) dba_hist_sqlstat (last &&cs_awr_search_days. days)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH 
FUNCTION /* cs_fs_internal_query_3 */ get_pdb_name (p_con_id IN VARCHAR2)
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
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sqlstats_deltas AS (
SELECT /*+ MATERIALIZE(@sqltext_mv) MATERIALIZE(@snapshot_mv) MATERIALIZE(@sqlstats_mv) NO_MERGE(@sqltext_mv) NO_MERGE(@snapshot_mv) NO_MERGE(@sqlstats_mv) ORDERED */
       t.begin_interval_time AS begin_timestamp,
       t.end_interval_time AS end_timestamp,
       (86400 * EXTRACT(DAY FROM (t.end_interval_time - t.begin_interval_time))) + (3600 * EXTRACT(HOUR FROM (t.end_interval_time - t.begin_interval_time))) + (60 * EXTRACT(MINUTE FROM (t.end_interval_time - t.begin_interval_time))) + EXTRACT(SECOND FROM (t.end_interval_time - t.begin_interval_time)) AS seconds,
       s.instance_number,
       s.parsing_schema_name,
       s.module,
       s.action,
       s.sql_profile,
       s.optimizer_cost,
       s.con_id,
       s.sql_id,
      --  s.force_matching_signature,
       s.plan_hash_value,
       get_sql_hv(x.sql_text) AS sql_hv,
       REPLACE(REPLACE(DBMS_LOB.substr(x.sql_text, 1000), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text,
       x.sql_text AS sql_fulltext,
       DBMS_LOB.GETLENGTH(x.sql_text) AS sql_len,
       GREATEST(s.executions_delta, 0) AS delta_execution_count,
       GREATEST(s.elapsed_time_delta, 0) AS delta_elapsed_time,
       GREATEST(s.cpu_time_delta, 0) AS delta_cpu_time,
       GREATEST(s.iowait_delta, 0) AS delta_user_io_wait_time,
       GREATEST(s.apwait_delta, 0) AS delta_application_wait_time,
       GREATEST(s.ccwait_delta, 0) AS delta_concurrency_time,
       GREATEST(s.plsexec_time_delta, 0) AS delta_plsql_exec_time,
       GREATEST(s.clwait_delta, 0) AS delta_cluster_wait_time,
       GREATEST(s.javexec_time_delta, 0) AS delta_java_exec_time,
       GREATEST(s.px_servers_execs_delta, 0) AS delta_px_servers_executions,
       GREATEST(s.end_of_fetch_count_delta, 0) AS delta_end_of_fetch_count,
       GREATEST(s.parse_calls_delta, 0) AS delta_parse_calls,
       GREATEST(s.invalidations_delta, 0) AS delta_invalidations,
       GREATEST(s.loads_delta, 0) AS delta_loads,
       GREATEST(s.buffer_gets_delta, 0) AS delta_buffer_gets,
       GREATEST(s.disk_reads_delta, 0) AS delta_disk_reads,
       GREATEST(s.direct_writes_delta, 0) AS delta_direct_writes,
       GREATEST(s.physical_read_requests_delta, 0) AS delta_physical_read_requests,
       GREATEST(s.physical_read_bytes_delta, 0) AS delta_physical_read_bytes,
       GREATEST(s.physical_write_requests_delta, 0) AS delta_physical_write_requests,
       GREATEST(s.physical_write_bytes_delta, 0) AS delta_physical_write_bytes,
       GREATEST(s.fetches_delta, 0) AS delta_fetch_count,
       GREATEST(s.sorts_delta, 0) AS delta_sorts,
       GREATEST(s.rows_processed_delta, 0) AS delta_rows_processed,
       GREATEST(s.io_interconnect_bytes_delta, 0) AS delta_io_interconnect_bytes,
       GREATEST(s.io_offload_elig_bytes_delta, 0) AS delta_cell_offload_elig_bytes,
       GREATEST(s.cell_uncompressed_bytes_delta, 0) AS delta_cell_uncompressed_bytes,
       GREATEST(s.io_offload_return_bytes_delta, 0) AS delta_cell_offload_retrn_bytes,
       s.version_count,
       s.sharable_mem,
       s.obsolete_count
  FROM dba_hist_snapshot t,
       dba_hist_sqlstat s,
       dba_hist_sqltext x
 WHERE 1 = 1
   AND TO_NUMBER('&&cs_awr_search_days.') > 0
   AND t.dbid = TO_NUMBER('&&cs_dbid.') 
   AND t.instance_number = TO_NUMBER('&&cs_instance_number.') 
   AND t.snap_id > TO_NUMBER('&&cs_min_snap_id.')
   AND s.snap_id = t.snap_id
   AND s.snap_id > TO_NUMBER('&&cs_min_snap_id.')
   AND s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
   AND x.dbid = TO_NUMBER('&&cs_dbid.')
   AND x.sql_id = s.sql_id
   AND x.con_id = s.con_id
   AND x.dbid = TO_NUMBER('&&cs_dbid.') 
   AND ('&&cs_include_sys.' = 'Y' OR (
       x.sql_text NOT LIKE '/* SQL Analyze(%'
   AND x.sql_text NOT LIKE '%/* cli_%'
   AND x.sql_text NOT LIKE '%/* cs_%'
   AND x.sql_text NOT LIKE '%FUNCTION application_category%'
   AND x.sql_text NOT LIKE '%MATERIALIZE NO_MERGE%'
   AND x.sql_text NOT LIKE '%NO_STATEMENT_QUEUING%'
   AND x.sql_text NOT LIKE 'SELECT /* &&cs_script_name. */%'
   ))
   AND CASE 
         WHEN LENGTH('&&cs_search_string.') = 5 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NULL /* number */ AND TO_CHAR(get_sql_hv(x.sql_text)) = '&&cs_search_string.' THEN 1
         WHEN LENGTH('&&cs_search_string.') = 13 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NOT NULL /* alpha */ AND LOWER('&&cs_search_string.') = '&&cs_search_string.' AND x.sql_id = '&&cs_search_string.' THEN 1
         WHEN LENGTH('&&cs_search_string.') BETWEEN 6 AND 10 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NULL /* number */ AND TO_CHAR(s.plan_hash_value) = '&&cs_search_string.' THEN 1
         WHEN UPPER(x.sql_text) LIKE UPPER('%&&cs_search_string.%') THEN 1
        END = 1
),
/****************************************************************************************/
sqlstats_metrics AS (
SELECT MIN(d.begin_timestamp) AS begin_timestamp,
       MAX(d.end_timestamp) AS end_timestamp,
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
       SUM(d.delta_execution_count) AS delta_execution_count2,
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
       d.sql_hv,
       d.sql_len,
       d.sql_id,
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
       d.parsing_schema_name,
      --  d.module,
      --  d.action,
       d.plan_hash_value,
       d.sql_text,
      --  d.sql_fulltext, -- not a GROUP BY column (CLOB)
       SUM(d.delta_execution_count) AS delta_execution_count,
       SUM(d.delta_elapsed_time) AS delta_elapsed_time,
       SUM(d.delta_cpu_time) AS delta_cpu_time,
       SUM(d.delta_user_io_wait_time) AS delta_user_io_wait_time,
       SUM(d.delta_application_wait_time) AS delta_application_wait_time,
       SUM(d.delta_concurrency_time) AS delta_concurrency_time,
       SUM(d.delta_plsql_exec_time) AS delta_plsql_exec_time,
       SUM(d.delta_cluster_wait_time) AS delta_cluster_wait_time,
       SUM(d.delta_java_exec_time) AS delta_java_exec_time,
       SUM(d.delta_px_servers_executions) AS delta_px_servers_executions,
       SUM(d.delta_end_of_fetch_count) AS delta_end_of_fetch_count,
       SUM(d.delta_parse_calls) AS delta_parse_calls,
       SUM(d.delta_invalidations) AS delta_invalidations,
       SUM(d.delta_loads) AS delta_loads,
       SUM(d.delta_buffer_gets) AS delta_buffer_gets,
       SUM(d.delta_disk_reads) AS delta_disk_reads,
       SUM(d.delta_direct_writes) AS delta_direct_writes,
       SUM(d.delta_physical_read_requests) AS delta_physical_read_requests,
       SUM(d.delta_physical_read_bytes) AS delta_physical_read_bytes,
       SUM(d.delta_physical_write_requests) AS delta_physical_write_requests,
       SUM(d.delta_physical_write_bytes) AS delta_physical_write_bytes,
       SUM(d.delta_fetch_count) AS delta_fetch_count,
       SUM(d.delta_sorts) AS delta_sorts,
       SUM(d.delta_rows_processed) AS delta_rows_processed,
       SUM(d.delta_io_interconnect_bytes) AS delta_io_interconnect_bytes,
       SUM(d.delta_cell_offload_elig_bytes) AS delta_cell_offload_elig_bytes,
       SUM(d.delta_cell_uncompressed_bytes) AS delta_cell_uncompressed_bytes,
       SUM(d.delta_cell_offload_retrn_bytes) AS delta_cell_offload_retrn_bytes,
       SUM(d.version_count) AS version_count,
       MAX(d.sharable_mem)/1e6 AS sharable_mem_mb,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE 1 = 1
   AND TO_NUMBER('&&cs_awr_search_days.') > 0
   AND d.seconds > 1 -- avoid snaps less than 1 sec appart
 GROUP BY
       d.con_id,
       d.sql_hv,
       d.sql_len,
       d.sql_id,
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
       d.parsing_schema_name,
      --  d.module,
      --  d.action,
       d.plan_hash_value,
       d.sql_text
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       '!' AS sep0,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       '|' AS sep1,
       s.et_aas,
       s.cpu_aas,
       s.io_aas,
       s.appl_aas,
       s.conc_aas,
       s.plsql_aas,
       s.cluster_aas,
       s.java_aas,
       '|' AS sep2,
       s.delta_execution_count2 AS delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.inval_per_sec,
       s.loads_per_sec,
       '|' AS sep3,
       s.gets_per_exec,
       s.reads_per_exec,
      --  s.direct_reads_per_exec,
       s.direct_writes_per_exec,
       s.phy_read_req_per_exec,
       s.phy_read_mb_per_exec,
       s.phy_write_req_per_exec,
       s.phy_write_mb_per_exec,
       s.fetches_per_exec,
       s.sorts_per_exec,
       '|' AS sep4,
       s.delta_rows_processed,
       s.rows_per_exec,
       '|' AS sep5,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
       '|' AS sep6,
       s.sql_hv,
       s.sql_len,
       s.sql_id,
       s.plan_hash_value,
       v.has_baseline,
       v.has_profile,
       v.has_patch,
       s.sql_text,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE s.parsing_schema_name END AS pdb_or_parsing_schema_name,
       t.num_rows, 
       t.blocks,
       s.begin_timestamp,
       s.end_timestamp,
       s.seconds
  FROM sqlstats_metrics s
  OUTER APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch,
                -- v.parsing_schema_name,
                v.hash_value,
                v.address
           FROM v$sql v
          WHERE v.sql_id = s.sql_id
            AND v.con_id = s.con_id
            AND v.plan_hash_value = s.plan_hash_value
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
  OUTER APPLY ( -- only works when executed within a PDB
        SELECT  t.num_rows, t.blocks
          FROM  v$object_dependency d, dba_users u, dba_tables t
         WHERE  d.from_hash = v.hash_value
           AND  d.from_address = v.address
           AND  d.to_type = 2 -- table
           AND  d.to_owner <> 'SYS'
           AND  d.con_id = s.con_id
           AND  u.username = d.to_owner
           AND  u.oracle_maintained = 'N'
           AND  u.common = 'NO'
           AND  t.owner = d.to_owner
           AND  t.table_name = d.to_name
         ORDER BY 
               t.num_rows DESC NULLS LAST
         FETCH FIRST 1 ROW ONLY
       ) t
 WHERE 1 = 1
   AND TO_NUMBER('&&cs_awr_search_days.') > 0
   AND ('&&cs_include_sys.' = 'Y' OR NVL(s.parsing_schema_name, '-666') <> 'SYS')
 ORDER BY
       s.et_ms_per_exec DESC
/
