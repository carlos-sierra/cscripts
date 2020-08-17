----------------------------------------------------------------------------------------
--
-- File name:   cs_cores_and_disk_for_customer_pie.sql 
--
-- Purpose:     DB CPU Cores and Disk Space used for one Customer
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB that contains repository (SEA1 KIEV99A1)
--
--              Enter filter parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_cores_and_disk_for_customer_pie.sql
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
DEF cs_script_name = 'cs_cores_and_disk_for_customer_pie';
--
COL customer_or_pdb FOR A64;
COL realm FOR A5;
COL rgn FOR A3;
COL rgn_ord FOR A3 NOPRI;
COL region FOR A16;
COL locale FOR A6;
COL cdbs FOR 9,990;
COL pdbs FOR 9,990;
COL kiev FOR 9,990;
COL aas_on_cpu FOR 999,990.0 HEA 'CPU CORES';
COL used_space_gbs FOR 999,990.0 HEA 'DISK GBs';
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF aas_on_cpu used_space_gbs pdbs kiev ON REPORT;
--
SELECT COALESCE(customer_oci_service, 'PDB:'||pdb_name) AS customer_or_pdb, 
       ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu,        
       ROUND(SUM(used_space_gbs), 3) AS used_space_gbs,   
       COUNT(DISTINCT jdbc_connect_string) AS pdbs, 
       SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev,
       COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 GROUP BY
       COALESCE(customer_oci_service, 'PDB:'||pdb_name)
 ORDER BY
       CASE WHEN COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE 'PDB:%' THEN 2 ELSE 1 END,
       COALESCE(customer_oci_service, 'PDB:'||pdb_name)
/
PRO
PRO 1. Enter CUSTOMER_OR_PDB:
DEF cs_customer_or_pdb = '&1.';
UNDEF 1;
--
SELECT realm, 
       ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu,        
       ROUND(SUM(used_space_gbs), 3) AS used_space_gbs,   
       COUNT(DISTINCT jdbc_connect_string) AS pdbs, 
       SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev,
       COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 WHERE COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE '%&&cs_customer_or_pdb.%'
 GROUP BY
       realm
 ORDER BY
       realm
/
PRO
PRO 2. Enter REALM: [{*}|OC1|OC2|OC3]
DEF cs_realm = '&2.';
UNDEF 2;
COL cs_realm NEW_V cs_realm FOR A3 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_realm.')), '*') AS cs_realm FROM DUAL
/
--
SELECT realm, rgn_ord, rgn, region, 
       ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu,        
       ROUND(SUM(used_space_gbs), 3) AS used_space_gbs,   
       COUNT(DISTINCT jdbc_connect_string) AS pdbs,
       SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev, 
       COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 WHERE COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE '%&&cs_customer_or_pdb.%'
   AND '&&cs_realm.' IN ('*', realm)
 GROUP BY
       realm, rgn_ord, rgn, region
 ORDER BY
       realm, rgn_ord, rgn, region
/
PRO
PRO 3. Enter RGN or REGION: [{*}|RGN|REGION]
DEF cs_rgn_or_region = '&3.';
UNDEF 3;
COL cs_rgn_or_region NEW_V cs_rgn_or_region FOR A32 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_rgn_or_region.')), '*') AS cs_rgn_or_region FROM DUAL
/
--
SELECT realm, rgn_ord, rgn, region, locale, 
       ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu,        
       ROUND(SUM(used_space_gbs), 3) AS used_space_gbs,   
       COUNT(DISTINCT jdbc_connect_string) AS pdbs, 
       SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev, 
       COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 WHERE COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE '%&&cs_customer_or_pdb.%'
   AND '&&cs_realm.' IN ('*', realm)
   AND '&&cs_rgn_or_region.' IN ('*', rgn, region)
 GROUP BY
       realm, rgn_ord, rgn, region, locale
 ORDER BY
       realm, rgn_ord, rgn, region, locale
/
PRO
PRO 4. Enter LOCALE: [{*}|AD1|AD2|AD3|RGN]
DEF cs_locale = '&4.';
UNDEF 4;
COL cs_locale NEW_V cs_locale FOR A32 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_locale.')), '*') AS cs_locale FROM DUAL
/
SELECT CASE WHEN '&&cs_locale.' IN ('*', 'AD1', 'AD2', 'AD3', 'RGN') THEN '&&cs_locale.' ELSE '*' END AS cs_locale FROM DUAL
/
--
SELECT realm, rgn_ord, rgn, region, locale, db_name, 
       ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu,        
       ROUND(SUM(used_space_gbs), 3) AS used_space_gbs,   
       COUNT(DISTINCT jdbc_connect_string) AS pdbs, 
       SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev,
       COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 WHERE COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE '%&&cs_customer_or_pdb.%'
   AND '&&cs_realm.' IN ('*', realm)
   AND '&&cs_rgn_or_region.' IN ('*', rgn, region)
   AND '&&cs_locale.' IN ('*', locale)
 GROUP BY
       realm, rgn_ord, rgn, region, locale, db_name
 ORDER BY
       realm, rgn_ord, rgn, region, locale, db_name
