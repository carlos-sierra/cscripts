-- pdb.sql - List all PDBs, then connect into one PDB
@@set.sql
COL cs_con_name NEW_V cs_con_name NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name FROM DUAL
/
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
--
COL pdb_name FOR A30 HEA 'PDB Name' PRI;
COL con_id FOR 990 HEA 'CON|ID' PRI;
COL cpus FOR 9,990.000 HEA 'CPUs' PRI;
COL cpus_perc FOR 990.0 HEA 'CPUs|Perc%' PRI;
COL cpus_rank FOR 990 HEA 'CPUs|Rank' PRI;
COL space_gb FOR 99,990.000 HEA 'Space|GBs' PRI;
COL space_perc FOR 990.0 HEA 'Space|Perc%' PRI;
COL space_rank FOR 990 HEA 'Space|Rank' PRI;
COL iops FOR 9,999,990.000 HEA 'IOPS' PRI;
COL iops_perc FOR 990.0 HEA 'IOPS|Perc%' PRI;
COL iops_rank FOR 990 HEA 'IOPS|Rank' PRI;
COL mbps FOR 999,990.000 HEA 'MBPS' PRI;
COL mbps_perc FOR 990.0 HEA 'MBPS|Perc%' PRI;
COL mbps_rank FOR 990 HEA 'MBPS|Rank' PRI;
--
BREAK ON REPORT;
COMPUTE SUM OF cpus cpus_perc space_gb space_perc iops iops_perc mbps mbps_perc ON REPORT;
--
PRO
PRO Top PDBs
PRO ~~~~~~~~
WITH
rsrcmgrmetric AS (
SELECT r.con_id,
       c.name AS pdb_name,
       (SUM(r.cpu_consumed_time) / 1000) / (MAX(r.intsize_csec) / 100) AS cpus,
       MAX(c.total_size) / POWER(2,30) AS space_gb,
       SUM(r.io_requests) / (MAX(r.intsize_csec) / 100) AS iops,
       SUM(r.io_megabytes) / (MAX(r.intsize_csec) / 100) AS mbps
  FROM v$rsrcmgrmetric r,
       v$containers c
 WHERE r.con_id > 2 -- exclude CDB$ROOT
   AND r.intsize_csec > 0
   AND c.con_id = r.con_id
 GROUP BY
       r.con_id, -- needed since there are multiple consumer groups (usually 3) per time slice
       c.name
),
rsrcmgrmetric_ext AS (
SELECT con_id,
       pdb_name,
       cpus,
       100 * cpus / NULLIF(SUM(cpus) OVER(), 0) AS cpus_perc,
       RANK() OVER(ORDER BY cpus DESC) AS cpus_rank,
       space_gb,
       100 * space_gb / NULLIF(SUM(space_gb) OVER(), 0) AS space_perc,
       RANK() OVER(ORDER BY space_gb DESC) AS space_rank,
       iops,
       100 * iops / NULLIF(SUM(iops) OVER(), 0) AS iops_perc,
       RANK() OVER(ORDER BY iops DESC) AS iops_rank,
       mbps,
       100 * mbps / NULLIF(SUM(mbps) OVER(), 0) AS mbps_perc,
       RANK() OVER(ORDER BY mbps DESC) AS mbps_rank
  FROM rsrcmgrmetric
)
SELECT r.cpus,
       r.cpus_perc,
       r.cpus_rank,
       r.space_gb,
       r.space_perc,
       r.space_rank,
       r.iops,
       r.iops_perc,
       r.iops_rank,
       r.mbps,
       r.mbps_perc,
       r.mbps_rank,
       r.pdb_name,
       r.con_id
  FROM rsrcmgrmetric_ext r
 WHERE (r.cpus_perc > 1 OR r.space_perc > 1 OR r.iops_perc > 1 OR r.mbps_perc > 1) 
   AND (r.cpus > 0.1 OR r.space_gb > 0.1 OR r.iops > 0.001 OR r.mbps > 0.001)
  --  AND r.cpus > 0.1
  --  AND r.space_gb > 0.1
  --  AND r.iops > 0.001
  --  AND r.mbps > 0.001
ORDER BY
      r.cpus_perc DESC,
      r.space_perc DESC,
      r.iops_perc DESC,
      r.mbps_perc DESC
