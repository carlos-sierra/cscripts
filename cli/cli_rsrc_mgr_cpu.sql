SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30 HEA '.|.|PDB Name';
COL avg_aas_on_cpu FOR 999,990.0 HEA 'Sessions|ON CPU|Average';
COL p95_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p95th PCTL';
COL p99_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|p99th PCTL';
COL max_aas_on_cpu FOR 999,990 HEA 'Sessions|ON CPU|Maximum';
--
WITH
ash_by_con_and_sample AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       h.con_id, h.sample_id, COUNT(*) AS aas_on_cpu
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND h.sample_time >= SYSDATE - 7
   AND h.session_state = 'ON CPU'
   AND ROWNUM >= 1
 GROUP BY
       h.con_id, h.sample_id
),
ash_by_con AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       h.con_id,
       AVG(h.aas_on_cpu) AS avg_aas_on_cpu,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p95_aas_on_cpu,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY h.aas_on_cpu) AS p99_aas_on_cpu,
       MAX(h.aas_on_cpu) AS max_aas_on_cpu
  FROM ash_by_con_and_sample h
 WHERE ROWNUM >= 1
 GROUP BY
       h.con_id
),
ash_by_con_ext AS (
SELECT c.name AS pdb_name,
       h.avg_aas_on_cpu, h.p95_aas_on_cpu, h.p99_aas_on_cpu, h.max_aas_on_cpu
  FROM ash_by_con h, v$containers c
 WHERE c.con_id = h.con_id
)
SELECT pdb_name, avg_aas_on_cpu, p95_aas_on_cpu, p99_aas_on_cpu, max_aas_on_cpu
  FROM ash_by_con_ext
 WHERE (pdb_name LIKE '%COMPUTE%' OR pdb_name LIKE '%VCN%')
 ORDER BY
       pdb_name
/