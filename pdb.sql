-- pdb.sql - List all PDBs and Connect into one PDB
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF; 
SET PAGES 1000;
CLEAR BREAK COLUMNS COMPUTE;
--
ALTER SESSION SET container = CDB$ROOT;
--
COL pdb_name FOR A30 TRUNC;
COL con_id FOR 99999;
COL sessions FOR 999,990;
COL active FOR 999.000;
COL size_gb FOR 9,990.0
COL restricted FOR A4;
COL kiev FOR 9990;
BREAK ON REPORT;
COMPUTE COUNT OF kiev con_id ON REPORT;
COMPUTE SUM OF sessions active size_gb ON REPORT;
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
c.name AS pdb_name,   
c.con_id, (SELECT NULLIF(COUNT(*), 0) FROM cdb_tables t WHERE t.con_id = c.con_id AND t.table_name = 'KIEVBUCKETS' AND ROWNUM = 1) AS kiev, 
s.sessions, r.avg_running_sessions AS active, c.total_size/POWER(10,9) AS size_gb,
'|' AS "|",
TO_CHAR(h.op_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') AS created, c.open_mode, c.restricted, TO_CHAR(c.open_time, 'YYYY-MM-DD"T"HH24:MI:SS') AS open_time
FROM v$containers c, cdb_pdb_history h, v$rsrcmgrmetric r, (SELECT con_id, COUNT(*) AS sessions FROM v$session GROUP BY con_id) s
WHERE c.con_id > 2 AND h.operation(+) = 'CREATE' AND h.con_id(+) = c.con_id AND r.con_id(+) = c.con_id AND r.consumer_group_name(+) = 'OTHER_GROUPS' AND c.con_id = s.con_id
ORDER BY c.name
/
CLEAR BREAK COMPUTE;
--
PRO
PRO 1. Enter PDB_NAME:
DEF pdb_name = '&1.';
UNDEF 1;
COL pdb_name NEW_V pdb_name FOR A30 NOPRI;
SELECT NVL('&&pdb_name.', 'CDB$ROOT') AS pdb_name FROM DUAL;
--
ALTER SESSION SET container = &pdb_name.;
--
PRO
PRO Connected to: &pdb_name.
PRO
--
UNDEF 1 2 3 4 5 6 7 8 9;
SET HEA ON LIN 80 PAGES 14 TAB ON FEED ON ECHO OFF VER ON TRIMS OFF TRIM ON TI OFF TIMI OFF LONG 80 LONGC 80 SERVEROUT OFF;
CLEAR BREAK COLUMNS COMPUTE;
--
