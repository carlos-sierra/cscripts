SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET TIMI ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
WITH
last_awr AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ MAX(end_interval_time) AS end_interval_time, ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds FROM dba_hist_snapshot WHERE end_interval_time < SYSTIMESTAMP 
),
sqlstats AS ( -- expecting less than 10 seconds and less than 500 rows per execution
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       SYSTIMESTAMP AS snap_timestamp,
       w.end_interval_time AS last_awr_end_timestamp,
       w.age_seconds AS last_awr_age_seconds,
       s.*
  FROM v$sqlstats s, last_awr w
 WHERE s.delta_elapsed_time > 0
   AND s.delta_elapsed_time/GREATEST(w.age_seconds,1)/1e6 >= 0.01 -- DB AAS (SQL load threshold)
   AND ROWNUM >= 1
)
SELECT /*+ GATHER_PLAN_STATISTICS MONITOR */ COUNT(*) FROM sqlstats
/
