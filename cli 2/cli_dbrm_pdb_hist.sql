SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL comments FOR A60 HEA 'Comments';
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30 HEA 'PDB Name';
COL shares FOR 9,990 HEA 'Shares';
COL utilization_limit FOR 9,990 HEA 'CPUs|Allotted %'
COL parallel_server_limit FOR 9,990 HEA 'Parallel|Alloted %';
COL directive_type FOR A20 HEA 'Directive Type';
COL end_date FOR A19 HEA 'Expires';
COL reference HEA 'Reference';
COL snap_time HEA 'Created';
COL aas_req FOR 999,990.0 HEA 'CPUs|Required|tot';
COL aas_pct FOR 999,990 HEA 'CPUs|Required|pct%';
COL aas_avg FOR 999,990.0 HEA 'CPUs|Required|avg';
COL aas_p95 FOR 999,990 HEA 'CPUs|Required|p95';
COL aas_p99 FOR 999,990 HEA 'CPUs|Required|p99';
COL aas_avg_c FOR 999,990.0 HEA 'CPUs|Consumed|avg';
COL aas_p95_c FOR 999,990 HEA 'CPUs|Consumed|p95';
COL aas_p99_c FOR 999,990 HEA 'CPUs|Consumed|p99';
--
PRO
PRO PDBs Directives History (CDB$ROOT c##iod.rsrc_mgr_pdb_hist)
PRO ~~~~~~~~~~~~~~~~~~~~~~~
WITH
augmented AS (
SELECT pdb_name AS pluggable_database,
       snap_time,
       utilization_limit,
       shares,
       parallel_server_limit,
       reference,
       aas_pct,
       aas_req,
       aas_avg,
       aas_p95,
       aas_p99,
       aas_avg_c,
       aas_p95_c,
       aas_p99_c,
       directive_dml,
       LAG(utilization_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_utilization_limit,
       LAG(shares, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_shares,
       LAG(parallel_server_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_parallel_server_limit,
       LAG(reference, 1, NULL) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_reference,
       LAG(aas_pct, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_aas_pct,
       ROW_NUMBER() OVER (PARTITION BY pdb_name ORDER BY snap_time DESC) AS rn
  FROM c##iod.rsrc_mgr_pdb_hist
 WHERE plan = 'IOD_CDB_PLAN'
),
filtered AS (
SELECT pluggable_database,
       snap_time,
       utilization_limit,
       shares,
       parallel_server_limit,
       reference,
       aas_pct,
       aas_req,
       aas_avg,
       aas_p95,
       aas_p99,
       aas_avg_c,
       aas_p95_c,
       aas_p99_c,
       ROW_NUMBER() OVER (PARTITION BY pluggable_database ORDER BY snap_time DESC) AS rn
  FROM augmented
 WHERE aas_avg_c IS NULL -- to get old rows before 2019-07-01
    OR directive_dml IS NOT NULL -- I|U or null
    OR utilization_limit <> lag_utilization_limit
    OR shares <> lag_shares
    OR parallel_server_limit <> lag_parallel_server_limit
    OR COALESCE(reference, '-666') <> COALESCE(lag_reference, '-666')
)
SELECT pluggable_database,
       snap_time,
       utilization_limit,
       shares,
       parallel_server_limit,
       reference,
       '|' AS "|",
       aas_pct,
       aas_req,
       aas_avg,
       aas_p95,
       aas_p99,
       aas_avg_c,
       aas_p95_c,
       aas_p99_c
  FROM filtered
 WHERE rn = 1
   AND aas_pct > 12
   --AND utilization_limit >= aas_pct
 ORDER BY
       pluggable_database
/
--