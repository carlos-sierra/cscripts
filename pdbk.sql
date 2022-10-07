-- pdbk.sql - List KIEV PDBs, then connect into one PDB
@@set.sql
COL cs_con_name NEW_V cs_con_name NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name FROM DUAL
/
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
--
COL pdb_name FOR A30 HEA '.|.|PDB Name' PRI;
COL con_id FOR 990 HEA 'CON|ID' PRI;
COL running_sessions_limit FOR 9,990.000 HEA 'Running|Sessions|Limit' PRI;
COL avg_running_sessions FOR 9,990.000 HEA 'Average|Running|Sessions' PRI;
COL avg_waiting_sessions FOR 9,990.000 HEA 'Average|Waiting|Sessions' PRI;
COL available_headroom_sessions FOR 9,990.000 HEA 'Available|Headroom|Sessions' PRI;
COL total_size_gb FOR 999,990.0 HEA 'Disk Space|Size (GBs)' PRI;
COL kiev FOR 9990 HEA 'Kiev|PDB' PRI;
COL wf FOR 990 HEA 'WF|PDB' PRI;
COL iops FOR 9,999,990 HEA 'IOPS' PRI;
COL mbps FOR 9,999,990 HEA 'MBPS' PRI;
COL creation_time FOR A19 HEA 'Creation Time' PRI;
COL open_time FOR A19 HEA 'Open Time' PRI;
COL open_mode FOR A10 HEA 'Open Mode' PRI;
--
BREAK ON REPORT;
COMPUTE COUNT OF kiev wf con_id ON REPORT;
COMPUTE SUM OF running_sessions_limit avg_running_sessions avg_waiting_sessions available_headroom_sessions iops mbps total_size_gb ON REPORT;
--
PRO
PRO KIEV PDBs
PRO ~~~~~~~~~
WITH
c AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, name AS pdb_name, CASE restricted WHEN 'YES' THEN 'RESTRICTED' ELSE open_mode END AS open_mode, CAST(open_time AS DATE) AS open_time, total_size / POWER(10, 9) AS total_size_gb, creation_time -- creation_time does not exist on 12.1
  FROM v$containers
 WHERE 1 = 1
   --AND con_id > 2
   AND ROWNUM >= 1 /* MATERIALIZE */
),
r AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, running_sessions_limit, avg_running_sessions, avg_waiting_sessions, 
       GREATEST(running_sessions_limit - avg_running_sessions /* - avg_waiting_sessions */, 0) AS available_headroom_sessions,
       io_requests / (end_time - begin_time) / 24 / 3600 AS iops,
       io_megabytes / (end_time - begin_time) / 24 / 3600 AS mbps,
       ROW_NUMBER() OVER (PARTITION BY con_id ORDER BY avg_running_sessions DESC NULLS LAST) AS rn
  FROM v$rsrcmgrmetric
 WHERE consumer_group_name = 'OTHER_GROUPS'
   AND end_time - begin_time > 0
   AND ROWNUM >= 1 /* MATERIALIZE */
),
k AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
       con_id
  FROM cdb_tables
 WHERE table_name = 'KIEVDATASTOREMETADATA' 
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       con_id
),
w AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */
       con_id
  FROM cdb_tables
 WHERE table_name = 'WORKFLOWINSTANCES' 
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       con_id
)
SELECT c.pdb_name, c.con_id, 
       r.running_sessions_limit, 
       r.avg_running_sessions, r.available_headroom_sessions, r.avg_waiting_sessions,  
       r.iops, r.mbps, c.total_size_gb, 
       CASE WHEN k.con_id IS NOT NULL THEN 1 END AS kiev, 
       CASE WHEN w.con_id IS NOT NULL THEN 1 END AS wf, 
       '|' AS "|",
       c.creation_time, c.open_time, c.open_mode
  FROM c, r, k, w
 WHERE r.con_id(+) = c.con_id
   --AND r.rn(+) = 1 -- expecting only one row anyways!
   AND k.con_id = c.con_id
   AND w.con_id(+) = c.con_id
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
