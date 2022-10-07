----------------------------------------------------------------------------------------
--
-- File name:   iod_fleet_top_pdbs_to_migrate.sql
--
-- Purpose:     Identifies top PDBs for top CDBs as candidates to by migrated
--
-- Author:      Carlos Sierra
--
-- Version:     2022/01/29
--
-- Usage:       Execute connected to CDB on KIEV99A1.
--
--              Enter parameters when requested.
--              1. CASPER: Y means CASPER only, N means all but CASPER
--              2. Avg Running Sessions: Y means consider this metric for Relative Weight function
--              3. Total Size Bytes: Y means consider this metric for Relative Weight function
--              4. Region: from CDB for which script displays top PDBs
--              5. DB Name: from CDB for which script displays top PDBs
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @iod_fleet_top_pdbs_to_migrate.sql
--
---------------------------------------------------------------------------------------
--
DEF cdb_weight_threshold = '25';
DEF pdb_weight_threshold = '25';
DEF version_age_days_threshold = '14';
DEF include_pdbs = 'Y';
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
PRO
PRO ***
PRO
PRO There are two process modes: either focus is CASPER, or all non-CASPER pdbs (default)
PRO
PRO 1. CASPER?: [{N}|Y]
DEF include_casper = '&1.'
UNDEF 1;
COL include_casper NEW_V include_casper NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_casper.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_casper.'), 1, 1)) ELSE 'N' END AS include_casper FROM DUAL
/
--
PRO
PRO ***
PRO
PRO This is to specify if "CPU utilization" should be considered in computations
PRO
PRO 2. Consider "Avg Running Sessions" to compute PDB Weight?: [{Y}|N]
DEF include_avg_running_sessions = '&2.';
UNDEF 2;
COL include_avg_running_sessions NEW_V include_avg_running_sessions NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_avg_running_sessions.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_avg_running_sessions.'), 1, 1)) ELSE 'Y' END AS include_avg_running_sessions FROM DUAL
/
--
PRO
PRO ***
PRO
PRO This is to specify if "Space on Disk" should be considered in computations
PRO
PRO 3. Consider "Total Size Bytes" to compute PDB Weight?: [{Y}|N]
DEF include_total_size_bytes = '&3.';
UNDEF 3;
COL include_total_size_bytes NEW_V include_total_size_bytes NOPRI;
SELECT CASE WHEN UPPER(SUBSTR(TRIM('&&include_total_size_bytes.'), 1, 1)) IN ('Y', 'N') THEN UPPER(SUBSTR(TRIM('&&include_total_size_bytes.'), 1, 1)) ELSE 'Y' END AS include_total_size_bytes FROM DUAL
/
--
COL weight_contribution_percent FOR 990.000 HEA 'Relative Weight|Contribution|Percent(%)';
COL weight_contribution_cumulative FOR 990.000 HEA 'Relative Weight|Contribution|Cumulative(%)';
COL maxed_out FOR A5 HEA 'CDB|Maxed|Out';
COL pdbs_count FOR 999,990 HEA 'PDBs|Count';
COL sum_avg_running_sessions FOR 999,999,990.000 HEA 'Average|Running|Sessions';
COL sum_total_size_gbs FOR 999,999,990.0 HEA 'Disk Space|Used (GBs)';
COL region_acronym FOR A6 HEA '.|.|Region';
COL db_name FOR A10 HEA 'DB Name';
COL pdb_name FOR A30 HEA 'PDB Name';
COL kiev_flag FOR A4 HEA 'Has|Kiev|PDBs';
COL casper_flag FOR A6 HEA 'Has|Casper|PDBs';
COL kiev_or_wf FOR A4 HEA 'Kiev|or|WF';
COL realm FOR A5 HEA 'Realm';
COL locale NEW_V locale FOR A6 HEA 'Locale';
COL db_domain FOR A20 HEA 'DB Domanin';
COL host_name FOR A64 HEA 'Host Name';
COL pdb_version FOR A10 HEA 'PDB Level|Metadata|Version' TRUNC;
COL cdb_version FOR A10 HEA 'CDB Level|Metadata|Version' TRUNC;
COL num_cpu_cores FOR 999,990 HEA 'CPU|Cores';
COL load_avg FOR 999,990.000 HEA 'Host|Load|Average';
COL u02_available_gbs FOR 999,999,990.0 HEA 'Disk Space|Available|(GBs)';
COL cpu_cores_utilization_perc FOR 99,990.000 HEA 'CPU Cores|Utilization|Percent %';
COL disk_utilization_perc FOR 9,990.000 HEA 'Disk Space|Utilization|Percent %';
COL cdb_weight FOR 9,990 HEA 'CDB|Weight';
--
BREAK ON REPORT;
COMPUTE SUM OF weight_contribution_percent pdbs_count sum_avg_running_sessions sum_total_size_gbs load_avg u02_available_gbs cpu_cores_utilization_perc disk_utilization_perc ON REPORT;
--
PRO
PRO ***
PRO
PRO List of CDBs with high resources utilization as per: number of PDBs, running sessions and/or disk space (the last two as per input parameres)
PRO
PRO Top CDBs (as per Relative Weight Contribution Cumulative(%) <= ~&&cdb_weight_threshold.%)
PRO ~~~~~~~~
WITH
cdb_attributes_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       cdb_weight, maxed_out, kiev_flag, casper_flag,
       num_cpu_cores, load_avg, u02_available,
       ROW_NUMBER() OVER (PARTITION BY region_acronym, db_name ORDER BY version DESC NULLS LAST) AS version_rn
  FROM C##IOD.cdb_attributes
 WHERE locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND num_cpu_cores >= 36 -- exclude VMs
   AND version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND ROWNUM >= 1
),
cdb_attributes_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       num_cpu_cores, load_avg, u02_available,
       cdb_weight, CASE maxed_out WHEN 0 THEN 'N' ELSE 'Y' END AS maxed_out, kiev_flag, casper_flag
  FROM cdb_attributes_all_versions
 WHERE version_rn = 1
   AND ROWNUM >= 1
),
all_pdbs_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name,
       COUNT(*) AS pdbs_count,
       SUM(p.avg_running_sessions) AS sum_avg_running_sessions,
       SUM(p.total_size_bytes) AS sum_total_size_bytes,
       ROW_NUMBER() OVER (PARTITION BY p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name ORDER BY p.version DESC NULLS LAST) AS version_rn
  FROM C##IOD.pdb_attributes p
 WHERE p.locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND p.avg_running_sessions > 0
   AND p.total_size_bytes > 0
   AND p.version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND ROWNUM >= 1
 GROUP BY
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name
),
all_pdbs_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name,
       p.pdbs_count, p.sum_avg_running_sessions, p.sum_total_size_bytes,
       -- 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () AS weight_pdbs_count,
       -- 100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () AS weight_avg_running_sessions,
       -- 100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () AS weight_total_size_bytes,
       -- (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () ELSE 0 END)
       --   + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () ELSE 0 END)
       --   + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () ELSE 0 END)
       -- ) / (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 1 ELSE 0 END)
       --       + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 1 ELSE 0 END) 
       --       + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 1 ELSE 0 END)
       --     ) 
       -- AS weight_contribution_percent,
       100 * p.pdbs_count / SUM(p.pdbs_count) OVER () AS weight_pdbs_count,
       100 * c.load_avg / c.num_cpu_cores / SUM(c.load_avg / c.num_cpu_cores) OVER () AS weight_cpu_cores,
       100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) / SUM(p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10)))) OVER () AS weight_disk_space,
       (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () ELSE 0 END)
         + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 100 * c.load_avg / c.num_cpu_cores / SUM(c.load_avg / c.num_cpu_cores) OVER () ELSE 0 END)
         + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) / SUM(p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10)))) OVER () ELSE 0 END)
       ) / (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 1 ELSE 0 END)
             + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 1 ELSE 0 END) 
             + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 1 ELSE 0 END)
           ) 
       AS weight_contribution_percent,
       c.cdb_weight, c.maxed_out, c.kiev_flag, c.casper_flag, c.version AS cdb_version,
       c.num_cpu_cores, c.load_avg, ROUND(NVL(c.u02_available, 0) * POWER(2,10) / POWER(10,9), 3) AS u02_available_gbs,
       100 * c.load_avg / c.num_cpu_cores AS cpu_cores_utilization_perc,
       100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) AS disk_utilization_perc
  FROM all_pdbs_all_versions p,
       cdb_attributes_last_version c
 WHERE p.version_rn = 1
   AND c.region_acronym = p.region_acronym
   AND c.db_name = p.db_name
   AND ROWNUM >= 1
),
top_cdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.weight_pdbs_count, p.weight_cpu_cores, p.weight_disk_space,
       p.weight_contribution_percent,
       SUM(p.weight_contribution_percent) OVER (ORDER BY p.weight_contribution_percent DESC, p.host_name RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weight_contribution_cumulative,
       p.pdbs_count,
       p.sum_avg_running_sessions,
       p.sum_total_size_bytes / POWER(10,9) AS sum_total_size_gbs,
       p.realm, p.region_acronym, p.locale, p.db_name, p.db_domain, p.host_name, p.version AS pdb_version,
       p.cdb_weight, p.maxed_out, p.kiev_flag, p.casper_flag, p.cdb_version,
       p.num_cpu_cores, p.load_avg, p.u02_available_gbs,
       p.cpu_cores_utilization_perc, p.disk_utilization_perc
  FROM all_pdbs_last_version p
 WHERE ROWNUM >= 1
)
SELECT region_acronym, db_name,
       '|' AS "|",
       maxed_out,
       cdb_weight,
       -- weight_pdbs_count, weight_cpu_cores, weight_disk_space,
       weight_contribution_percent,
       weight_contribution_cumulative,
       '|' AS "|",
       pdbs_count,
       cpu_cores_utilization_perc,
       disk_utilization_perc,
       '|' AS "|",
       num_cpu_cores,
       load_avg,
       sum_avg_running_sessions,
       sum_total_size_gbs,
       u02_available_gbs,
       '|' AS "|",
       kiev_flag, casper_flag,
       realm, locale, db_domain, host_name, pdb_version,
       cdb_version
  FROM top_cdbs
 WHERE ROUND(weight_contribution_cumulative) <= &&cdb_weight_threshold.
 ORDER BY
       weight_contribution_percent DESC,
       region_acronym, db_name
