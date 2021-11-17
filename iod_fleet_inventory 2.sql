
-- iod_fleet_inventory.sql - IOD Fleet CDBs Inventory
DEF cs_version = '&1.';
UNDEF 1;
--
CLEAR COMPUTE BREAK COLUMNS;
--
COL realm_type HEA 'Type';
COL realm FOR A5 HEA 'Realm';
COL region_acronym FOR A3 HEA 'Rgn';
COL region FOR A17 HEA 'Region';
COL locale FOR A5 HEA 'Local';
COL db_name FOR A9 HEA 'DB Name';
COL host_name FOR A64 HEA 'Primary Host Name';
COL pdbs FOR 999,990 HEA 'PDBs';
COL kiev_pdbs FOR 999,990 HEA 'KIEV|PDBs';
COL wf_pdbs FOR 999,990 HEA 'WF|PDBs';
COL casper_pdbs FOR 999,990 HEA 'CASPER|PDBs';
COL db_servers FOR 999,990 HEA 'Tot DB|Servers';
COL db_primary FOR 999,990 HEA 'Primary';
COL maxed_out FOR 9,990 HEA 'Maxed|Out';
COL cdb_weight FOR 9,990 HEA 'CDB|Weight';
COL num_cpu_cores_total FOR 999,990 HEA 'CPU Cores|Total';
COL num_cpu_cores_server FOR 999,990 HEA 'CPU Cores|Per Server';
COL num_cpu_threads_server FOR 999,990 HEA 'CPU Threads|Per Server';
COL threads_util_perc_avg FOR 999 HEA 'Thread Util % Avg';
COL threads_util_perc_p90 FOR 999 HEA 'Thread Util % P90';
COL threads_util_perc_p95 FOR 999 HEA 'Thread Util % P95';
COL threads_util_perc_p99 FOR 999 HEA 'Thread Util % P99';
COL aas_on_cpu_avg FOR 999 HEA 'AAS on CPU Avg';
COL aas_on_cpu_p90 FOR 999 HEA 'AAS on CPU P90';
COL aas_on_cpu_p95 FOR 999 HEA 'AAS on CPU P95';
COL aas_on_cpu_p99 FOR 999 HEA 'AAS on CPU P99';
COL disk_space_tb_total FOR 999,990.0 HEA 'DISK TB|Total';
COL used_space_tb_total FOR 999,990.0 HEA 'Used TB|Total';
COL disk_space_tb_server FOR 999,990.0 HEA 'DISK TB|Per Server';
COL used_space_tb_server FOR 999,990.0 HEA 'Used TB|Per Server';
COL used_space_tb_1m FOR 999,990.0 HEA 'Used TB|Last Month';
COL fs_u02_at_80p FOR A10 HEA 'Disk|at 80%';
COL fs_u02_at_90p FOR A10 HEA 'Disk|at 90%';
COL fs_u02_at_95p FOR A10 HEA 'Disk|at 95%';
COL perc_cpu_threads FOR 999,990 HEA 'Thread|Util %';
COL perc_space_tb_now FOR 999,990 HEA 'Current|Space Util %';
COL perc_space_tb_1m FOR 999,990.0 HEA 'Last Month|Space Util %';
COL disk_config FOR A16 HEA 'Disk|Config';
COL host_shape FOR A64 HEA 'Host Shape';
COL host_class FOR A64 HEA 'Host Class';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF pdbs wf_pdbs kiev_pdbs casper_pdbs db_servers db_primary maxed_out num_cpu_cores_total disk_space_tb_total used_space_tb_total ON REPORT;
--
WITH
all_db_servers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       realm_type_order_by,
       realm_type, 
       realm_order_by,
       realm,
       region_order_by,
       region_acronym,
       region,
       locale_order_by,
       locale,
       host_class,
       db_name,
       db_version,
       GREATEST(dg_members, 1) AS db_servers,
       1 AS db_primary,
       maxed_out,
       cdb_weight,
       GREATEST(dg_members, 1) * num_cpu_cores AS num_cpu_cores_total,
       num_cpu_cores AS num_cpu_cores_server,
       num_cpu_threads AS num_cpu_threads_server,
       ROUND(100 * load_avg / num_cpu_threads) AS threads_util_perc_avg,
       ROUND(100 * load_p90 / num_cpu_threads) AS threads_util_perc_p90,
       ROUND(100 * load_p95 / num_cpu_threads) AS threads_util_perc_p95,
       ROUND(100 * load_p99 / num_cpu_threads) AS threads_util_perc_p99,
       ROUND(aas_on_cpu_avg) AS aas_on_cpu_avg,
       aas_on_cpu_p90,
       aas_on_cpu_p95,
       aas_on_cpu_p99,
       ROUND(GREATEST(dg_members, 1) * (NVL(u02_used, 0) + NVL(u02_available, 0)) * 1024 / POWER(10,12), 3) AS disk_space_tb_total,
       ROUND(GREATEST(dg_members, 1) * NVL(u02_used, 0) * 1024 / POWER(10,12), 3) AS used_space_tb_total,
       ROUND((NVL(u02_used, 0) + NVL(u02_available, 0)) * 1024 / POWER(10,12), 3) AS disk_space_tb_server,
       ROUND(NVL(u02_used, 0) * 1024 / POWER(10,12), 3) AS used_space_tb_server,
       ROUND((NVL(u02_used, 0) - NVL(u02_used_1m, 0)) * 1024 / POWER(10,12), 3) AS used_space_tb_1m,
       fs_u02_util_perc AS fs_u02_util_perc_now,
       100 * (NVL(u02_used, 0) - NVL(u02_used_1m, 0)) / NULLIF((NVL(u02_used, 0) + NVL(u02_available, 0)), 0) AS fs_u02_util_perc_1m,
       fs_u02_at_80p,
       fs_u02_at_90p,
       fs_u02_at_95p,
       disk_config,
       pdbs,
       kiev_pdbs,
       wf_pdbs,
       casper_pdbs AS casper_pdbs,
       kiev_flag,
       wf_flag,
       casper_flag,
       host_shape,
       host_name
  FROM c##iod.cdb_attributes
 WHERE version = '&&cs_version.'
),
ordered AS (
SELECT realm_type, 
       realm,
       region_acronym,
       region,
       locale,
       host_class,
       db_name,
       db_version,
       db_servers,
       db_primary,
       maxed_out,
       cdb_weight,
       num_cpu_cores_total,
       num_cpu_cores_server,
       num_cpu_threads_server,
       threads_util_perc_avg,
       threads_util_perc_p90,
       threads_util_perc_p95,
       threads_util_perc_p99,
       aas_on_cpu_avg,
       aas_on_cpu_p90,
       aas_on_cpu_p95,
       aas_on_cpu_p99,
       ROUND(disk_space_tb_total,1) AS disk_space_tb_total,
       ROUND(used_space_tb_total,1) AS used_space_tb_total,
       ROUND(disk_space_tb_server,1) AS disk_space_tb_server,
       ROUND(used_space_tb_server,1) AS used_space_tb_server,
       CASE WHEN ROUND(used_space_tb_1m,1) >= 0.1 AND ROUND(fs_u02_util_perc_1m, 1) > 0.1 THEN ROUND(used_space_tb_1m,1) END AS used_space_tb_1m,
       CEIL(fs_u02_util_perc_now) AS perc_space_tb_now,
       CASE WHEN ROUND(used_space_tb_1m,1) >= 0.1 AND ROUND(fs_u02_util_perc_1m, 1) > 0.1 THEN ROUND(fs_u02_util_perc_1m, 1) END AS perc_space_tb_1m,
       fs_u02_at_80p,
       fs_u02_at_90p,
       fs_u02_at_95p,
       disk_config,
       pdbs,
       kiev_pdbs,
       wf_pdbs,
       casper_pdbs,
       kiev_flag,
       wf_flag,
       casper_flag,
       host_shape,
       host_name
  FROM all_db_servers
 ORDER BY
       realm_type_order_by NULLS LAST,
       realm_type NULLS LAST,
       realm_order_by NULLS LAST,
       realm NULLS LAST,
       region_order_by NULLS LAST,
       region_acronym NULLS LAST,
       region NULLS LAST,
       locale_order_by NULLS LAST,
       locale NULLS LAST,
       db_name NULLS LAST
)
--SELECT * FROM ordered
--SELECT 'Type,Realm,Rgn,Region,Local,Host Class,DB Name,DB Servers,Primary,Maxed Out,CDB Weight,CPU Cores Total,CPU Cores per Server,CPU Threads per Server,Thread Util % Avg,Thread Util % P90,Thread Util % P95,Thread Util % P99,AAS on CPU Avg,AAS on CPU P90,AAS on CPU P95,AAS on CPU P99,Disk TB Total,Used TB Total,Disk TB per Server,Used TB per Server,Used TB last Month,Current Space Util %,Last Month Space Util %,Disk at 80%,Disk at 90%,Disk at 95%,Disk Config,PDBs,KIEV,WF,CASPER,KIEV PDBs,WF PDBs,Casper PDBs,Host Shape,Primary Host Name' AS line
SELECT 'Type,Realm,Rgn,Region,Local,Host Class,DB Name,DB Version,Maxed Out,CDB Weight,CPU Cores per Server,CPU Threads per Server,Thread Util % Avg,Thread Util % P90,Thread Util % P95,Thread Util % P99,Disk TB per Server,Used TB per Server,Used TB last Month,Current Space Util %,Last Month Space Util %,Disk at 80%,Disk at 90%,Disk at 95%,Disk Config,PDBs,KIEV,WF,CASPER,KIEV PDBs,WF PDBs,Casper PDBs,Host Shape,Primary Host Name' AS line
  FROM DUAL
 UNION ALL
