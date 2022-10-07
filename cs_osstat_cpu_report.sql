----------------------------------------------------------------------------------------
--
-- File name:   cs_osstat_cpu_report.sql
--
-- Purpose:     CPU Cores Load and Busyness as per OS Stats from AWR (time series report)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/03
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_osstat_cpu_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_osstat_cpu_report';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
COL time FOR A19 HEA 'END_TIME';
COL cores FOR 990;
COL cpus FOR 990;
COL load FOR 9,990;
COL dbrm FOR 990.0 HEA 'DBRM|CPUs';
COL usr FOR 990.0 HEA 'USR|CPUs';
COL sys FOR 990.0 HEA 'SYS|CPUs';
COL io FOR 990.0 HEA 'IO|CPUs';
COL nice FOR 990.0 HEA 'NICE|CPUs';
COL busy FOR 990.0 HEA 'BUSY|CPUs';
COL idle FOR 990.0 HEA 'IDLE|CPUs';
COL cpu_util_perc FOR 990.0 HEA 'CPU UTL|PERC %';
--
BREAK ON REPORT;
COMPUTE MAX LABEL 'MAX' OF cores cpus load dbrm usr sys io nice busy idle cpu_util_perc ON REPORT;
--
PRO
PRO OS Stats from AWR
PRO ~~~~~~~~~~~~~~~~~
WITH
osstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 seconds,
       h.stat_name,
       CASE 
         WHEN h.stat_name IN ('NUM_CPUS','LOAD','NUM_CPU_CORES') THEN h.value
         WHEN h.stat_name LIKE '%TIME' THEN h.value - LAG(h.value) OVER (PARTITION BY h.stat_name ORDER BY h.snap_id) 
         ELSE 0
       END value,
       ROW_NUMBER() OVER (PARTITION BY h.stat_name ORDER BY h.snap_id) row_number
  FROM dba_hist_osstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.stat_name IN ('NUM_CPUS','IDLE_TIME','BUSY_TIME','USER_TIME','SYS_TIME','IOWAIT_TIME','NICE_TIME','RSRC_MGR_CPU_WAIT_TIME','LOAD','NUM_CPU_CORES')
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
),
my_query AS (
SELECT end_time time,
       ROUND(SUM(CASE stat_name WHEN 'LOAD' THEN value ELSE 0 END), 1) load,
       SUM(CASE stat_name WHEN 'NUM_CPU_CORES' THEN value ELSE 0 END) cores,
       SUM(CASE stat_name WHEN 'NUM_CPUS' THEN value ELSE 0 END) cpus,
       ROUND(SUM(CASE stat_name WHEN 'IDLE_TIME' THEN value / 100 / seconds ELSE 0 END), 1) idle,
       ROUND(SUM(CASE stat_name WHEN 'BUSY_TIME' THEN value / 100 / seconds ELSE 0 END), 1) busy,
       ROUND(SUM(CASE stat_name WHEN 'USER_TIME' THEN value / 100 / seconds ELSE 0 END), 1) usr,
       ROUND(SUM(CASE stat_name WHEN 'SYS_TIME' THEN value / 100 / seconds ELSE 0 END), 1) sys,
       ROUND(SUM(CASE stat_name WHEN 'IOWAIT_TIME' THEN value / 100 / seconds ELSE 0 END), 1) io,
       ROUND(SUM(CASE stat_name WHEN 'NICE_TIME' THEN value / 100 / seconds ELSE 0 END), 1) nice,
       ROUND(SUM(CASE stat_name WHEN 'RSRC_MGR_CPU_WAIT_TIME' THEN value / 100 / seconds ELSE 0 END), 1) dbrm
  FROM osstat
 WHERE row_number > 1 -- remove first row
   AND value >= 0
   AND seconds > 0
 GROUP BY
       end_time
)
SELECT q.time,
       q.cores,
       q.cpus,
       q.load,
       q.dbrm,
       q.usr,
       q.sys,
       q.io,
       q.nice,
       q.busy,
       q.idle,
       100 * q.busy / (q.busy + q.idle) AS cpu_util_perc
  FROM my_query q
 ORDER BY
       q.time
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--