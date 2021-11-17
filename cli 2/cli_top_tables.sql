SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
DEF cs_oracle_maint = 'N';
--
COL gb FOR 999,990.000 HEA 'GB';
COL owner FOR A30 TRUNC;
COL segment_name FOR A30 TRUNC;
COL tablespace_name FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF gb ON REPORT;
--
PRO
PRO TOP TABLES
PRO ~~~~~~~~~~
SELECT '|' AS "|",
       SUM(s.bytes)/1e9 AS gb,
       s.owner,
       s.segment_name,
       s.segment_type,
       s.tablespace_name,
       c.name AS pdb_name
  FROM cdb_segments s,
       cdb_users u,
       v$containers c
 WHERE s.segment_type LIKE 'TABLE%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND ('&&cs_oracle_maint.' = 'Y' OR u.oracle_maintained = 'N')
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
 GROUP BY
       s.owner,
       s.segment_name,
       s.segment_type,
       s.tablespace_name,
       c.name
HAVING SUM(s.bytes)/1e9 > 0.001
 ORDER BY
       2 DESC
 FETCH FIRST 30 ROWS ONLY
/
--
CLEAR BREAK COMPUTE COLUMNS;
--