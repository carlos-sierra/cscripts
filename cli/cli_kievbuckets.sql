SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
BREAK ON pdb_name SKIP 1 DUPL;
SELECT pdb_name, owner, num_rows, last_analyzed
FROM (
SELECT c.name AS pdb_name, t.owner, t.num_rows, t.last_analyzed, COUNT(*) OVER (PARTITION BY c.name) AS cnt
FROM cdb_tables t, v$containers c
WHERE t.table_name = 'KIEVBUCKETS'
AND c.con_id = t.con_id
) WHERE cnt > 1
ORDER BY pdb_name, owner
/
