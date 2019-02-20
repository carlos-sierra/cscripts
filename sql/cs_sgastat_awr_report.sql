----------------------------------------------------------------------------------------
--
-- File name:   cs_sgastat_awr_report.sql
--
-- Purpose:     SGA Pools History Report from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2018/12/16
--
-- Usage:       Execute connected to CDB
--
--              Enter range of dates.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sgastat_awr_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_secondary.sql
--@@cs_internal/cs_pdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sgastat_awr_report';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. (&&cs_snap_id_from.)
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
--
COL snap_id FOR 9999999 HEA 'Snap ID';
COL begin_time FOR A19 HEA 'Begin Time';
COL end_time FOR A19 HEA 'End Time';
COL pga_aggregate_target FOR 9,990.000 HEA 'PGA|Aggregate|Target';
COL sga_target FOR 9,990.0 HEA 'SGA|Target';
COL buffer_cache FOR 9,990.000 HEA 'Buffer|Cache';
COL log_buffer FOR 9,990.000 HEA 'Log|Buffer';
COL shared_io_pool FOR 9,990.000 HEA 'Shared|IO Pool';
COL fixed_sga FOR 9,990.000 HEA 'Fixed|SGA';
COL shared_pool FOR 9,990.000 HEA 'Shared|Pool';
COL shared_pool_free_memory FOR 9,990.000 HEA 'Shared|Pool|Free|Memory';
COL large_pool FOR 9,990.000 HEA 'Large|Pool';
COL large_pool_free_memory FOR 9,990.000 HEA 'Large|Pool|Free|Memory';
COL java_pool FOR 9,990.000 HEA 'Java|Pool';
COL java_pool_free_memory FOR 9,990.000 HEA 'Java|Pool|Free|Memory';
COL streams_pool FOR 9,990.000 HEA 'Streams|Pool';
COL streams_pool_free_memory FOR 9,990.000 HEA 'Streams|Pool|Free|Memory';
--
PRO
PRO Memory Pools (GBs)
PRO ~~~~~~~~~~~~~~~~~~
WITH
sgastat AS (
SELECT /*+ NO_MERGE */
       snap_id,
       ROUND(SUM(CASE WHEN name = 'buffer_cache' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) buffer_cache, -- see bug 18166499
       ROUND(SUM(CASE WHEN name = 'log_buffer' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) log_buffer,
       ROUND(SUM(CASE WHEN name = 'shared_io_pool' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_io_pool,
       ROUND(SUM(CASE WHEN name = 'fixed_sga' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) fixed_sga,
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'large pool'  AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'large pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool_free_memory
  FROM dba_hist_sgastat
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       snap_id
),
param AS (
SELECT /*+ NO_MERGE */
       snap_id,
       ROUND(SUM(CASE parameter_name WHEN '__db_cache_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) buffer_cache,
       ROUND(SUM(CASE parameter_name WHEN '__shared_io_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) shared_io_pool,
       ROUND(SUM(CASE parameter_name WHEN '__shared_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) shared_pool,
       ROUND(SUM(CASE parameter_name WHEN '__large_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) large_pool,
       ROUND(SUM(CASE parameter_name WHEN '__java_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) java_pool,
       ROUND(SUM(CASE parameter_name WHEN '__streams_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) streams_pool,
       ROUND(SUM(CASE parameter_name WHEN '__sga_target' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) sga_target,
       ROUND(SUM(CASE parameter_name WHEN '__pga_aggregate_target' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) pga_aggregate_target
  FROM dba_hist_parameter
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND parameter_name IN ('__db_cache_size', '__java_pool_size', '__large_pool_size', '__pga_aggregate_target', '__sga_target', '__shared_io_pool_size', '__shared_pool_size', '__streams_pool_size')
 GROUP BY
       snap_id
),
my_query AS (
SELECT /*+ NO_MERGE */
       s.snap_id,
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       p.pga_aggregate_target,
       p.sga_target,
       p.buffer_cache,
       p.shared_pool,
       p.large_pool,
       p.java_pool,
       p.streams_pool,
       p.shared_io_pool,
       t.shared_pool_free_memory,
       t.large_pool_free_memory,
       t.java_pool_free_memory,
       t.streams_pool_free_memory
  FROM dba_hist_snapshot s,
       sgastat t,
       param p
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND t.snap_id = s.snap_id
   AND p.snap_id = s.snap_id
)
SELECT end_time,
       pga_aggregate_target,
       sga_target,
       buffer_cache,
       shared_pool,
       large_pool,
       java_pool,
       streams_pool,
       shared_io_pool,
       shared_pool_free_memory,
       large_pool_free_memory,
       java_pool_free_memory,
       streams_pool_free_memory
  FROM my_query
 ORDER BY
       snap_id
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--