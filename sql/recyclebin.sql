SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET FEED ON;

COL segment_name FOR A80;
COL size_mbs FOR 999,990.000;

BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF size_mbs ON REPORT;

SELECT rb.owner||'.'||rb.original_name segment_name,
       rb.createtime,
       rb.droptime,
       ROUND(rb.space * ts.block_size / POWER(2,20), 3) size_mbs
       --rb.object_name,
       --rb.operation,
       --rb.type,
       --rb.ts_name,
  FROM dba_recyclebin rb,
       dba_tablespaces ts
 WHERE ts.tablespace_name = rb.ts_name
 ORDER BY
       rb.owner||'.'||rb.original_name
/

SELECT COUNT(*)
  FROM dba_segments
 WHERE segment_name LIKE 'BIN$%'
/

CLEAR BREAK COMPUTE;

