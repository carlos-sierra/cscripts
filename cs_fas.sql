----------------------------------------------------------------------------------------
--
-- File name:   cs_fas.sql
--
-- Purpose:     Find all SQL statements matching some string
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/17
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter string to match when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_fas.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF low_value = '0';
DEF high_value = '1000000000000000';
DEF executions_min = '&&low_value.';
DEF executions_max = '&&high_value.';
DEF ms_per_exec_min = '&&low_value.';
DEF ms_per_exec_max = '&&high_value.';
DEF rows_per_exec_min = '&&low_value.';
DEF rows_per_exec_max = '&&high_value.';
DEF valid = 'Y';
DEF invalid = 'Y';
--
DEF last_active_hours = '168';
DEF include_awr = 'Y';
DEF short_circuit = 'N';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_fas';
--
PRO 1. SEARCH_STRING: SQL_ID or SQL_TEXT piece or PLAN_HASH_VALUE: (e.g.: ScanQuery, getValues, TableName, IndexName)
DEF search_string = '&1.';
UNDEF 1;
COL search_string NEW_V search_string;
SELECT /* &&cs_script_name. */ TRIM('&&search_string.') search_string FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&search_string." 
@@cs_internal/cs_spool_id.sql
--
PRO SEARCH_STRING: &&search_string.
--
COL table_num_rows FOR 999,999,999,990;
COL table_blocks FOR 999,999,990;
COL num_rows FOR 999,999,999,990;
COL db_time_secs FOR 999,999,990;
COL executions FOR 999,999,990;
COL ms_per_exec FOR 999,999,990.000;
COL bg_per_exec FOR 999,999,999,990;
COL bg_per_row FOR 999,999,999,990;
COL rows_per_exec FOR 999,999,990.0;
COL plan_hash_value FOR 9999999999 HEA 'PHV';
COL min_cost FOR 999,999,990;
COL max_cost FOR 999,999,990;
COL lns FOR 999;
COL curs FOR 9999;
COL val FOR 9999;
COL invl FOR 9999;
COL obsl FOR 9999;
COL shar FOR 9999;
COL spbl FOR 9999;
COL sprf FOR 9999;
COL spch FOR 9999;
COL first_load_time FOR A19;
COL last_load_time FOR A19;
COL last_active_time FOR A19;
COL sqlid FOR A5 HEA 'SQLHV';
COL len FOR 99990 HEA 'LENGHT';
COL prd FOR 99990 HEA 'WHERE';
COL sql_text_80 FOR A80 HEA 'SQL_TEXT';
COL pdb_name FOR A35;
COL please_stop NEW_V please_stop NOPRI;
DEF please_stop = '';
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       MIN(s.optimizer_cost) min_cost,
       MAX(s.optimizer_cost) max_cost,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       MIN(s.first_load_time) first_load_time,
       MAX(s.last_load_time) last_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s
          CROSS APPLY (
              SELECT  MAX(t.num_rows) AS table_num_rows, MAX(t.blocks) AS table_blocks -- rows and blocks could be from different tables and that is intended
              FROM    v$object_dependency d, dba_users u, dba_tables t
              WHERE   d.from_hash = s.hash_value
              AND     d.from_address = s.address
              AND     d.to_type = 2 -- table
              AND     u.username = d.to_owner
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.parsing_schema_name,
       s.sql_text,
       s.plan_hash_value,
       t.table_num_rows,
       t.table_blocks,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       MIN(s.optimizer_cost) min_cost,
       MAX(s.optimizer_cost) max_cost,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       MIN(s.first_load_time) first_load_time,
       MAX(s.last_load_time) last_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s
          CROSS APPLY (
              SELECT  MAX(t.num_rows) AS table_num_rows, MAX(t.blocks) AS table_blocks -- rows and blocks could be from different tables and that is intended
              FROM    v$object_dependency d, dba_users u, dba_tables t
              WHERE   d.from_hash = s.hash_value
              AND     d.from_address = s.address
              AND     d.to_type = 2 -- table
              AND     u.username = d.to_owner
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.parsing_schema_name,
       s.sql_text,
       s.plan_hash_value,
       t.table_num_rows,
       t.table_blocks,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       MIN(s.optimizer_cost) min_cost,
       MAX(s.optimizer_cost) max_cost,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       MIN(s.first_load_time) first_load_time,
       MAX(s.last_load_time) last_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s
          CROSS APPLY (
              SELECT  MAX(t.num_rows) AS table_num_rows, MAX(t.blocks) AS table_blocks -- rows and blocks could be from different tables and that is intended
              FROM    v$object_dependency d, dba_users u, dba_tables t
              WHERE   d.from_hash = s.hash_value
              AND     d.from_address = s.address
              AND     d.to_type = 2 -- table
              AND     u.username = d.to_owner
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') -- case insensitive
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.parsing_schema_name,
       s.sql_text,
       s.plan_hash_value,
       t.table_num_rows,
       t.table_blocks,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       COUNT(*) curs,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       COUNT(*) curs,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       s.sql_id,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 80) sql_text_80,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.rows_processed),0)) AS bg_per_row,
       s.plan_hash_value,
       COUNT(*) curs,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
  --  AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') -- case insensitive
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
 GROUP BY
       s.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0'),
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       DBMS_LOB.instr(s.sql_fulltext, 'WHERE'),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       sqlid, len, prd, sql_id, db_time_secs DESC
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN h.sql_text LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(h.sql_text, '\[([[:digit:]]{4})\] ') ELSE h.sql_text END),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(h.sql_text) len,
       DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 prd,
       h.sql_id,
       REPLACE(DBMS_LOB.substr(h.sql_text, 80), CHR(10), CHR(32)) sql_text_80,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
   AND '&&include_awr' = 'Y'
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   AND DBMS_LOB.substr(h.sql_text, 80) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 80) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND h.sql_id = '&&search_string.'
 ORDER BY
       sqlid, len, prd, sql_id
/
--
SELECT /* &&cs_script_name. */
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN h.sql_text LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(h.sql_text, '\[([[:digit:]]{4})\] ') ELSE h.sql_text END),100000),5,'0') AS sqlid,
       DBMS_LOB.getlength(h.sql_text) len,
       DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 prd,
       h.sql_id,
       REPLACE(DBMS_LOB.substr(h.sql_text, 80), CHR(10), CHR(32)) sql_text_80,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE ('&&please_stop.' IS NULL OR '&&short_circuit.' = 'N') -- short-circuit if a prior sibling query returned rows
   AND '&&include_awr' = 'Y'
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   AND DBMS_LOB.substr(h.sql_text, 80) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 80) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE UPPER('%&&search_string.%') -- case insensitive
 ORDER BY
       sqlid, len, prd, sql_id
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&search_string." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--