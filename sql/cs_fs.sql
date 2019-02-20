----------------------------------------------------------------------------------------
--
-- File name:   cs_fs.sql
--
-- Purpose:     Finds SQL statements matching some string
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/25
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter string to match when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_fs.sql
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
DEF invalid = 'N';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_fs';
--
PRO 1. SEARCH_STRING: SQL_ID or SQL_TEXT piece or PLAN_HASH_VALUE: (e.g. performScanQuery%leaseDecorators)
DEF search_string = '&1.';
COL search_string NEW_V search_string;
SELECT /* &&cs_script_name. */ TRIM('&&search_string.') search_string FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&search_string." 
@@cs_internal/cs_spool_id.sql
--
PRO SEARCH_STRING: &&search_string.
--
COL db_time_secs FOR 999,999,990;
COL executions FOR 999,999,990;
COL ms_per_exec FOR 999,990.000;
COL rows_per_exec FOR 999,999,990.0;
COL plan_hash_value FOR 9999999999 HEA 'PHV';
COL curs FOR 9999;
COL val FOR 9999;
COL invl FOR 9999;
COL obsl FOR 9999;
COL shar FOR 9999;
COL spbl FOR 9999;
COL sprf FOR 9999;
COL spch FOR 9999;
COL len FOR 99,990 HEA 'LENGTH';
COL sql_text_60 FOR A60 HEA 'SQL_TEXT';
COL pdb_name FOR A35;
COL please_stop NEW_V please_stop NOPRI;
DEF please_stop = '';
--
BREAK ON sql_id SKIP 1 ON len ON sql_text_60;
-- 
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
       SUM(s.rows_processed)/NULLIF(SUM(s.executions),0) rows_per_exec,
       s.plan_hash_value,
       COUNT(*) curs,
       SUM(CASE WHEN s.object_status LIKE 'VALID%' THEN 1 ELSE 0 END) val,
       SUM(CASE WHEN s.object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invl,
       SUM(CASE WHEN s.is_obsolete = 'Y' THEN 1 ELSE 0 END) obsl,
       SUM(CASE WHEN s.is_shareable = 'Y' THEN 1 ELSE 0 END) shar,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sql s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND ((s.object_status LIKE 'VALID%' AND '&&valid.' = 'Y') OR (s.object_status LIKE 'INVALID%' AND '&&invalid.' = 'Y'))
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') -- case insensitive
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
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
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND s.sql_id = '&&search_string.'
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
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
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by phv
   AND LENGTH('&&search_string.') <= 10 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NULL -- number
   AND TO_CHAR(s.plan_hash_value) = '&&search_string.'
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       s.sql_id,
       DBMS_LOB.getlength(s.sql_fulltext) len,
       SUBSTR(REPLACE(s.sql_text, CHR(10), CHR(32)), 1, 60) sql_text_60,
       SUM(s.elapsed_time)/1e6 db_time_secs,
       SUM(s.executions) executions,
       SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3 ms_per_exec,
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
       c.name||'('||s.con_id||')' pdb_name,
       'Y' please_stop
  FROM v$sqlstats s,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(s.sql_text) LIKE UPPER('%&&search_string.%') -- case insensitive
 GROUP BY
       s.sql_id,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       s.sql_text,
       s.plan_hash_value,
       s.con_id,
       c.name
HAVING NVL(SUM(s.executions), 0) BETWEEN &&executions_min. AND &&executions_max.
   AND NVL(SUM(s.elapsed_time)/NULLIF(SUM(s.executions),0)/1e3, 0) BETWEEN &&ms_per_exec_min. AND &&ms_per_exec_max.
   AND NVL(SUM(s.rows_processed)/NULLIF(SUM(s.executions),0), 0) BETWEEN &&rows_per_exec_min. AND &&rows_per_exec_max.
 ORDER BY
       1, 2, 3, 4 DESC NULLS LAST, 5 DESC NULLS LAST, 6 DESC NULLS LAST
/
--
SELECT /* &&cs_script_name. */
       h.sql_id,
       DBMS_LOB.getlength(h.sql_text) len,
       REPLACE(DBMS_LOB.substr(h.sql_text, 60), CHR(10), CHR(32)) sql_text_60,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_id
   AND LENGTH('&&search_string.') = 13 
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND h.sql_id = '&&search_string.'
 ORDER BY
       1, 2, 3, 4
/
--
SELECT /* &&cs_script_name. */
       h.sql_id,
       DBMS_LOB.getlength(h.sql_text) len,
       REPLACE(DBMS_LOB.substr(h.sql_text, 60), CHR(10), CHR(32)) sql_text_60,
       c.name||'('||h.con_id||')' pdb_name,
       'Y' please_stop
  FROM dba_hist_sqltext h,
       v$containers c
 WHERE '&&please_stop.' IS NULL -- short-circuit if a prior sibling query returned rows
   AND '&&executions_min.' = '&&low_value.'
   AND '&&executions_max.' = '&&high_value.'
   AND '&&ms_per_exec_min.' = '&&low_value.'
   AND '&&ms_per_exec_max.' = '&&high_value.'
   AND '&&rows_per_exec_min.' = '&&low_value.'
   AND '&&rows_per_exec_max.' = '&&high_value.'
   AND h.dbid = TO_NUMBER('&&cs_dbid')
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '/* SQL Analyze(%'
   AND DBMS_LOB.substr(h.sql_text, 60) NOT LIKE '%/* &&cs_script_name. */%'
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   -- by sql_text
   AND TRIM(TRANSLATE('&&search_string.', ' 0123456789', ' ')) IS NOT NULL -- some alpha
   AND UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE UPPER('%&&search_string.%') -- case insensitive
 ORDER BY
       1, 2, 3, 4
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&search_string." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--