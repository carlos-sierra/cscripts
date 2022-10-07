----------------------------------------------------------------------------------------
--
-- File name:   cs_dba_hist_parameter.sql
--
-- Purpose:     System Parameters History
--
-- Author:      Carlos Sierra
--
-- Version:     2021/12/06
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dba_hist_parameter.sql
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
DEF cs_script_name = 'cs_dba_hist_parameter';
DEF cs_hours_range_default = '1440';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL parameter_name FOR A43;
COL dist_values FOR 999,990;
--
SELECT h.parameter_name, COUNT(DISTINCT h.value) AS dist_values
  FROM dba_hist_parameter h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND &&cs_con_id. IN (1, h.con_id)
 GROUP BY
       h.parameter_name
HAVING COUNT(DISTINCT h.value) > 1
 ORDER BY
       h.parameter_name
/
PRO
PRO 3. Parameter Name (opt):
DEF parameter_name = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&parameter_name."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO PARAMETER    : "&&parameter_name."
--
PRO
PRO PARAMETERS CHANGED
PRO ~~~~~~~~~~~~~~~~~~
SELECT h.parameter_name, COUNT(DISTINCT h.value) AS dist_values
  FROM dba_hist_parameter h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND &&cs_con_id. IN (1, h.con_id)
 GROUP BY
       h.parameter_name
HAVING COUNT(DISTINCT h.value) > 1
 ORDER BY
       h.parameter_name
/

COL begin_time FOR A19;
COL end_time FOR A19;
COL parameter_name FOR A43;
COL prior_value FOR A50 HEA 'BEGIN_VALUE';
COL value FOR A50 HEA 'END_VALUE';
COL change FOR 999,999,999,999,990 HEA 'NET_CHANGE';
COL con_id FOR 999990;
COL pdb_name FOR A30 TRUNC;
--
BREAK ON begin_time SKIP PAGE ON end_time;
--
PRO
PRO PARAMETERS CHANGES
PRO ~~~~~~~~~~~~~~~~~~
WITH
parameter_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.dbid,
       h.instance_number,
       h.parameter_name,
       LAG(h.value) OVER (PARTITION BY h.dbid, h.instance_number, h.parameter_name, h.con_id ORDER BY h.snap_id) AS prior_value,
       h.value,
       h.con_id
  FROM dba_hist_parameter h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND &&cs_con_id. IN (1, h.con_id)
   AND ('&&parameter_name.' IS NULL OR UPPER(parameter_name) = UPPER('&&parameter_name.'))
),
parameter_changes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.dbid,
       h.instance_number,
       h.parameter_name,
       h.prior_value,
       h.value,
       h.con_id,
       s.begin_interval_time,
       s.end_interval_time
  FROM parameter_hist h,
       dba_hist_snapshot s
 WHERE NVL(h.value, '-666') <> NVL(h.prior_value, '-666')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
)
SELECT CAST(p.begin_interval_time AS DATE) AS begin_time,
       CAST(p.end_interval_time AS DATE) AS end_time,
       p.parameter_name,
       p.prior_value,
       p.value,
       CASE WHEN REGEXP_LIKE(p.prior_value, '^[^a-zA-Z]*$') AND REGEXP_LIKE(p.value, '^[^a-zA-Z]*$') THEN TO_NUMBER(p.value) - TO_NUMBER(p.prior_value) END AS change, -- https://asktom.oracle.com/pls/apex/asktom.search?tag=determine-whether-the-given-is-numeric-alphanumeric-and-hexadecimal
       p.con_id,
       (SELECT c.name AS pdb_name FROM v$containers c WHERE c.con_id = p.con_id) AS pdb_name
  FROM parameter_changes p
 ORDER BY
       p.begin_interval_time,
       p.parameter_name,
       p.con_id
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&parameter_name."
--
@@cs_internal/cs_spool_tail.sql
--
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
