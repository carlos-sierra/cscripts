----------------------------------------------------------------------------------------
--
-- File name:   iod_fleet_capacity_planning.sql
--
-- Purpose:     Capacity Planning report for IOD fleet
--
-- Author:      Carlos Sierra
--
-- Version:     2022/01/29
--
-- Usage:       Execute connected to CDB on KIEV99A1.
--
--              Enter parameters when requested.
--              1. CASPER: Y means CASPER only, N means all but CASPER
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @iod_fleet_capacity_planning.sql
--
---------------------------------------------------------------------------------------
--
DEF version_age_days_threshold = '14';
DEF include_sandbox = 'N';
DEF include_telemetry_vm = 'N';
DEF def_pdbs_per_core = '1.5';
DEF def_cores_util_perc = '50';
DEF def_disk_util_perc = '33';
DEF def_cpu_cores_new_shape = '52';
DEF def_disk_space_new_shape_tbs = '12.8';
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
PRO
PRO ***
PRO
PRO Specify below wchich host classes to include in analysis
PRO
PRO 1. IOD-DB AND IOD-DB-KIEV?: [{Y}|N]
DEF include_db_and_kiev = '&1.';
UNDEF 1;
COL include_db_and_kiev NEW_V include_db_and_kiev NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_db_and_kiev.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_db_and_kiev.'), 1, 1)) ELSE 'Y' END AS include_db_and_kiev FROM DUAL
/
PRO
PRO 2. IOD-DB-CASPER?: [{N}|Y]
DEF include_casper = '&2.';
UNDEF 2;
COL include_casper NEW_V include_casper NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_casper.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_casper.'), 1, 1)) ELSE 'N' END AS include_casper FROM DUAL
/
PRO
PRO 3. IOD-DB-TELEMETRY?: [{N}|Y]
DEF include_telemetry = '&3.';
UNDEF 3;
COL include_telemetry NEW_V include_telemetry NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_telemetry.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_telemetry.'), 1, 1)) ELSE 'N' END AS include_telemetry FROM DUAL
/
PRO
PRO 4. IOD-DB-BLING?: [{N}|Y]
DEF include_bling = '&4.';
UNDEF 4;
COL include_bling NEW_V include_bling NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_bling.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_bling.'), 1, 1)) ELSE 'N' END AS include_bling FROM DUAL
/
PRO
PRO 5. IOD-WF?: [{N}|Y]
DEF include_wf = '&5.';
UNDEF 5;
COL include_wf NEW_V include_wf NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_wf.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_wf.'), 1, 1)) ELSE 'N' END AS include_wf FROM DUAL
/
--
COL realm FOR A5 HEA '.|.|Realm';
COL region_acronym FOR A6 HEA 'Region';
COL locale NEW_V locale FOR A6 HEA 'Locale';
COL host_class FOR A20 HEA 'Host Class';
COL db_name FOR A10 HEA 'DB Name';
COL maxed_out FOR 99990 HEA 'Maxed|Out';
COL cdb_weight FOR 9,990 HEA 'CDB|Weight';
COL cdbs FOR 999,990 HEA 'Current|CDBs|Count';
COL pdbs FOR 999,990 HEA 'PDBs|Count';
COL kiev_pdbs FOR 999,990 HEA 'Kiev|PDBs|Count';
COL wf_pdbs FOR 999,990 HEA 'WF|PDBs|Count';
COL casper_pdbs FOR 999,990 HEA 'Casper|PDBs|Count';
COL   pdbs_per_core FOR 990.000 HEA 'Current|PDBs per|CPU Core' NEW_V pdbs_per_core;
COL l_pdbs_per_core FOR 990.000 HEA 'Current|PDBs per|CPU Core';
COL num_cpu_cores FOR 999,990 HEA 'Current|CPU|Cores';
COL load_avg FOR 999,990.000 HEA 'Host|Load|Average';
COL   cpu_cores_utilization_perc FOR 99,990.000 HEA 'Current|CPU Cores|Util Perc%' NEW_V cpu_cores_utilization_perc;
COL l_cpu_cores_utilization_perc FOR 99,990.000 HEA 'Current|CPU Cores|Util Perc%';
COL u02_size_gbs FOR 999,999,990.0 HEA '/u02 Current|Disk Space|(GBs)';
COL u02_usable_size_gbs FOR 999,999,990.0 HEA '/u02 Usable|Disk Space|(GBs)';
COL u02_used_gbs FOR 999,999,990.0 HEA 'Disk Space|Used|(GBs)';
COL u02_available_gbs FOR 999,999,990.0 HEA 'Disk Space|Available|(GBs)';
COL   disk_utilization_perc FOR 9,990.000 HEA 'Current|Disk Space|Util Perc%' NEW_V disk_utilization_perc;
COL l_disk_utilization_perc FOR 9,990.000 HEA 'Current|Disk Space|Util Perc%';
COL host_name FOR A64 HEA 'Host Name';
COL cdb_version FOR A10 HEA 'CDB Level|Metadata|Version' TRUNC;
COL target_cpu_cores_1 FOR 99,990 HEA 'CPU Cores|Target due to|PDBs per Core';
COL acquire_cpu_cores_1 FOR 99,990 HEA 'CPU Cores to|Obtain due to|PDBs per Core';
COL target_cpu_cores_2 FOR 99,990 HEA 'CPU Cores|Target due to|Core Util Perc';
COL acquire_cpu_cores_2 FOR 99,990 HEA 'CPU Cores to|Obtain due to|Core Util Perc';
COL target_u02_size_gbs FOR 999,999,990.0 HEA '/u02 Target|Disk Space|(GBs)';
COL acquire_u02_size_gbs FOR 999,999,990.0 HEA 'Disk Space|to Obtain|(GBs)';
COL acquire_cdbs_1 FOR 9,990 HEA 'New CDBs Planned|due to|PDBs per Core';
COL acquire_cdbs_2 FOR 9,990 HEA 'New CDBs Planned|due to|Core Util Perc';
COL acquire_cdbs_3 FOR 9,990 HEA 'New CDBs Planned|due to|Disk Util Perc';
COL acquire_cdbs_t FOR 9,990 HEA 'New|CDBs|Planned' NEW_V acquire_cdbs_t;
COL targetted_cdbs FOR 9,990 HEA 'Future|CDBs|Count';
--
CLEAR BREAK COMPUTE;
PRO
PRO ***
PRO
PRO Fleet Inventory
PRO ~~~~~~~~~~~~~~~
WITH
all_versions AS ( 
SELECT /*+ MATERIALIZE NO_MERGE */ c.*, ROW_NUMBER() OVER (PARTITION BY db_domain, db_name ORDER BY version DESC NULLS LAST) AS rn
  FROM C##IOD.cdb_attributes c
 WHERE c.locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND c.num_cpu_cores >= 36 -- exclude VMs
   AND c.version > SYSDATE - &&version_age_days_threshold.
   AND (
            ('&&include_db_and_kiev.' = 'Y'  AND c.host_class IN ('IOD-DB', 'IOD-DB-KIEV'))
        OR  ('&&include_casper.' = 'Y'       AND c.host_class = 'IOD-DB-CASPER' AND SUBSTR(c.db_name, 1, 4) IN ('CASP', 'TENA'))
        OR  ('&&include_telemetry.' = 'Y'    AND c.host_class = 'IOD-DB-TELEMETRY')
        OR  ('&&include_bling.' = 'Y'        AND c.host_class = 'IOD-DB-BLING')
        OR  ('&&include_wf.' = 'Y'           AND c.host_class = 'IOD-DB-WF')
        OR  ('&&include_sandbox.' = 'Y'      AND c.host_class = 'IOD-DB-SANDBOX')
        OR  ('&&include_telemetry_vm.' = 'Y' AND c.host_class = 'IOD-DB-TELEMETRY-VM')
   )
   AND ROWNUM >= 1
),
latest_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type,
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       c.db_domain,
       c.db_name,
       c.host_name,
       c.host_class,
       c.num_cpu_cores,
       c.maxed_out,
       c.cdb_weight,
       c.load_avg,
       c.load_p90,
       c.load_p95,
       c.load_p99,
       c.aas_on_cpu_avg,
       c.aas_on_cpu_p90,
       c.aas_on_cpu_p95,
       c.aas_on_cpu_p99,
       c.u02_size,
       c.u02_used,
       c.u02_available,
       c.fs_u02_util_perc,
       c.pdbs,
       c.kiev_pdbs,
       c.wf_pdbs,
       c.casper_pdbs,
       c.version
  FROM all_versions c
 WHERE c.rn = 1
),
cdb_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       c.host_class,
       c.db_name,
       c.maxed_out,
       c.cdb_weight,
       1 AS cdbs,
       c.pdbs,
       c.kiev_pdbs,
       c.wf_pdbs,
       c.casper_pdbs,
       c.pdbs / c.num_cpu_cores AS pdbs_per_core,
       c.num_cpu_cores,
       c.load_avg,
       100 * c.load_avg / c.num_cpu_cores AS cpu_cores_utilization_perc,
       c.u02_size * POWER(2,10) / POWER(10,9) AS u02_size_gbs,
       (c.u02_used + c.u02_available) * POWER(2,10) / POWER(10,9) AS u02_usable_size_gbs,
       c.u02_used * POWER(2,10) / POWER(10,9) AS u02_used_gbs,
       c.u02_available * POWER(2,10) / POWER(10,9) AS u02_available_gbs,
       100 * c.u02_used / (c.u02_used + c.u02_available) AS disk_utilization_perc,
       c.host_name,
       c.version AS cdb_version
  FROM latest_version c
),
locale_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       '~ locale level ~' AS host_class,
       '~ 1. sum' AS db_name,
       SUM(c.maxed_out) AS maxed_out,
       TO_NUMBER(NULL) AS cdb_weight,
       SUM(c.cdbs) AS cdbs,
       SUM(c.pdbs) AS pdbs,
       SUM(c.kiev_pdbs) AS kiev_pdbs,
       SUM(c.wf_pdbs) AS wf_pdbs,
       SUM(c.casper_pdbs) AS casper_pdbs,
       SUM(c.pdbs) / SUM(c.num_cpu_cores) AS pdbs_per_core,
       SUM(c.num_cpu_cores) AS num_cpu_cores,
       SUM(c.load_avg) AS load_avg,
       100 * SUM(c.load_avg) / SUM(c.num_cpu_cores) AS cpu_cores_utilization_perc,
       SUM(c.u02_size_gbs) AS u02_size_gbs,
       SUM(c.u02_usable_size_gbs) AS u02_usable_size_gbs,
       SUM(c.u02_used_gbs) AS u02_used_gbs,
       SUM(c.u02_available_gbs) AS u02_available_gbs,
       100 * SUM(c.u02_used_gbs) / SUM(c.u02_used_gbs + c.u02_available_gbs) AS disk_utilization_perc,
       '~' AS host_name,
       '~' AS cdb_version
  FROM cdb_level c
 GROUP BY
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by
),
region_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       '~' AS locale,
       999999 AS locale_order_by,
       '~ region level ~' AS host_class,
       '~ 2. sum' AS db_name,
       SUM(c.maxed_out) AS maxed_out,
       TO_NUMBER(NULL) AS cdb_weight,
       SUM(c.cdbs) AS cdbs,
       SUM(c.pdbs) AS pdbs,
       SUM(c.kiev_pdbs) AS kiev_pdbs,
       SUM(c.wf_pdbs) AS wf_pdbs,
       SUM(c.casper_pdbs) AS casper_pdbs,
       SUM(c.pdbs) / SUM(c.num_cpu_cores) AS pdbs_per_core,
       SUM(c.num_cpu_cores) AS num_cpu_cores,
       SUM(c.load_avg) AS load_avg,
       100 * SUM(c.load_avg) / SUM(c.num_cpu_cores) AS cpu_cores_utilization_perc,
       SUM(c.u02_size_gbs) AS u02_size_gbs,
       SUM(c.u02_usable_size_gbs) AS u02_usable_size_gbs,
       SUM(c.u02_used_gbs) AS u02_used_gbs,
       SUM(c.u02_available_gbs) AS u02_available_gbs,
       100 * SUM(c.u02_used_gbs) / SUM(c.u02_used_gbs + c.u02_available_gbs) AS disk_utilization_perc,
       '~' AS host_name,
       '~' AS cdb_version
  FROM cdb_level c
 GROUP BY
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region_order_by,
       c.region,
       c.region_acronym
),
realm_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       '~' AS region,
       '~' AS region_acronym,
       999999 AS region_order_by,
       '~' AS locale,
       999999 AS locale_order_by,
       '~ realm level ~' AS host_class,
       '~ 3. sum' AS db_name,
       SUM(c.maxed_out) AS maxed_out,
       TO_NUMBER(NULL) AS cdb_weight,
       SUM(c.cdbs) AS cdbs,
       SUM(c.pdbs) AS pdbs,
       SUM(c.kiev_pdbs) AS kiev_pdbs,
       SUM(c.wf_pdbs) AS wf_pdbs,
       SUM(c.casper_pdbs) AS casper_pdbs,
       SUM(c.pdbs) / SUM(c.num_cpu_cores) AS pdbs_per_core,
       SUM(c.num_cpu_cores) AS num_cpu_cores,
       SUM(c.load_avg) AS load_avg,
       100 * SUM(c.load_avg) / SUM(c.num_cpu_cores) AS cpu_cores_utilization_perc,
       SUM(c.u02_size_gbs) AS u02_size_gbs,
       SUM(c.u02_usable_size_gbs) AS u02_usable_size_gbs,
       SUM(c.u02_used_gbs) AS u02_used_gbs,
       SUM(c.u02_available_gbs) AS u02_available_gbs,
       100 * SUM(c.u02_used_gbs) / SUM(c.u02_used_gbs + c.u02_available_gbs) AS disk_utilization_perc,
       '~' AS host_name,
       '~' AS cdb_version
  FROM cdb_level c
 GROUP BY
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by
),
fleet_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       999999 AS realm_type_order_by,
       '~' AS realm,
       999999 AS realm_order_by,
       '~' AS region,
       '~' AS region_acronym,
       999999 AS region_order_by,
       '~' AS locale,
       999999 AS locale_order_by,
       '~ fleet level ~' AS host_class,
       '~ 4. sum' AS db_name,
       SUM(c.maxed_out) AS maxed_out,
       TO_NUMBER(NULL) AS cdb_weight,
       SUM(c.cdbs) AS cdbs,
       SUM(c.pdbs) AS pdbs,
       SUM(c.kiev_pdbs) AS kiev_pdbs,
       SUM(c.wf_pdbs) AS wf_pdbs,
       SUM(c.casper_pdbs) AS casper_pdbs,
       SUM(c.pdbs) / SUM(c.num_cpu_cores) AS pdbs_per_core,
       SUM(c.num_cpu_cores) AS num_cpu_cores,
       SUM(c.load_avg) AS load_avg,
       100 * SUM(c.load_avg) / SUM(c.num_cpu_cores) AS cpu_cores_utilization_perc,
       SUM(c.u02_size_gbs) AS u02_size_gbs,
       SUM(c.u02_usable_size_gbs) AS u02_usable_size_gbs,
       SUM(c.u02_used_gbs) AS u02_used_gbs,
       SUM(c.u02_available_gbs) AS u02_available_gbs,
       100 * SUM(c.u02_used_gbs) / SUM(c.u02_used_gbs + c.u02_available_gbs) AS disk_utilization_perc,
       '~' AS host_name,
       '~' AS cdb_version
  FROM cdb_level c
),
union_all_levels AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       c.host_class,
       c.db_name,
       c.maxed_out,
       c.cdb_weight,
       c.cdbs,
       c.pdbs,
       c.kiev_pdbs,
       c.wf_pdbs,
       c.casper_pdbs,
       c.pdbs_per_core,
       c.num_cpu_cores,
       c.load_avg,
       c.cpu_cores_utilization_perc,
       c.u02_size_gbs,
       c.u02_usable_size_gbs,
       c.u02_used_gbs,
       c.u02_available_gbs,
       c.disk_utilization_perc,
       c.host_name,
       c.cdb_version
  FROM cdb_level c
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm,
       l.realm_order_by,
       l.region,
       l.region_acronym,
       l.region_order_by,
       l.locale,
       l.locale_order_by,
       l.host_class,
       l.db_name,
       l.maxed_out,
       l.cdb_weight,
       l.cdbs,
       l.pdbs,
       l.kiev_pdbs,
       l.wf_pdbs,
       l.casper_pdbs,
       l.pdbs_per_core,
       l.num_cpu_cores,
       l.load_avg,
       l.cpu_cores_utilization_perc,
       l.u02_size_gbs,
       l.u02_usable_size_gbs,
       l.u02_used_gbs,
       l.u02_available_gbs,
       l.disk_utilization_perc,
       l.host_name,
       l.cdb_version
  FROM locale_level l
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       r.realm_type_order_by,
       r.realm,
       r.realm_order_by,
       r.region,
       r.region_acronym,
       r.region_order_by,
       r.locale,
       r.locale_order_by,
       r.host_class,
       r.db_name,
       r.maxed_out,
       r.cdb_weight,
       r.cdbs,
       r.pdbs,
       r.kiev_pdbs,
       r.wf_pdbs,
       r.casper_pdbs,
       r.pdbs_per_core,
       r.num_cpu_cores,
       r.load_avg,
       r.cpu_cores_utilization_perc,
       r.u02_size_gbs,
       r.u02_usable_size_gbs,
       r.u02_used_gbs,
       r.u02_available_gbs,
       r.disk_utilization_perc,
       r.host_name,
       r.cdb_version
  FROM region_level r
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       r.realm_type_order_by,
       r.realm,
       r.realm_order_by,
       r.region,
       r.region_acronym,
       r.region_order_by,
       r.locale,
       r.locale_order_by,
       r.host_class,
       r.db_name,
       r.maxed_out,
       r.cdb_weight,
       r.cdbs,
       r.pdbs,
       r.kiev_pdbs,
       r.wf_pdbs,
       r.casper_pdbs,
       r.pdbs_per_core,
       r.num_cpu_cores,
       r.load_avg,
       r.cpu_cores_utilization_perc,
       r.u02_size_gbs,
       r.u02_usable_size_gbs,
       r.u02_used_gbs,
       r.u02_available_gbs,
       r.disk_utilization_perc,
       r.host_name,
       r.cdb_version
  FROM realm_level r
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       f.realm_type_order_by,
       f.realm,
       f.realm_order_by,
       f.region,
       f.region_acronym,
       f.region_order_by,
       f.locale,
       f.locale_order_by,
       f.host_class,
       f.db_name,
       f.maxed_out,
       f.cdb_weight,
       f.cdbs,
       f.pdbs,
       f.kiev_pdbs,
       f.wf_pdbs,
       f.casper_pdbs,
       f.pdbs_per_core,
       f.num_cpu_cores,
       f.load_avg,
       f.cpu_cores_utilization_perc,
       f.u02_size_gbs,
       f.u02_usable_size_gbs,
       f.u02_used_gbs,
       f.u02_available_gbs,
       f.disk_utilization_perc,
       f.host_name,
       f.cdb_version
  FROM fleet_level f
)
SELECT /*+ MATERIALIZE NO_MERGE */ 
       u.realm,
       u.region_acronym,
       u.locale,
       u.db_name,
       u.host_class,
       '|' AS "|",
       u.pdbs_per_core,
       u.cpu_cores_utilization_perc,
       u.disk_utilization_perc,
       '|' AS "|",
       u.maxed_out,
       u.cdb_weight,
       u.cdbs,
       u.pdbs,
       u.kiev_pdbs,
       u.wf_pdbs,
       u.casper_pdbs,
    --    u.pdbs_per_core,
       u.num_cpu_cores,
       u.load_avg,
    --    u.cpu_cores_utilization_perc,
       u.u02_size_gbs,
       u.u02_usable_size_gbs,
       u.u02_used_gbs,
       u.u02_available_gbs,
    --    u.disk_utilization_perc,
       u.host_name,
       u.cdb_version
  FROM union_all_levels u
 ORDER BY
       u.realm_type_order_by,
       u.realm_order_by,
       u.region_order_by,
       u.locale_order_by,
       u.db_name,
       u.host_class
