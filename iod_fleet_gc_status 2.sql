-- iod_fleet_gc_status.sql
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
--
COL version NEW_V version;
SELECT TO_CHAR(version, 'YYYY-MM-DD') AS version, COUNT(*) FROM c##iod.gc_status GROUP BY version ORDER BY version
/
PRO
PRO 1. Enter version:
DEF cs_version = '&1.';
UNDEF 1;
--
SET HEA ON PAGES 100;
--
COL perc FOR 990.0;
BREAK ON REPORT;
COMP SUM OF tables num_rows blocks perc ON REPORT;
--
SPO /tmp/gc_status.txt
--
SELECT gc_status,
       SUM(tables) AS tables,
       SUM(num_rows) AS num_rows,
       SUM(blocks) AS blocks,
       100 * SUM(blocks) / SUM(SUM(blocks)) OVER() AS perc
  FROM c##iod.gc_status
 WHERE version = TO_DATE('&&cs_version.', 'YYYY-MM-DD')
 GROUP BY
       gc_status
 ORDER BY
       4 DESC
/
--
SELECT COUNT(DISTINCT host_name) AS cdbs,
       COUNT(DISTINCT host_name||pdb_name) AS pdbs
  FROM c##iod.gc_status
 WHERE version = TO_DATE('&&cs_version.', 'YYYY-MM-DD')
/
--
SPO OFF;
