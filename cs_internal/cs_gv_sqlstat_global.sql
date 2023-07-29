-- cs_gv_sqlstat_global.sql: called by cs_planx.sql and cs_sqlperf.sql
@@cs_sqlstat_cols.sql
PRO 
PRO SQL STATS - CURRENT BY SQL (gv$sqlstats) since last AWR snapshot
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH 
FUNCTION /* cs_gv_sqlstat_global */ get_pdb_name (p_con_id IN VARCHAR2)
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
sqlstats_metrics AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.*,
       w.age_seconds AS seconds,
       w.snap_id,
       w.begin_timestamp,
       w.end_timestamp,
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_cpu_time/GREATEST(s.delta_execution_count,1)/1e3 AS cpu_ms_per_exec,
       s.delta_user_io_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS io_ms_per_exec,
       s.delta_application_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS appl_ms_per_exec,
       s.delta_concurrency_time/GREATEST(s.delta_execution_count,1)/1e3 AS conc_ms_per_exec,
       s.delta_plsql_exec_time/GREATEST(s.delta_execution_count,1)/1e3 AS plsql_ms_per_exec,
       s.delta_cluster_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS cluster_ms_per_exec,
       s.delta_java_exec_time/GREATEST(s.delta_execution_count,1)/1e3 AS java_ms_per_exec,
       s.delta_elapsed_time/GREATEST(w.age_seconds,1)/1e6 AS et_aas,
       s.delta_cpu_time/GREATEST(w.age_seconds,1)/1e6 AS cpu_aas,
       s.delta_user_io_wait_time/GREATEST(w.age_seconds,1)/1e6 AS io_aas,
       s.delta_application_wait_time/GREATEST(w.age_seconds,1)/1e6 AS appl_aas,
       s.delta_concurrency_time/GREATEST(w.age_seconds,1)/1e6 AS conc_aas,
       s.delta_plsql_exec_time/GREATEST(w.age_seconds,1)/1e6 AS plsql_aas,
       s.delta_cluster_wait_time/GREATEST(w.age_seconds,1)/1e6 AS cluster_aas,
       s.delta_java_exec_time/GREATEST(w.age_seconds,1)/1e6 AS java_aas,
       s.delta_execution_count/GREATEST(w.age_seconds,1) AS execs_per_sec,
       s.delta_px_servers_executions/GREATEST(w.age_seconds,1) AS px_execs_per_sec,
       s.delta_end_of_fetch_count/GREATEST(w.age_seconds,1) AS end_of_fetch_per_sec,
       s.delta_parse_calls/GREATEST(w.age_seconds,1) AS parses_per_sec,
       s.delta_invalidations/GREATEST(w.age_seconds,1) AS inval_per_sec,
       s.delta_loads/GREATEST(w.age_seconds,1) AS loads_per_sec,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) AS gets_per_exec,
       s.delta_disk_reads/GREATEST(s.delta_execution_count,1) AS reads_per_exec,
       s.delta_direct_reads/GREATEST(s.delta_execution_count,1) AS direct_reads_per_exec,
       s.delta_direct_writes/GREATEST(s.delta_execution_count,1) AS direct_writes_per_exec,
       s.delta_physical_read_requests/GREATEST(s.delta_execution_count,1) AS phy_read_req_per_exec,
       s.delta_physical_read_bytes/GREATEST(s.delta_execution_count,1)/1e6 AS phy_read_mb_per_exec,
       s.delta_physical_write_requests/GREATEST(s.delta_execution_count,1) AS phy_write_req_per_exec,
       s.delta_physical_write_bytes/GREATEST(s.delta_execution_count,1)/1e6 AS phy_write_mb_per_exec,
       s.delta_fetch_count/GREATEST(s.delta_execution_count,1) AS fetches_per_exec,
       s.delta_sorts/GREATEST(s.delta_execution_count,1) AS sorts_per_exec,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_elapsed_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS et_ms_per_row,
       s.delta_cpu_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS cpu_ms_per_row,
       s.delta_user_io_wait_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS io_ms_per_row,
       s.delta_buffer_gets/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS gets_per_row,
       s.delta_disk_reads/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS reads_per_row,
      --  s.avg_hard_parse_time,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_text LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_text, '\[([[:digit:]]{4})\] ') ELSE s.sql_text END),100000),5,'0') AS sqlid
       get_sql_hv(s.sql_fulltext) AS sqlid
  FROM gv$sqlstats s, 
       (SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ 
               ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds ,
               MAX(snap_id) + 1 AS snap_id,
               MAX(end_interval_time) AS begin_timestamp,
               SYSTIMESTAMP AS end_timestamp
          FROM dba_hist_snapshot 
         WHERE end_interval_time < SYSTIMESTAMP) w
 WHERE &&cs_filter_1.
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37))
   AND ROWNUM >= 1 -- materialize
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       '!' AS sep0,
       LPAD(s.snap_id, 7, '0') AS snap_id,
    --    s.day,
       s.begin_timestamp,
       s.end_timestamp,
       s.seconds,
       s.sqlid,
       s.sql_id,
       s.inst_id,
       s.plan_hash_value,
    --    s.optimizer_cost,
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
       s.delta_physical_read_bytes/1e6 AS delta_physical_read_mb,
       s.delta_physical_write_requests,
       s.delta_physical_write_bytes/1e6 AS delta_physical_write_mb,
       s.delta_fetch_count,
       s.delta_sorts,
       s.delta_io_interconnect_bytes/1e6 AS delta_io_interconnect_mb,
       s.delta_cell_offload_elig_bytes/1e6 AS delta_cell_offload_elig_mb,
       s.delta_cell_uncompressed_bytes/1e6 AS delta_cell_uncompressed_mb,
    --    s.delta_cell_offload_retrn_mb,
       '!' AS sep8,
       s.version_count,
    --    s.obsolete_count,
       s.delta_loads,
       s.delta_invalidations,
       s.sharable_mem/1e6 AS sharable_mem_mb,
       '!' AS sep9,
       s.sql_text,
       v.module,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE v.parsing_schema_name END AS pdb_or_parsing_schema_name
  FROM sqlstats_metrics s
 OUTER APPLY (
         SELECT v.module,
                v.parsing_schema_name
           FROM gv$sql v
          WHERE v.sql_id = s.sql_id
            AND v.con_id = s.con_id
            AND v.inst_id = s.inst_id
            AND v.plan_hash_value = s.plan_hash_value
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
 ORDER BY
       s.snap_id,
    --    s.day,
       s.begin_timestamp,
       s.end_timestamp,
       s.sqlid,
       s.sql_id,
       s.inst_id,
       s.plan_hash_value,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE v.parsing_schema_name END,
       v.module
/
--
@@cs_sqlstat_foot.sql
@@cs_sqlstat_clear.sql