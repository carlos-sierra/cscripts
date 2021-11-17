SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL begin_interval_time FOR A23;
COL end_interval_time FOR A23;
COL rows_processed FOR 999,999,990;
--
BREAK ON REPORT;
COMPUTE SUM OF rows_processed ON REPORT;
--
 SELECT begin_interval_time,
        end_interval_time,
        SUM(rows_processed_delta) AS rows_processed
   FROM dba_hist_sqltext t,
        dba_hist_sqlstat m,
        dba_hist_snapshot s
  WHERE t.sql_text LIKE 'delete from APPLICATION_INVENTORY where (agent, node_resource_id) IN%'
    AND m.dbid = t.dbid
    AND m.sql_id = t.sql_id
    AND s.snap_id = m.snap_id
    AND s.dbid = m.dbid
    AND s.instance_number = m.instance_number
    AND s.begin_interval_time > SYSDATE - 1
  GROUP BY
        begin_interval_time,
        end_interval_time
  ORDER BY
        begin_interval_time,
        end_interval_time
/

