COL log_time FOR A23 TRUNC;
COL plan_hash_value FOR 9999999999 HEA 'PHV';
COL is_cursor_mature FOR A6 HEA 'IS CUR|MATURE';
COL is_cursor_active FOR A6 HEA 'IS CUR|ACTIVE';
COL parsing_user_id FOR 9999990 HEA 'PARSING|USER_ID';
COL parsing_schema_id FOR 9999990 HEA 'PARSING|SCHEMA';
COL parsing_schema_name FOR A30 TRUNC;
COL table_rows FOR 999,999,999,990;
COL table_block FOR 999,999,990 HEA 'TABLE_BLOCKS';
COL aas_on_cpu FOR 990.000 HEA 'AWR AAS|ON CPU';
COL plan_name FOR A30 TRUNC;
COL baseline_repro_fail FOR 990 HEA 'REPRO|FAIL'; 
COL profile_name FOR A30 TRUNC;
COL patch_name FOR A30 TRUNC;
COL cur_executions FOR 999,999,990 HEA 'CURSOR|EXECUTIONS';
COL cur_cpu_time FOR 9,999,999,999,990 HEA 'CURSOR|CPU TIME';
COL cur_rows_processed FOR 9,999,999,990 HEA 'CURSOR|ROWS PROC';
COL cur_buffer_gets FOR 999,999,990,990 HEA 'CURSOR|BUFFER GETS';
COL awr_executions FOR 999,999,990 HEA 'DELTA AWR|EXECUTIONS';
COL awr_cpu_time FOR 9,999,999,999,990 HEA 'DELTA AWR|CPU TIME';
COL awr_rows_processed FOR 9,999,999,990 HEA 'DELTA AWR|ROWS PROC';
COL awr_buffer_gets FOR 999,999,990,990 HEA 'DELTA AWR|BUFFER GETS';
COL spb_executions FOR 999,999,990 HEA 'BASELINE|EXECUTIONS';
COL spb_cpu_time FOR 9,999,999,999,990 HEA 'BASELINE|CPU TIME';
COL spb_rows_processed FOR 9,999,999,990 HEA 'BASELINE|ROWS PROC';
COL spb_buffer_gets FOR 999,999,990,990 HEA 'BASELINE|BUFFER GETS';
COL action_and_result FOR A30 HEA 'ACTION: RESULT';
COL pdb_name FOR A30 TRUNC;
--
SELECT log_time,
       sql_id,
       plan_hash_value,
       is_cursor_mature,
       is_cursor_active,
      --  parsing_user_id,
      --  parsing_schema_id,
      --  parsing_schema_name,
       table_rows,
       table_block,
       cur_executions,
       cur_cpu_time,
       cur_rows_processed,
       cur_buffer_gets,
       awr_executions,
       awr_cpu_time,
       awr_rows_processed,
       awr_buffer_gets,
       aas_on_cpu,
       plan_name,
       baseline_repro_fail,
       profile_name,
       patch_name,
       spb_executions,
       spb_cpu_time,
       spb_rows_processed,
       spb_buffer_gets,
       action_and_result
      --  pdb_name
  FROM &&cs_tools_schema..zapper_log_v
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = NVL('&&cs_sql_id.', sql_id)
   AND log_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND (NVL(patch_create,0) + NVL(plans_create,0) + NVL(plans_disable,0) + NVL(plans_drop,0) > 0 OR '&&cs_null.' = 'Y')
 ORDER BY
       log_time
/
--
PRO
PRO ZAPPER-19 ENTRIES (C##IOD.zapper_log) api_output + description + message
PRO ~~~~~~~~~~~~~~~~~
SET HEA OFF PAGES 0;
SELECT api_output||TO_CHAR(log_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF6')||' d:'||description||
       CASE WHEN patch_create > 0 THEN ' patch_create:'||patch_create END||
       CASE WHEN plans_create > 0 THEN ' plans_create:'||plans_create END||
       CASE WHEN plans_disable > 0 THEN ' plans_disable:'||plans_disable END||
       CASE WHEN plans_drop > 0 THEN ' plans_drop:'||plans_drop END||
       CASE WHEN baseline_repro_fail > 0 THEN ' baseline_repro_fail:'||baseline_repro_fail END||
       CHR(10)||TO_CHAR(log_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF6')||' m:'||message AS line
  FROM &&cs_tools_schema..zapper_log_v
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = NVL('&&cs_sql_id.', sql_id)
   AND log_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND (NVL(patch_create,0) + NVL(plans_create,0) + NVL(plans_disable,0) + NVL(plans_drop,0) + NVL(baseline_repro_fail,0) > 0 OR '&&cs_null.' = 'Y')
   AND api_output IS NOT NULL
 ORDER BY
       log_time
/
SET HEA ON PAGES 100;