/
--
COL c_pdbs_per_core NEW_V c_pdbs_per_core NOPRI;
COL c_cpu_cores_utilization_perc NEW_V c_cpu_cores_utilization_perc NOPRI;
COL c_disk_utilization_perc NEW_V c_disk_utilization_perc NOPRI;
--
SELECT TRIM(TO_CHAR(ROUND(&&pdbs_per_core.,3), '990.000')) AS c_pdbs_per_core,
       TRIM(TO_CHAR(ROUND(&&cpu_cores_utilization_perc.,1), '990.0')) AS c_cpu_cores_utilization_perc,
       TRIM(TO_CHAR(ROUND(&&disk_utilization_perc.,1), '990.0')) AS c_disk_utilization_perc
  FROM DUAL
/
--
PRO
PRO ***
PRO
PRO There are currently &&c_pdbs_per_core. PDBs per CPU Core. One PDB per CPU core is desired, and 0.5 is even better. 
PRO Note: On an X7, having 2 PDBs per CPU Core would render ~100 PDBs per CDB.
PRO 
PRO 6. PDBs per CPU Core Target: [{&&c_pdbs_per_core.}|0.02-4] (currently:&&c_pdbs_per_core., recommended:<&&def_pdbs_per_core.)
DEF target_pdbs_per_core = '&6.';
UNDEF 6;
COL target_pdbs_per_core NEW_V target_pdbs_per_core NOPRI;
SELECT CASE WHEN TO_NUMBER('&&target_pdbs_per_core.') BETWEEN 0.02 AND 4 THEN TRIM('&&target_pdbs_per_core.') ELSE '&&c_pdbs_per_core.' END AS target_pdbs_per_core FROM DUAL
/
--
PRO
PRO ***
PRO
PRO Current CPU Cores Utilization Percent is &&c_cpu_cores_utilization_perc. Utilization below 50% is desired, and below 33% is even better. 
PRO Note: Applications tend to increase their CPU Cores Utilization constantly, mostly slowly.
PRO 
PRO 7. CPU Cores Utilization Percent Target: [{&&c_cpu_cores_utilization_perc.}|1-200] (currently:&&c_cpu_cores_utilization_perc., recommended:<&&def_cores_util_perc.)
DEF target_cores_util_perc = '&7.';
UNDEF 7;
COL target_cores_util_perc NEW_V target_cores_util_perc NOPRI;
SELECT CASE WHEN TO_NUMBER('&&target_cores_util_perc.') BETWEEN 1 AND 200 THEN TRIM('&&target_cores_util_perc.') ELSE '&&c_cpu_cores_utilization_perc.' END AS target_cores_util_perc FROM DUAL
/
--
PRO
PRO ***
PRO
PRO Current Disk Space Utilization Percent is &&c_disk_utilization_perc. Utilization below 33% is desired, and below 20% is even better. 
PRO Note: Applications tend to increase their Disk Space Utilization constantly, some rapidly.
PRO 
PRO 8. Disk Space Utilization Percent Target: [{&&c_disk_utilization_perc.}|1-100] (currently:&&c_disk_utilization_perc., recommended:&&def_disk_util_perc.)
DEF target_disk_util_perc = '&8.';
UNDEF 8;
COL target_disk_util_perc NEW_V target_disk_util_perc NOPRI;
SELECT CASE WHEN TO_NUMBER('&&target_disk_util_perc.') BETWEEN 1 AND 100 THEN TRIM('&&target_disk_util_perc.') ELSE '&&c_disk_utilization_perc.' END AS target_disk_util_perc FROM DUAL
/
--
PRO
PRO ***
PRO
PRO Number of CPU Cores on Bare Metal (BM) Shape to be provisioned.
PRO Note: most X7-2 have 52 CPU Cores 
PRO 
PRO 9. CPU Cores on new Shape: [{&&def_cpu_cores_new_shape.}|36-128]
DEF cpu_cores_new_shape = '&9.';
UNDEF 9;
COL cpu_cores_new_shape NEW_V cpu_cores_new_shape NOPRI;
SELECT CASE WHEN TO_NUMBER('&&cpu_cores_new_shape.') BETWEEN 36 AND 128 THEN TRIM('&&cpu_cores_new_shape.') ELSE '&&def_cpu_cores_new_shape.' END AS cpu_cores_new_shape FROM DUAL
/
PRO
PRO ***
PRO
PRO Terabytes of Disk Space on Bare Metal (BM) Shape to be provisioned.
PRO Note: most X7-2 have 12.8 TBs of Disk Space
PRO 
PRO 10. TBs of Disk Space on new Shape: [{&&def_disk_space_new_shape_tbs.}|3.2-25.6]
DEF disk_space_new_shape_tbs = '&10.';
UNDEF 10;
COL disk_space_new_shape_tbs NEW_V disk_space_new_shape_tbs NOPRI;
SELECT CASE WHEN TO_NUMBER('&&disk_space_new_shape_tbs.') BETWEEN 3.2 AND 25.6 THEN TRIM('&&disk_space_new_shape_tbs.') ELSE '&&def_disk_space_new_shape_tbs.' END AS disk_space_new_shape_tbs FROM DUAL
/
--
PRO
PRO ***
PRO
PRO Current Utilization Thresholds:
PRO 1. PDBs per CPU Core: &&c_pdbs_per_core.
PRO 2. CPU Cores Utilization Percent: &&c_cpu_cores_utilization_perc.%
PRO 3. Disk Space Utilization Percent: &&c_disk_utilization_perc.%
PRO
PRO Capacity Planning Targets:
PRO 1. PDBs per CPU Core: &&target_pdbs_per_core.  
PRO 2. CPU Cores Utilization Percent: &&target_cores_util_perc.%
PRO 3. Disk Space Utilization Percent: &&target_disk_util_perc.%
PRO
PRO Targgeted New Bare Metal (BM) Shape Capacity:
PRO 1. CPU Cores: &&cpu_cores_new_shape.
PRO 2. Disk Space: &&disk_space_new_shape_tbs. TBs
PRO
PRO Capacity Planning Results
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
all_versions AS ( 
SELECT /*+ MATERIALIZE NO_MERGE */ c.*, ROW_NUMBER() OVER (PARTITION BY db_domain, db_name ORDER BY version DESC NULLS LAST) AS rn
  FROM C##IOD.cdb_attributes c
 WHERE c.locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND c.num_cpu_cores >= 36 -- exclude VMs
   AND c.version > SYSDATE - &&version_age_days_threshold.
   AND (
            ('&&include_db_and_kiev.' = 'Y'  AND c.host_class IN ('IOD-DB', 'IOD-DB-KIEV'))
        OR  ('&&include_casper.' = 'Y'       AND c.host_class = 'IOD-DB-CASPER' AND SUBSTR(c.db_name, 1, 4) IN ('CASP', 'TENA'))
        OR  ('&&include_telemetry.' = 'Y'    AND c.host_class = 'IOD-DB-TELEMETRY')
        OR  ('&&include_bling.' = 'Y'        AND c.host_class = 'IOD-DB-BLING')
        OR  ('&&include_wf.' = 'Y'           AND c.host_class = 'IOD-DB-WF')
        OR  ('&&include_sandbox.' = 'Y'      AND c.host_class = 'IOD-DB-SANDBOX')
        OR  ('&&include_telemetry_vm.' = 'Y' AND c.host_class = 'IOD-DB-TELEMETRY-VM')
   )
   AND ROWNUM >= 1
),
latest_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type,
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       c.db_domain,
       c.db_name,
       c.host_name,
       c.host_class,
       c.num_cpu_cores,
       c.maxed_out,
       c.cdb_weight,
       c.load_avg,
       c.load_p90,
       c.load_p95,
       c.load_p99,
       c.aas_on_cpu_avg,
       c.aas_on_cpu_p90,
       c.aas_on_cpu_p95,
       c.aas_on_cpu_p99,
       c.u02_size,
       c.u02_used,
       c.u02_available,
       c.fs_u02_util_perc,
       c.pdbs,
       c.kiev_pdbs,
       c.wf_pdbs,
       c.casper_pdbs,
       c.version
  FROM all_versions c
 WHERE c.rn = 1
),
cdb_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       c.host_class,
       c.db_name,
       c.maxed_out,
       c.cdb_weight,
       1 AS cdbs,
       c.pdbs,
       c.kiev_pdbs,
       c.wf_pdbs,
       c.casper_pdbs,
       c.pdbs / c.num_cpu_cores AS pdbs_per_core,
       c.num_cpu_cores,
       c.load_avg,
       100 * c.load_avg / c.num_cpu_cores AS cpu_cores_utilization_perc,
       c.u02_size * POWER(2,10) / POWER(10,9) AS u02_size_gbs,
       (c.u02_used + c.u02_available) * POWER(2,10) / POWER(10,9) AS u02_usable_size_gbs,
       c.u02_used * POWER(2,10) / POWER(10,9) AS u02_used_gbs,
       c.u02_available * POWER(2,10) / POWER(10,9) AS u02_available_gbs,
       100 * c.u02_used / (c.u02_used + c.u02_available) AS disk_utilization_perc,
       c.host_name,
       c.version AS cdb_version
  FROM latest_version c
),
locale_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by,
       '~ locale level ~' AS host_class,
       '~ 1. sum' AS db_name,
       SUM(c.maxed_out) AS maxed_out,
       TO_NUMBER(NULL) AS cdb_weight,
       SUM(c.cdbs) AS cdbs,
       SUM(c.pdbs) AS pdbs,
       SUM(c.kiev_pdbs) AS kiev_pdbs,
       SUM(c.wf_pdbs) AS wf_pdbs,
       SUM(c.casper_pdbs) AS casper_pdbs,
       SUM(c.pdbs) / SUM(c.num_cpu_cores) AS pdbs_per_core,
       SUM(c.num_cpu_cores) AS num_cpu_cores,
       SUM(c.load_avg) AS load_avg,
       100 * SUM(c.load_avg) / SUM(c.num_cpu_cores) AS cpu_cores_utilization_perc,
       SUM(c.u02_size_gbs) AS u02_size_gbs,
       SUM(c.u02_usable_size_gbs) AS u02_usable_size_gbs,
       SUM(c.u02_used_gbs) AS u02_used_gbs,
       SUM(c.u02_available_gbs) AS u02_available_gbs,
       100 * SUM(c.u02_used_gbs) / SUM(c.u02_used_gbs + c.u02_available_gbs) AS disk_utilization_perc,
       '~' AS host_name,
       '~' AS cdb_version
  FROM cdb_level c
 GROUP BY
       c.realm_type_order_by,
       c.realm,
       c.realm_order_by,
       c.region,
       c.region_acronym,
       c.region_order_by,
       c.locale,
       c.locale_order_by
),
locale_level_ext AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm_order_by,
       l.region_order_by,
       l.locale_order_by,
       l.realm,
       l.region,
       l.region_acronym,
       l.locale,
       l.cdbs,
       l.pdbs,
       l.load_avg,
       l.u02_used_gbs,
       l.u02_available_gbs,
       l.pdbs_per_core AS l_pdbs_per_core,
       l.cpu_cores_utilization_perc AS l_cpu_cores_utilization_perc,
       l.disk_utilization_perc AS l_disk_utilization_perc,
       CEIL(l.num_cpu_cores * (l.pdbs_per_core / TO_NUMBER('&&target_pdbs_per_core.'))) AS target_cpu_cores_1,
       l.num_cpu_cores,
       CASE WHEN CEIL(l.pdbs / TO_NUMBER('&&target_pdbs_per_core.')) > l.num_cpu_cores THEN CEIL(l.pdbs / TO_NUMBER('&&target_pdbs_per_core.')) - l.num_cpu_cores ELSE 0 END AS acquire_cpu_cores_1,
       CEIL(l.num_cpu_cores * (l.cpu_cores_utilization_perc / TO_NUMBER('&&target_cores_util_perc.'))) AS target_cpu_cores_2,
       CASE WHEN CEIL(l.num_cpu_cores * (l.cpu_cores_utilization_perc / TO_NUMBER('&&target_cores_util_perc.'))) > l.num_cpu_cores THEN CEIL(l.num_cpu_cores * (l.cpu_cores_utilization_perc / TO_NUMBER('&&target_cores_util_perc.'))) - l.num_cpu_cores ELSE 0 END AS acquire_cpu_cores_2,
       CEIL(l.u02_size_gbs * (l.disk_utilization_perc / TO_NUMBER('&&target_disk_util_perc.'))) AS target_u02_size_gbs,
       l.u02_size_gbs,
       CASE WHEN CEIL(l.u02_size_gbs * (l.disk_utilization_perc / TO_NUMBER('&&target_disk_util_perc.'))) > l.u02_size_gbs THEN CEIL(l.u02_size_gbs * (l.disk_utilization_perc / TO_NUMBER('&&target_disk_util_perc.'))) - l.u02_size_gbs ELSE 0 END AS acquire_u02_size_gbs
  FROM locale_level l
),
locale_level_ext2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm_order_by,
       l.region_order_by,
       l.locale_order_by,
       l.realm,
       l.region,
       l.region_acronym,
       l.locale,
       l.cdbs,
       l.pdbs,
       l.load_avg,
       l.u02_used_gbs,
       l.u02_available_gbs,
       l.l_pdbs_per_core,
       l.l_cpu_cores_utilization_perc,
       l.l_disk_utilization_perc,
       l.target_cpu_cores_1,
       l.num_cpu_cores,
       l.acquire_cpu_cores_1,
       CEIL(l.acquire_cpu_cores_1 / TO_NUMBER('&&cpu_cores_new_shape.')) AS acquire_cdbs_1,
       l.target_cpu_cores_2,
       l.acquire_cpu_cores_2,
       CEIL(l.acquire_cpu_cores_2 / TO_NUMBER('&&cpu_cores_new_shape.')) AS acquire_cdbs_2,
       l.target_u02_size_gbs,
       l.u02_size_gbs,
       l.acquire_u02_size_gbs,
       CEIL(l.acquire_u02_size_gbs / (TO_NUMBER('&&disk_space_new_shape_tbs.') * POWER(10, 3))) AS acquire_cdbs_3,
       GREATEST(CEIL(l.acquire_cpu_cores_1 / TO_NUMBER('&&cpu_cores_new_shape.')), CEIL(l.acquire_cpu_cores_2 / TO_NUMBER('&&cpu_cores_new_shape.')), CEIL(l.acquire_u02_size_gbs / (TO_NUMBER('&&disk_space_new_shape_tbs.') * POWER(10, 3)))) AS acquire_cdbs_t
  FROM locale_level_ext l
),
region_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm_order_by,
       l.region_order_by,
       999999 AS locale_order_by,
       l.realm,
       l.region,
       l.region_acronym,
       '~' AS locale,
       SUM(l.cdbs) AS cdbs,
       SUM(l.pdbs) AS pdbs,
       SUM(l.load_avg) AS load_avg,
       SUM(l.u02_used_gbs) AS u02_used_gbs,
       SUM(l.u02_available_gbs) AS u02_available_gbs,
       SUM(l.pdbs) / SUM(l.num_cpu_cores) AS l_pdbs_per_core,
       100 * SUM(l.load_avg) / SUM(l.num_cpu_cores) AS l_cpu_cores_utilization_perc,
       100 * SUM(l.u02_used_gbs) / SUM(l.u02_used_gbs + l.u02_available_gbs) AS l_disk_utilization_perc,
       SUM(l.target_cpu_cores_1) AS target_cpu_cores_1,
       SUM(l.num_cpu_cores) AS num_cpu_cores,
       SUM(l.acquire_cpu_cores_1) AS acquire_cpu_cores_1,
       SUM(l.acquire_cdbs_1) AS acquire_cdbs_1,
       SUM(target_cpu_cores_2) AS target_cpu_cores_2,
       SUM(l.acquire_cpu_cores_2) AS acquire_cpu_cores_2,
       SUM(l.acquire_cdbs_2) AS acquire_cdbs_2,
       SUM(l.target_u02_size_gbs) AS target_u02_size_gbs,
       SUM(l.u02_size_gbs) AS u02_size_gbs,
       SUM(l.acquire_u02_size_gbs) AS acquire_u02_size_gbs,
       SUM(l.acquire_cdbs_3) AS acquire_cdbs_3,
       SUM(l.acquire_cdbs_t) AS acquire_cdbs_t
  FROM locale_level_ext2 l
 GROUP BY
       l.realm_type_order_by,
       l.realm_order_by,
       l.region_order_by,
       l.realm,
       l.region,
       l.region_acronym
),
realm_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm_order_by,
       999999 AS region_order_by,
       999999 AS locale_order_by,
       l.realm,
       '~' AS region,
       '~' AS region_acronym,
       '~' AS locale,
       SUM(l.cdbs) AS cdbs,
       SUM(l.pdbs) AS pdbs,
       SUM(l.load_avg) AS load_avg,
       SUM(l.u02_used_gbs) AS u02_used_gbs,
       SUM(l.u02_available_gbs) AS u02_available_gbs,
       SUM(l.pdbs) / SUM(l.num_cpu_cores) AS l_pdbs_per_core,
       100 * SUM(l.load_avg) / SUM(l.num_cpu_cores) AS l_cpu_cores_utilization_perc,
       100 * SUM(l.u02_used_gbs) / SUM(l.u02_used_gbs + l.u02_available_gbs) AS l_disk_utilization_perc,
       SUM(l.target_cpu_cores_1) AS target_cpu_cores_1,
       SUM(l.num_cpu_cores) AS num_cpu_cores,
       SUM(l.acquire_cpu_cores_1) AS acquire_cpu_cores_1,
       SUM(l.acquire_cdbs_1) AS acquire_cdbs_1,
       SUM(target_cpu_cores_2) AS target_cpu_cores_2,
       SUM(l.acquire_cpu_cores_2) AS acquire_cpu_cores_2,
       SUM(l.acquire_cdbs_2) AS acquire_cdbs_2,
       SUM(l.target_u02_size_gbs) AS target_u02_size_gbs,
       SUM(l.u02_size_gbs) AS u02_size_gbs,
       SUM(l.acquire_u02_size_gbs) AS acquire_u02_size_gbs,
       SUM(l.acquire_cdbs_3) AS acquire_cdbs_3,
       SUM(l.acquire_cdbs_t) AS acquire_cdbs_t
  FROM locale_level_ext2 l
 GROUP BY
       l.realm_type_order_by,
       l.realm_order_by,
       l.realm
),
fleet_level AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       999999 AS realm_type_order_by,
       999999 AS realm_order_by,
       999999 AS region_order_by,
       999999 AS locale_order_by,
       '~' AS realm,
       '~' AS region,
       '~' AS region_acronym,
       '~' AS locale,
       SUM(l.cdbs) AS cdbs,
       SUM(l.pdbs) AS pdbs,
       SUM(l.load_avg) AS load_avg,
       SUM(l.u02_used_gbs) AS u02_used_gbs,
       SUM(l.u02_available_gbs) AS u02_available_gbs,
       SUM(l.pdbs) / SUM(l.num_cpu_cores) AS l_pdbs_per_core,
       100 * SUM(l.load_avg) / SUM(l.num_cpu_cores) AS l_cpu_cores_utilization_perc,
       100 * SUM(l.u02_used_gbs) / SUM(l.u02_used_gbs + l.u02_available_gbs) AS l_disk_utilization_perc,
       SUM(l.target_cpu_cores_1) AS target_cpu_cores_1,
       SUM(l.num_cpu_cores) AS num_cpu_cores,
       SUM(l.acquire_cpu_cores_1) AS acquire_cpu_cores_1,
       SUM(l.acquire_cdbs_1) AS acquire_cdbs_1,
       SUM(target_cpu_cores_2) AS target_cpu_cores_2,
       SUM(l.acquire_cpu_cores_2) AS acquire_cpu_cores_2,
       SUM(l.acquire_cdbs_2) AS acquire_cdbs_2,
       SUM(l.target_u02_size_gbs) AS target_u02_size_gbs,
       SUM(l.u02_size_gbs) AS u02_size_gbs,
       SUM(l.acquire_u02_size_gbs) AS acquire_u02_size_gbs,
       SUM(l.acquire_cdbs_3) AS acquire_cdbs_3,
       SUM(l.acquire_cdbs_t) AS acquire_cdbs_t
  FROM locale_level_ext2 l
),
union_all_levels AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       l.realm_type_order_by,
       l.realm_order_by,
       l.region_order_by,
       l.locale_order_by,
       l.realm,
       l.region_acronym,
       l.locale,
       l.cdbs,
       l.pdbs,
       l.load_avg,
       l.u02_used_gbs,
       l.u02_available_gbs,
       l.l_pdbs_per_core,
       l.l_cpu_cores_utilization_perc,
       l.l_disk_utilization_perc,
       l.target_cpu_cores_1,
       l.num_cpu_cores,
       l.acquire_cpu_cores_1,
       l.acquire_cdbs_1,
       l.target_cpu_cores_2,
       l.acquire_cpu_cores_2,
       l.acquire_cdbs_2,
       l.target_u02_size_gbs,
       l.u02_size_gbs,
       l.acquire_u02_size_gbs,
       l.acquire_cdbs_3,
       l.acquire_cdbs_t,
       l.cdbs + l.acquire_cdbs_t AS targetted_cdbs
  FROM locale_level_ext2 l
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       r.realm_type_order_by,
       r.realm_order_by,
       r.region_order_by,
       r.locale_order_by,
       r.realm,
       r.region_acronym,
       r.locale,
       r.cdbs,
       r.pdbs,
       r.load_avg,
       r.u02_used_gbs,
       r.u02_available_gbs,
       r.l_pdbs_per_core,
       r.l_cpu_cores_utilization_perc,
       r.l_disk_utilization_perc,
       r.target_cpu_cores_1,
       r.num_cpu_cores,
       r.acquire_cpu_cores_1,
       r.acquire_cdbs_1,
       r.target_cpu_cores_2,
       r.acquire_cpu_cores_2,
       r.acquire_cdbs_2,
       r.target_u02_size_gbs,
       r.u02_size_gbs,
       r.acquire_u02_size_gbs,
       r.acquire_cdbs_3,
       r.acquire_cdbs_t,
       r.cdbs + r.acquire_cdbs_t AS targetted_cdbs
  FROM region_level r
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       r.realm_type_order_by,
       r.realm_order_by,
       r.region_order_by,
       r.locale_order_by,
       r.realm,
       r.region_acronym,
       r.locale,
       r.cdbs,
       r.pdbs,
       r.load_avg,
       r.u02_used_gbs,
       r.u02_available_gbs,
       r.l_pdbs_per_core,
       r.l_cpu_cores_utilization_perc,
       r.l_disk_utilization_perc,
       r.target_cpu_cores_1,
       r.num_cpu_cores,
       r.acquire_cpu_cores_1,
       r.acquire_cdbs_1,
       r.target_cpu_cores_2,
       r.acquire_cpu_cores_2,
       r.acquire_cdbs_2,
       r.target_u02_size_gbs,
       r.u02_size_gbs,
       r.acquire_u02_size_gbs,
       r.acquire_cdbs_3,
       r.acquire_cdbs_t,
       r.cdbs + r.acquire_cdbs_t AS targetted_cdbs
  FROM realm_level r
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */ 
       f.realm_type_order_by,
       f.realm_order_by,
       f.region_order_by,
       f.locale_order_by,
       f.realm,
       f.region_acronym,
       f.locale,
       f.cdbs,
       f.pdbs,
       f.load_avg,
       f.u02_used_gbs,
       f.u02_available_gbs,
       f.l_pdbs_per_core,
       f.l_cpu_cores_utilization_perc,
       f.l_disk_utilization_perc,
       f.target_cpu_cores_1,
       f.num_cpu_cores,
       f.acquire_cpu_cores_1,
       f.acquire_cdbs_1,
       f.target_cpu_cores_2,
       f.acquire_cpu_cores_2,
       f.acquire_cdbs_2,
       f.target_u02_size_gbs,
       f.u02_size_gbs,
       f.acquire_u02_size_gbs,
       f.acquire_cdbs_3,
       f.acquire_cdbs_t,
       f.cdbs + f.acquire_cdbs_t AS targetted_cdbs
  FROM fleet_level f
)
SELECT u.realm,
       u.region_acronym,
       u.locale,
       '|' AS "|",
       u.cdbs,
       u.acquire_cdbs_t,
       u.targetted_cdbs,
       '|' AS "|",
       u.l_pdbs_per_core,
       u.l_cpu_cores_utilization_perc,
       u.l_disk_utilization_perc,
       '|' AS "|",
       u.target_cpu_cores_1,
       u.num_cpu_cores,
       u.acquire_cpu_cores_1,
       u.acquire_cdbs_1,
       '|' AS "|",
       u.target_cpu_cores_2,
       --u.num_cpu_cores,
       u.acquire_cpu_cores_2,
       u.acquire_cdbs_2,
       '|' AS "|",
       u.target_u02_size_gbs,
       u.u02_size_gbs,
       u.acquire_u02_size_gbs,
       u.acquire_cdbs_3
  FROM union_all_levels u
 ORDER BY
       u.realm_type_order_by,
       u.realm_order_by,
       u.region_order_by,
       u.locale_order_by
/
--
COL f_acquire_cdbs_t NEW_V f_acquire_cdbs_t NOPRI;
--
SELECT TRIM(TO_CHAR(3 * &&acquire_cdbs_t.)) AS f_acquire_cdbs_t
  FROM DUAL
/
--
PRO
PRO IOD Fleet Capacity Plan requires &&f_acquire_cdbs_t. additional DB servers with &&cpu_cores_new_shape. CPU Cores and &&disk_space_new_shape_tbs. TBs of Disk Space each.
PRO Note: 3 DB servers for each additional CDB planned, to accomodate for required Primary, Standby and Bystander
PRO