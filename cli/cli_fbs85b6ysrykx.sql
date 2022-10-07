SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
-- COL sample_time FOR A23;
-- COL sid FOR 99999;
-- COL serial# FOR 9999999;
-- select sample_time, session_id as sid, session_serial# as serial# from DBA_HIST_ACTIVE_SESS_HISTORY where top_level_sql_id = 'fbs85b6ysrykx' order by sample_id;
COL time FOR A13;
COL min_sample_time FOR A23;
COL max_sample_time FOR A23;
COL secs FOR 99999;
SELECT TO_CHAR(sample_time, 'YYYY-MM-DD"T"HH24') AS time, MIN(sample_time) AS min_sample_time, MAX(sample_time) AS max_sample_time, (CAST(MAX(sample_time) AS DATE) - CAST(MIN(sample_time) AS DATE)) * 24 * 3600 AS secs
  FROM v$active_session_history /*DBA_HIST_ACTIVE_SESS_HISTORY*/ where top_level_sql_id = 'fbs85b6ysrykx'
GROUP BY TO_CHAR(sample_time, 'YYYY-MM-DD"T"HH24')
HAVING COUNT(*) > 1
ORDER BY 1
/