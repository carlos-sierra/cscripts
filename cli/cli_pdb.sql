SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 1000;
SET TIMI ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET container = CDB$ROOT;
CLEAR BREAK COLUMNS COMPUTE;
--
COL pdb_name FOR A30 HEA 'PDB Name' PRI;
COL con_id FOR 990 HEA 'CON|ID' PRI;
COL running_sessions_limit FOR 999,990.0 HEA 'Running|Sessions|Limit' PRI;
COL avg_running_sessions FOR 999,990.0 HEA 'Average|Running|Sessions' PRI;
COL avg_waiting_sessions FOR 999,990.0 HEA 'Average|Waiting|Sessions' PRI;
COL available_headroom_sessions FOR 999,990.0 HEA 'Available|Headroom|Sessions' PRI;
COL total_size_gb FOR 999,990.0 HEA 'Size GBs' PRI;
COL kiev FOR 9990 HEA 'Kiev' PRI;
COL iops FOR 9,999,990 HEA 'IOPS' PRI;
COL mbps FOR 9,999,990 HEA 'MBPS' PRI;
COL creation_time FOR A19 HEA 'Creation Time' PRI;
COL open_time FOR A19 HEA 'Open Time' PRI;
COL open_mode FOR A10 HEA 'Open Mode' PRI;
--
BREAK ON REPORT;
COMPUTE COUNT OF kiev con_id ON REPORT;
COMPUTE SUM OF running_sessions_limit avg_running_sessions available_headroom_sessions total_size_gb ON REPORT;
--
WITH
c AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, name AS pdb_name, CASE restricted WHEN 'YES' THEN 'RESTRICTED' ELSE open_mode END AS open_mode, CAST(open_time AS DATE) AS open_time, total_size / POWER(10, 9) AS total_size_gb, creation_time
  FROM v$containers
 WHERE con_id > 2
   AND ROWNUM >= 1 /* MATERIALIZE */
),
r AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, running_sessions_limit, avg_running_sessions, avg_waiting_sessions, 
       GREATEST(running_sessions_limit - avg_running_sessions - avg_waiting_sessions, 0) AS available_headroom_sessions,
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
)
SELECT c.pdb_name, c.con_id, r.running_sessions_limit, r.avg_running_sessions, r.available_headroom_sessions, c.total_size_gb, 
       CASE WHEN k.con_id IS NOT NULL THEN 1 END AS kiev, '|' AS "|",
       c.creation_time, c.open_time, c.open_mode
  FROM c, r, k
 WHERE r.con_id(+) = c.con_id
   AND r.rn(+) = 1 -- expecting only one row anyways!
   AND k.con_id(+) = c.con_id
 ORDER BY
       c.pdb_name
/
--
CLEAR BREAK COMPUTE;
