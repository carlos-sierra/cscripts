-- cs_fs_internal_query_2.sql: called by cs_fs.sql
PRO 
PRO DB Latency (and DB Load) v$sqlstats (last &&cs_last_snap_mins. minutes)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION /* cs_fs_internal_query_2 */ get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.con_id,
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
       s.delta_execution_count AS delta_execution_count,
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
       s.delta_rows_processed,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_elapsed_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS et_ms_per_row,
       s.delta_cpu_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS cpu_ms_per_row,
       s.delta_user_io_wait_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS io_ms_per_row,
       s.delta_buffer_gets/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS gets_per_row,
       s.delta_disk_reads/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS reads_per_row,
       s.avg_hard_parse_time,
       s.sql_id,
       s.sql_text,
       s.sql_fulltext,
       DBMS_LOB.GETLENGTH(s.sql_fulltext) AS sql_len,
       s.plan_hash_value,
       s.last_active_child_address
  FROM v$sqlstats s, 
       (SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ 
               ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds 
          FROM dba_hist_snapshot 
         WHERE end_interval_time < SYSTIMESTAMP) w
 WHERE 1 = 1
   AND ('&&cs_include_sys.' = 'Y' OR (
       s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* cli_%'
   AND s.sql_text NOT LIKE '%/* cs_%'
   AND s.sql_text NOT LIKE '%FUNCTION application_category%'
   AND s.sql_text NOT LIKE '%MATERIALIZE NO_MERGE%'
   AND s.sql_text NOT LIKE '%NO_STATEMENT_QUEUING%'
   AND s.sql_text NOT LIKE 'SELECT /* &&cs_script_name. */%'
   ))
   AND CASE 
         WHEN LENGTH('&&cs_search_string.') = 5 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NULL /* number */ AND TO_CHAR(get_sql_hv(s.sql_fulltext)) = '&&cs_search_string.' THEN 1
         WHEN LENGTH('&&cs_search_string.') = 13 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NOT NULL /* alpha */ AND LOWER('&&cs_search_string.') = '&&cs_search_string.' AND s.sql_id = '&&cs_search_string.' THEN 1
         WHEN LENGTH('&&cs_search_string.') BETWEEN 6 AND 10 AND TRIM(TRANSLATE('&&cs_search_string.', ' 0123456789', ' ')) IS NULL /* number */ AND TO_CHAR(s.plan_hash_value) = '&&cs_search_string.' THEN 1
         WHEN UPPER(s.sql_fulltext) LIKE UPPER('%&&cs_search_string.%') THEN 1
        END = 1
   AND ROWNUM >= 1 -- materialize
),
sqlstats_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       s.et_aas,
       s.cpu_aas,
       s.io_aas,
       s.appl_aas,
       s.conc_aas,
       s.plsql_aas,
       s.cluster_aas,
       s.java_aas,
       s.delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.avg_hard_parse_time,
       s.inval_per_sec,
       s.loads_per_sec,
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
       s.delta_rows_processed,
       s.rows_per_exec,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
       s.sql_id,
       s.sql_len,
       s.sql_text,
       s.sql_fulltext,
       s.plan_hash_value,
       s.last_active_child_address,
       s.con_id,
       c.name AS pdb_name
  FROM sqlstats s,
       v$containers c
 WHERE c.con_id = s.con_id
   AND ROWNUM >= 1
)
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
       s.delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.avg_hard_parse_time,
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
       get_sql_hv(s.sql_fulltext) AS sql_hv,
       s.sql_len,
       s.sql_id,
       s.plan_hash_value,
       v.has_baseline,
       v.has_profile,
       v.has_patch,
       s.sql_text,
       CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN s.pdb_name ELSE v.parsing_schema_name END AS pdb_or_parsing_schema_name,
       t.num_rows, 
       t.blocks
  FROM sqlstats_extended s
  OUTER APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch,
                v.parsing_schema_name,
                v.hash_value,
                v.address
           FROM v$sql v
          WHERE 1 = 1
            AND v.sql_id = s.sql_id
            AND v.con_id = s.con_id
            AND v.plan_hash_value = s.plan_hash_value
            AND v.child_address = s.last_active_child_address
          ORDER BY 
                v.last_active_time DESC NULLS LAST
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
   AND ('&&cs_include_sys.' = 'Y' OR NVL(v.parsing_schema_name, '-666') <> 'SYS')
 ORDER BY
       s.et_ms_per_exec DESC
/
