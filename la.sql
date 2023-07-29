DEF cs_top_latency = '20';
DEF cs_top_load = '10';
DEF cs_ms_threshold_latency = '0.05';
DEF cs_aas_threshold_latency = '0.005';
DEF cs_aas_threshold_load = '0.05';
DEF cs_uncommon_col = 'NOPRINT';
--
COL cs_last_snap_mins NEW_V cs_last_snap_mins NOPRI;
SELECT TRIM(TO_CHAR(ROUND((SYSDATE - CAST(end_interval_time AS DATE)) * 24 * 60, 1), '99990.0')) cs_last_snap_mins
  FROM dba_hist_snapshot
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
DEF cs_execs_delta_h = '&&cs_last_snap_mins. mins';
--
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name FROM DUAL
/
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
@@cs_internal/cs_latency_internal_cols.sql
@@cs_internal/cs_latency_internal_query_1.sql
