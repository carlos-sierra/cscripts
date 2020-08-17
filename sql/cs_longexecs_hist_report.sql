SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL application_category FOR A4 HEA 'Type';
COL times_threshold FOR 999,990.0 HEA 'Violation|Factor';
COL elapsed_seconds FOR 999,990 HEA 'Elapsed|Seconds';
COL sql_exec_start FOR A19 HEA 'SQL Execution Start';
COL last_update_time FOR A19 HEA 'Last Update Time';
COL sql_plan_hash_value FOR 9999999990 HEA 'Plan|Hash Value';
COL sql_plan_line_id FOR 990 HEA 'Line|ID';
COL source FOR A6 HEA 'Source';
COL status FOR A19 HEA 'Status';
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
COL sql_text FOR A80 HEA 'SQL Text' TRUNC;
COL elapsed_seconds_threshold FOR 999,990 HEA 'Elapsed|Seconds|Threshold';
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
--
BREAK ON application_category SKIP PAGE DUPL ON sql_id SKIP 1 DUPL;
--
WITH
longexecs AS (
SELECT application_category,
       times_threshold,
       elapsed_seconds,
       sql_exec_start,
       last_update_time,
       sql_id,
       sql_plan_hash_value,
       sql_plan_line_id,
       source,
       status,
       sid||','||serial# AS sid_serial#,
       sql_text,
       elapsed_seconds_threshold,
       username,
       pdb_name,
       MAX(times_threshold) OVER (PARTITION BY sql_id) AS max_times_threshold,
       AVG(times_threshold) OVER (PARTITION BY sql_id) AS avg_times_threshold
  FROM C##IOD.longexecs_hist_v1
)
SELECT application_category,
       sql_id,
       sql_exec_start,
       last_update_time,
       times_threshold,
       elapsed_seconds,
       sql_plan_hash_value,
       sql_plan_line_id,
       source,
       status,
       sid_serial#,
       sql_text,
       username,
       pdb_name,
       elapsed_seconds_threshold
  FROM longexecs
 ORDER BY
       CASE application_category WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 ELSE 5 END,
       (max_times_threshold + avg_times_threshold) DESC,
       sql_id,
       sql_exec_start,
       last_update_time,
       times_threshold DESC,
       elapsed_seconds DESC,
       sql_plan_hash_value,
       sql_plan_line_id,
       source
/