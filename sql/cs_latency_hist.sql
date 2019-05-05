----------------------------------------------------------------------------------------
--
-- File name:   cs_latency_hist.sql
--
-- Purpose:     SQL latency (elapsed time over executions)
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/21
--
-- Usage:       Execute connected to PDB or CDB
--
--              Enter optional filter parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_latency_hist.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_latency_hist';
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 1. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&1.';
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 2. SQL Text piece (optional):
DEF sql_text_piece = '&2.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope is further reduced
PRO
PRO 3. SQL_ID (optional):
DEF cs_sql_id = '&3.';
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_TYPE     : "&&kiev_tx." [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG]
PRO SQL_TEXT     : "&&sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
--
COL sql_rank_nopri NOPRI;
COL plan_hash_value HEA 'Plan|Hash Value';
COL latency_ms_since_last_awr FOR 9,999,990.000 HEA 'Latency (ms)|since|last AWR';
COL latency_ms_on_last_awr FOR 9,999,990.000 HEA 'Latency (ms)|during|last AWR';
COL latency_ms_on_last_1h FOR 9,999,990.000 HEA 'Latency (ms)|during|last 1h';
COL latency_ms_on_mem FOR 9,999,990.000 HEA 'Latency (ms)|as per|V$SQL';
COL latency_ms_on_last_1d FOR 9,999,990.000 HEA 'Latency (ms)|during|last 1d';
COL latency_ms_on_last_7d FOR 9,999,990.000 HEA 'Latency (ms)|during|last 7d';
COL latency_ms_on_last_30d FOR 9,999,990.000 HEA 'Latency (ms)|during|last 30d';
COL latency_ms_on_awr FOR 9,999,990.000 HEA 'Latency (ms)|as per AWR|whole hist';
COL latency_ms_on_spb FOR 9,999,990.000 HEA 'Latency (ms)|SQL Plan|Baseline';
COL execs_since_last_awr FOR 9,999,999,990 HEA 'Executions|since|last AWR';
COL execs_on_last_awr FOR 9,999,999,990 HEA 'Executions|during|last AWR';
COL execs_on_last_1h FOR 9,999,999,990 HEA 'Executions|during|last 1h';
COL execs_on_mem FOR 9,999,999,990 HEA 'Executions|as per|V$SQL';
COL execs_on_last_1d FOR 9,999,999,990 HEA 'Executions|during|last 1d';
COL execs_on_last_7d FOR 9,999,999,990 HEA 'Executions|during|last 7d';
COL execs_on_last_30d FOR 9,999,999,990 HEA 'Executions|during|last 30d';
COL execs_on_awr FOR 9,999,999,990 HEA 'Executions|as per AWR|whole hist';
COL execs_on_spb FOR 9,999,999,990 HEA 'Executions|SQL Plan|Baseline';
COL created_spb FOR A19 HEA 'SQL Plan|Baseline|Created';
COL pdb_or_schema_name FOR A35 HEA 'PDB or Schema Name' TRUNC;
COL sql_type FOR A4 HEA 'SQL|Type';
COL sql_text FOR A100 HEA 'SQL Text' TRUNC;
COL signature FOR 99999999999999999999 HEA 'Signature';
COL plan_name HEA 'Plan Name';
--
BREAK ON sql_rank_nopri SKIP 1;
--
PRO
PRO SQL Latency
PRO ~~~~~~~~~~~
WITH
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
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
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
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
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
baselines AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       signature,
       plan_name,
       --
       CAST(created AS DATE) created,
       elapsed_time,
       executions
  FROM cdb_sql_plan_baselines
 WHERE ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.substr(sql_text, 1000))||CHR(37))
),
stats_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       exact_matching_signature signature,
       --
       sql_text,
       application_category(sql_text) sql_type,
       --
       elapsed_time,
       executions,
       delta_elapsed_time,
       delta_execution_count,
       --
       ROW_NUMBER () OVER (ORDER BY elapsed_time/GREATEST(executions,1) DESC NULLS LAST) stats_all_rank,
       ROW_NUMBER () OVER (ORDER BY delta_elapsed_time/GREATEST(delta_execution_count,1) DESC NULLS LAST) stats_awr_rank
  FROM v$sqlstats
 WHERE ('&&sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(sql_text)||CHR(37))
),
mem_plan_schema AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       exact_matching_signature signature,
       sql_plan_baseline plan_name,
       plan_hash_value,
       parsing_schema_name,
       --
       SUM(CASE WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN elapsed_time ELSE 0 END) elapsed_time_mem,
       SUM(CASE WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN executions ELSE 0 END) executions_mem,
       --
       ROW_NUMBER () OVER (ORDER BY SUM(CASE WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN elapsed_time ELSE 0 END)/GREATEST(SUM(CASE WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN executions ELSE 0 END),1) DESC NULLS LAST) mem_all_rank_p
  FROM v$sql
 WHERE ('&&sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(sql_text)||CHR(37))
   AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
 GROUP BY
       con_id,
       sql_id,
       exact_matching_signature,
       sql_plan_baseline,
       plan_hash_value,
       parsing_schema_name
),
mem_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       signature,
       MIN(plan_name) min_plan_name,
       MAX(plan_name) max_plan_name,
       MIN(plan_hash_value) min_plan_hash_value,
       MAX(plan_hash_value) max_plan_hash_value,
       --
       SUM(elapsed_time_mem) elapsed_time_mem,
       SUM(executions_mem) executions_mem,
       --
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_mem)/GREATEST(SUM(executions_mem),1) DESC NULLS LAST) mem_all_rank
  FROM mem_plan_schema
 GROUP BY
       con_id,
       sql_id,
       signature
),
awr_plan_schema AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       h.plan_hash_value,
       h.parsing_schema_name,
       --
       SUM(CASE WHEN h.snap_id = &&cs_max_snap_id. THEN h.elapsed_time_delta ELSE 0 END) elapsed_time_15m,
       SUM(CASE WHEN h.snap_id = &&cs_max_snap_id. THEN h.executions_delta ELSE 0 END) executions_15m,
       SUM(CASE WHEN h.snap_id >= &&cs_1h_snap_id. THEN h.elapsed_time_delta ELSE 0 END) elapsed_time_1h,
       SUM(CASE WHEN h.snap_id >= &&cs_1h_snap_id. THEN h.executions_delta ELSE 0 END) executions_1h,
       SUM(CASE WHEN h.snap_id >= &&cs_1d_snap_id. THEN h.elapsed_time_delta ELSE 0 END) elapsed_time_1d,
       SUM(CASE WHEN h.snap_id >= &&cs_1d_snap_id. THEN h.executions_delta ELSE 0 END) executions_1d,
       SUM(CASE WHEN h.snap_id >= &&cs_7d_snap_id. THEN h.elapsed_time_delta ELSE 0 END) elapsed_time_7d,
       SUM(CASE WHEN h.snap_id >= &&cs_7d_snap_id. THEN h.executions_delta ELSE 0 END) executions_7d,
       SUM(CASE WHEN h.snap_id >= &&cs_30d_snap_id. THEN h.elapsed_time_delta ELSE 0 END) elapsed_time_30d,
       SUM(CASE WHEN h.snap_id >= &&cs_30d_snap_id. THEN h.executions_delta ELSE 0 END) executions_30d,
       SUM(h.elapsed_time_delta) elapsed_time_total,
       SUM(h.executions_delta) executions_total
  FROM dba_hist_sqlstat h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND EXISTS
       (SELECT NULL
          FROM mem_plan_schema m
         WHERE m.con_id = h.con_id
           AND m.sql_id = h.sql_id
           AND m.plan_hash_value = h.plan_hash_value
           AND m.parsing_schema_name = h.parsing_schema_name)
 GROUP BY
       h.con_id,
       h.sql_id,
       h.plan_hash_value,
       h.parsing_schema_name
),
awr_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       MIN(plan_hash_value) min_plan_hash_value,
       MAX(plan_hash_value) max_plan_hash_value,
       --
       SUM(elapsed_time_15m) elapsed_time_15m,
       SUM(executions_15m) executions_15m,
       SUM(elapsed_time_1h) elapsed_time_1h,
       SUM(executions_1h) executions_1h,
       SUM(elapsed_time_1d) elapsed_time_1d,
       SUM(executions_1d) executions_1d,
       SUM(elapsed_time_7d) elapsed_time_7d,
       SUM(executions_7d) executions_7d,
       SUM(elapsed_time_30d) elapsed_time_30d,
       SUM(executions_30d) executions_30d,
       SUM(elapsed_time_total) elapsed_time_total,
       SUM(executions_total) executions_total,
       --
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_15m)/GREATEST(SUM(executions_15m),1) DESC NULLS LAST) awr_15m_rank,
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_1h)/GREATEST(SUM(executions_1h),1) DESC NULLS LAST) awr_1h_rank,
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_1d)/GREATEST(SUM(executions_1d),1) DESC NULLS LAST) awr_1d_rank,
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_7d)/GREATEST(SUM(executions_7d),1) DESC NULLS LAST) awr_7d_rank,
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_30d)/GREATEST(SUM(executions_30d),1) DESC NULLS LAST) awr_30d_rank,
       ROW_NUMBER () OVER (ORDER BY SUM(elapsed_time_total)/GREATEST(SUM(executions_total),1) DESC NULLS LAST) awr_total_rank
  FROM awr_plan_schema
 GROUP BY
       con_id,
       sql_id
),
grp_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
       s.sql_id,
       s.signature,
       m.min_plan_name,
       m.max_plan_name,
       m.min_plan_hash_value,
       m.max_plan_hash_value,
       --
       s.sql_text,
       s.sql_type,
       --
       s.delta_elapsed_time,
       s.delta_execution_count,
       a.elapsed_time_15m,
       a.executions_15m,
       a.elapsed_time_1h,
       a.executions_1h,
       s.elapsed_time,
       s.executions,
       m.elapsed_time_mem,
       m.executions_mem,
       a.elapsed_time_1d,
       a.executions_1d,
       a.elapsed_time_7d,
       a.executions_7d,
       a.elapsed_time_30d,
       a.executions_30d,
       a.elapsed_time_total,
       a.executions_total,
       --
       s.stats_awr_rank sql_rank_1,
       a.awr_15m_rank sql_rank_2,
       a.awr_1h_rank sql_rank_3,
       (s.stats_all_rank + m.mem_all_rank) sql_rank_4,
       (a.awr_1d_rank + a.awr_7d_rank + a.awr_30d_rank + a.awr_total_rank) sql_rank_5,
       --
       (SELECT COUNT(*)
          FROM mem_plan_schema p
         WHERE p.con_id = s.con_id
           AND p.sql_id = s.sql_id) plans_count
  FROM stats_sql s,
       mem_sql m,
       awr_sql a
 WHERE m.con_id = s.con_id
   AND m.sql_id = s.sql_id
   AND m.signature = s.signature
   AND a.con_id(+) = m.con_id
   AND a.sql_id(+) = m.sql_id
),
grp_pln AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
       s.sql_id,
       s.signature,
       m.plan_name,
       m.plan_hash_value,
       m.parsing_schema_name,
       --
       s.sql_text,
       s.sql_type,
       --
       s.delta_elapsed_time,
       s.delta_execution_count,
       a.elapsed_time_15m,
       a.executions_15m,
       a.elapsed_time_1h,
       a.executions_1h,
       s.elapsed_time,
       s.executions,
       m.elapsed_time_mem,
       m.executions_mem,
       a.elapsed_time_1d,
       a.executions_1d,
       a.elapsed_time_7d,
       a.executions_7d,
       a.elapsed_time_30d,
       a.executions_30d,
       a.elapsed_time_total,
       a.executions_total,
       b.elapsed_time elapsed_time_spb,
       b.executions executions_spb,
       b.created created_spb,
       --
       s.sql_rank_1,
       s.sql_rank_2,
       s.sql_rank_3,
       s.sql_rank_4,
       s.sql_rank_5,
       --
       ROW_NUMBER () OVER (ORDER BY a.elapsed_time_15m/GREATEST(a.executions_15m,1) DESC NULLS LAST) pln_rank_1,
       ROW_NUMBER () OVER (ORDER BY a.elapsed_time_1h/GREATEST(a.executions_1h,1) DESC NULLS LAST) pln_rank_2,
       m.mem_all_rank_p pln_rank_3,
       --
       s.plans_count
  FROM grp_sql s,
       mem_plan_schema m,
       awr_plan_schema a,
       baselines b
 WHERE m.con_id = s.con_id
   AND m.sql_id = s.sql_id
   AND m.signature = s.signature
   AND a.con_id(+) = m.con_id
   AND a.sql_id(+) = m.sql_id
   AND a.plan_hash_value(+) = m.plan_hash_value
   AND a.parsing_schema_name(+) = m.parsing_schema_name
   AND b.con_id(+) = m.con_id
   AND b.signature(+) = m.signature
   AND b.plan_name(+) = m.plan_name
),
grp_all AS (
SELECT /*+ MATERIALIZE NO_MERGE */ -- PDB level
       s.con_id,
       s.sql_id,
       s.signature,
       CASE s.plans_count WHEN 1 THEN s.min_plan_name ELSE TO_NUMBER(NULL) END plan_name,
       CASE s.plans_count WHEN 1 THEN s.min_plan_hash_value ELSE TO_NUMBER(NULL) END plan_hash_value,
       NULL parsing_schema_name,
       'PDB:'||c.name pdb_name,
       --
       s.sql_text,
       s.sql_type,
       'S' grp_type,
       --
       s.delta_elapsed_time,
       s.delta_execution_count,
       s.elapsed_time_15m,
       s.executions_15m,
       s.elapsed_time_1h,
       s.executions_1h,
       s.elapsed_time,
       s.executions,
       s.elapsed_time_mem,
       s.executions_mem,
       s.elapsed_time_1d,
       s.executions_1d,
       s.elapsed_time_7d,
       s.executions_7d,
       s.elapsed_time_30d,
       s.executions_30d,
       s.elapsed_time_total,
       s.executions_total,
       CASE s.plans_count WHEN 1 THEN b.elapsed_time ELSE TO_NUMBER(NULL) END elapsed_time_spb,
       CASE s.plans_count WHEN 1 THEN b.executions ELSE TO_NUMBER(NULL) END executions_spb,
       CASE s.plans_count WHEN 1 THEN b.created ELSE TO_DATE(NULL) END created_spb,
       --
       s.sql_rank_1,
       s.sql_rank_2,
       s.sql_rank_3,
       s.sql_rank_4,
       s.sql_rank_5,
       --
       TO_NUMBER(NULL) pln_rank_1,
       TO_NUMBER(NULL) pln_rank_2,
       TO_NUMBER(NULL) pln_rank_3
  FROM grp_sql s,
       v$containers c,
       baselines b
 WHERE c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   AND b.con_id(+) = s.con_id
   AND b.signature(+) = s.signature
   AND b.plan_name(+) = s.min_plan_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ -- plan level
       TO_NUMBER(NULL) con_id,
       NULL sql_id,
       p.signature,
       p.plan_name,
       p.plan_hash_value,
       'SCH:'||p.parsing_schema_name parsing_schema_name,
       NULL pdb_name,
       --
       NULL sql_text,
       NULL sql_type,
       'P' grp_type,
       --
       TO_NUMBER(NULL) delta_elapsed_time,
       TO_NUMBER(NULL) delta_execution_count,
       p.elapsed_time_15m,
       p.executions_15m,
       p.elapsed_time_1h,
       p.executions_1h,
       TO_NUMBER(NULL) elapsed_time,
       TO_NUMBER(NULL) executions,
       p.elapsed_time_mem,
       p.executions_mem,
       p.elapsed_time_1d,
       p.executions_1d,
       p.elapsed_time_7d,
       p.executions_7d,
       p.elapsed_time_30d,
       p.executions_30d,
       p.elapsed_time_total,
       p.executions_total,
       p.elapsed_time_spb,
       p.executions_spb,
       p.created_spb,
       --
       p.sql_rank_1,
       p.sql_rank_2,
       p.sql_rank_3,
       p.sql_rank_4,
       p.sql_rank_5,
       --
       p.pln_rank_1,
       p.pln_rank_2,
       p.pln_rank_3
  FROM grp_pln p
 WHERE p.plans_count > 1
)
SELECT s.sql_rank_1||' '||s.sql_rank_2||' '||s.sql_rank_3||' '||s.sql_rank_4||' '||s.sql_rank_5 sql_rank_nopri,
       --
       s.sql_id,
       s.plan_hash_value,
