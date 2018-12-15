-- IOD_REPEATING_KIEV_BUCKETS_RESET (daily at 4PM UTC) KIEV
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Must execute on PRIMARY ***');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET HEA OFF;
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
SPO /tmp/StatsModFrequency.sql;
SELECT 'ALTER SESSION SET CONTAINER = '||c.name||';'||CHR(10)||
       'SELECT BUCKETID, NAME, '||t1.column_name||', '||t2.column_name||' FROM '||t1.owner||'.'||t1.table_name||' ORDER BY BUCKETID;'||CHR(10)||
       'UPDATE '||t1.owner||'.'||t1.table_name||' SET '||t1.column_name||' = -1 WHERE NVL('||t1.column_name||', 0) <> -1;'||CHR(10)||
       'UPDATE '||t2.owner||'.'||t2.table_name||' SET '||t2.column_name||' = 5400 WHERE NVL('||t2.column_name||', 0) > 5400;'||CHR(10)||
       'SELECT BUCKETID, NAME, '||t1.column_name||', '||t2.column_name||' FROM '||t1.owner||'.'||t1.table_name||' ORDER BY BUCKETID;'||CHR(10)||
       'COMMIT;'
  FROM cdb_tab_columns t1,
       cdb_tab_columns t2,
       v$containers c
 WHERE t1.table_name = 'KIEVBUCKETS'
   AND t1.column_name = 'STATSMODFREQUENCY'
   AND t2.con_id = t1.con_id
   AND t2.owner = t1.owner
   AND t2.table_name = t1.table_name
   AND t2.column_name = 'MAXGARBAGEAGE'
   AND c.con_id = t1.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name,
       t1.owner
/
SPO OFF;
SET HEA ON FEED ON ECHO ON VER ON TI ON TIMI ON;
SPO /tmp/StatsModFrequency.txt;
@/tmp/StatsModFrequency.sql;
SPO OFF;
PRO LOG: /tmp/StatsModFrequency.txt;
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
WHENEVER SQLERROR CONTINUE;
