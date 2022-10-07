--
BREAK ON pluggable_database SKIP 1;
--
PRO
PRO PDBs Directives Changes (&&cs_tools_schema..rsrc_mgr_pdb_hist)
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
       --LAG(snap_time) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_snap_time,
       --LEAD(snap_time) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lead_snap_time,
       LAG(utilization_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_utilization_limit,
       LAG(shares, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_shares,
       LAG(parallel_server_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_parallel_server_limit,
       LAG(reference, 1, NULL) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_reference,
       LAG(aas_pct, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_aas_pct
  FROM &&cs_tools_schema..rsrc_mgr_pdb_hist
 WHERE plan = '&&resource_manager_plan.'
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND pdb_name IN (SELECT name FROM v$containers WHERE con_id > 2)
   AND snap_time > SYSDATE - 365
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
       '|' AS "|",
       aas_avg,
       aas_p95,
       aas_p99,
       '|' AS "|",
       aas_avg_c,
       aas_p95_c,
       aas_p99_c,
       '|' AS "|",
       directive_dml
  FROM augmented
 WHERE directive_dml IS NOT NULL -- I|U or null
    OR utilization_limit <> lag_utilization_limit
    OR shares <> lag_shares
    OR parallel_server_limit <> lag_parallel_server_limit
    OR COALESCE(reference, '-666') <> COALESCE(lag_reference, '-666')
    --OR aas_pct <> lag_aas_pct
 ORDER BY
       pluggable_database,
       snap_time
/
PRO
PRO CPU Required pct%: percent of "CPU Required tot" with respect to NUM_CPU_THREADS. this is a computed estimate of what utilization_limit should be before applying PDB cap (currently 24%.)
PRO CPU Required tot: refers to GREATEST(3x avg, 2x p95, 1.5x p99.)
PRO CPU Required: refers to AAS ON CPU or RM Scheduler, for a 3d moving window.
PRO CPU Consumed: refers to AAS ON CPU, for a 3d moving window.
--
CLEAR BREAK;
--
PRO
PRO Recent Changes - 7d (&&cs_tools_schema..rsrc_mgr_pdb_hist)
PRO ~~~~~~~~~~~~~~~~~~~
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
       --LAG(snap_time) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_snap_time,
       --LEAD(snap_time) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lead_snap_time,
       LAG(utilization_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_utilization_limit,
       LAG(shares, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_shares,
       LAG(parallel_server_limit, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_parallel_server_limit,
       LAG(reference, 1, NULL) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_reference,
       LAG(aas_pct, 1, 0) OVER (PARTITION BY pdb_name ORDER BY snap_time) AS lag_aas_pct
  FROM &&cs_tools_schema..rsrc_mgr_pdb_hist
 WHERE plan = '&&resource_manager_plan.'
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND pdb_name IN (SELECT name FROM v$containers WHERE con_id > 2)
   AND snap_time > SYSDATE - 7
)
SELECT snap_time,
       pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       reference,
       '|' AS "|",
       aas_pct,
       aas_req,
       '|' AS "|",
       aas_avg,
       aas_p95,
       aas_p99,
       '|' AS "|",
       aas_avg_c,
       aas_p95_c,
       aas_p99_c,
       '|' AS "|",
       directive_dml
  FROM augmented
 WHERE aas_avg_c IS NULL -- to get old rows before 2019-07-01
    OR directive_dml IS NOT NULL -- I|U or null
    OR utilization_limit <> lag_utilization_limit
    OR shares <> lag_shares
    OR parallel_server_limit <> lag_parallel_server_limit
    OR COALESCE(reference, '-666') <> COALESCE(lag_reference, '-666')
    --OR aas_pct <> lag_aas_pct
 ORDER BY
       snap_time,
       pluggable_database
/
PRO
PRO CPU Required pct%: percent of "CPU Required tot" with respect to NUM_CPU_THREADS. this is a computed estimate of what utilization_limit should be before applying PDB cap (currently 24%.)
PRO CPU Required tot: refers to GREATEST(3x avg, 2x p95, 1.5x p99.)
PRO CPU Required: refers to AAS ON CPU or RM Scheduler, for a 3d moving window.
PRO CPU Consumed: refers to AAS ON CPU, for a 3d moving window.