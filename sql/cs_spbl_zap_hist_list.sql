----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_zap_hist_list.sql
--
-- Purpose:     SQL Plan Baseline - Zapper History List
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/18
--
-- Usage:       Execute connected to PDB.
--
--              Enter range of dates and SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_hist_list.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_zap_hist_list';
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
--   
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
--
PRO
PRO 4. Include NULL actions?: [{Y}|N] 
DEF cs_null = '&4.';
COL cs_null NEW_V cs_null;
SELECT NVL(UPPER(TRIM('&&cs_null.')),'Y') cs_null FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_null." 
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. 
PRO TIME_TO      : &&cs_sample_time_to. 
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO INCLUDE_NULL : "&&cs_null." [{Y}|N]
--
COL snap_id FOR 99999 HEA 'RUNID';
COL zapper_aggressiveness FOR 99999 HEA 'LEVEL';
COL zapper_action HEA 'ACTION';
COL plan_hash_value FOR 9999999999 HEA 'PLAN_HASH';
COL pdb_name FOR A35;
COL snap_time HEA 'ZAPPER_TIME';
COL parsing_schema_name FOR A30;
COL spb_enabled HEA 'ENA';
COL spb_accepted HEA 'ACC';
COL spb_fixed HEA 'FIX';
COL executions FOR 999,999,999,990;
COL et_ms_per_exec FOR 999,999,990.000 HEA 'ET_MS|PER_EXEC';
COL cpu_ms_per_exec FOR 999,999,990.000 HEA 'CPU_MS|PER_EXEC';
COL buffer_gets_per_exec FOR 999,999,990.0 HEA 'BUFFER_GETS|PER_EXEC';
COL disk_reads_per_exec FOR 999,999,990.0 HEA 'DISK_READS|PER_EXEC';
COL rows_processed_per_exec FOR 999,999,990.0 HEA 'ROWS_PROCESSED|PER_EXEC';
COL spb_description FOR A166;
COL zapper_message FOR A166;
--
BREAK ON snap_id SKIP PAGE ON zapper_aggressiveness ON pdb_name;
--
PRO
PRO Performance
PRO ~~~~~~~~~~~
SELECT snap_id,
       zapper_aggressiveness,
       pdb_name||'('||con_id||')' pdb_name,
       snap_time,
       parsing_schema_name,
       plan_hash_value,
       zapper_action,
       src,
       executions,
       elapsed_time / GREATEST(1, executions) / 1e3 et_ms_per_exec,
       cpu_time / GREATEST(1, executions) / 1e3 cpu_ms_per_exec,
       buffer_gets / GREATEST(1, executions) buffer_gets_per_exec,
       disk_reads / GREATEST(1, executions) disk_reads_per_exec,
       rows_processed / GREATEST(1, executions) rows_processed_per_exec
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
   AND (zapper_action <> 'NULL' OR '&&cs_null.' = 'Y')
 ORDER BY
       snap_id,
       zapper_aggressiveness,
       pdb_name,
       snap_time
/
PRO
PRO Baseline
PRO ~~~~~~~~
SELECT snap_id,
       zapper_aggressiveness,
       pdb_name||'('||con_id||')' pdb_name,
       snap_time,
       parsing_schema_name,
       plan_hash_value,
       zapper_action,
       src,
       spb_plan_name,
       spb_created,
       spb_last_modified,
       spb_enabled,
       spb_accepted,
       spb_fixed
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
   AND (zapper_action <> 'NULL' OR '&&cs_null.' = 'Y')
   AND spb_plan_name IS NOT NULL
 ORDER BY
       snap_id,
       zapper_aggressiveness,
       pdb_name,
       snap_time
/
PRO
PRO Description
PRO ~~~~~~~~~~~
SET RECSEP OFF;
SELECT snap_id,
       zapper_aggressiveness,
       pdb_name||'('||con_id||')' pdb_name,
       snap_time,
       parsing_schema_name,
       plan_hash_value,
       zapper_action,
       src,
       spb_plan_name,
       spb_description
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
   AND (zapper_action <> 'NULL' OR '&&cs_null.' = 'Y')
   AND spb_description IS NOT NULL
 ORDER BY
       snap_id,
       zapper_aggressiveness,
       pdb_name,
       snap_time
/
PRO
PRO Message
PRO ~~~~~~~
SELECT snap_id,
       zapper_aggressiveness,
       pdb_name||'('||con_id||')' pdb_name,
       snap_time,
       parsing_schema_name,
       plan_hash_value,
       zapper_action,
       src,
       spb_plan_name,
       zapper_message1||
       CASE WHEN zapper_message2 IS NOT NULL THEN CHR(10)||zapper_message2 END||
       CASE WHEN zapper_message3 IS NOT NULL THEN CHR(10)||zapper_message3 END
       zapper_message
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
   AND (zapper_action <> 'NULL' OR '&&cs_null.' = 'Y')
   AND zapper_message1||zapper_message2||zapper_message3 IS NOT NULL
 ORDER BY
       snap_id,
       zapper_aggressiveness,
       pdb_name,
       snap_time
/
SET RECSEP WR;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_null." 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--