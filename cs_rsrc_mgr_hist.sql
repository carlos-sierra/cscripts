----------------------------------------------------------------------------------------
--
-- File name:   dbrmh.sql | cs_rsrc_mgr_hist.sql
--
-- Purpose:     Database Resource Manager (DBRM) Metrics History (by minute)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/19
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_hist.sql
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
DEF cs_script_name = 'cs_rsrc_mgr_hist';
DEF cs_script_acronym = 'dbrmh.sql | ';
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
COL begin_time FOR A19 HEA '.|.|.|Begin Time';
COL end_time FOR A19 HEA 'End Time';
COL num_cpus FOR 9990 HEA 'CPU|Count|Rsrc|Mgr';
COL pdb_running_sessions_limit FOR 999,990.0 HEA 'PDB|Running|Sessions|Limit';
COL pdb_avg_running_sessions FOR 999,990.0 HEA 'PDB|Average|Running|Sessions';
COL pdb_avg_waiting_sessions FOR 999,990.0 HEA 'PDB|Average|Waiting|Sessions';
COL pdb_headroom_sessions FOR 999,990.0 HEA 'PDB|Available|Headroom|Sessions';
COL pdb_iops FOR 9,999,990 HEA 'PDB|IOPS';
COL pdb_mbps FOR 9,999,990 HEA 'PDB|MBPS';
COL cdb_running_sessions_limit FOR 999,990.0 HEA 'CDB|Running|Sessions|Limit';
COL cdb_avg_running_sessions FOR 999,990.0 HEA 'CDB|Average|Running|Sessions';
COL cdb_avg_waiting_sessions FOR 999,990.0 HEA 'CDB|Average|Waiting|Sessions';
COL cdb_headroom_sessions FOR 999,990.0 HEA 'CDB|Available|Headroom|Sessions';
COL cdb_iops FOR 9,999,990 HEA 'CDB|IOPS';
COL cdb_mbps FOR 9,999,990 HEA 'CDB|MBPS';
--
BREAK ON REPORT;
COMPUTE MAX AVG MIN OF num_cpus pdb_running_sessions_limit pdb_avg_running_sessions pdb_avg_waiting_sessions pdb_headroom_sessions pdb_iops pdb_mbps cdb_running_sessions_limit cdb_avg_running_sessions cdb_avg_waiting_sessions cdb_headroom_sessions cdb_iops cdb_mbps ON REPORT;
--
PRO
PRO DB Resource Manager Metrics from HIST for PDB: &&cs_con_name. (&&cs_tools_schema..dbc_rsrcmgrmetric_history and v$rsrcmgrmetric_history)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
rsrc_mgr_metric_history AS (
SELECT v.begin_time, v.end_time, 
       MAX(v.num_cpus) AS num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.running_sessions_limit ELSE 0 END), 6) AS pdb_running_sessions_limit,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_running_sessions ELSE 0 END), 6) AS pdb_avg_running_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_waiting_sessions ELSE 0 END), 6) AS pdb_avg_waiting_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_requests ELSE 0 END), 6) AS pdb_io_requests,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_megabytes ELSE 0 END), 6) AS pdb_io_megabytes,
       ROUND(SUM(v.running_sessions_limit), 6) AS cdb_running_sessions_limit,
       ROUND(SUM(v.avg_running_sessions), 6) AS cdb_avg_running_sessions,
       ROUND(SUM(v.avg_waiting_sessions), 6) AS cdb_avg_waiting_sessions,
       ROUND(SUM(v.io_requests), 6) AS cdb_io_requests,
       ROUND(SUM(v.io_megabytes), 6) AS cdb_io_megabytes
  FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') < SYSDATE - (1/24) -- get history from dbc table iff time_fromm is older than 1h
   AND v.end_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND v.begin_time <= TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       v.begin_time, v.end_time
UNION
SELECT v.begin_time, v.end_time, 
       MAX(v.num_cpus) AS num_cpus, (v.end_time - v.begin_time) * 24 * 3600 AS seconds,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.running_sessions_limit ELSE 0 END), 6) AS pdb_running_sessions_limit,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_running_sessions ELSE 0 END), 6) AS pdb_avg_running_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.avg_waiting_sessions ELSE 0 END), 6) AS pdb_avg_waiting_sessions,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_requests ELSE 0 END), 6) AS pdb_io_requests,
       ROUND(SUM(CASE v.con_id WHEN &&cs_con_id. THEN v.io_megabytes ELSE 0 END), 6) AS pdb_io_megabytes,
       ROUND(SUM(v.running_sessions_limit), 6) AS cdb_running_sessions_limit,
       ROUND(SUM(v.avg_running_sessions), 6) AS cdb_avg_running_sessions,
       ROUND(SUM(v.avg_waiting_sessions), 6) AS cdb_avg_waiting_sessions,
       ROUND(SUM(v.io_requests), 6) AS cdb_io_requests,
       ROUND(SUM(v.io_megabytes), 6) AS cdb_io_megabytes
  FROM v$rsrcmgrmetric_history v
 WHERE v.consumer_group_name = 'OTHER_GROUPS'
   AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') > SYSDATE - (1/24) -- get history from memory iff time_to is within last 1h
 GROUP BY
       v.begin_time, v.end_time
),
rsrc_mgr_metric_history_ext AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.begin_time, h.end_time, h.num_cpus,
       h.pdb_running_sessions_limit, h.pdb_avg_running_sessions, h.pdb_avg_waiting_sessions,
       ROUND(GREATEST(h.pdb_running_sessions_limit - h.pdb_avg_running_sessions /* - h.pdb_avg_waiting_sessions */, 0), 6) AS pdb_headroom_sessions,
       ROUND(h.pdb_io_requests / h.seconds, 6) AS pdb_iops, ROUND(h.pdb_io_megabytes / h.seconds, 6) AS pdb_mbps,
       h.cdb_running_sessions_limit, h.cdb_avg_running_sessions, h.cdb_avg_waiting_sessions,
       ROUND(GREATEST(LEAST(h.num_cpus, h.cdb_running_sessions_limit) - h.cdb_avg_running_sessions /* - h.cdb_avg_waiting_sessions */, 0), 6) AS cdb_headroom_sessions,
       ROUND(h.cdb_io_requests / h.seconds, 6) AS cdb_iops, ROUND(h.cdb_io_megabytes / h.seconds, 6) AS cdb_mbps
  FROM rsrc_mgr_metric_history h
 WHERE h.seconds > 0
   AND ROWNUM >= 1
)
SELECT h.begin_time, h.end_time, h.num_cpus, 
       '|' AS "|",
       h.pdb_running_sessions_limit, 
       h.pdb_avg_running_sessions, h.pdb_headroom_sessions, h.pdb_avg_waiting_sessions, 
       h.pdb_iops, h.pdb_mbps, 
       '|' AS "|",
       h.cdb_running_sessions_limit, 
       h.cdb_avg_running_sessions, h.cdb_headroom_sessions, h.cdb_avg_waiting_sessions, 
       h.cdb_iops, h.cdb_mbps
  FROM rsrc_mgr_metric_history_ext h
 ORDER BY
       h.begin_time, h.end_time
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