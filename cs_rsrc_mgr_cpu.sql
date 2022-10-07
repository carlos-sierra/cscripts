----------------------------------------------------------------------------------------
--
-- File name:   dbrmc.sql | cs_rsrc_mgr_cpu.sql
--
-- Purpose:     Database Resource Manager (DBRM) CPU Utilization per PDB (from ASH AWR)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/19
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_cpu.sql
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
DEF cs_script_name = 'cs_rsrc_mgr_cpu';
DEF cs_script_acronym = 'dbrmc.sql | ';
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
COL pdb_name FOR A30 HEA '.|.|PDB Name';
COL avg_aas_on_cpu FOR 999,990.0 HEA 'Sessions|ON CPU|Average';
COL p95_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p95th PCTL';
COL p97_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p97th PCTL';
COL p99_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p99th PCTL';
COL p999_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p99.9th PCTL';
COL max_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|Maximum';
--
BREAK ON REPORT;
COMPUTE SUM OF avg_aas_on_cpu p95_aas_on_cpu p97_aas_on_cpu p99_aas_on_cpu p999_aas_on_cpu max_aas_on_cpu ON REPORT;
--
WITH
ash_by_con_and_sample AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       h.con_id, h.sample_id, COUNT(*) AS aas_on_cpu
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND h.dbid = &&cs_dbid. AND h.instance_number = &&cs_instance_number. AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to. 
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.session_state = 'ON CPU'
   AND ROWNUM >= 1
 GROUP BY
       h.con_id, h.sample_id
),
ash_by_con AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       h.con_id,
       AVG(h.aas_on_cpu) AS avg_aas_on_cpu,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p95_aas_on_cpu,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p97_aas_on_cpu,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p99_aas_on_cpu,
       PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p999_aas_on_cpu,
       MAX(h.aas_on_cpu) AS max_aas_on_cpu
  FROM ash_by_con_and_sample h
 WHERE ROWNUM >= 1
 GROUP BY
       h.con_id
),
ash_by_con_ext AS (
SELECT c.name AS pdb_name,
       h.avg_aas_on_cpu, h.p95_aas_on_cpu, h.p97_aas_on_cpu, h.p99_aas_on_cpu, h.p999_aas_on_cpu, h.max_aas_on_cpu
  FROM ash_by_con h, v$containers c
 WHERE c.con_id = h.con_id
)
SELECT pdb_name, avg_aas_on_cpu, p95_aas_on_cpu, p97_aas_on_cpu, p99_aas_on_cpu, p999_aas_on_cpu, max_aas_on_cpu
  FROM ash_by_con_ext
 ORDER BY
       pdb_name
/
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