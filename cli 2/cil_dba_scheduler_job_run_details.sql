SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
-- COL errors FOR A30;
-- COL status FOR A10;
-- SELECT log_date, status, error#, req_start_date, actual_start_date, run_duration, errors
--   FROM dba_scheduler_job_run_details
--  WHERE JOB_NAME = 'IOD_SESS_MONITOR'
--  AND log_date BETWEEN TO_DATE('2021-04-29T20:30') AND TO_DATE('2021-04-29T21:00')
--  ORDER BY log_date
-- /
--
WITH
run_details AS (
SELECT CAST(LAG(log_date) OVER(PARTITION BY job_name ORDER BY log_date) AS DATE) AS gap_begin,
       CAST(log_date AS DATE) AS gap_end,
       (CAST(log_date AS DATE) - CAST(LAG(log_date) OVER(PARTITION BY job_name ORDER BY log_date) AS DATE)) * 24 * 3600 AS seconds
  FROM dba_scheduler_job_run_details
WHERE JOB_NAME = 'IOD_SESS_MONITOR'
 --AND log_date BETWEEN TO_DATE('2021-04-29T20:30') AND TO_DATE('2021-04-29T21:00')
)
SELECT * FROM run_details WHERE seconds > 60
ORDER BY 1 NULLS FIRST
/
