----------------------------------------------------------------------------------------
--
-- File name:   dbrma.sql | cs_rsrc_mgr_aggregate.sql
--
-- Purpose:     Database Resource Manager (DBRM) Metrics Aggregate per PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/19
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_aggregate.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_rsrc_mgr_aggregate';
DEF cs_script_acronym = 'dbrma.sql | ';
--
COL pdb_name NEW_V pdb_name FOR A30;
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
COL pdb_name FOR A30 HEA '.|.|.|PDB Name';
COL num_cpus FOR 9990 HEA 'CPU|Count|Rsrc|Mgr';
COL avg_running_sessions_limit FOR 999,990.0 HEA 'AVG|Running|Sessions|Limit';
COL avg_avg_running_sessions FOR 999,990.0 HEA 'AVG|Average|Running|Sessions';
COL avg_avg_waiting_sessions FOR 999,990.0 HEA 'AVG|Average|Waiting|Sessions';
COL avg_headroom_sessions FOR 999,990.0 HEA 'AVG|Available|Headroom|Sessions';
COL avg_iops FOR 9,999,990 HEA 'AVG|IOPS';
COL avg_mbps FOR 9,999,990 HEA 'AVG|MBPS';
COL max_running_sessions_limit FOR 999,990.0 HEA 'MAX|Running|Sessions|Limit';
COL max_avg_running_sessions FOR 999,990.0 HEA 'MAX|Average|Running|Sessions';
COL max_avg_waiting_sessions FOR 999,990.0 HEA 'MAX|Average|Waiting|Sessions';
COL max_headroom_sessions FOR 999,990.0 HEA 'MAX|Available|Headroom|Sessions';
COL max_iops FOR 9,999,990 HEA 'MAX|IOPS';
COL max_mbps FOR 9,999,990 HEA 'MAX|MBPS';
--
BREAK ON REPORT;
COMPUTE SUM MAX AVG MIN OF num_cpus avg_running_sessions_limit avg_avg_running_sessions avg_avg_waiting_sessions avg_headroom_sessions avg_iops avg_mbps max_running_sessions_limit max_avg_running_sessions max_avg_waiting_sessions max_headroom_sessions max_iops max_mbps ON REPORT;
--
PRO
PRO DB Resource Manager Metrics Aggregate per PDB: (&&cs_tools_schema..dbc_rsrcmgrmetric_history and v$rsrcmgrmetric_history)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
rsrc_mgr_metric_history AS (
SELECT v.con_id, v.begin_time, v.end_time, 
       v.num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(v.running_sessions_limit, 6) AS pdb_running_sessions_limit,
       ROUND(v.avg_running_sessions, 6) AS pdb_avg_running_sessions,
       ROUND(v.avg_waiting_sessions, 6) AS pdb_avg_waiting_sessions,
       ROUND(v.io_requests, 6) AS pdb_io_requests,
       ROUND(v.io_megabytes, 6) AS pdb_io_megabytes
  FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') < SYSDATE - (1/24) -- get history from dbc table iff time_fromm is older than 1h
   AND v.end_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND v.begin_time <= TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
UNION
SELECT v.con_id, v.begin_time, v.end_time, 
       v.num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(v.running_sessions_limit, 6) AS pdb_running_sessions_limit,
       ROUND(v.avg_running_sessions, 6) AS pdb_avg_running_sessions,
       ROUND(v.avg_waiting_sessions, 6) AS pdb_avg_waiting_sessions,
       ROUND(v.io_requests, 6) AS pdb_io_requests,
       ROUND(v.io_megabytes, 6) AS pdb_io_megabytes
  FROM v$rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') > SYSDATE - (1/24) -- get history from memory iff time_to is within last 1h
),
rsrc_mgr_metric_history_ext AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id, h.begin_time, h.end_time, h.num_cpus,
       h.pdb_running_sessions_limit, h.pdb_avg_running_sessions, h.pdb_avg_waiting_sessions,
       ROUND(GREATEST(h.pdb_running_sessions_limit - h.pdb_avg_running_sessions /* - h.pdb_avg_waiting_sessions */, 0), 6) AS pdb_headroom_sessions,
       ROUND(h.pdb_io_requests / h.seconds, 6) AS pdb_iops, ROUND(h.pdb_io_megabytes / h.seconds, 6) AS pdb_mbps
  FROM rsrc_mgr_metric_history h
 WHERE h.seconds > 0
   AND ROWNUM >= 1
),
rsrc_mgr_metric_history_aggr AS (
SELECT h.con_id, MAX(h.num_cpus) AS num_cpus,
       ROUND(AVG(h.pdb_running_sessions_limit), 6) AS avg_running_sessions_limit,
       ROUND(AVG(h.pdb_avg_running_sessions), 6) AS avg_avg_running_sessions,
       ROUND(AVG(h.pdb_avg_waiting_sessions), 6) AS avg_avg_waiting_sessions,
       ROUND(AVG(h.pdb_headroom_sessions), 6) AS avg_headroom_sessions,
       ROUND(AVG(h.pdb_iops), 6) AS avg_iops,
       ROUND(AVG(h.pdb_mbps), 6) AS avg_mbps,
       ROUND(MAX(h.pdb_running_sessions_limit), 6) AS max_running_sessions_limit,
       ROUND(MAX(h.pdb_avg_running_sessions), 6) AS max_avg_running_sessions,
       ROUND(MAX(h.pdb_avg_waiting_sessions), 6) AS max_avg_waiting_sessions,
       ROUND(MAX(h.pdb_headroom_sessions), 6) AS max_headroom_sessions,
       ROUND(MAX(h.pdb_iops), 6) AS max_iops,
       ROUND(MAX(h.pdb_mbps), 6) AS max_mbps
  FROM rsrc_mgr_metric_history_ext h
 GROUP BY
       h.con_id
)
SELECT c.name AS pdb_name, h.num_cpus, 
       '|' AS "|",
       h.avg_running_sessions_limit, 
       h.avg_avg_running_sessions, h.avg_headroom_sessions, h.avg_avg_waiting_sessions, 
       h.avg_iops, h.avg_mbps, 
       '|' AS "|",
       h.max_running_sessions_limit, 
       h.max_avg_running_sessions, h.max_headroom_sessions, h.max_avg_waiting_sessions, 
       h.max_iops, h.max_mbps
  FROM rsrc_mgr_metric_history_aggr h, v$containers c
 WHERE c.con_id = h.con_id
 ORDER BY
       c.name
/
PRO
PRO Running Sessions Limit: Resource Manager Utilization Limit (CPU cap after which throttling stars.)
PRO Average Running Sessions: AAS on CPU.
PRO Available Headroom Sessions: Potential AAS slots available for sessions on CPU.
PRO Average Waiting Sessions: AAS wating on Scheduler (Resource Manager throttling.)
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--