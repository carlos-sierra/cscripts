----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_top_binds.sql
--
-- Purpose:     SQL Monitor Top Binds for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2021/03/09
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlmon_top_binds.sql
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
DEF cs_script_name = 'cs_sqlmon_top_binds';
DEF cs_hours_range_default = '168';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..iod_sql_monitor
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
ALTER SESSION SET container = CDB$ROOT;
--
COL key NOPRI;
COL sql_exec_start FOR A19;
COL last_refresh_time FOR A19;
COL seconds FOR 999,990;
COL status FOR A19;
COL sql_plan_hash_value FOR 9999999999 HEA 'PHV';
COL elapsed_secs FOR 999,990.000 HEA 'ELAP_SECS';
COL cpu_secs FOR 999,990.000 HEA 'CPU_SECS';
COL buffer_gets FOR 999,999,990;
COL disk_reads FOR 999,999,990;
COL pos FOR 999;
COL type FOR A20;
COL name_and_value FOR A200;
--
BREAK ON key SKIP PAGE ON sql_exec_start ON last_refresh_time ON seconds ON status ON sql_plan_hash_value ON elapsed_secs ON cpu_secs ON buffer_gets ON disk_reads;
--
PRO
PRO TOP SQL MONITOR BINDS (&&cs_tools_schema..iod_sql_monitor)
PRO ~~~~~~~~~~~~~~~~~~~~~
--
COL sum_elapsed_secs FOR 999,990 HEA 'Sum|Elapsed|Seconds';
COL sum_cpu_secs FOR 999,990 HEA 'Sum|CPU|Seconds';
COL sum_buffer_gets FOR 999,999,999,990 HEA 'Sum|Buffer|Gets';
COL sum_disk_reads FOR 999,999,999,990 HEA 'Sum|Disk|Reads';
COL avg_elapsed_secs FOR 999,990 HEA 'Avg|Elapsed|Seconds';
COL avg_cpu_secs FOR 999,990 HEA 'Avg|CPU|Seconds';
COL avg_buffer_gets FOR 999,999,999,990 HEA 'Avg|Buffer|Gets';
COL avg_disk_reads FOR 999,999,999,990 HEA 'Avg|Disk|Reads';
COL max_elapsed_secs FOR 999,990 HEA 'Max|Elapsed|Seconds';
COL max_cpu_secs FOR 999,990 HEA 'Max|CPU|Seconds';
COL max_buffer_gets FOR 999,999,999,990 HEA 'Max|Buffer|Gets';
COL max_disk_reads FOR 999,999,999,990 HEA 'Max|Disk|Reads';
COL cnt FOR 999,990 HEA 'Count';
COL name_and_value FOR A200 HEA 'Bind Name and Value';
COL min_sql_exec_start HEA 'Min SQL|Exec Start';
COL max_last_refresh_time HEA 'Max Last|Refresh Time';
COL d1 FOR A1 HEA '|';
COL d2 FOR A1 HEA '|';
COL d3 FOR A1 HEA '|';
COL d4 FOR A1 HEA '|';
--
WITH 
mon AS (
SELECT s.key,
       s.con_id,
       s.sql_plan_hash_value,
       s.sql_exec_id,
       s.sql_exec_start,
       s.last_refresh_time,
       (s.last_refresh_time - s.sql_exec_start) * 24 * 3600 AS seconds,
       s.status,
       s.username,
       s.sid,
       s.session_serial# AS serial#,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.module,
       s.action,
       s.program,
       bv.pos,
       bv.name,
       bv.type,
       bv.maxlen,
       bv.len,
       bv.value
  FROM &&cs_tools_schema..iod_sql_monitor s, 
       xmltable( '/binds/bind'
                  passing xmltype(REPLACE(REPLACE(ASCIISTR(s.binds_xml), '\FFFF'), CHR(0)))
                  COLUMNS name   VARCHAR2( 30 )   path '@name' ,
                          pos    NUMBER           path '@pos',
                          type   VARCHAR2( 15 )   path '@dtystr' ,
                          maxlen NUMBER           path '@maxlen', 
                          len    NUMBER           path '@len',
                          value  VARCHAR2( 4000 ) path '.'
               ) bv
 WHERE s.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND s.sql_id = '&&cs_sql_id.'
   AND s.binds_xml IS NOT NULL
--    AND s.status LIKE 'DONE%'
),
grp AS (
SELECT SUM(elapsed_time) / POWER(10, 6) AS sum_elapsed_secs,
       SUM(cpu_time) / POWER(10, 6) AS sum_cpu_secs,
       SUM(buffer_gets) AS sum_buffer_gets,
       SUM(disk_reads) AS sum_disk_reads,
       AVG(elapsed_time) / POWER(10, 6) AS avg_elapsed_secs,
       AVG(cpu_time) / POWER(10, 6) AS avg_cpu_secs,
       AVG(buffer_gets) AS avg_buffer_gets,
       AVG(disk_reads) AS avg_disk_reads,
       MAX(elapsed_time) / POWER(10, 6) AS max_elapsed_secs,
       MAX(cpu_time) / POWER(10, 6) AS max_cpu_secs,
       MAX(buffer_gets) AS max_buffer_gets,
       MAX(disk_reads) AS max_disk_reads,
       COUNT(*) AS cnt,
       MIN(sql_exec_start) AS min_sql_exec_start,
       MAX(last_refresh_time) AS max_last_refresh_time,
       name,
       value
  FROM mon
 GROUP BY
       name,
       value
)
SELECT sum_elapsed_secs,
       sum_cpu_secs,
       sum_buffer_gets,
       sum_disk_reads,
       '|' AS d1,
       avg_elapsed_secs,
       avg_cpu_secs,
       avg_buffer_gets,
       avg_disk_reads,
       '|' AS d2,
       max_elapsed_secs,
       max_cpu_secs,
       max_buffer_gets,
       max_disk_reads,
       '|' AS d3,
       name||' = '||value AS name_and_value,
       '|' AS d4,
       cnt,
       min_sql_exec_start,
       max_last_refresh_time
  FROM grp
 ORDER BY
       sum_elapsed_secs DESC,
       name,
       value
 FETCH FIRST 100 ROWS ONLY
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--

