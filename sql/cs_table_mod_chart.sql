----------------------------------------------------------------------------------------
--
-- File name:   cs_table_mod_chart.sql
--
-- Purpose:     Modification History for given Table
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/20
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_mod_chart.sql
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
DEF cs_script_name = 'cs_table_mod_chart';
--
COL pdb_name NEW_V pdb_name FOR A30;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT DISTINCT owner table_owner
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
 ORDER BY 1
/
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
--
SELECT DISTINCT table_name
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
   AND owner = UPPER(TRIM('&&table_owner.'))
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
--
SELECT '&&cs_file_prefix._&&table_owner..&&table_name._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name.";
DEF chart_title = "&&table_owner..&&table_name.";
DEF xaxis_title = "";
DEF vaxis_title = "Rows per Hour";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:0";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Inserts'
PRO ,'Deletes'
PRO ,'Updates'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT last_analyzed,
       timestamp,
       num_rows,
       inserts,
       updates,
       deletes,
       truncated,
       drop_segments,
       ROUND(inserts / ((timestamp - last_analyzed) * 24)) inserts_per_hr,
       ROUND(updates / ((timestamp - last_analyzed) * 24)) updates_per_hr,
       ROUND(deletes / ((timestamp - last_analyzed) * 24)) deletes_per_hr
  FROM c##iod.tab_modifications_hist
 WHERE pdb_name = UPPER(TRIM('&&pdb_name.'))
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
)
SELECT ', [new Date('||
       TO_CHAR(q.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(q.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(q.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(q.timestamp, 'SS')|| /* second */
       ')'||
       ','||q.inserts_per_hr|| 
       ','||q.deletes_per_hr|| 
       ','||q.updates_per_hr|| 
       ']'
  FROM my_query q
 ORDER BY
       q.timestamp
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Line';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
PRO
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
--
ALTER SESSION SET CONTAINER = &&pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
