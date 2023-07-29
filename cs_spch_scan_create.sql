----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_scan_create.sql
--
-- Purpose:     Create a SQL Patch for slow KIEV performScanQuery without Baselines, Profiles and Patches
--              (if milliseconds per row processed > 1)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/02/10
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spch_scan_create.sql
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
DEF cs_script_name = 'cs_spch_scan_create';
DEF hints_text = "FIRST_ROWS(1) OPT_PARAM(''_fix_control'' ''5922070:OFF'')";
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL et_ms_per_exec FOR 999,990 HEA 'ET|ms p/e';
COL cpu_ms_per_exec FOR 999,990 HEA 'CPU|ms p/e';
COL io_ms_per_exec FOR 999,990 HEA 'I/O|ms p/e';
COL appl_ms_per_exec FOR 999,990 HEA 'Appl|ms p/e';
COL conc_ms_per_exec FOR 999,990 HEA 'Conc|ms p/e';
COL execs FOR 999,990 HEA 'Execs';
COL rows_per_exec FOR 999,999,990 HEA 'Rows|p/e';
COL gets_per_exec FOR 999,999,990 HEA 'Buffer Gets|p/e';
COL reads_per_exec FOR 9,999,990 HEA 'Disk Rs|p/e';
COL writes_per_exec FOR 999,990 HEA 'Dir Wr|p/e';
COL fetches_per_exec FOR 999,990 HEA 'Fetches|p/e';
COL sql_text FOR A60 TRUNC;
COL plan_hash_value FOR 9999999999 HEA 'Plan Hash';
COL has_baseline FOR A2 HEA 'BL';
COL has_profile FOR A2 HEA 'PR';
COL has_patch FOR A2 HEA 'PA';
COL line FOR A500;
--
PRO 
PRO KIEV performScanQuery Latency (as per last &&cs_last_snap_mins. minutes)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_cpu_time/GREATEST(s.delta_execution_count,1)/1e3 AS cpu_ms_per_exec,
       s.delta_user_io_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS io_ms_per_exec,
       s.delta_application_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS appl_ms_per_exec,
       s.delta_concurrency_time/GREATEST(s.delta_execution_count,1)/1e3 AS conc_ms_per_exec,
       s.delta_execution_count AS execs,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) AS gets_per_exec,
       s.delta_disk_reads/GREATEST(s.delta_execution_count,1) AS reads_per_exec,
       s.delta_direct_writes/GREATEST(s.delta_execution_count,1) AS writes_per_exec,
       s.delta_fetch_count/GREATEST(s.delta_execution_count,1) AS fetches_per_exec,
       s.sql_id,
       s.sql_text,
       s.plan_hash_value,
       s.last_active_child_address
  FROM v$sqlstats s
 WHERE s.delta_elapsed_time > 0
   AND s.sql_text LIKE '/* performScanQuery(%'
)
SELECT s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.execs,
       s.rows_per_exec,
       s.gets_per_exec,
       s.reads_per_exec,
       s.sql_id,
       s.plan_hash_value,
      --  v.has_baseline,
      --  v.has_profile,
      --  v.has_patch,
       s.sql_text
  FROM sqlstats s
  CROSS APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
           FROM v$sql v
          WHERE s.plan_hash_value > 0
            AND v.sql_id = s.sql_id
            AND v.plan_hash_value = s.plan_hash_value
            AND v.child_address = s.last_active_child_address
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
 WHERE v.has_baseline = 'N'
   AND v.has_profile = 'N'
   AND v.has_patch = 'N'
   AND s.et_ms_per_exec / GREATEST(s.rows_per_exec, 1) > 1 -- if milliseconds per row processed > 1
 ORDER BY
       s.et_ms_per_exec DESC
/
--
PRO
PAUSE Review list above and press "return" key to generate SQL Patch commands
--
PRO 
PRO Create SQL Patch commands
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SET HEA OFF PAGES 0 LIN 500;
SPO &&cs_file_name._COMMANDS.sql;
PRO SET ECHO ON;
WITH
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_cpu_time/GREATEST(s.delta_execution_count,1)/1e3 AS cpu_ms_per_exec,
       s.delta_user_io_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS io_ms_per_exec,
       s.delta_application_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS appl_ms_per_exec,
       s.delta_concurrency_time/GREATEST(s.delta_execution_count,1)/1e3 AS conc_ms_per_exec,
       s.delta_execution_count AS execs,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) AS gets_per_exec,
       s.delta_disk_reads/GREATEST(s.delta_execution_count,1) AS reads_per_exec,
       s.delta_direct_writes/GREATEST(s.delta_execution_count,1) AS writes_per_exec,
       s.delta_fetch_count/GREATEST(s.delta_execution_count,1) AS fetches_per_exec,
       s.sql_id,
       s.sql_text,
       s.plan_hash_value,
       s.last_active_child_address,
       SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1) AS kiev_table_name
  FROM v$sqlstats s
 WHERE s.delta_elapsed_time > 0
   AND s.sql_text LIKE '/* performScanQuery(%'
)
SELECT CASE
         WHEN '&&cs_db_version.' > '12.1.0.2.0' 
         THEN 'DECLARE'||CHR(10)||'l_name VARCHAR2(1000);'||CHR(10)||'BEGIN'||CHR(10)||
              'l_name :=  DBMS_SQLDIAG.create_sql_patch(sql_id => '''||s.sql_id||''', hint_text => q''[&&hints_text. LEADING(@SEL$1 '||s.kiev_table_name||')]'', name => ''spch_'||s.sql_id||''', description => q''[&&cs_script_name..sql /*+ &&hints_text. LEADING(@SEL$1 '||s.kiev_table_name||') */ &&cs_reference_sanitized. &&who_am_i.]'');'||CHR(10)|| -- 19c
              'END;'||CHR(10)||'/'
         ELSE 'EXEC DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_id => '''||s.sql_id||''', hint_text => q''[&&hints_text. LEADING(@SEL$1 '||s.kiev_table_name||')]'', name => ''spch_'||s.sql_id||''', description => q''[&&cs_script_name..sql /*+ &&hints_text. LEADING(@SEL$1 '||s.kiev_table_name||') */ &&cs_reference_sanitized. &&who_am_i.]'');' -- 12c
       END||CHR(10) AS line
  FROM sqlstats s
  CROSS APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
           FROM v$sql v
          WHERE s.plan_hash_value > 0
            AND v.sql_id = s.sql_id
            AND v.plan_hash_value = s.plan_hash_value
            AND v.child_address = s.last_active_child_address
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
 WHERE v.has_baseline = 'N'
   AND v.has_profile = 'N'
   AND v.has_patch = 'N'
   AND s.et_ms_per_exec / GREATEST(s.rows_per_exec, 1) > 1 -- if milliseconds per row processed > 1
 ORDER BY
       s.et_ms_per_exec DESC
/
PRO SET ECHO OFF LIN 300;
SPO OFF;
HOS chmod 644 &&cs_file_name._COMMANDS.sql
SET HEA ON PAGES 100;
--
PRO
PAUSE Review list above and press "return" key to execute SQL Patch commands
--
-- continues with original spool
SPO &&cs_file_name..txt APP
--
-- execute scripts to create sql patches
@@&&cs_file_name._COMMANDS.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
