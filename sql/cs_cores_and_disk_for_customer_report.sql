----------------------------------------------------------------------------------------
--
-- File name:   cs_cores_and_disk_for_customer_report.sql
--
-- Purpose:     DB CPU Cores and Disk Space used for one Customer
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to CDB that contains repository (SEA1 KIEV99A1)
--
--              Enter filter parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_cores_and_disk_for_customer_report.sql
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
DEF cs_script_name = 'cs_cores_and_disk_for_customer_report';
--
COL customer_or_pdb FOR A64;
COL pdb_name FOR A30 TRUNC;
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
SELECT pdb_name, realm, rgn_ord, rgn, region, locale, db_name, 
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
   AND '&&cs_dbname.' IN ('*', db_name)
 GROUP BY
       pdb_name, realm, rgn_ord, rgn, region, locale, db_name
 ORDER BY
       pdb_name, realm, rgn_ord, rgn, region, locale, db_name
/
PRO
PRO 6. Enter PDB_NAME: [{*}|PDB_NAME]
DEF cs_pdbname = '&6.';
UNDEF 6;
COL cs_pdbname NEW_V cs_pdbname FOR A30 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_pdbname.')), '*') AS cs_pdbname FROM DUAL
/
--
PRO
PRO 7. Enter KIEV Only: [{Y}|N]
DEF cs_kiev_only = '&7.';
UNDEF 7;
COL cs_kiev_only NEW_V cs_kiev_only FOR A3 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_kiev_only.')), 'Y') AS cs_kiev_only FROM DUAL
/
SELECT CASE WHEN '&&cs_kiev_only.' IN ('Y', 'N') THEN '&&cs_kiev_only.' ELSE 'Y' END AS cs_kiev_only FROM DUAL
/
--
PRO
PRO 8. Enter ORDER BY: [{NAME}|CPU|DISK]
DEF cs_order_by = '&8.';
UNDEF 8;
COL cs_order_by NEW_V cs_order_by FOR A4 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_order_by.')), 'NAME') AS cs_order_by FROM DUAL
/
SELECT CASE WHEN '&&cs_order_by.' IN ('NAME', 'CPU', 'DISK') THEN '&&cs_order_by.' ELSE 'NAME' END AS cs_order_by FROM DUAL
/
COL cs_actual_order_by_clause NEW_V cs_actual_order_by_clause FOR A128 NOPRI TRUNC;
SELECT CASE '&&cs_order_by.' 
WHEN 'NAME' THEN 'pdb_name, realm, rgn_ord, rgn, region, locale, db_name'
WHEN 'CPU' THEN 'aas_on_cpu DESC, used_space_gbs DESC, pdb_name, realm, rgn_ord, rgn, region, locale, db_name'
WHEN 'DISK' THEN 'used_space_gbs DESC, aas_on_cpu DESC, pdb_name, realm, rgn_ord, rgn, region, locale, db_name'
END cs_actual_order_by_clause FROM DUAL
/
--
COL cs_default_top_n_rows NEW_V cs_default_top_n_rows FOR A4 NOPRI;
SELECT CASE '&&cs_order_by.' 
WHEN 'NAME' THEN '5000'
WHEN 'CPU' THEN '20'
WHEN 'DISK' THEN '20'
END cs_default_top_n_rows FROM DUAL
/
PRO
PRO 9. Top N Rows Only: [{&&cs_default_top_n_rows.}|1-10000]
DEF cs_top_n_rows = '&9.';
UNDEF 9;
COL cs_top_n_rows NEW_V cs_top_n_rows FOR A5 NOPRI TRUNC;
SELECT NVL(UPPER(TRIM('&&cs_top_n_rows.')), '&&cs_default_top_n_rows.') AS cs_top_n_rows FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_customer_or_pdb." "&&cs_realm." "&&cs_rgn_or_region." "&&cs_locale." "&&cs_dbname." "&&cs_pdbname." "&&cs_kiev_only." "&&cs_order_by." "&&cs_top_n_rows."
--@@cs_internal/cs_spool_id.sql
--CLEAR SCREEN;
PRO
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
PRO ORDER_BY     : "&&cs_order_by." [{NAME}|CPU|DISK]
PRO TOP_N_ROWS   : "&&cs_top_n_rows." [{&&cs_default_top_n_rows.}|1-10000]
--
COL cdbs FOR 9,990;
COL pdbs FOR 9,990;
COL host_cpu_cores FOR 9999,990 HEA 'HOST CPU|CORES';
COL host_cpu_threads FOR 9999,990 HEA 'HOST CPU|THREADS';
COL host_cpu_count FOR 9999,990 HEA 'HOST CPU|COUNT';
COL dbrm_cap FOR 999,990.0 HEA 'DBRM|CAP';
COL aas_on_cpu_or_dbrm FOR 999,999,990.0 HEA 'AVG ACT SESS|ON CPU OR DBRM';
COL aas_on_cpu FOR 999,999,990.0 HEA 'AVG ACT SESS|ON CPU';
COL mas_on_cpu_or_dbrm FOR 999,999,990.0 HEA 'MAX ACT SESS|ON CPU OR DBRM';
COL mas_on_cpu FOR 999,999,990.0 HEA 'MAX ACT SESS|ON CPU';
COL used_space_gbs FOR 999,990.0 HEA 'USED SPACE|GBs';
COL tablespace_size_gbs FOR 999,990.0 HEA 'TABLESPACE|SIZE GBs';
-- renaming more customer friendly:
COL aas_on_cpu FOR 999,990.0 HEA 'CPU CORES';
COL used_space_gbs FOR 999,990.0 HEA 'DISK GBs';
COL aas_on_cpu_p FOR 990.0 HEA 'Perc%';
COL used_space_gbs_p FOR 990.0 HEA 'Perc%';
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF kiev used_space_gbs_p aas_on_cpu_p pdbs host_cpu_cores host_cpu_threads host_cpu_count aas_on_cpu_or_dbrm aas_on_cpu mas_on_cpu_or_dbrm mas_on_cpu used_space_gbs tablespace_size_gbs dbrm_cap ON REPORT;
--
WITH
resources_per_pdb AS (
SELECT 
  realm, rgn_ord, rgn, region, locale, db_name, pdb_name
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
   AND '&&cs_pdbname.' IN ('*', pdb_name)
   AND '&&cs_kiev_only.' IN ('N', kiev)
 GROUP BY
       realm, rgn_ord, rgn, region, locale, db_name, pdb_name
)
SELECT 
  pdb_name
, aas_on_cpu
, aas_on_cpu_p
, used_space_gbs
, used_space_gbs_p
, pdbs
, kiev
, realm, rgn_ord, rgn, region, locale, db_name
  FROM resources_per_pdb
 ORDER BY
       &&cs_actual_order_by_clause.
FETCH FIRST &&cs_top_n_rows. ROWS ONLY
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_customer_or_pdb." "&&cs_realm." "&&cs_rgn_or_region." "&&cs_locale." "&&cs_dbname." "&&cs_pdbname." "&&cs_kiev_only." "&&cs_order_by." "&&cs_top_n_rows."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--