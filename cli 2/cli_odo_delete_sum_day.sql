SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL begin_date FOR A13 TRUNC;
COL end_date FOR A13 TRUNC;
COL rows_processed FOR 999,999,999,990;
--
BREAK ON REPORT;
COMPUTE SUM OF rows_processed ON REPORT;
--
WITH
hist AS (
 SELECT TRUNC(CAST(begin_interval_time AS DATE), 'HH24') AS begin_date,
        TRUNC(CAST(begin_interval_time AS DATE), 'HH24') + (1/24) AS end_date,
        SUM(rows_processed_delta) AS rows_processed,
        ROW_NUMBER() OVER (ORDER BY TRUNC(CAST(begin_interval_time AS DATE), 'HH24') ASC) AS rn_a,
        ROW_NUMBER() OVER (ORDER BY TRUNC(CAST(begin_interval_time AS DATE), 'HH24') DESC) AS rn_d
   FROM dba_hist_sqltext t,
        dba_hist_sqlstat m,
        dba_hist_snapshot s
  WHERE t.sql_text LIKE 'delete from APPLICATION_INVENTORY where (agent, node_resource_id) IN%'
    AND m.dbid = t.dbid
    AND m.sql_id = t.sql_id
    AND s.snap_id = m.snap_id
    AND s.dbid = m.dbid
    AND s.instance_number = m.instance_number
    --AND s.begin_interval_time > SYSDATE - 1
  GROUP BY
        TRUNC(CAST(begin_interval_time AS DATE), 'HH24')
)
SELECT begin_date,
       end_date,
       rows_processed
  FROM hist
 WHERE rn_a > 1
   AND rn_d > 1
   AND begin_date >= SYSDATE - (26/24)
  ORDER BY
        1
/

