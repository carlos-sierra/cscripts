----------------------------------------------------------------------------------------
--
-- File name:   ssai.sql | cs_sqlstat_analytics_iod.sql
--
-- Purpose:     SQL Statistics Analytics (IOD) - 1m Granularity
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/03
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_analytics_iod.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
-- @@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlstat_analytics_iod';
DEF cs_script_acronym = 'ssai.sql | ';
--
DEF cs_hours_range_default = '12';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO
PRO SQL Statistic                       Note
PRO ~~~~~~~~~~~~~                       ~~~~~~
PRO delta_execution_count
PRO delta_elapsed_time
PRO delta_cpu_time
PRO delta_user_io_wait_time
PRO delta_application_wait_time
PRO delta_concurrency_time
PRO delta_plsql_exec_time
PRO delta_cluster_wait_time
PRO delta_java_exec_time
PRO delta_px_servers_executions
PRO delta_end_of_fetch_count
PRO delta_parse_calls
PRO delta_invalidations
PRO delta_loads
PRO delta_buffer_gets
PRO delta_disk_reads
PRO delta_direct_writes
PRO delta_physical_read_requests
PRO delta_physical_read_mb
PRO delta_physical_write_requests
PRO delta_physical_write_mb
PRO delta_fetch_count
PRO delta_sorts
PRO delta_rows_processed
PRO delta_io_interconnect_mb
PRO delta_cell_offload_elig_mb
PRO delta_cell_uncompressed_mb
PRO delta_cell_offload_retrn_mb
PRO version_count
PRO sharable_mem_mb
PRO obsolete_count
PRO et_ms_per_exec ...................  default
PRO cpu_ms_per_exec
PRO io_ms_per_exec
PRO appl_ms_per_exec
PRO conc_ms_per_exec
PRO plsql_ms_per_exec
PRO cluster_ms_per_exec
PRO java_ms_per_exec
PRO et_aas ...........................  common
PRO cpu_aas
PRO io_aas
PRO appl_aas
PRO conc_aas
PRO plsql_aas
PRO cluster_aas
PRO java_aas
PRO execs_per_sec ....................  common
PRO px_execs_per_sec
PRO end_of_fetch_per_sec
PRO parses_per_sec
PRO avg_hard_parse_time
PRO inval_per_sec
PRO loads_per_sec
PRO gets_per_exec ....................  common
PRO reads_per_exec
PRO direct_writes_per_exec
PRO phy_read_req_per_exec
PRO phy_read_mb_per_exec
PRO phy_write_req_per_exec
PRO phy_write_mb_per_exec
PRO fetches_per_exec
PRO sorts_per_exec
PRO rows_per_exec ....................  common
PRO et_ms_per_row
PRO cpu_ms_per_row
PRO io_ms_per_row
PRO gets_per_row
PRO reads_per_row
PRO
PRO 3. SQL Statistic: [{et_ms_per_exec}|<SQL Statistic>]
DEF cs_sql_statistic = '&3.';
UNDEF 3;
COL cs_sql_statistic NEW_V cs_sql_statistic NOPRI;
SELECT LOWER(NVL(TRIM('&&cs_sql_statistic.'), 'et_ms_per_exec')) AS cs_sql_statistic FROM DUAL
/
--
PRO
PRO 4. SQL Type: [{null}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF cs_sql_type = '&4.';
UNDEF 4;
COL cs_sql_type NEW_V cs_sql_type NOPRI;
SELECT UPPER(TRIM('&&cs_sql_type.')) AS cs_sql_type FROM DUAL
/
--
PRO
PRO 5. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&5.';
UNDEF 5;
--
PRO
PRO 6. SQL_ID (optional):
DEF cs_sql_id = '&6.';
UNDEF 6;
DEF cs_filter_1 = '';
DEF cs_filter_2 = '';
COL cs_filter_1 NEW_V cs_filter_1 NOPRI;
COL cs_filter_2 NEW_V cs_filter_2 NOPRI;
SELECT CASE WHEN LENGTH('&&cs_sql_id.') = 13 THEN 'sql_id = ''&&cs_sql_id.''' ELSE '1 = 1' END AS cs_filter_1,
       CASE '&&cs_con_id.' WHEN '1' THEN '1 = 1' ELSE 'con_id = &&cs_con_id.' END AS cs_filter_2 
FROM DUAL
/
--
DEF spool_id_chart_footer_script = 'cs_sqlstat_analytics_iod_footer.sql';
--
DEF sql_id_01 = '             ';
DEF sql_id_02 = '             ';
DEF sql_id_03 = '             ';
DEF sql_id_04 = '             ';
DEF sql_id_05 = '             ';
DEF sql_id_06 = '             ';
DEF sql_id_07 = '             ';
DEF sql_id_08 = '             ';
DEF sql_id_09 = '             ';
DEF sql_id_10 = '             ';
DEF sql_id_11 = '             ';
DEF sql_id_12 = '             ';
DEF sql_id_13 = '             ';
--
COL sql_id_01 NEW_V sql_id_01 TRUNC NOPRI;
COL sql_id_02 NEW_V sql_id_02 TRUNC NOPRI;
COL sql_id_03 NEW_V sql_id_03 TRUNC NOPRI;
COL sql_id_04 NEW_V sql_id_04 TRUNC NOPRI;
COL sql_id_05 NEW_V sql_id_05 TRUNC NOPRI;
COL sql_id_06 NEW_V sql_id_06 TRUNC NOPRI;
COL sql_id_07 NEW_V sql_id_07 TRUNC NOPRI;
COL sql_id_08 NEW_V sql_id_08 TRUNC NOPRI;
COL sql_id_09 NEW_V sql_id_09 TRUNC NOPRI;
COL sql_id_10 NEW_V sql_id_10 TRUNC NOPRI;
COL sql_id_11 NEW_V sql_id_11 TRUNC NOPRI;
COL sql_id_12 NEW_V sql_id_12 TRUNC NOPRI;
COL sql_id_13 NEW_V sql_id_13 TRUNC NOPRI;
--
DEF plan_hash_value_01 = '          ';
DEF plan_hash_value_02 = '          ';
DEF plan_hash_value_03 = '          ';
DEF plan_hash_value_04 = '          ';
DEF plan_hash_value_05 = '          ';
DEF plan_hash_value_06 = '          ';
DEF plan_hash_value_07 = '          ';
DEF plan_hash_value_08 = '          ';
DEF plan_hash_value_09 = '          ';
DEF plan_hash_value_10 = '          ';
DEF plan_hash_value_11 = '          ';
DEF plan_hash_value_12 = '          ';
DEF plan_hash_value_13 = '          ';
--
COL plan_hash_value_01 NEW_V plan_hash_value_01 TRUNC NOPRI;
COL plan_hash_value_02 NEW_V plan_hash_value_02 TRUNC NOPRI;
COL plan_hash_value_03 NEW_V plan_hash_value_03 TRUNC NOPRI;
COL plan_hash_value_04 NEW_V plan_hash_value_04 TRUNC NOPRI;
COL plan_hash_value_05 NEW_V plan_hash_value_05 TRUNC NOPRI;
COL plan_hash_value_06 NEW_V plan_hash_value_06 TRUNC NOPRI;
COL plan_hash_value_07 NEW_V plan_hash_value_07 TRUNC NOPRI;
COL plan_hash_value_08 NEW_V plan_hash_value_08 TRUNC NOPRI;
COL plan_hash_value_09 NEW_V plan_hash_value_09 TRUNC NOPRI;
COL plan_hash_value_10 NEW_V plan_hash_value_10 TRUNC NOPRI;
COL plan_hash_value_11 NEW_V plan_hash_value_11 TRUNC NOPRI;
COL plan_hash_value_12 NEW_V plan_hash_value_12 TRUNC NOPRI;
COL plan_hash_value_13 NEW_V plan_hash_value_13 TRUNC NOPRI;
--
DEF value_01 = '               ';
DEF value_02 = '               ';
DEF value_03 = '               ';
DEF value_04 = '               ';
DEF value_05 = '               ';
DEF value_06 = '               ';
DEF value_07 = '               ';
DEF value_08 = '               ';
DEF value_09 = '               ';
DEF value_10 = '               ';
DEF value_11 = '               ';
DEF value_12 = '               ';
DEF value_13 = '               ';
--
COL value_01 NEW_V value_01 TRUNC NOPRI;
COL value_02 NEW_V value_02 TRUNC NOPRI;
COL value_03 NEW_V value_03 TRUNC NOPRI;
COL value_04 NEW_V value_04 TRUNC NOPRI;
COL value_05 NEW_V value_05 TRUNC NOPRI;
COL value_06 NEW_V value_06 TRUNC NOPRI;
COL value_07 NEW_V value_07 TRUNC NOPRI;
COL value_08 NEW_V value_08 TRUNC NOPRI;
COL value_09 NEW_V value_09 TRUNC NOPRI;
COL value_10 NEW_V value_10 TRUNC NOPRI;
COL value_11 NEW_V value_11 TRUNC NOPRI;
COL value_12 NEW_V value_12 TRUNC NOPRI;
COL value_13 NEW_V value_13 TRUNC NOPRI;
--
DEF sql_type_01 = '   ';
DEF sql_type_02 = '   ';
DEF sql_type_03 = '   ';
DEF sql_type_04 = '   ';
DEF sql_type_05 = '   ';
DEF sql_type_06 = '   ';
DEF sql_type_07 = '   ';
DEF sql_type_08 = '   ';
DEF sql_type_09 = '   ';
DEF sql_type_10 = '   ';
DEF sql_type_11 = '   ';
DEF sql_type_12 = '   ';
DEF sql_type_13 = '   ';
--
COL sql_type_01 NEW_V sql_type_01 TRUNC NOPRI;
COL sql_type_02 NEW_V sql_type_02 TRUNC NOPRI;
COL sql_type_03 NEW_V sql_type_03 TRUNC NOPRI;
COL sql_type_04 NEW_V sql_type_04 TRUNC NOPRI;
COL sql_type_05 NEW_V sql_type_05 TRUNC NOPRI;
COL sql_type_06 NEW_V sql_type_06 TRUNC NOPRI;
COL sql_type_07 NEW_V sql_type_07 TRUNC NOPRI;
COL sql_type_08 NEW_V sql_type_08 TRUNC NOPRI;
COL sql_type_09 NEW_V sql_type_09 TRUNC NOPRI;
COL sql_type_10 NEW_V sql_type_10 TRUNC NOPRI;
COL sql_type_11 NEW_V sql_type_11 TRUNC NOPRI;
COL sql_type_12 NEW_V sql_type_12 TRUNC NOPRI;
COL sql_type_13 NEW_V sql_type_13 TRUNC NOPRI;
--
DEF pdb_name_01 = '                              ';
DEF pdb_name_02 = '                              ';
DEF pdb_name_03 = '                              ';
DEF pdb_name_04 = '                              ';
DEF pdb_name_05 = '                              ';
DEF pdb_name_06 = '                              ';
DEF pdb_name_07 = '                              ';
DEF pdb_name_08 = '                              ';
DEF pdb_name_09 = '                              ';
DEF pdb_name_10 = '                              ';
DEF pdb_name_11 = '                              ';
DEF pdb_name_12 = '                              ';
DEF pdb_name_13 = '                              ';
--
COL pdb_name_01 NEW_V pdb_name_01 TRUNC NOPRI;
COL pdb_name_02 NEW_V pdb_name_02 TRUNC NOPRI;
COL pdb_name_03 NEW_V pdb_name_03 TRUNC NOPRI;
COL pdb_name_04 NEW_V pdb_name_04 TRUNC NOPRI;
COL pdb_name_05 NEW_V pdb_name_05 TRUNC NOPRI;
COL pdb_name_06 NEW_V pdb_name_06 TRUNC NOPRI;
COL pdb_name_07 NEW_V pdb_name_07 TRUNC NOPRI;
COL pdb_name_08 NEW_V pdb_name_08 TRUNC NOPRI;
COL pdb_name_09 NEW_V pdb_name_09 TRUNC NOPRI;
COL pdb_name_10 NEW_V pdb_name_10 TRUNC NOPRI;
COL pdb_name_11 NEW_V pdb_name_11 TRUNC NOPRI;
COL pdb_name_12 NEW_V pdb_name_12 TRUNC NOPRI;
COL pdb_name_13 NEW_V pdb_name_13 TRUNC NOPRI;
--
DEF sql_text_01 = '                                                            ';
DEF sql_text_02 = '                                                            ';
DEF sql_text_03 = '                                                            ';
DEF sql_text_04 = '                                                            ';
DEF sql_text_05 = '                                                            ';
DEF sql_text_06 = '                                                            ';
DEF sql_text_07 = '                                                            ';
DEF sql_text_08 = '                                                            ';
DEF sql_text_09 = '                                                            ';
DEF sql_text_10 = '                                                            ';
DEF sql_text_11 = '                                                            ';
DEF sql_text_12 = '                                                            ';
DEF sql_text_13 = '                                                            ';
--
COL sql_text_01 NEW_V sql_text_01 TRUNC NOPRI;
COL sql_text_02 NEW_V sql_text_02 TRUNC NOPRI;
COL sql_text_03 NEW_V sql_text_03 TRUNC NOPRI;
COL sql_text_04 NEW_V sql_text_04 TRUNC NOPRI;
COL sql_text_05 NEW_V sql_text_05 TRUNC NOPRI;
COL sql_text_06 NEW_V sql_text_06 TRUNC NOPRI;
COL sql_text_07 NEW_V sql_text_07 TRUNC NOPRI;
COL sql_text_08 NEW_V sql_text_08 TRUNC NOPRI;
COL sql_text_09 NEW_V sql_text_09 TRUNC NOPRI;
COL sql_text_10 NEW_V sql_text_10 TRUNC NOPRI;
COL sql_text_11 NEW_V sql_text_11 TRUNC NOPRI;
COL sql_text_12 NEW_V sql_text_12 TRUNC NOPRI;
COL sql_text_13 NEW_V sql_text_13 TRUNC NOPRI;
--
DEF module_01 = '                                ';
DEF module_02 = '                                ';
DEF module_03 = '                                ';
DEF module_04 = '                                ';
DEF module_05 = '                                ';
DEF module_06 = '                                ';
DEF module_07 = '                                ';
DEF module_08 = '                                ';
DEF module_09 = '                                ';
DEF module_10 = '                                ';
DEF module_11 = '                                ';
DEF module_12 = '                                ';
DEF module_13 = '                                ';
--
COL module_01 NEW_V module_01 TRUNC NOPRI;
COL module_02 NEW_V module_02 TRUNC NOPRI;
COL module_03 NEW_V module_03 TRUNC NOPRI;
COL module_04 NEW_V module_04 TRUNC NOPRI;
COL module_05 NEW_V module_05 TRUNC NOPRI;
COL module_06 NEW_V module_06 TRUNC NOPRI;
COL module_07 NEW_V module_07 TRUNC NOPRI;
COL module_08 NEW_V module_08 TRUNC NOPRI;
COL module_09 NEW_V module_09 TRUNC NOPRI;
COL module_10 NEW_V module_10 TRUNC NOPRI;
COL module_11 NEW_V module_11 TRUNC NOPRI;
COL module_12 NEW_V module_12 TRUNC NOPRI;
COL module_13 NEW_V module_13 TRUNC NOPRI;
--
PRO
PRO please wait... computing top sql...
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
/****************************************************************************************/
WITH 
FUNCTION /* cs_sqlstat_analytics_iod 1 */ get_pdb_name (p_con_id IN VARCHAR2)
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
       &&cs_tools_schema..iod_spm.application_category(s.sql_text, 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
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
       d.sql_type,
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
       AVG(d.avg_hard_parse_time) AS avg_hard_parse_time,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE d.seconds > 1 -- avoid snaps less than 1 sec appart
   AND ('&&cs_sql_type.' IS NULL OR INSTR('&&cs_sql_type.', d.sql_type) > 0)
 GROUP BY
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
       d.sql_type,
       d.sql_text
),
/****************************************************************************************/
full_list AS (
SELECT m.con_id,
       SUBSTR(get_pdb_name(m.con_id), 1, 30) AS pdb_name,
       m.sqlid,
       m.sql_id,
      --  m.exact_matching_signature,
      --  m.force_matching_signature,
      --  m.sql_profile,
      --  m.instance_number,
      --  m.parsing_schema_name,
      --  SUBSTR(m.module, 1, 32) AS module,
      --  m.action,
       m.plan_hash_value,
       m.sql_type,
       SUBSTR(m.sql_text, 1, 60) AS sql_text,
       m.&&cs_sql_statistic. AS value,
       ROW_NUMBER() OVER (ORDER BY m.&&cs_sql_statistic. DESC NULLS LAST) AS rn
  FROM sqlstats_metrics m
 WHERE NVL(m.&&cs_sql_statistic., 0) >= 0 -- negative values are possible but unwanted
),
/****************************************************************************************/
list AS (
SELECT con_id,
       pdb_name,
       sqlid,
       sql_id,
      --  exact_matching_signature,
      --  force_matching_signature,
      --  sql_profile,
      --  instance_number,
      --  parsing_schema_name,
      --  module,
      --  action,
       plan_hash_value,
       sql_type,
       sql_text,
       value,
       rn
  FROM full_list
 WHERE rn < 14
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       MAX(CASE rn WHEN 01 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_01,
       MAX(CASE rn WHEN 02 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_02,
       MAX(CASE rn WHEN 03 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_03,
       MAX(CASE rn WHEN 04 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_04,
       MAX(CASE rn WHEN 05 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_05,
       MAX(CASE rn WHEN 06 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_06,
       MAX(CASE rn WHEN 07 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_07,
       MAX(CASE rn WHEN 08 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_08,
       MAX(CASE rn WHEN 09 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_09,
       MAX(CASE rn WHEN 10 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_10,
       MAX(CASE rn WHEN 11 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_11,
       MAX(CASE rn WHEN 12 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_12,
       MAX(CASE rn WHEN 13 THEN RPAD(sql_id, 13, ' ') ELSE RPAD(' ', 13, ' ') END) AS sql_id_13,
       MAX(CASE rn WHEN 01 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_01,
       MAX(CASE rn WHEN 02 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_02,
       MAX(CASE rn WHEN 03 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_03,
       MAX(CASE rn WHEN 04 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_04,
       MAX(CASE rn WHEN 05 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_05,
       MAX(CASE rn WHEN 06 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_06,
       MAX(CASE rn WHEN 07 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_07,
       MAX(CASE rn WHEN 08 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_08,
       MAX(CASE rn WHEN 09 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_09,
       MAX(CASE rn WHEN 10 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_10,
       MAX(CASE rn WHEN 11 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_11,
       MAX(CASE rn WHEN 12 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_12,
       MAX(CASE rn WHEN 13 THEN RPAD(plan_hash_value, 10, ' ') ELSE RPAD(' ', 10, ' ') END) AS plan_hash_value_13,
       MAX(CASE rn WHEN 01 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_01,
       MAX(CASE rn WHEN 02 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_02,
       MAX(CASE rn WHEN 03 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_03,
       MAX(CASE rn WHEN 04 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_04,
       MAX(CASE rn WHEN 05 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_05,
       MAX(CASE rn WHEN 06 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_06,
       MAX(CASE rn WHEN 07 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_07,
       MAX(CASE rn WHEN 08 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_08,
       MAX(CASE rn WHEN 09 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_09,
       MAX(CASE rn WHEN 10 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_10,
       MAX(CASE rn WHEN 11 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_11,
       MAX(CASE rn WHEN 12 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_12,
       MAX(CASE rn WHEN 13 THEN LPAD(TO_CHAR(value, 'fm999,999,990.000'), 15, ' ') ELSE LPAD(' ', 15, ' ') END) AS value_13,
       MAX(CASE rn WHEN 01 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_01,
       MAX(CASE rn WHEN 02 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_02,
       MAX(CASE rn WHEN 03 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_03,
       MAX(CASE rn WHEN 04 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_04,
       MAX(CASE rn WHEN 05 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_05,
       MAX(CASE rn WHEN 06 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_06,
       MAX(CASE rn WHEN 07 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_07,
       MAX(CASE rn WHEN 08 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_08,
       MAX(CASE rn WHEN 09 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_09,
       MAX(CASE rn WHEN 10 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_10,
       MAX(CASE rn WHEN 11 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_11,
       MAX(CASE rn WHEN 12 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_12,
       MAX(CASE rn WHEN 13 THEN RPAD(sql_type, 3, ' ') ELSE RPAD(' ', 3, ' ') END) AS sql_type_13,
       MAX(CASE rn WHEN 01 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_01,
       MAX(CASE rn WHEN 02 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_02,
       MAX(CASE rn WHEN 03 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_03,
       MAX(CASE rn WHEN 04 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_04,
       MAX(CASE rn WHEN 05 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_05,
       MAX(CASE rn WHEN 06 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_06,
       MAX(CASE rn WHEN 07 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_07,
       MAX(CASE rn WHEN 08 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_08,
       MAX(CASE rn WHEN 09 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_09,
       MAX(CASE rn WHEN 10 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_10,
       MAX(CASE rn WHEN 11 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_11,
       MAX(CASE rn WHEN 12 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_12,
       MAX(CASE rn WHEN 13 THEN RPAD(pdb_name, 30, ' ') ELSE RPAD(' ', 30, ' ') END) AS pdb_name_13,
       MAX(CASE rn WHEN 01 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_01,
       MAX(CASE rn WHEN 02 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_02,
       MAX(CASE rn WHEN 03 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_03,
       MAX(CASE rn WHEN 04 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_04,
       MAX(CASE rn WHEN 05 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_05,
       MAX(CASE rn WHEN 06 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_06,
       MAX(CASE rn WHEN 07 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_07,
       MAX(CASE rn WHEN 08 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_08,
       MAX(CASE rn WHEN 09 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_09,
       MAX(CASE rn WHEN 10 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_10,
       MAX(CASE rn WHEN 11 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_11,
       MAX(CASE rn WHEN 12 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_12,
       MAX(CASE rn WHEN 13 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_13
      --  MAX(CASE rn WHEN 01 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_01,
      --  MAX(CASE rn WHEN 02 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_02,
      --  MAX(CASE rn WHEN 03 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_03,
      --  MAX(CASE rn WHEN 04 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_04,
      --  MAX(CASE rn WHEN 05 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_05,
      --  MAX(CASE rn WHEN 06 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_06,
      --  MAX(CASE rn WHEN 07 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_07,
      --  MAX(CASE rn WHEN 08 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_08,
      --  MAX(CASE rn WHEN 09 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_09,
      --  MAX(CASE rn WHEN 10 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_10,
      --  MAX(CASE rn WHEN 11 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_11,
      --  MAX(CASE rn WHEN 12 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_12,
      --  MAX(CASE rn WHEN 13 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_13
  FROM list
/
/****************************************************************************************/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Top SQL by average "&&cs_sql_statistic." between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = '&&cs_sql_statistic.';
DEF xaxis_title = '';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
'&&cs_rgn. &&cs_locale. &&cs_con_name.'||
CASE WHEN '&&cs_sql_type.' IS NOT NULL THEN ' Type:&&cs_sql_type.' END||
CASE WHEN '&&cs2_sql_text_piece.' IS NOT NULL THEN ' Text:"%&&cs2_sql_text_piece.%"' END||
CASE WHEN '&&cs_sql_id.' IS NOT NULL THEN ' SQL_ID:&&cs_sql_id.' END AS xaxis_title
FROM DUAL
/
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = '<br>2) &&xaxis_title.';
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_statistic." "&&cs_sql_type." "&&cs2_sql_text_piece." "&&cs_sql_id."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&sql_id_01. &&plan_hash_value_01. &&sql_type_01. &&pdb_name_01.', id:'01', type:'number'}
PRO ,{label:'&&sql_id_02. &&plan_hash_value_02. &&sql_type_02. &&pdb_name_02.', id:'02', type:'number'}
PRO ,{label:'&&sql_id_03. &&plan_hash_value_03. &&sql_type_03. &&pdb_name_03.', id:'03', type:'number'}
PRO ,{label:'&&sql_id_04. &&plan_hash_value_04. &&sql_type_04. &&pdb_name_04.', id:'04', type:'number'}
PRO ,{label:'&&sql_id_05. &&plan_hash_value_05. &&sql_type_05. &&pdb_name_05.', id:'05', type:'number'}
PRO ,{label:'&&sql_id_06. &&plan_hash_value_06. &&sql_type_06. &&pdb_name_06.', id:'06', type:'number'}
PRO ,{label:'&&sql_id_07. &&plan_hash_value_07. &&sql_type_07. &&pdb_name_07.', id:'07', type:'number'}
PRO ,{label:'&&sql_id_08. &&plan_hash_value_08. &&sql_type_08. &&pdb_name_08.', id:'08', type:'number'}
PRO ,{label:'&&sql_id_09. &&plan_hash_value_09. &&sql_type_09. &&pdb_name_09.', id:'09', type:'number'}
PRO ,{label:'&&sql_id_10. &&plan_hash_value_10. &&sql_type_10. &&pdb_name_10.', id:'10', type:'number'}
PRO ,{label:'&&sql_id_11. &&plan_hash_value_11. &&sql_type_11. &&pdb_name_11.', id:'11', type:'number'}
PRO ,{label:'&&sql_id_12. &&plan_hash_value_12. &&sql_type_12. &&pdb_name_12.', id:'12', type:'number'}
PRO ,{label:'&&sql_id_13. &&plan_hash_value_13. &&sql_type_13. &&pdb_name_13.', id:'13', type:'number'}     
PRO ]
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
FUNCTION /* cs_sqlstat_analytics_iod 2 */ num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
FUNCTION get_pdb_name (p_con_id IN VARCHAR2)
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
       &&cs_tools_schema..iod_spm.application_category(s.sql_text, 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
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
   AND s.sql_id IN 
   (TRIM('&&sql_id_01')
   ,TRIM('&&sql_id_02')
   ,TRIM('&&sql_id_03')
   ,TRIM('&&sql_id_04')
   ,TRIM('&&sql_id_05')
   ,TRIM('&&sql_id_06')
   ,TRIM('&&sql_id_07')
   ,TRIM('&&sql_id_08')
   ,TRIM('&&sql_id_09')
   ,TRIM('&&sql_id_10')
   ,TRIM('&&sql_id_11')
   ,TRIM('&&sql_id_12')
   ,TRIM('&&sql_id_13')
   )
   AND s.plan_hash_value IN
   (TO_NUMBER(TRIM('&&plan_hash_value_01.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_02.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_03.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_04.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_05.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_06.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_07.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_08.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_09.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_10.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_11.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_12.'))
   ,TO_NUMBER(TRIM('&&plan_hash_value_13.'))
   )
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
       d.sql_type,
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
       AVG(d.avg_hard_parse_time) AS avg_hard_parse_time,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE d.seconds > 1 -- avoid snaps less than 1 sec appart
   AND ('&&cs_sql_type.' IS NULL OR INSTR('&&cs_sql_type.', d.sql_type) > 0)
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
       d.sql_type,
       d.sql_text
),
/****************************************************************************************/
full_list AS (
SELECT m.begin_timestamp,
       m.end_timestamp,
       m.seconds,
       m.con_id,
       m.pdb_name,
       m.sqlid,
       m.sql_id,
      --  m.force_matching_signature,
      --  m.sql_profile,
      --  m.instance_number,
      --  m.parsing_schema_name,
      --  m.module,
      --  m.action,
       m.plan_hash_value,
       m.sql_type,
       m.sql_text,
       m.&&cs_sql_statistic. AS value
  FROM sqlstats_metrics m
 WHERE NVL(m.&&cs_sql_statistic., 0) >= 0 -- negative values are possible but unwanted
   AND m.pdb_name IN 
   (TRIM('&&pdb_name_01.')
   ,TRIM('&&pdb_name_02.')
   ,TRIM('&&pdb_name_03.')
   ,TRIM('&&pdb_name_04.')
   ,TRIM('&&pdb_name_05.')
   ,TRIM('&&pdb_name_06.')
   ,TRIM('&&pdb_name_07.')
   ,TRIM('&&pdb_name_08.')
   ,TRIM('&&pdb_name_09.')
   ,TRIM('&&pdb_name_10.')
   ,TRIM('&&pdb_name_11.')
   ,TRIM('&&pdb_name_12.')
   ,TRIM('&&pdb_name_13.')
   )
),
/****************************************************************************************/
list AS (
SELECT end_timestamp AS time,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_01.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_01.')) AND pdb_name = TRIM('&&pdb_name_01.') THEN value ELSE 0 END) AS value_01,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_02.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_02.')) AND pdb_name = TRIM('&&pdb_name_02.') THEN value ELSE 0 END) AS value_02,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_03.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_03.')) AND pdb_name = TRIM('&&pdb_name_03.') THEN value ELSE 0 END) AS value_03,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_04.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_04.')) AND pdb_name = TRIM('&&pdb_name_04.') THEN value ELSE 0 END) AS value_04,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_05.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_05.')) AND pdb_name = TRIM('&&pdb_name_05.') THEN value ELSE 0 END) AS value_05,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_06.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_06.')) AND pdb_name = TRIM('&&pdb_name_06.') THEN value ELSE 0 END) AS value_06,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_07.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_07.')) AND pdb_name = TRIM('&&pdb_name_07.') THEN value ELSE 0 END) AS value_07,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_08.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_08.')) AND pdb_name = TRIM('&&pdb_name_08.') THEN value ELSE 0 END) AS value_08,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_09.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_09.')) AND pdb_name = TRIM('&&pdb_name_09.') THEN value ELSE 0 END) AS value_09,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_10.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_10.')) AND pdb_name = TRIM('&&pdb_name_10.') THEN value ELSE 0 END) AS value_10,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_11.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_11.')) AND pdb_name = TRIM('&&pdb_name_11.') THEN value ELSE 0 END) AS value_11,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_12.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_12.')) AND pdb_name = TRIM('&&pdb_name_12.') THEN value ELSE 0 END) AS value_12,
       SUM(CASE WHEN sql_id = TRIM('&&sql_id_13.') AND plan_hash_value = TO_NUMBER(TRIM('&&plan_hash_value_13.')) AND pdb_name = TRIM('&&pdb_name_13.') THEN value ELSE 0 END) AS value_13
  FROM full_list
 GROUP BY
       end_timestamp
)
/****************************************************************************************/
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.value_01, 3)|| 
       ','||num_format(q.value_02, 3)|| 
       ','||num_format(q.value_03, 3)|| 
       ','||num_format(q.value_04, 3)|| 
       ','||num_format(q.value_05, 3)|| 
       ','||num_format(q.value_06, 3)|| 
       ','||num_format(q.value_07, 3)|| 
       ','||num_format(q.value_08, 3)|| 
       ','||num_format(q.value_09, 3)|| 
       ','||num_format(q.value_10, 3)|| 
       ','||num_format(q.value_11, 3)|| 
       ','||num_format(q.value_12, 3)|| 
       ','||num_format(q.value_13, 3)|| 
       ']'
  FROM list q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Scatter';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--