SELECT realm_type||','||
       realm||','||
       region_acronym||','||
       region||','||
       locale||','||
       host_class||','||
       db_name||','||
       db_version||','||
       --db_servers||','||
       --db_primary||','||
       maxed_out||','||
       cdb_weight||','||
       --num_cpu_cores_total||','||
       num_cpu_cores_server||','||
       num_cpu_threads_server||','||
       threads_util_perc_avg||','||
       threads_util_perc_p90||','||
       threads_util_perc_p95||','||
       threads_util_perc_p99||','||
       --aas_on_cpu_avg||','||
       --aas_on_cpu_p90||','||
       --aas_on_cpu_p95||','||
       --aas_on_cpu_p99||','||
       --disk_space_tb_total||','||
       --used_space_tb_total||','||
       disk_space_tb_server||','||
       used_space_tb_server||','||
       used_space_tb_1m||','||
       perc_space_tb_now||','||
       perc_space_tb_1m||','||
       fs_u02_at_80p||','||
       fs_u02_at_90p||','||
       fs_u02_at_95p||','||
       disk_config||','||
       pdbs||','||
       kiev_flag||','||
       wf_flag||','||
       casper_flag||','||
       kiev_pdbs||','||
       wf_pdbs||','||
       casper_pdbs||','||
       host_shape||','||
       host_name AS line
  FROM ordered 
/
--
CLEAR COMPUTE BREAK COLUMNS;
