----------------------------------------------------------------------------------------
--
-- File name:   cs_fs.sql
--
-- Purpose:     Finds SQL statements matching some string
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/06
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
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_fs';
--
PRO 1. SQL_ID or SIGNATURE or PLAN_HASH_VALUE or PLAN_NAME or SQL_TEXT piece: 
DEF sql_text_piece = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&sql_text_piece."
@@cs_internal/cs_spool_id.sql
--
PRO TEXT_PIECE   : &&sql_text_piece.
--
COL pdb_name FOR A35;
COL executions FOR 999,999,990;
COL ms_per_exec FOR 999,990.000;
COL rows_per_exec FOR 999,999,990.0;
COL phv FOR 9999999999;
COL curs FOR 9999;
COL spbl FOR 9999;
COL sprf FOR 9999;
COL spch FOR 9999;
COL len FOR 9999;
COL sql_text_100 FOR A100;
COL last_active_time FOR A19;
COL v FOR A1;
COL o FOR A1;
COL s FOR A1;
--
SELECT /* EXCLUDE_ME please */
       (SELECT p.name||'('||p.con_id||')' FROM v$containers p WHERE p.con_id = s.con_id) pdb_name, 
       MAX(s.last_active_time) last_active_time,
       s.sql_id,
       s.plan_hash_value phv,
       CASE MAX(s.object_status) WHEN 'VALID' THEN 'Y' ELSE 'N' END v,
       MIN(s.is_obsolete) o,
       MAX(s.is_shareable) s,
       SUM(s.executions) executions, 
       SUM(s.elapsed_time)/GREATEST(SUM(s.executions),1)/1e3 ms_per_exec,
       SUM(s.rows_processed)/GREATEST(SUM(s.executions),1) rows_per_exec,
       COUNT(*) curs,
       COUNT(DISTINCT s.sql_plan_baseline) spbl,
       COUNT(DISTINCT s.sql_profile) sprf,
       COUNT(DISTINCT s.sql_patch) spch,
       DBMS_LOB.GETLENGTH(s.sql_fulltext) len,
       SUBSTR(CASE WHEN sql_text LIKE '/*'||CHR(37) THEN SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) ELSE sql_text END, 1, 100) sql_text_100
  FROM v$sql s
 WHERE (    s.sql_text LIKE '&&sql_text_piece.%'
         OR s.sql_text LIKE '%&&sql_text_piece.%'
         OR UPPER(s.sql_text) LIKE UPPER('%&&sql_text_piece.%') 
         OR s.sql_id LIKE SUBSTR('&&sql_text_piece.', 1, 13)||'%'
         OR TO_CHAR(s.exact_matching_signature) = '&&sql_text_piece.'
         OR s.sql_plan_baseline = '&&sql_text_piece.'
         OR TO_CHAR(s.plan_hash_value) = '&&sql_text_piece.'
       )
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND s.sql_text NOT LIKE 'SELECT /* EXCLUDE_ME please */%'
 GROUP BY
       s.con_id, s.sql_id, s.plan_hash_value,
       DBMS_LOB.GETLENGTH(s.sql_fulltext),
       SUBSTR(CASE WHEN sql_text LIKE '/*'||CHR(37) THEN SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) ELSE sql_text END, 1, 100)
 ORDER BY
       1, 2, 3, 4
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&sql_text_piece."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--