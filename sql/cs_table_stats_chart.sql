----------------------------------------------------------------------------------------
--
-- File name:   cs_table_stats_chart.sql
--
-- Purpose:     CBO Statistics History for given Table
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
--              SQL> @cs_table_stats_chart.sql
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
DEF cs_script_name = 'cs_table_stats_chart';

--
ALTER SESSION SET container = CDB$ROOT;
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT DISTINCT h.owner
  FROM c##iod.table_stats_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
SELECT DISTINCT h.table_name
  FROM c##iod.table_stats_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND h.owner = UPPER(TRIM('&&table_owner.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
COL table_name NEW_V table_name NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name.";
DEF chart_title = "&&table_owner..&&table_name.";
DEF xaxis_title = "";
DEF vaxis_title = "";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Num Rows'
PRO ,'Blocks'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT last_analyzed,
       num_rows,
       blocks,
       avg_row_len,
       sample_size
  FROM c##iod.table_stats_hist
 WHERE pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND table_name = UPPER(TRIM('&&table_name.'))
)
SELECT ', [new Date('||
       TO_CHAR(q.last_analyzed, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.last_analyzed, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.last_analyzed, 'DD')|| /* day */
       ','||TO_CHAR(q.last_analyzed, 'HH24')|| /* hour */
       ','||TO_CHAR(q.last_analyzed, 'MI')|| /* minute */
       ','||TO_CHAR(q.last_analyzed, 'SS')|| /* second */
       ')'||
       ','||q.num_rows|| 
       ','||q.blocks|| 
       ']'
  FROM my_query q
 ORDER BY
       q.last_analyzed
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|Scatter]
DEF cs_chart_type = 'Scatter';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