/
--
CLEAR BREAK COMPUTE;
--
COL pdb_name FOR A30 HEA '.|.|PDB Name' PRI;
COL con_id FOR 990 HEA 'CON|ID' PRI;
COL running_sessions_limit FOR 9,990.000 HEA 'Running|Sessions|Limit' PRI;
COL avg_running_sessions FOR 9,990.000 HEA 'Average|Running|Sessions' PRI;
COL avg_waiting_sessions FOR 9,990.000 HEA 'Average|Waiting|Sessions' PRI;
COL available_headroom_sessions FOR 9,990.000 HEA 'Available|Headroom|Sessions' PRI;
-- COL sessions FOR A9 HEA 'Sessions|Parameter' PRI;
COL sessions FOR 99,990 HEA 'Sessions|Parameter' PRI;
COL total_size_gb FOR 999,990.000 HEA 'Disk Space|Size (GBs)' PRI;
COL kiev FOR 9990 HEA 'Kiev|PDB' PRI;
COL wf FOR 990 HEA 'WF|PDB' PRI;
COL cpus FOR 9,990.000 HEA 'CPUs' PRI;
COL iops FOR 999,990.000 HEA 'IOPS' PRI;
COL mbps FOR 999,990.000 HEA 'MBPS' PRI;
COL creation_time FOR A19 HEA 'Creation Time' PRI;
COL open_time FOR A19 HEA 'Open Time' PRI;
COL open_mode FOR A10 HEA 'Open Mode' PRI;
--
BREAK ON REPORT;
COMPUTE COUNT OF kiev wf con_id ON REPORT;
COMPUTE SUM OF running_sessions_limit avg_running_sessions avg_waiting_sessions sessions available_headroom_sessions sessions cpus iops mbps total_size_gb ON REPORT;
--
PRO
PRO ALL PDBs
PRO ~~~~~~~~
WITH
c AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, con_uid, name AS pdb_name, CASE restricted WHEN 'YES' THEN 'RESTRICTED' ELSE open_mode END AS open_mode, CAST(open_time AS DATE) AS open_time, total_size / POWER(10, 9) AS total_size_gb, creation_time -- creation_time does not exist on 12.1
  FROM v$containers
 WHERE 1 = 1
   AND con_id > 2
   AND ROWNUM >= 1 /* MATERIALIZE */
),
r AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, MAX(running_sessions_limit) AS running_sessions_limit, SUM(avg_running_sessions) AS avg_running_sessions, SUM(avg_waiting_sessions) AS avg_waiting_sessions, 
       GREATEST(MAX(running_sessions_limit) - SUM(avg_running_sessions), 0) AS available_headroom_sessions,
       (SUM(cpu_consumed_time) / 1000) / (MAX(intsize_csec) / 100) AS cpus,
       SUM(io_requests) / (MAX(intsize_csec) / 100) AS iops,
       SUM(io_megabytes) / (MAX(intsize_csec) / 100) AS mbps,
       ROW_NUMBER() OVER (PARTITION BY con_id ORDER BY SUM(avg_running_sessions) DESC NULLS LAST) AS rn
  FROM v$rsrcmgrmetric
 WHERE intsize_csec > 0
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       con_id
),
-- k AS (
-- SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
--        con_id
--   FROM cdb_tables
--  WHERE table_name = 'KIEVDATASTOREMETADATA' 
--    AND ROWNUM >= 1 /* MATERIALIZE */
--  GROUP BY
--        con_id
-- ),
-- for better performance:
k AS (
SELECT DISTINCT con_id
  FROM CONTAINERS(obj$)
 WHERE name = 'KIEVDATASTOREMETADATA' 
   AND namespace = 1
   AND type# = 2
   AND status = 1
),
-- w AS (
-- SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
--        con_id
--   FROM cdb_tables
--  WHERE table_name = 'WORKFLOWINSTANCES' 
--    AND ROWNUM >= 1 /* MATERIALIZE */
--  GROUP BY
--        con_id
-- ),
-- for better performance:
w AS (
SELECT DISTINCT con_id
  FROM CONTAINERS(obj$)
 WHERE name = 'WORKFLOWINSTANCES' 
   AND namespace = 1
   AND type# = 2
   AND status = 1
),
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, MAX(TO_NUMBER(value)) AS value
  FROM v$system_parameter
 WHERE name = 'sessions'
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       con_id
),
p AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       --pdb_uid, MAX(TO_NUMBER(value$)) AS value
       pdb_uid, SUBSTR(MAX(value$), 1, INSTR(MAX(value$)||',', ',') - 1) AS value
  FROM sys.pdb_spfile$
 WHERE pdb_uid > 1
   AND BITAND(NVL(spare2, 0), 1) = 0 -- or: and spare2=0 (as per wilko.edens@gmail.com)
   AND LOWER(name) = 'sessions'
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       pdb_uid
)
SELECT /*+ ORDERED */
       c.pdb_name, c.con_id, 
       r.running_sessions_limit, 
       r.avg_running_sessions, r.available_headroom_sessions, r.avg_waiting_sessions,  
      --  COALESCE(s.value, p.value) AS sessions,
      --  LPAD(COALESCE(TO_CHAR(s.value), p.value), 9, ' ') AS sessions,
       COALESCE(s.value, TO_NUMBER(REGEXP_REPLACE(p.value, '[^0-9]', ''))) AS sessions,
       r.cpus, c.total_size_gb, r.iops, r.mbps, 
       CASE WHEN k.con_id IS NOT NULL THEN 1 END AS kiev, 
       CASE WHEN w.con_id IS NOT NULL THEN 1 END AS wf, 
      --  '|' AS "|",
      --  c.creation_time, c.open_time, 
       c.open_mode
  FROM c, r, k, w, s, p
 WHERE r.con_id(+) = c.con_id
   --AND r.rn(+) = 1 -- expecting only one row anyways!
   AND k.con_id(+) = c.con_id
   AND w.con_id(+) = c.con_id
   AND s.con_id(+) = c.con_id
   AND p.pdb_uid(+) = c.con_uid
 ORDER BY
       c.pdb_name
/
PRO
PRO Running Sessions Limit: Resource Manager Utilization Limit (CPU cap after which throttling stars.)
PRO Average Running Sessions: AAS on CPU.
PRO Available Headroom Sessions: Potential AAS slots available for sessions on CPU.
PRO Average Waiting Sessions: AAS wating on Scheduler (Resource Manager throttling.)
--
PRO
PRO 1. Enter PDB Name: [{&&cs_con_name.}|PDB Name]
DEF pdb_name = '&1.';
UNDEF 1 2 3 4 5 6 7 8 9 10 11 12;
SELECT COALESCE(TRIM('&&pdb_name.'), '&&cs_con_name.') AS cs_con_name FROM DUAL
/
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO Connected to: &cs_con_name.
PRO
--
CLEAR BREAK COLUMNS COMPUTE;