/
--
PRO
PRO Review list above and determine which Region and DB Name to select for listing top PDBs on it
PRO
PRO 4. Region: (req)
DEF cs_region = '&4.';
UNDEF 4;
COL cs_region NEW_V cs_region NOPRI;
SELECT UPPER(TRIM('&&cs_region.')) AS cs_region FROM DUAL
/
--
PRO
PRO 5. DB Name: (req)
DEF cs_db_name = '&5.';
UNDEF 5;
COL cs_db_name NEW_V cs_db_name NOPRI;
SELECT UPPER(TRIM('&&cs_db_name.')) AS cs_db_name FROM DUAL
/
--
PRO
PRO ***
PRO
PRO List of PDBs with high resources utilization as per: running sessions and/or disk space (as per input parameres)
PRO
PRO Top PDBs for &&cs_region. &&cs_db_name. (as per Relative Weight Contribution Cumulative(%) <= ~&&pdb_weight_threshold.%)
PRO ~~~~~~~~
WITH
cdb_attributes_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       cdb_weight, maxed_out, kiev_flag, casper_flag,
       num_cpu_cores, load_avg, u02_available,
       ROW_NUMBER() OVER (PARTITION BY region_acronym, db_name ORDER BY version DESC NULLS LAST) AS version_rn
  FROM C##IOD.cdb_attributes
 WHERE locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND num_cpu_cores >= 36 -- exclude VMs
   AND version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND region_acronym = '&&cs_region.'
   AND db_name = '&&cs_db_name.'   AND ROWNUM >= 1
),
cdb_attributes_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       num_cpu_cores, load_avg, u02_available,
       cdb_weight, CASE maxed_out WHEN 0 THEN 'N' ELSE 'Y' END AS maxed_out, kiev_flag, casper_flag
  FROM cdb_attributes_all_versions
 WHERE version_rn = 1
   AND ROWNUM >= 1
),
all_pdbs_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name, p.pdb_name, p.kiev_or_wf,
       COUNT(*) AS pdbs_count,
       SUM(p.avg_running_sessions) AS sum_avg_running_sessions,
       SUM(p.total_size_bytes) AS sum_total_size_bytes,
       ROW_NUMBER() OVER (PARTITION BY p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.pdb_name ORDER BY p.version DESC NULLS LAST) AS version_rn
  FROM C##IOD.pdb_attributes p
 WHERE p.locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND p.avg_running_sessions > 0
   AND p.total_size_bytes > 0
   AND p.version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND p.region_acronym = '&&cs_region.'
   AND p.db_name = '&&cs_db_name.'
   AND ROWNUM >= 1
 GROUP BY
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name, p.pdb_name, p.kiev_or_wf
),
all_pdbs_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name, p.pdb_name, p.kiev_or_wf,
       p.pdbs_count, p.sum_avg_running_sessions, p.sum_total_size_bytes,
       100 * p.pdbs_count / SUM(p.pdbs_count) OVER () AS weight_pdbs_count,
       100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () AS weight_avg_running_sessions,
       100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () AS weight_total_size_bytes,
       (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () ELSE 0 END)
         + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () ELSE 0 END)
         + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () ELSE 0 END)
       ) / (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 1 ELSE 0 END)
             + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 1 ELSE 0 END) 
             + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 1 ELSE 0 END)
           ) 
       AS weight_contribution_percent,
       c.cdb_weight, c.maxed_out, c.kiev_flag, c.casper_flag, c.version AS cdb_version,
       c.num_cpu_cores, c.load_avg, ROUND(NVL(c.u02_available, 0) * POWER(2,10) / POWER(10,9), 3) AS u02_available_gbs,
       100 * c.load_avg / c.num_cpu_cores AS cpu_cores_utilization_perc,
       100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) AS disk_utilization_perc
  FROM all_pdbs_all_versions p,
       cdb_attributes_last_version c
 WHERE p.version_rn = 1
   AND c.region_acronym = p.region_acronym
   AND c.db_name = p.db_name
   AND ROWNUM >= 1
),
top_pdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.weight_contribution_percent,
       SUM(p.weight_contribution_percent) OVER (ORDER BY p.weight_contribution_percent DESC, p.pdb_name RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weight_contribution_cumulative,
       p.pdbs_count,
       p.sum_avg_running_sessions,
       p.sum_total_size_bytes / POWER(10,9) AS sum_total_size_gbs,
       p.realm, p.region_acronym, p.locale, p.db_name,p. db_domain, p.host_name, p.pdb_name, p.kiev_or_wf, p.version AS pdb_version,
       p.cdb_weight, p.maxed_out, p.kiev_flag, p.casper_flag, p.cdb_version,
       p.num_cpu_cores, p.load_avg, p.u02_available_gbs,
       p.cpu_cores_utilization_perc, p.disk_utilization_perc
  FROM all_pdbs_last_version p
 WHERE ROWNUM >= 1
)
SELECT -- region_acronym, db_name, 
       pdb_name, kiev_or_wf,
       '|' AS "|",
       -- maxed_out,
       weight_contribution_percent,
       weight_contribution_cumulative,
       '|' AS "|",
       -- pdbs_count,
       -- cpu_cores_utilization_perc,
       -- disk_utilization_perc,
       -- '|' AS "|",
       sum_avg_running_sessions,
       sum_total_size_gbs,
       -- num_cpu_cores,
       -- load_avg,
       -- u02_available_gbs,
       '|' AS "|",
       -- kiev_flag, casper_flag,
       -- realm, 
       locale, 
       -- db_domain, 
       host_name, pdb_version,
       cdb_version
  FROM top_pdbs
 WHERE ROUND(weight_contribution_cumulative) <= &&pdb_weight_threshold.
 ORDER BY
       weight_contribution_percent DESC,
       region_acronym, db_name, pdb_name
