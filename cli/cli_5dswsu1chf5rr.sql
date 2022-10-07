SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL et_ms_per_exec FOR 99,999,990.000 HEA 'Latency(ms) Per Exec';
COL et_aas FOR 9,990.000 HEA 'DB Load(aas)';
COL execs_per_sec FOR 99,990.000 HEA 'Execs Per Sec';
COL parses_per_sec FOR 99,990.000 HEA 'Parses Per Sec';
COL avg_hard_parse_time FOR 9,999,990 HEA 'Avg Hard Parse Time(us)';
SELECT '|' AS "|",
       s.delta_elapsed_time/GREATEST(w.age_seconds,1)/1e6 AS et_aas,
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_execution_count/GREATEST(w.age_seconds,1) AS execs_per_sec,
       s.delta_parse_calls/GREATEST(w.age_seconds,1) AS parses_per_sec,
       s.avg_hard_parse_time
  FROM v$sqlstats s, 
       (SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ 
               ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds 
          FROM dba_hist_snapshot 
         WHERE end_interval_time < SYSTIMESTAMP) w
 WHERE s.sql_id = '5dswsu1chf5rr'
/
