----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_pdb_utilization.sql
--
-- Purpose:     Health Check (HC) PDB Utilization
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/19
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_pdb_utilization.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_pdb_utilization';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
BREAK ON hc_pdb_in_use_value SKIP PAGE DUPL;
COMPUTE SUM OF avg_running_sessions_7d avg_running_sessions sessions avg_sessions_7d max_sessions_7d total_allocated_bytes ON hc_pdb_in_use_value;
--
COL hc_pdb_in_use_value FOR A10 HEA 'PDB in use|HC Value';
COL hc_pdb_in_use_status FOR A10 HEA 'PDB in use|HC Status';
COL con_id FOR 999990;
COL pdb_name FOR A30 TRUNC;
COL created FOR A19;
COL load FOR A4;
COL avg_running_sessions_7d FOR 990.000 HEA 'AVG Running|Sessions 7d';
COL avg_running_sessions FOR 990.000 HEA 'AVG Running|Sessions Now';
COL reads FOR A5;
COL sessions FOR 999,990 HEA 'Sessions|Now';
COL avg_sessions_7d FOR 9,990.000 HEA '7d AVG|Sessions';
COL max_sessions_7d FOR 999,990 HEA '7d MAX|Sessions';
COL writes FOR A6;
COL delta_appl_used_space_7d FOR A12 HEA '7d Delta|Appl|Used Space';
COL appl_used_space FOR A12 HEA 'Appl|Used Space';
COL appl_free_space FOR A12 HEA 'Appl|Free Space';
COL appl_allocated_space FOR A12 HEA 'Appl|Alloc Space';
COL total_allocated_space FOR A12 HEA 'Total|Alloc Space';
COL total_allocated_bytes FOR 999,999,999,999,990 HEA 'Total|Alloc Bytes';
COL kiev_or_wf FOR A5 HEA 'KIEV|or WF';
-- COL delta_kt_space_7d FOR A12 HEA '7d Delta|KIEV Trans|Used Space';
-- COL kt_space  FOR A12 HEA 'KIEV Trans|Used Space';
COL delta_kt_num_rows_7d FOR 9,999,999,990 HEA '7d Delta|KIEV Trans|Rows';
COL kt_num_rows FOR 9,999,999,990 HEA 'Current|KIEV Trans|Rows';
COL kt_blocks FOR 999,999,990 HEA 'Current|KIEV Trans|Blocks';
COL timestamp FOR A19 TRUNC;
COL ez_connect_string FOR A120;
--
PRO
PRO PDB Utilization (&cs_tools_schema..hc_pdb_manifest_v2)
PRO ~~~~~~~~~~~~~~~
SELECT v.hc_pdb_in_use_value,
       v.hc_pdb_in_use_status,
       v.con_id,
       v.pdb_name,
       v.created,
       '|' AS "|",
       v.load,
       v.avg_running_sessions_7d,
       v.avg_running_sessions,
       '|' AS "|",
       v.reads,
       v.sessions,
       v.avg_sessions_7d,
       v.max_sessions_7d,
       '|' AS "|",
       v.writes,
       LPAD(v.delta_appl_used_space_7d, 12) AS delta_appl_used_space_7d,
       LPAD(v.appl_used_space, 12) AS appl_used_space,
       LPAD(v.appl_free_space, 12) AS appl_free_space,
       LPAD(v.appl_allocated_space, 12) AS appl_allocated_space,
       LPAD(v.total_allocated_space, 12) AS total_allocated_space,
       v.total_allocated_bytes,
       '|' AS "|",
       v.kiev_or_wf,
      --  LPAD(v.delta_kt_space_7d, 12) AS delta_kt_space_7d,
      --  LPAD(v.kt_space, 12) AS kt_space,
       v.delta_kt_num_rows_7d,
       v.kt_num_rows,
       v.kt_blocks,
       '|' AS "|",
       v.timestamp,
       v.ez_connect_string
  FROM &cs_tools_schema..hc_pdb_manifest_v2 v
 WHERE &&cs_con_id. IN (1, v.con_id)
 ORDER BY
       v.hc_pdb_in_use_value,
       CASE v.hc_pdb_in_use_status WHEN 'PASS' THEN 1 WHEN 'FAIL' THEN 2 WHEN 'WARNING' THEN 3 WHEN 'INFO' THEN 4 ELSE 9 END,
       v.con_id,
       v.ez_connect_string
/
--
CLEAR BREAK;
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