/
--
PRO
PRO ***
PRO
PRO CDBs (other than &&cs_db_name.) available on same Region &&cs_region. and Locale &&locale., where PDBs on list above could be migrated to.
PRO Verify target CDB is not maxed out and that Casper/Kiev flags are compatible with PDBs to be moved.
PRO
PRO Candidate CDBs
PRO ~~~~~~~~~~~~~~
WITH
cdb_attributes_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       cdb_weight, maxed_out, kiev_flag, casper_flag,
       num_cpu_cores, load_avg, u02_available,
       ROW_NUMBER() OVER (PARTITION BY region_acronym, db_name ORDER BY version DESC NULLS LAST) AS version_rn
  FROM C##IOD.cdb_attributes
 WHERE locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND num_cpu_cores >= 36 -- exclude VMs
   AND version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND db_name <> '&&cs_db_name.'
   AND locale = '&&locale.'
   AND ROWNUM >= 1
),
cdb_attributes_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       version, region_acronym, db_name,
       num_cpu_cores, load_avg, u02_available,
       cdb_weight, CASE maxed_out WHEN 0 THEN 'N' ELSE 'Y' END AS maxed_out, kiev_flag, casper_flag
  FROM cdb_attributes_all_versions
 WHERE version_rn = 1
   AND ROWNUM >= 1
),
all_pdbs_all_versions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name,
       COUNT(*) AS pdbs_count,
       SUM(p.avg_running_sessions) AS sum_avg_running_sessions,
       SUM(p.total_size_bytes) AS sum_total_size_bytes,
       ROW_NUMBER() OVER (PARTITION BY p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name ORDER BY p.version DESC NULLS LAST) AS version_rn
  FROM C##IOD.pdb_attributes p
 WHERE p.locale IN ('RGN', 'AD1', 'AD2', 'AD3')
   AND p.avg_running_sessions > 0
   AND p.total_size_bytes > 0
   AND p.version > SYSDATE - &&version_age_days_threshold.
   AND (('&&include_casper.' = 'Y' AND SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')) OR ('&&include_casper.' = 'N' AND NOT SUBSTR(p.db_name, 1, 4) IN ('CASP', 'TENA')))
   AND ('&&include_pdbs.' = 'Y' OR '&&include_avg_running_sessions.' = 'Y' OR '&&include_total_size_bytes.' = 'Y')
   AND p.region_acronym = '&&cs_region.'
   AND p.db_name <> '&&cs_db_name.'
   AND p.locale = '&&locale.'
   AND ROWNUM >= 1
 GROUP BY
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name
),
all_pdbs_last_version AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.version, p.realm, p.realm_order_by, p.region_acronym, p.region_order_by, p.locale, p.locale_order_by, p.db_domain, p.db_name, p.host_name,
       p.pdbs_count, p.sum_avg_running_sessions, p.sum_total_size_bytes,
       -- 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () AS weight_pdbs_count,
       -- 100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () AS weight_avg_running_sessions,
       -- 100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () AS weight_total_size_bytes,
       -- (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () ELSE 0 END)
       --   + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 100 * p.sum_avg_running_sessions / SUM(p.sum_avg_running_sessions) OVER () ELSE 0 END)
       --   + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 100 * p.sum_total_size_bytes / SUM(p.sum_total_size_bytes) OVER () ELSE 0 END)
       -- ) / (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 1 ELSE 0 END)
       --       + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 1 ELSE 0 END) 
       --       + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 1 ELSE 0 END)
       --     ) 
       -- AS weight_contribution_percent,
       100 * p.pdbs_count / SUM(p.pdbs_count) OVER () AS weight_pdbs_count,
       100 * c.load_avg / c.num_cpu_cores / SUM(c.load_avg / c.num_cpu_cores) OVER () AS weight_cpu_cores,
       100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) / SUM(p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10)))) OVER () AS weight_disk_space,
       (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 100 * p.pdbs_count / SUM(p.pdbs_count) OVER () ELSE 0 END)
         + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 100 * c.load_avg / c.num_cpu_cores / SUM(c.load_avg / c.num_cpu_cores) OVER () ELSE 0 END)
         + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) / SUM(p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10)))) OVER () ELSE 0 END)
       ) / (   (CASE '&&include_pdbs.' WHEN 'Y' THEN 1 ELSE 0 END)
             + (CASE '&&include_avg_running_sessions.' WHEN 'Y' THEN 1 ELSE 0 END) 
             + (CASE '&&include_total_size_bytes.' WHEN 'Y' THEN 1 ELSE 0 END)
           ) 
       AS weight_contribution_percent,
       c.cdb_weight, c.maxed_out, c.kiev_flag, c.casper_flag, c.version AS cdb_version,
       c.num_cpu_cores, c.load_avg, ROUND(NVL(c.u02_available, 0) * POWER(2,10) / POWER(10,9), 3) AS u02_available_gbs,
       100 * c.load_avg / c.num_cpu_cores AS cpu_cores_utilization_perc,
       100 * p.sum_total_size_bytes / (p.sum_total_size_bytes + (NVL(c.u02_available, 0) * POWER(2,10))) AS disk_utilization_perc
  FROM all_pdbs_all_versions p,
       cdb_attributes_last_version c
 WHERE p.version_rn = 1
   AND c.region_acronym = p.region_acronym
   AND c.db_name = p.db_name
   AND ROWNUM >= 1
),
top_cdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.weight_pdbs_count, p.weight_cpu_cores, p.weight_disk_space,
       p.weight_contribution_percent,
       SUM(p.weight_contribution_percent) OVER (ORDER BY p.weight_contribution_percent ASC, p.host_name DESC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weight_contribution_cumulative,
       p.pdbs_count,
       p.sum_avg_running_sessions,
       p.sum_total_size_bytes / POWER(10,9) AS sum_total_size_gbs,
       p.realm, p.region_acronym, p.locale, p.db_name, p.db_domain, p.host_name, p.version AS pdb_version,
       p.cdb_weight, p.maxed_out, p.kiev_flag, p.casper_flag, p.cdb_version,
       p.num_cpu_cores, p.load_avg, p.u02_available_gbs,
       p.cpu_cores_utilization_perc, p.disk_utilization_perc
  FROM all_pdbs_last_version p
 WHERE ROWNUM >= 1
)
SELECT region_acronym, db_name,
       '|' AS "|",
       maxed_out,
       cdb_weight,
       -- weight_pdbs_count, weight_cpu_cores, weight_disk_space,
       weight_contribution_percent,
       weight_contribution_cumulative,
       '|' AS "|",
       pdbs_count,
       cpu_cores_utilization_perc,
       disk_utilization_perc,
       '|' AS "|",
       num_cpu_cores,
       load_avg,
       sum_avg_running_sessions,
       sum_total_size_gbs,
       u02_available_gbs,
       '|' AS "|",
       kiev_flag, casper_flag,
       realm, locale, db_domain, host_name, pdb_version,
       cdb_version
  FROM top_cdbs
 ORDER BY
       weight_contribution_percent ASC,
       region_acronym, db_name
/
