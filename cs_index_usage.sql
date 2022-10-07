----------------------------------------------------------------------------------------
--
-- File name:   cs_index_usage.sql
--
-- Purpose:     Index Usage (is an index still in use?)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/26
--
-- Usage:       Execute connected to PDB
--
--              Enter owner, table and index
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_index_usage.sql
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
DEF cs_script_name = 'cs_index_usage';
--
COL username FOR A30;
SELECT username
  FROM dba_users
 WHERE oracle_maintained = 'N'
   AND common = 'NO'
 ORDER BY
       username
/
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
COL p_owner NEW_V p_owner FOR A30 NOPRI;
SELECT username AS p_owner 
  FROM dba_users 
 WHERE oracle_maintained = 'N'
   AND common = 'NO'
   AND username = UPPER(TRIM('&&table_owner.')) 
   AND ROWNUM = 1
/
--
COL table_name FOR A30;
SELECT table_name, blocks, num_rows
  FROM dba_tables
 WHERE owner = '&&p_owner.'
 ORDER BY
       table_name
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL p_table_name NEW_V p_table_name NOPRI;
SELECT table_name AS p_table_name 
  FROM dba_tables 
 WHERE owner = '&&p_owner.'
   AND table_name = UPPER(TRIM('&&table_name.')) 
   AND ROWNUM = 1
/
--
COL index_name FOR A30;
SELECT index_name, leaf_blocks
  FROM dba_indexes
 WHERE owner = '&&p_owner.'
   AND table_name = '&&p_table_name.'
 ORDER BY
       index_name
/
PRO
PRO 3. Index Name:
DEF index_name = '&3.'
UNDEF 3;
COL p_index_name NEW_V p_index_name NOPRI;
SELECT index_name AS p_index_name
  FROM dba_indexes
 WHERE owner = '&&p_owner.'
   AND table_name = '&&p_table_name.'
   AND index_name = UPPER(TRIM('&&index_name.')) 
   AND ROWNUM = 1
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&p_owner..&&p_table_name..&&p_index_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&p_index_name." 
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&p_owner.
PRO TABLE_NAME   : &&p_table_name.
PRO INDEX_NAME   : &&p_index_name.
--
COL plan_hash_value FOR 999999999999999;
COL executions FOR 999,999,999,990;
COL elapsed_seconds FOR 999,999,990;
COL cpu_seconds FOR 999,999,990;
COL sql_text FOR A100 TRUNC;
BREAK ON REPORT;
COMPUTE SUM LABEL "TOTAL" OF executions elapsed_seconds cpu_seconds ON REPORT;
PRO
PRO v$object_dependency -> v$sql
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT   s.sql_id, s.plan_hash_value, s.sql_text, 
         s.executions, s.elapsed_seconds, s.cpu_seconds, s.last_active_time
FROM     (  SELECT   d.from_hash, d.from_address
            FROM     v$object_dependency d, v$db_object_cache c
            WHERE    d.to_owner = '&&p_owner.'
            AND      d.to_name = '&&p_index_name.'
            --AND      d.to_type = 70 -- MULTI-VERSIONED OBJECT
            AND      c.hash_value = d.to_hash
            AND      c.addr = d.to_address
            AND      c.type = 'MULTI-VERSIONED OBJECT'
            GROUP BY d.from_hash, d.from_address
         ) d
         CROSS APPLY (
            SELECT   s.sql_id, s.sql_text, s.plan_hash_value,
                     SUM(s.executions) AS executions,
                     ROUND(SUM(s.elapsed_time)/POWER(10, 6)) AS elapsed_seconds,
                     ROUND(SUM(s.cpu_time)/POWER(10, 6)) AS cpu_seconds,
                     MAX(s.last_active_time) AS last_active_time
            FROM     v$sql s
            WHERE    s.hash_value = d.from_hash
            AND      s.address = d.from_address
            GROUP BY
                     s.sql_id, s.sql_text, s.plan_hash_value
         ) s
ORDER BY
         s.sql_id, s.plan_hash_value
/
PRO
PRO v$sql_plan -> v$sql
PRO ~~~~~~~~~~~~~~~~~~~
SELECT   p.sql_id, p.plan_hash_value, s.sql_text,
         s.executions, s.elapsed_seconds, s.cpu_seconds, s.last_active_time
FROM     (  SELECT   p.sql_id, p.plan_hash_value
            FROM     v$sql_plan p
            WHERE    p.object_owner = '&&p_owner.'
            AND      p.object_name = '&&p_index_name.'
            AND      p.object_type LIKE '%INDEX%'
            GROUP BY p.sql_id, p.plan_hash_value
         ) p
         CROSS APPLY (
            SELECT   MAX(s.sql_text) AS sql_text,
                     SUM(s.executions) AS executions,
                     ROUND(SUM(s.elapsed_time)/POWER(10, 6)) AS elapsed_seconds,
                     ROUND(SUM(s.cpu_time)/POWER(10, 6)) AS cpu_seconds,
                     MAX(s.last_active_time) AS last_active_time
            FROM     v$sql s
            WHERE    s.sql_id = p.sql_id
            AND      s.plan_hash_value = p.plan_hash_value
         ) s
ORDER BY
         s.sql_id, s.plan_hash_value
/
PRO
PRO dba_hist_sql_plan -> dba_hist_sqltext
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT   p.sql_id, p.plan_hash_value, s.sql_text, p.timestamp
FROM     (  SELECT   p.sql_id, p.plan_hash_value, MAX(timestamp) AS timestamp
            FROM     dba_hist_sql_plan p
            WHERE    p.object_owner = '&&p_owner.'
            AND      p.object_name = '&&p_index_name.'
            AND      p.object_type LIKE '%INDEX%'
            AND      p.dbid = TO_NUMBER('&&cs_dbid.') 
            GROUP BY p.sql_id, p.plan_hash_value
         ) p
         CROSS APPLY (
            SELECT   MAX(DBMS_LOB.SUBSTR(s.sql_text, 1000)) AS sql_text
            FROM     dba_hist_sqltext s
            WHERE    s.sql_id = p.sql_id
         ) s
ORDER BY
         p.sql_id, p.plan_hash_value
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&p_owner." "&&p_table_name." "&&p_index_name." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
