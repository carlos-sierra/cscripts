----------------------------------------------------------------------------------------
--
-- File name:   ssa.sql | cs_sqlstat_analytics.sql
--
-- Purpose:     SQL Statistics Analytics (AWR) - 15m Granularity
--
-- Author:      Carlos Sierra
--
-- Version:     2023/03/30
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_analytics.sql
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
DEF cs_script_name = 'cs_sqlstat_analytics';
DEF cs_script_acronym = 'ssa.sql | ';
--
DEF cs_hours_range_default = '168';
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
PRO mbps_r
PRO mbps_w
PRO mbps_rw
PRO iops_r
PRO iops_w
PRO iops_rw
PRO
PRO 3. SQL Statistic: [{et_ms_per_exec}|<SQL Statistic>]
DEF cs_sql_statistic = '&3.';
UNDEF 3;
COL cs_sql_statistic NEW_V cs_sql_statistic NOPRI;
SELECT LOWER(NVL(TRIM('&&cs_sql_statistic.'), 'et_ms_per_exec')) AS cs_sql_statistic FROM DUAL
/
--
PRO
PRO 4. SQL Type: [{null}|TP|RO|BG|IG|UN|SYS|TP,RO|TP,RO,BG] 
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
COL cs_filter_1 NEW_V cs_filter_1 NOPRI;
SELECT CASE WHEN LENGTH('&&cs_sql_id.') = 13 THEN 'sql_id = ''&&cs_sql_id.''' ELSE '1 = 1' END AS cs_filter_1 FROM DUAL
/
--
PRO
PRO 7. Include SYS: [{N}|Y]
DEF cs_include_sys = '&7.';
UNDEF 7;
COL cs_include_sys NEW_V cs_include_sys NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_include_sys.')) IN ('Y', 'N') THEN UPPER(TRIM('&&cs_include_sys.')) ELSE 'N' END AS cs_include_sys FROM DUAL
/
--
PRO
PRO 8. Graph Type: [{Scatter}|Line|SteppedArea|Area] note: SteppedArea and Area are stacked 
DEF graph_type = '&8.';
UNDEF 8;
COL cs_graph_type NEW_V cs_graph_type NOPRI;
SELECT CASE WHEN '&&graph_type.' IN ('SteppedArea', 'Line', 'Area', 'Scatter') THEN '&&graph_type.' ELSE 'Scatter' END AS cs_graph_type FROM DUAL
/
--
DEF spool_id_chart_footer_script = 'cs_sqlstat_analytics_footer.sql';
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
DEF data_points_01 = '            ';
DEF data_points_02 = '            ';
DEF data_points_03 = '            ';
DEF data_points_04 = '            ';
DEF data_points_05 = '            ';
DEF data_points_06 = '            ';
DEF data_points_07 = '            ';
DEF data_points_08 = '            ';
DEF data_points_09 = '            ';
DEF data_points_10 = '            ';
DEF data_points_11 = '            ';
DEF data_points_12 = '            ';
DEF data_points_13 = '            ';
--
COL data_points_01 NEW_V data_points_01 TRUNC NOPRI;
COL data_points_02 NEW_V data_points_02 TRUNC NOPRI;
COL data_points_03 NEW_V data_points_03 TRUNC NOPRI;
COL data_points_04 NEW_V data_points_04 TRUNC NOPRI;
COL data_points_05 NEW_V data_points_05 TRUNC NOPRI;
COL data_points_06 NEW_V data_points_06 TRUNC NOPRI;
COL data_points_07 NEW_V data_points_07 TRUNC NOPRI;
COL data_points_08 NEW_V data_points_08 TRUNC NOPRI;
COL data_points_09 NEW_V data_points_09 TRUNC NOPRI;
COL data_points_10 NEW_V data_points_10 TRUNC NOPRI;
COL data_points_11 NEW_V data_points_11 TRUNC NOPRI;
COL data_points_12 NEW_V data_points_12 TRUNC NOPRI;
COL data_points_13 NEW_V data_points_13 TRUNC NOPRI;
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
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
/****************************************************************************************/
WITH 
FUNCTION /* cs_sqlstat_analytics 1 */ get_pdb_name (p_con_id IN VARCHAR2)
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
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := CHR(37)||'/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'Set ddl lock timeout for session'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getForUpdate.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Drop partition'||k_appl_handle_suffix 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getPriorWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeaseTypes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getHistoricalAssignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAllWorkflowDefinitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getVersionHistory'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find interval partitions for schema'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getStepInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getOldestGcWorkflowInstance'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextRecordID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseNonce'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getByKey.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRecordId.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if there are active rows for partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRunningInstancesCount'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLatestWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.step_instances'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorks'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMinorVersionsAtAndAfter'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseDecorators'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeasesByFiFo'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
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
sqltext_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqltext_mv) */ 
       dbid,
       con_id,
       sql_id,
       get_sql_hv(sql_text) AS sqlid,
       application_category(DBMS_LOB.substr(sql_text, 1000), 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
       REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 1000), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text,
       sql_text AS sql_fulltext
  FROM dba_hist_sqltext
 WHERE dbid = TO_NUMBER('&&cs_dbid.') 
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%')
  --  AND ('&&cs_sql_id.' IS NULL OR sql_id = TRIM('&&cs_sql_id.'))
   AND &&cs_filter_1.
   AND ROWNUM >= 1
),
/****************************************************************************************/
snapshot_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(snapshot_mv) */ 
       s.*
  FROM dba_hist_snapshot s
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.') 
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.') 
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND s.end_interval_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND s.end_interval_time <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1
),
/****************************************************************************************/
sqlstats_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqlstats_mv) */ 
       s.*
  FROM dba_hist_sqlstat s
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.') 
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.') 
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
  --  AND ('&&cs_sql_id.' IS NULL OR s.sql_id = TRIM('&&cs_sql_id.'))
   AND &&cs_filter_1.
   AND ('&&cs_include_sys.' = 'Y' OR s.parsing_user_id > 0)
   AND s.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
   AND ROWNUM >= 1
),
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
       CASE s.parsing_schema_name WHEN 'SYS' THEN 'SYS' ELSE x.sql_type END AS sql_type, 
       x.sqlid,
       x.sql_text,
       x.sql_fulltext,
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
  FROM snapshot_mv t,
       sqlstats_mv s,
       sqltext_mv x
 WHERE s.snap_id = t.snap_id
   AND s.dbid = t.dbid
   AND s.instance_number = t.instance_number
   AND x.dbid = s.dbid
   AND x.sql_id = s.sql_id
   AND x.con_id = s.con_id
),
/****************************************************************************************/
sqlstats_metrics AS (
SELECT MIN(d.begin_timestamp) AS begin_timestamp,
       MAX(d.end_timestamp) AS end_timestamp,
       SUM(d.seconds) AS seconds,
       COUNT(*) AS data_points,
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
       SUM(d.delta_physical_read_bytes)/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_r,
       SUM(d.delta_physical_write_bytes)/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_w,
       (SUM(d.delta_physical_read_bytes)+SUM(d.delta_physical_write_bytes))/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_rw,
       SUM(d.delta_physical_read_requests)/NULLIF(SUM(d.seconds),0) AS iops_r,
       SUM(d.delta_physical_write_requests)/NULLIF(SUM(d.seconds),0) AS iops_w,
       (SUM(d.delta_physical_read_requests)+SUM(d.delta_physical_write_requests))/NULLIF(SUM(d.seconds),0) AS iops_rw,
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
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
      --  d.parsing_schema_name,
       d.module,
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
       SUM(d.delta_physical_read_bytes)/1e6 AS delta_physical_read_mp,
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
       MAX(d.sharable_mem)/1e6 AS sharable_mem_mb,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE d.seconds > 1 -- avoid snaps less than 1 sec appart
   AND ('&&cs_sql_type.' IS NULL OR INSTR('&&cs_sql_type.', d.sql_type) > 0)
 GROUP BY
       d.con_id,
       d.sqlid,
       d.sql_id,
      --  d.force_matching_signature,
      --  d.sql_profile,
      --  d.instance_number,
      --  d.parsing_schema_name,
       d.module,
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
      --  m.force_matching_signature,
      --  m.sql_profile,
      --  m.instance_number,
      --  m.parsing_schema_name,
       SUBSTR(m.module, 1, 32) AS module,
      --  m.action,
       m.plan_hash_value,
       m.sql_type,
       SUBSTR(m.sql_text, 1, 60) AS sql_text,
       m.&&cs_sql_statistic. AS value,
       ROW_NUMBER() OVER (ORDER BY m.&&cs_sql_statistic. DESC NULLS LAST) AS rn,
       m.data_points
  FROM sqlstats_metrics m
 WHERE NVL(m.&&cs_sql_statistic., 0) >= 0 -- negative values are possible but unwanted
),
/****************************************************************************************/
list AS (
SELECT con_id,
       pdb_name,
       sqlid,
       sql_id,
      --  force_matching_signature,
      --  sql_profile,
      --  instance_number,
      --  parsing_schema_name,
       module,
      --  action,
       plan_hash_value,
       sql_type,
       sql_text,
       value,
       rn,
       data_points
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
       MAX(CASE rn WHEN 01 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_01,
       MAX(CASE rn WHEN 02 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_02,
       MAX(CASE rn WHEN 03 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_03,
       MAX(CASE rn WHEN 04 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_04,
       MAX(CASE rn WHEN 05 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_05,
       MAX(CASE rn WHEN 06 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_06,
       MAX(CASE rn WHEN 07 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_07,
       MAX(CASE rn WHEN 08 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_08,
       MAX(CASE rn WHEN 09 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_09,
       MAX(CASE rn WHEN 10 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_10,
       MAX(CASE rn WHEN 11 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_11,
       MAX(CASE rn WHEN 12 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_12,
       MAX(CASE rn WHEN 13 THEN LPAD(TO_CHAR(data_points, 'fm999,999,990'), 12, ' ') ELSE LPAD(' ', 12, ' ') END) AS data_points_13,
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
       MAX(CASE rn WHEN 13 THEN RPAD(sql_text, 60, ' ') ELSE RPAD(' ', 60, ' ') END) AS sql_text_13,
       MAX(CASE rn WHEN 01 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_01,
       MAX(CASE rn WHEN 02 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_02,
       MAX(CASE rn WHEN 03 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_03,
       MAX(CASE rn WHEN 04 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_04,
       MAX(CASE rn WHEN 05 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_05,
       MAX(CASE rn WHEN 06 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_06,
       MAX(CASE rn WHEN 07 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_07,
       MAX(CASE rn WHEN 08 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_08,
       MAX(CASE rn WHEN 09 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_09,
       MAX(CASE rn WHEN 10 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_10,
       MAX(CASE rn WHEN 11 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_11,
       MAX(CASE rn WHEN 12 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_12,
       MAX(CASE rn WHEN 13 THEN RPAD(module, 32, ' ') ELSE RPAD(' ', 32, ' ') END) AS module_13
  FROM list
/
/****************************************************************************************/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_statistic.'||NVL2('&&cs_sql_id.', '_&&cs_sql_id.', NULL) AS cs_file_name FROM DUAL;
--
DEF report_title = 'Top SQL by average "&&cs_sql_statistic." between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = '&&cs_sql_statistic.';
DEF xaxis_title = '';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
'&&cs_rgn. &&cs_locale. &&cs_con_name. sys:&&cs_include_sys.'||
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_statistic." "&&cs_sql_type." "&&cs2_sql_text_piece." "&&cs_sql_id." "&&cs_include_sys." "&&cs_graph_type."';
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
FUNCTION /* cs_sqlstat_analytics 2 */ num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
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
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2 
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := CHR(37)||'/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'Set ddl lock timeout for session'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getForUpdate.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Drop partition'||k_appl_handle_suffix 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getPriorWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeaseTypes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getHistoricalAssignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAllWorkflowDefinitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getVersionHistory'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find interval partitions for schema'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getStepInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getOldestGcWorkflowInstance'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextRecordID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseNonce'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getByKey.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRecordId.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if there are active rows for partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRunningInstancesCount'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLatestWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.step_instances'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorks'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMinorVersionsAtAndAfter'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseDecorators'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeasesByFiFo'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
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
sqltext_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqltext_mv) */ 
       dbid,
       con_id,
       sql_id,
       get_sql_hv(sql_text) AS sqlid,
       application_category(DBMS_LOB.substr(sql_text, 1000), 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
       REPLACE(REPLACE(DBMS_LOB.substr(sql_text, 1000), CHR(10), CHR(32)), CHR(9), CHR(32)) AS sql_text,
       sql_text AS sql_fulltext
  FROM dba_hist_sqltext
 WHERE dbid = TO_NUMBER('&&cs_dbid.') 
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%')
   AND ('&&cs_sql_id.' IS NULL OR sql_id = TRIM('&&cs_sql_id.'))
  --  AND &&cs_filter_1. -- for some reason it performs poorly when used on this query... it needs further investigation!
   AND sql_id IN 
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
   AND ROWNUM >= 1
),
/****************************************************************************************/
snapshot_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(snapshot_mv) */ 
       s.*
  FROM dba_hist_snapshot s
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.') 
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.') 
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND s.end_interval_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND s.end_interval_time <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1
),
/****************************************************************************************/
sqlstats_mv AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqlstats_mv) */ 
       s.*
  FROM dba_hist_sqlstat s
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.') 
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.') 
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.') + 1
   AND ('&&cs_sql_id.' IS NULL OR s.sql_id = TRIM('&&cs_sql_id.'))
   AND s.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
  --  AND &&cs_filter_1. -- for some reason it performs poorly when used on this query... it needs further investigation!
  --  AND ('&&cs_include_sys.' = 'Y' OR s.parsing_user_id > 0) -- not needed here since other filters (below) already considered this
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
   AND ROWNUM >= 1
),
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
       CASE s.parsing_schema_name WHEN 'SYS' THEN 'SYS' ELSE x.sql_type END AS sql_type, 
       x.sqlid,
       x.sql_text,
       x.sql_fulltext,
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
  FROM snapshot_mv t,
       sqlstats_mv s,
       sqltext_mv x
 WHERE s.snap_id = t.snap_id
   AND s.dbid = t.dbid
   AND s.instance_number = t.instance_number
   AND x.dbid = s.dbid
   AND x.sql_id = s.sql_id
   AND x.con_id = s.con_id
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
       SUM(d.delta_physical_read_bytes)/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_r,
       SUM(d.delta_physical_write_bytes)/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_w,
       (SUM(d.delta_physical_read_bytes)+SUM(d.delta_physical_write_bytes))/POWER(10,6)/NULLIF(SUM(d.seconds),0) AS mbps_rw,
       SUM(d.delta_physical_read_requests)/NULLIF(SUM(d.seconds),0) AS iops_r,
       SUM(d.delta_physical_write_requests)/NULLIF(SUM(d.seconds),0) AS iops_w,
       (SUM(d.delta_physical_read_requests)+SUM(d.delta_physical_write_requests))/NULLIF(SUM(d.seconds),0) AS iops_rw,
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
       MAX(d.sharable_mem)/1e6 AS sharable_mem_mb,
       SUM(d.obsolete_count) AS obsolete_count
  FROM sqlstats_deltas d
 WHERE d.seconds > 1 -- avoid snaps less than 1 sec appart
   AND ('&&cs_sql_type.' IS NULL OR INSTR('&&cs_sql_type.', d.sql_type) > 0)
 GROUP BY
       d.begin_timestamp,
       d.end_timestamp,
       d.con_id,
       d.sqlid,
       d.sql_id,
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
DEF cs_chart_type = '&&cs_graph_type.';
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
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--