-- iod_fleet_summary.sql - IOD Feet CDBs Summary
DEF cs_version = '&1.';
UNDEF 1;
--
CLEAR BREAK COLUMNS;
COL realm_type HEA 'Type';
COL realm FOR A5 HEA 'Realm';
COL region_acronym FOR A3 HEA 'Rgn';
COL region FOR A20 HEA 'Region';
COL pdbs FOR 999,990 HEA 'PDBs';
COL kiev_pdbs FOR 999,990 HEA 'KIEV|PDBs';
COL wf_pdbs FOR 999,990 HEA 'WF|PDBs';
COL casper_pdbs FOR 999,990 HEA 'CASPER|PDBs';
COL db_servers FOR 999,990 HEA 'DB|Servers';
COL db_primary FOR 999,990 HEA 'Primary';
COL maxed_out FOR 9,990 HEA 'Maxed|Out';
COL cdb_weight FOR 9,990 HEA 'CDB|Weight';
COL num_cpu_cores FOR 999,990 HEA 'CPU|Cores';
COL used_cpu_cores FOR 999,990 HEA 'Used|Cores';
COL disk_space_tb FOR 999,990 HEA 'Disk|TB';
COL used_space_tb FOR 999,990 HEA 'Used|TB';
COL perc_cpu_cores FOR A4 HEA '   %';
COL perc_space_tb FOR A4 HEA '   %';
BREAK ON realm_type SKIP 1 ON realm;
--
WITH
all_db_servers AS (
SELECT realm_type_order_by,
       realm_type, 
       realm_order_by,
       realm,
       region_order_by,
       region_acronym,
       region,
       SUM(GREATEST(dg_members, 1)) AS db_servers,
       COUNT(*) AS db_primary,
       SUM(maxed_out) AS maxed_out,
       SUM(GREATEST(dg_members, 1) * num_cpu_cores) AS num_cpu_cores,
       ROUND(SUM(NVL(load_avg, 0) * GREATEST(dg_members, 1))) AS used_cpu_cores,
       ROUND(SUM(GREATEST(dg_members, 1) * (NVL(u02_used, 0) + NVL(u02_available, 0)) * 1024 / POWER(10,12)), 3) AS disk_space_tb,
       ROUND(SUM(GREATEST(dg_members, 1) * NVL(u02_used, 0) * 1024 / POWER(10,12)), 3) AS used_space_tb,
       SUM(pdbs) AS pdbs,
       SUM(kiev_pdbs) AS kiev_pdbs,
       SUM(wf_pdbs) AS wf_pdbs,
       SUM(casper_pdbs) AS casper_pdbs
  FROM c##iod.cdb_attributes
 WHERE version = '&&cs_version.'
 GROUP BY 
       realm_type_order_by,
       realm_type, 
       realm_order_by,
       realm,
       region_order_by,
       region_acronym,
       region
),
with_subtotals AS (
SELECT realm_type_order_by,
       realm_type, 
       realm_order_by,
       realm,
       region_order_by,
       region_acronym,
       region,
       db_servers,
       db_primary,
       maxed_out,
       num_cpu_cores,
       used_cpu_cores,
       disk_space_tb,
       used_space_tb,
       pdbs,
       kiev_pdbs,
       wf_pdbs,
       casper_pdbs
  FROM all_db_servers
 UNION ALL
SELECT realm_type_order_by,
       realm_type, 
       TO_NUMBER(NULL) AS realm_order_by,
       NULL AS realm,
       TO_NUMBER(NULL) AS rregion_order_by,
       NULL AS region_acronym,
       realm_type AS region,
       SUM(db_servers) AS db_servers,
       SUM(db_primary) AS db_primary,
       SUM(maxed_out) AS maxed_out,
       SUM(num_cpu_cores) AS num_cpu_cores,
       SUM(used_cpu_cores) AS used_cpu_cores,
       SUM(disk_space_tb) AS disk_space_tb,
       SUM(used_space_tb) AS used_space_tb,
       SUM(pdbs) AS pdbs,
       SUM(kiev_pdbs) AS kiev_pdbs,
       SUM(wf_pdbs) AS wf_pdbs,
       SUM(casper_pdbs) AS casper_pdbs
  FROM all_db_servers
 GROUP BY 
       realm_type_order_by,
       realm_type
 UNION ALL
SELECT TO_NUMBER(NULL) AS  realm_type_order_by,
       'All' AS realm_type, 
       TO_NUMBER(NULL) AS realm_order_by,
       NULL AS realm,
       TO_NUMBER(NULL) AS rregion_order_by,
       NULL AS region_acronym,
       'Fleet' AS region,
       SUM(db_servers) AS db_servers,
       SUM(db_primary) AS db_primary,
       SUM(maxed_out) AS maxed_out,
       SUM(num_cpu_cores) AS num_cpu_cores,
       SUM(used_cpu_cores) AS used_cpu_cores,
       SUM(disk_space_tb) AS disk_space_tb,
       SUM(used_space_tb) AS used_space_tb,
       SUM(pdbs) AS pdbs,
       SUM(kiev_pdbs) AS kiev_pdbs,
       SUM(wf_pdbs) AS wf_pdbs,
       SUM(casper_pdbs) AS casper_pdbs
  FROM all_db_servers
)
SELECT realm_type, 
       realm,
       region_acronym,
       region,
       db_servers,
       db_primary,
       maxed_out,
       num_cpu_cores,
       used_cpu_cores,
       LPAD(TRIM(TO_CHAR(ROUND(100 * used_cpu_cores / NULLIF(num_cpu_cores, 0))))||'%', 4, ' ') AS perc_cpu_cores,
       ROUND(disk_space_tb,1) AS disk_space_tb,
       ROUND(used_space_tb,1) AS used_space_tb,
       LPAD(TRIM(TO_CHAR(CEIL(100 * used_space_tb / NULLIF(disk_space_tb, 0)), '990'))||'%', 4, ' ') AS perc_space_tb,
       pdbs,
       kiev_pdbs,
       wf_pdbs,
       casper_pdbs
  FROM with_subtotals
 ORDER BY
       realm_type_order_by NULLS LAST,
       realm_type NULLS LAST,
       realm_order_by NULLS LAST,
       realm NULLS LAST,
       region_order_by NULLS LAST,
       region_acronym NULLS LAST,
       region NULLS LAST
/
--
CLEAR BREAK COLUMNS;
