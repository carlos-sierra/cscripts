SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL cs2_owner NEW_V cs2_owner NOPRI;
COL cs2_table_name NEW_V cs2_table_name NOPRI;
SELECT owner AS cs2_owner, table_name AS cs2_table_name FROM dba_tables WHERE table_name LIKE 'KIEVGCEVENTS_PART%' ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY
/ 
--
COL min_eventtime FOR A19 TRUNC;
COL max_eventtime FOR A19 TRUNC;
COL days FOR 90.0;
--
WITH 
kiev_events AS (
SELECT eventtime, bucketname, TO_NUMBER(DBMS_LOB.substr(message, DBMS_LOB.instr(message, ' rows were deleted') - 1)) AS rows_deleted
  FROM &&cs2_owner..&&cs2_table_name. 
 WHERE gctype = 'BUCKET'
   AND bucketname IN ('futureWork','historicalAssignment','leaseDecorators','leases','stepInstances','workflowInstances','workflowInstancesIndex')
   AND DBMS_LOB.instr(message, ' rows were deleted') > 0
)
SELECT bucketname, 
       MIN(eventtime) AS min_eventtime, 
       MAX(eventtime) AS max_eventtime, 
       ROUND(CAST(MAX(eventtime) AS DATE) - CAST(MIN(eventtime) AS DATE), 1) AS days,
       SUM(rows_deleted) AS rows_deleted, 
       COUNT(*) AS executions, 
       ROUND(SUM(rows_deleted) / COUNT(*)) AS del_per_exec,
       MAX(rows_deleted) AS max_delete
  FROM kiev_events
 GROUP BY
       bucketname
 ORDER BY
       bucketname
/