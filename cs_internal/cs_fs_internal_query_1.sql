-- cs_fs_internal_query_1.sql: called by cs_fs.sql 
@@cs_sqlstat_cols.sql
PRO
PRO DB Latency (and DB Load) gv$sql (current)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
FUNCTION /* cs_fs_internal_query_1 */ get_pdb_name (p_con_id IN VARCHAR2)
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
sql_metrics AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.*,
       s.elapsed_time/GREATEST(s.executions,1)/1e3 AS et_ms_per_exec,
       s.cpu_time/GREATEST(s.executions,1)/1e3 AS cpu_ms_per_exec,
       s.user_io_wait_time/GREATEST(s.executions,1)/1e3 AS io_ms_per_exec,
       s.application_wait_time/GREATEST(s.executions,1)/1e3 AS appl_ms_per_exec,
       s.concurrency_wait_time/GREATEST(s.executions,1)/1e3 AS conc_ms_per_exec,
       s.plsql_exec_time/GREATEST(s.executions,1)/1e3 AS plsql_ms_per_exec,
       s.cluster_wait_time/GREATEST(s.executions,1)/1e3 AS cluster_ms_per_exec,
       s.java_exec_time/GREATEST(s.executions,1)/1e3 AS java_ms_per_exec,
       s.executions/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS execs_per_sec,
       s.px_servers_executions/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS px_execs_per_sec,
       s.end_of_fetch_count/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS end_of_fetch_per_sec,
       s.parse_calls/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS parses_per_sec,
       s.invalidations/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS inval_per_sec,
       s.loads/GREATEST(((SYSDATE - TO_DATE(REPLACE(s.last_load_time, '/', 'T'), '&&cs_datetime_full_format.')) * 24 * 3600),1) AS loads_per_sec,
       s.buffer_gets/GREATEST(s.executions,1) AS gets_per_exec,
       s.disk_reads/GREATEST(s.executions,1) AS reads_per_exec,
       s.direct_reads/GREATEST(s.executions,1) AS direct_reads_per_exec,
       s.direct_writes/GREATEST(s.executions,1) AS direct_writes_per_exec,
       s.physical_read_requests/GREATEST(s.executions,1) AS phy_read_req_per_exec,
       s.physical_read_bytes/GREATEST(s.executions,1)/1e6 AS phy_read_mb_per_exec,
       s.physical_write_requests/GREATEST(s.executions,1) AS phy_write_req_per_exec,
       s.physical_write_bytes/GREATEST(s.executions,1)/1e6 AS phy_write_mb_per_exec,
       s.fetches/GREATEST(s.executions,1) AS fetches_per_exec,
       s.sorts/GREATEST(s.executions,1) AS sorts_per_exec,
       s.rows_processed/GREATEST(s.executions,1) AS rows_per_exec,
       s.elapsed_time/GREATEST(s.rows_processed,s.executions,1)/1e3 AS et_ms_per_row,
       s.cpu_time/GREATEST(s.rows_processed,s.executions,1)/1e3 AS cpu_ms_per_row,
       s.user_io_wait_time/GREATEST(s.rows_processed,s.executions,1)/1e3 AS io_ms_per_row,
       s.buffer_gets/GREATEST(s.rows_processed,s.executions,1) AS gets_per_row,
       s.disk_reads/GREATEST(s.rows_processed,s.executions,1) AS reads_per_row,
       DBMS_LOB.GETLENGTH(s.sql_fulltext) AS sql_len,
       get_sql_hv(s.sql_fulltext) AS sql_hv
  FROM gv$sql s
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
   AND ('&&cs_include_sys.' = 'Y' OR NVL(s.parsing_schema_name, '-666') <> 'SYS')
   AND ROWNUM >= 1 -- materialize
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       '!' AS sep0,
       s.last_active_time,
       REPLACE(s.last_load_time, '/', 'T') AS last_load_time,
       REPLACE(s.first_load_time, '/', 'T') AS first_load_time,
       '!' AS sep1,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       '!' AS sep2,
       s.executions,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.inval_per_sec,
       s.loads_per_sec,
       '!' AS sep3,
       s.gets_per_exec,
       s.reads_per_exec,
       s.direct_writes_per_exec,
       s.phy_read_req_per_exec,
       s.phy_read_mb_per_exec,
       s.phy_write_req_per_exec,
       s.phy_write_mb_per_exec,
       s.fetches_per_exec,
       s.sorts_per_exec,
       '!' AS sep4,
       s.rows_per_exec,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
      --  '!' AS sep5,
      --  s.loaded_versions AS version_count,
      --  CASE s.is_obsolete WHEN 'Y' THEN 1 ELSE 0 END AS obsolete_count,
      --  CASE s.is_shareable WHEN 'Y' THEN 1 ELSE 0 END AS shareable_count,
      --  s.loads,
      --  s.invalidations,
      --  s.sharable_mem/1e6 AS sharable_mem_mb,
      --  '!' AS sep8,
       '!' AS sep9,
       s.sql_hv,
       s.sql_len,
       s.sql_id,
       s.inst_id,
       s.child_number,
       s.plan_hash_value,
       CASE WHEN s.sql_plan_baseline IS NOT NULL THEN 'YES' ELSE 'NO' END AS sql_bl,
       CASE WHEN s.sql_profile IS NOT NULL THEN 'YES' ELSE 'NO' END AS sql_prf,
       CASE WHEN s.sql_patch IS NOT NULL THEN 'YES' ELSE 'NO' END AS sql_pch,
       s.sql_text,
       s.module,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE s.parsing_schema_name END AS pdb_or_parsing_schema_name,
       s.optimizer_cost
  FROM sql_metrics s
 WHERE 1 = 1
 ORDER BY
       s.last_active_time,
       s.sql_hv,
       s.sql_id,
       s.inst_id,
       s.plan_hash_value,
       CASE SYS_CONTEXT('USERENV', 'CON_ID') WHEN '1' THEN get_pdb_name(s.con_id) ELSE s.parsing_schema_name END,
       s.module
/
