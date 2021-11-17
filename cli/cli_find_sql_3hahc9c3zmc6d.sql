REM cli_find_sql_v00_SQL_ID_OR_TEXT - Find SQL for given SQL_ID or SQL Text
DEF search_string = '3hahc9c3zmc6d';
-- 
DEF low_value = '0';
DEF high_value = '1000000000000000';
--
DEF executions_min = '&&low_value.';
DEF executions_max = '&&high_value.';
DEF ms_per_exec_min = '&&low_value.';
DEF ms_per_exec_max = '&&high_value.';
DEF rows_per_exec_min = '&&low_value.';
DEF rows_per_exec_max = '&&high_value.';
DEF valid = 'Y';
DEF invalid = 'N';
DEF last_active_hours = '1';
DEF include_awr = 'N';
DEF having_spbl = '0';
DEF having_sprf = '0';
DEF having_spch = '0';
DEF len = '';
DEF prd = '';
--
DEF last_active_hours = '24';
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL table_num_rows FOR 999,999,999,990;
COL table_blocks FOR 999,999,990;
COL num_rows FOR 999,999,999,990;
COL db_time_secs FOR 999,999,990;
COL executions FOR 999,999,990;
COL ms_per_exec FOR 999,999,990.000;
COL bg_per_exec FOR 999,999,999,990;
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
COL last_active_time FOR A19;
COL len FOR 99,990 HEA 'LENGTH';
COL prd FOR 99,990 HEA 'WHERE';
COL sql_text_60 FOR A60 HEA 'SQL_TEXT';
COL pdb_name FOR A35;
COL please_stop NEW_V please_stop NOPRI;
DEF please_stop = '';
--
DEF cs_script_name = 'cli_find_sql';
COL cs_dbid NEW_V cs_dbid FOR A12 NOPRI;
SELECT TO_CHAR(dbid) cs_dbid FROM v$database;
-- 
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
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
              AND     d.to_owner <> 'SYS'
              AND     d.to_owner NOT LIKE 'C##%'
              AND     u.username = d.to_owner
              AND     u.oracle_maintained = 'N'
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
   AND (COUNT(DISTINCT s.sql_plan_baseline) >= &&having_spbl. OR COUNT(DISTINCT s.sql_profile) >= &&having_sprf. OR COUNT(DISTINCT s.sql_patch) >= &&having_spch.)
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
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
              AND     d.to_owner <> 'SYS'
              AND     d.to_owner NOT LIKE 'C##%'
              AND     u.username = d.to_owner
              AND     u.oracle_maintained = 'N'
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
   AND (COUNT(DISTINCT s.sql_plan_baseline) >= &&having_spbl. OR COUNT(DISTINCT s.sql_profile) >= &&having_sprf. OR COUNT(DISTINCT s.sql_patch) >= &&having_spch.)
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       --(SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND t.owner = s.parsing_schema_name AND t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       t.table_num_rows,
       t.table_blocks,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
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
              AND     d.to_owner <> 'SYS'
              AND     d.to_owner NOT LIKE 'C##%'
              AND     u.username = d.to_owner
              AND     u.oracle_maintained = 'N'
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') ESCAPE '\' -- case insensitive
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
   AND (COUNT(DISTINCT s.sql_plan_baseline) >= &&having_spbl. OR COUNT(DISTINCT s.sql_profile) >= &&having_sprf. OR COUNT(DISTINCT s.sql_patch) >= &&having_spch.)
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       --SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       --SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       --SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       --SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       --COUNT(DISTINCT s.sql_plan_baseline) spbl,
       --COUNT(DISTINCT s.sql_profile) sprf,
       --COUNT(DISTINCT s.sql_patch) spch,
       --MIN(s.first_load_time) first_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       --SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       --SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       --SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       --SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       --COUNT(DISTINCT s.sql_plan_baseline) spbl,
       --COUNT(DISTINCT s.sql_profile) sprf,
       --COUNT(DISTINCT s.sql_patch) spch,
       --MIN(s.first_load_time) first_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 prd,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ t.num_rows FROM cdb_tables t WHERE t.con_id = s.con_id AND /*t.owner = s.parsing_schema_name AND*/ t.table_name = UPPER(SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1)) AND ROWNUM = 1) AS num_rows,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       ROUND(SUM(s.buffer_gets)/NULLIF(SUM(s.executions),0)) AS bg_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       --SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       --SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       --SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       --SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       --COUNT(DISTINCT s.sql_plan_baseline) spbl,
       --COUNT(DISTINCT s.sql_profile) sprf,
       --COUNT(DISTINCT s.sql_patch) spch,
       --MIN(s.first_load_time) first_load_time,
       MAX(s.last_active_time) last_active_time,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   --AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') ESCAPE '\' -- case insensitive
   AND s.last_active_time > SYSDATE - (&&last_active_hours. / 24)
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(s.sql_fulltext) - DBMS_LOB.instr(s.sql_fulltext, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 GROUP BY
       s.sql_id,
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
       1, 2, 3, 4 DESC NULLS LAST, 9 DESC NULLS LAST, 7 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       h.sql_id,
       DBMS_LOB.getlength(h.sql_text) len,
       DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 prd,
       REPLACE(DBMS_LOB.substr(h.sql_text, 60), CHR(10), CHR(32)) sql_text_60,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND '&&include_awr' = 'Y'
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   --AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND h.sql_id = '&&search_string.'
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(h.sql_text) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 ORDER BY
       1, 2, 3, 4
/
--
SELECT /* &&cs_script_name. */
       h.sql_id,
       DBMS_LOB.getlength(h.sql_text) len,
       DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 prd,
       REPLACE(DBMS_LOB.substr(h.sql_text, 60), CHR(10), CHR(32)) sql_text_60,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND '&&include_awr' = 'Y'
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   --AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE UPPER('%&&search_string.%') ESCAPE '\' -- case insensitive
   AND ('&&len.' IS NULL OR DBMS_LOB.getlength(h.sql_text) = TO_NUMBER('&&len.'))
   AND ('&&prd.' IS NULL OR DBMS_LOB.getlength(h.sql_text) - DBMS_LOB.instr(h.sql_text, 'WHERE') + 1 = TO_NUMBER('&&prd.'))
 ORDER BY
       1, 2, 3, 4
/
--