--       s.signature,
--       s.plan_name,
       --
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 latency_ms_since_last_awr,
       s.elapsed_time_15m/GREATEST(s.executions_15m,1)/1e3 latency_ms_on_last_awr,
       s.elapsed_time_1h/GREATEST(s.executions_1h,1)/1e3 latency_ms_on_last_1h,
       s.elapsed_time_mem/GREATEST(s.executions_mem,1)/1e3 latency_ms_on_mem,
       s.elapsed_time_1d/GREATEST(s.executions_1d,1)/1e3 latency_ms_on_last_1d,
       s.elapsed_time_7d/GREATEST(s.executions_7d,1)/1e3 latency_ms_on_last_7d,
       s.elapsed_time_30d/GREATEST(s.executions_30d,1)/1e3 latency_ms_on_last_30d,
       s.elapsed_time_total/GREATEST(s.executions_total,1)/1e3 latency_ms_on_awr,
       s.elapsed_time_spb/GREATEST(s.executions_spb,1)/1e3 latency_ms_on_spb,
       --
       s.delta_execution_count execs_since_last_awr,
       s.executions_15m execs_on_last_awr,
       s.executions_1h execs_on_last_1h,
       s.executions_mem execs_on_mem,
       s.executions_1d execs_on_last_1d,
       s.executions_7d execs_on_last_7d,
       s.executions_30d execs_on_last_30d,
       s.executions_total execs_on_awr,
       s.executions_spb execs_on_spb,
       s.created_spb,
       --
       COALESCE(s.pdb_name, s.parsing_schema_name) pdb_or_schema_name,
       s.sql_type,
       s.sql_text
  FROM grp_all s
 ORDER BY
       s.sql_rank_1,
       s.sql_rank_2,
       s.sql_rank_3,
       s.sql_rank_4,
       s.sql_rank_5,
       s.grp_type DESC,
       s.pln_rank_1,
       s.pln_rank_2,
       s.pln_rank_3
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--