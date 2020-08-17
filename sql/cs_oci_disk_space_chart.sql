----------------------------------------------------------------------------------------
--
-- File name:   cs_oci_disk_space_chart.sql
--
-- Purpose:     Disk Space Utilization Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_oci_disk_space_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
-- 1 TiB = 1.099511627776 TB
DEF TiB_to_TB = '1.099511627776';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_oci_disk_space_chart';
DEF cs_hours_range_default = '2880';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM c##iod.oci_iod_df_u02
/
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM c##iod.oci_tablespaces_hist
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL realm FOR A5;
SELECT DISTINCT realm
  FROM c##iod.oci_iod_df_u02
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 ORDER BY 1
/
PRO
PRO 3. Realm: (opt)
DEF cs_realm_p = '&3.';
UNDEF 3;
--
COL region FOR A32;
SELECT DISTINCT region
  FROM c##iod.oci_iod_df_u02
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs_realm_p.' IS NULL OR UPPER(realm) = UPPER('&&cs_realm_p.'))
 ORDER BY 1
/
PRO
PRO 4. Region: (opt)
DEF cs_region_p = '&4.';
UNDEF 4;
--
COL locale FOR A6;
SELECT DISTINCT locale
  FROM c##iod.oci_iod_df_u02
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs_realm_p.' IS NULL OR UPPER(realm) = UPPER('&&cs_realm_p.'))
   AND ('&&cs_region_p.' IS NULL OR UPPER(region) = UPPER('&&cs_region_p.'))
 ORDER BY 1
/
PRO
PRO 5. Locale: (opt)
DEF cs_locale_p = '&5.';
UNDEF 5;
--
COL dbname FOR A9;
SELECT DISTINCT dbname
  FROM c##iod.oci_iod_df_u02
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs_realm_p.' IS NULL OR UPPER(realm) = UPPER('&&cs_realm_p.'))
   AND ('&&cs_region_p.' IS NULL OR UPPER(region) = UPPER('&&cs_region_p.'))
   AND ('&&cs_locale_p.' IS NULL OR UPPER(locale) = UPPER('&&cs_locale_p.'))
 ORDER BY 1
/
PRO
PRO 6. DB Name: (opt)
DEF cs_dbname_p = '&6.';
UNDEF 6;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
--DEF report_title = "Disk FileSystem u02 and DB Utilization between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF report_title = "Disk FileSystem u02 and DB Utilization";
DEF chart_title = 'Realm:"&&cs_realm_p." Region:"&&cs_region_p." Locale:"&&cs_locale_p." DBName:"&&cs_dbname_p."';
DEF xaxis_title = '';
--DEF vaxis_title = "Tebibytes (TiB)";
DEF vaxis_title = "Terabytes (TB)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&baseline., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF vaxis_viewwindow = ", viewWindow: {min:0}";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_realm_p." "&&cs_region_p." "&&cs_locale_p." "&&cs_dbname_p."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'FileSystem u02 TB Space'
PRO ,'FileSystem u02 TB Used'
PRO ,'Database TB Allocated'
PRO ,'Database TB Used'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
per_day AS (
SELECT 
  TRUNC(snap_time, 'DD') AS snap_time
, u02_size_gib
, u02_used_gib
, u02_available_gib
, oem_allocated_space_gib
, oem_used_space_gib
, met_max_size_gib
, met_used_space_gib
, ROW_NUMBER() OVER (PARTITION BY realm, region, locale, dbname, TRUNC(snap_time, 'DD') ORDER BY u02_size_gib DESC NULLS LAST, u02_used_gib DESC NULLS LAST) AS rn
  FROM c##iod.oci_disk_space_v
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs_realm_p.' IS NULL OR UPPER(realm) = UPPER('&&cs_realm_p.'))
   AND ('&&cs_region_p.' IS NULL OR UPPER(region) = UPPER('&&cs_region_p.'))
   AND ('&&cs_locale_p.' IS NULL OR UPPER(locale) = UPPER('&&cs_locale_p.'))
   AND ('&&cs_dbname_p.' IS NULL OR UPPER(dbname) = UPPER('&&cs_dbname_p.'))
),
my_query AS (
SELECT 
  snap_time
  --
, ROUND(SUM(u02_size_gib)/POWER(2,10),3) AS u02_size_tib
, ROUND(SUM(u02_used_gib)/POWER(2,10),3) AS u02_used_tib
, ROUND(SUM(u02_available_gib)/POWER(2,10),3) AS u02_available_tib
, ROUND(SUM(oem_allocated_space_gib)/POWER(2,10),3) AS oem_allocated_space_tib
, ROUND(SUM(oem_used_space_gib)/POWER(2,10),3) AS oem_used_space_tib
, ROUND(SUM(met_max_size_gib)/POWER(2,10),3) AS met_max_size_tib
, ROUND(SUM(met_used_space_gib)/POWER(2,10),3) AS met_used_space_tib
  --
, ROUND(&&TiB_to_TB.*SUM(u02_size_gib)/POWER(2,10),3) AS u02_size_tb
, ROUND(&&TiB_to_TB.*SUM(u02_used_gib)/POWER(2,10),3) AS u02_used_tb
, ROUND(&&TiB_to_TB.*SUM(u02_available_gib)/POWER(2,10),3) AS u02_available_tb
, ROUND(&&TiB_to_TB.*SUM(oem_allocated_space_gib)/POWER(2,10),3) AS oem_allocated_space_tb
, ROUND(&&TiB_to_TB.*SUM(oem_used_space_gib)/POWER(2,10),3) AS oem_used_space_tb
, ROUND(&&TiB_to_TB.*SUM(met_max_size_gib)/POWER(2,10),3) AS met_max_size_tb
, ROUND(&&TiB_to_TB.*SUM(met_used_space_gib)/POWER(2,10),3) AS met_used_space_tb
  --
  FROM per_day
 WHERE rn = 1
GROUP BY snap_time 
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||q.u02_size_tb|| 
       ','||q.u02_used_tb|| 
       ','||q.oem_allocated_space_tb|| 
       ','||q.oem_used_space_tb|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Line';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
--@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_id_chart_pre.sql
@@cs_internal/cs_spool_id_chart_post.sql
--
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