/
PRO
PRO 5. Enter DB_NAME: [{*}|DB_NAME]
DEF cs_dbname = '&5.';
UNDEF 5;
COL cs_dbname NEW_V cs_dbname FOR A9 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_dbname.')), '*') AS cs_dbname FROM DUAL
/
--
PRO
PRO 6. Enter KIEV Only: [{Y}|N]
DEF cs_kiev_only = '&6.';
UNDEF 6;
COL cs_kiev_only NEW_V cs_kiev_only FOR A3 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_kiev_only.')), 'Y') AS cs_kiev_only FROM DUAL
/
SELECT CASE WHEN '&&cs_kiev_only.' IN ('Y', 'N') THEN '&&cs_kiev_only.' ELSE 'Y' END AS cs_kiev_only FROM DUAL
/
--
PRO
PRO 7. Enter Metric: [{CPU}|DISK]
DEF cs_metric = '&7.';
UNDEF 7;
COL cs_metric NEW_V cs_metric FOR A4 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_metric.')), 'CPU') AS cs_metric FROM DUAL
/
SELECT CASE WHEN '&&cs_metric.' IN ('CPU', 'DISK') THEN '&&cs_metric.' ELSE 'CPU' END AS cs_metric FROM DUAL
/
COL cs_display_metric NEW_V cs_display_metric FOR A16 NOPRI TRUNC;
SELECT CASE '&&cs_metric.' 
WHEN 'CPU' THEN 'DB CPU Cores'
WHEN 'DISK' THEN 'DB Disk Space (GBs)'
END cs_display_metric FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = '&&cs_display_metric. used by &&cs_customer_or_pdb.';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = '';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_1 = "";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_customer_or_pdb." "&&cs_realm." "&&cs_rgn_or_region." "&&cs_locale." "&&cs_dbname." "&&cs_metric."';
--
DEF chart_foot_note_0 = '';
DEF chart_foot_note_1 = '';
-- [Line|Area|SteppedArea|ScatterPie]
DEF cs_chart_type = 'Pie';
DEF cs_chart_width = '900px';
DEF cs_chart_height = '450px';
DEF cs_chartarea_height = '80%';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '//';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '';
-- pieSliceText [{percentage}|value|label|none]
DEF cs_chart_pie_slice_text = "// pieSliceText: 'percentage',";
--DEF cs_chart_pie_slice_text = "pieSliceText: 'value',";
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'VALUE'      
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/

WITH
resources_per_pdb AS (
SELECT 
  pdb_name
, ROUND(SUM(dbrm_cap), 3) AS dbrm_cap             
, ROUND(SUM(aas_on_cpu_or_dbrm), 3) AS aas_on_cpu_or_dbrm
, ROUND(SUM(aas_on_cpu), 3) AS aas_on_cpu
, ROUND(100 * SUM(aas_on_cpu) / SUM(SUM(aas_on_cpu)) OVER (), 3) AS aas_on_cpu_p
, ROUND(SUM(mas_on_cpu_or_dbrm), 3) AS mas_on_cpu_or_dbrm  
, ROUND(SUM(mas_on_cpu), 3) AS mas_on_cpu          
, ROUND(SUM(used_space_gbs), 3) AS used_space_gbs      
, ROUND(100 * SUM(used_space_gbs) / SUM(SUM(used_space_gbs)) OVER (), 3) AS used_space_gbs_p
, ROUND(SUM(tablespace_size_gbs), 3) AS tablespace_size_gbs 
, MAX(last_updated) AS last_updated               
, COUNT(DISTINCT jdbc_connect_string) AS pdbs           
, SUM(CASE kiev WHEN 'Y' THEN 1 ELSE 0 END) AS kiev
, COUNT(DISTINCT host_name) AS cdbs
  FROM c##iod.resources_per_pdb_v
 WHERE COALESCE(customer_oci_service, 'PDB:'||pdb_name) LIKE '%&&cs_customer_or_pdb.%'
   AND '&&cs_realm.' IN ('*', realm)
   AND '&&cs_rgn_or_region.' IN ('*', rgn, region)
   AND '&&cs_locale.' IN ('*', locale)
   AND '&&cs_dbname.' IN ('*', db_name)
   AND '&&cs_kiev_only.' IN ('N', kiev)
 GROUP BY
       pdb_name
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       pdb_name slice,
       CASE '&&cs_metric.' WHEN 'CPU' THEN ROUND(aas_on_cpu, 1) ELSE ROUND(used_space_gbs, 1) END AS value,
       ' ('||TRIM(TO_CHAR(CASE '&&cs_metric.' WHEN 'CPU' THEN ROUND(aas_on_cpu_p, 1) ELSE ROUND(used_space_gbs_p, 1) END, '990.0'))||'%)' AS percent
  FROM resources_per_pdb
)
SELECT ', ['''||TRIM(TO_CHAR(value, '999,990.0'))||' '||slice||percent||''','||value||']'
  FROM summary
 ORDER BY
       value DESC
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
--@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_id_chart_pre.sql
PRO <pre>
PRO DATE_TIME    : &&cs_date_time.Z
PRO REFERENCE    : &&cs_reference.
PRO LOCALE       : &&cs_realm. &&cs_region. &&cs_locale.
PRO DATABASE     : &&cs_db_name_u. (&&cs_db_version.) STARTUP:&&cs_startup_time.
PRO CONTAINER    : &&cs_db_name..&&cs_con_name. (&&cs_con_id.) &&cs_pdb_open_mode.
PRO CPU          : CORES:&&cs_num_cpu_cores. THREADS:&&cs_num_cpus. COUNT:&&cs_cpu_count. ALLOTTED:&&cs_allotted_cpu. PLAN:&&cs_resource_manager_plan.
PRO HOST         : &&cs_host_name.
PRO CONNECT_STRNG: &&cs_easy_connect_string.
PRO SCRIPT       : &&cs_script_name..sql
PRO KIEV_VERSION : &&cs_kiev_version. (&&cs_schema_name.)
PRO METRIC       : "&&cs_metric." [{CPU}|DISK]
PRO </pre>
@@cs_internal/cs_spool_id_chart_post.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--