SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL snap_time FOR A19 HEA '1st Violation Time';
COL alert_type FOR A9 HEA 'Metric'; 
COL application_category FOR A4 HEA 'Type';
COL threshold_violation_factor FOR 999,990.0 HEA 'Violation|Factor';
COL value FOR 999,990 HEA 'Value';
COL key_value FOR A200 HEA 'Key Value' TRUNC;
COL violation_count FOR 999,990 HEA 'Violation|Count';
COL last_violation_time FOR A19 HEA 'Last Violation Time';
--
SELECT snap_time,
       sql_id,
       alert_type,
       threshold_violation_factor,
       value,
       key_value,
       violation_count,
       last_violation_time
  FROM C##IOD.alerts_hist
 ORDER BY
       snap_time,
       sql_id,
       alert_type,
       threshold_violation_factor DESC
/