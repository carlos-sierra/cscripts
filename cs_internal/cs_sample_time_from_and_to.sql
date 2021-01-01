--
PRO
COL cs_default_time_window NEW_V cs_default_time_window NOPRI;
SELECT CASE 
       WHEN TO_NUMBER('&&cs_hours_range_default.') / 24 = ROUND(TO_NUMBER('&&cs_hours_range_default.') / 24) THEN '-'||TRIM(ROUND(TO_NUMBER('&&cs_hours_range_default.') / 24))||'d'
       ELSE '-&&cs_hours_range_default.h'
       END cs_default_time_window
  FROM DUAL
/
--
PRO
COL snap_id FOR 9999999;
COL cs_time_from_default NEW_V cs_time_from_default NOPRI;
COL cs_time_to_default NEW_V cs_time_to_default NOPRI;
SELECT TO_CHAR(SYSDATE-(&&cs_hours_range_default./24),'&&cs_datetime_full_format.') cs_time_from_default, TO_CHAR(SYSDATE,'&&cs_datetime_full_format.') cs_time_to_default FROM DUAL
/
--
--SELECT snap_id, 
--       TO_CHAR(CAST(begin_interval_time AS DATE), '&&cs_datetime_full_format.') begin_time, 
--       TO_CHAR(CAST(end_interval_time AS DATE), '&&cs_datetime_full_format.') end_time
--  FROM dba_hist_snapshot
-- WHERE dbid = &&cs_dbid.
--   AND instance_number = &&cs_instance_number.
--   AND end_interval_time > SYSDATE - (&&cs_hours_range_default./24)
-- ORDER BY
--       snap_id
--/
--
PRO
PRO Current Date and Time is: &&cs_date_time.
PRO Default Time Window: "&&cs_default_time_window." (i.e. FROM="now&&cs_default_time_window." and TO="now")
PRO Time can be entered as: "now", "-Nd" (minus N days), "-Nh" (minus N hours), "-Nm" (minus N minutes), or on partial format "&&cs_datetime_display_format."
PRO
PRO 1. Enter Time FROM: [{&&cs_default_time_window.(&&cs_time_from_default.)}|-Nd|-Nh|-Nm|&&cs_datetime_display_format.]
DEF cs_entered_time_from = '&1.';
UNDEF 1;
COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
SELECT CASE 
       WHEN '&cs_entered_time_from.' IS NULL THEN '&&cs_time_from_default.'
       WHEN LOWER('&cs_entered_time_from.') LIKE '%d%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_from.'), ' '), '-'), 'd')), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_from.') LIKE '%h%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_from.'), ' '), '-'), 'h') / 24), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_from.') LIKE '%m%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_from.'), ' '), '-'), 'm') / 24 / 60), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_from.') LIKE '%now%' THEN TO_CHAR(SYSDATE, '&&cs_datetime_full_format.')
       ELSE '&cs_entered_time_from.' 
       END cs_sample_time_from 
  FROM DUAL
/
PRO
PRO 2. Enter Time TO: [{now(&&cs_time_to_default.)}|-Nd|-Nh|-Nm|&&cs_datetime_display_format.] 
DEF cs_entered_time_to = '&2.';
UNDEF 2;
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT CASE
       WHEN '&cs_entered_time_to.' IS NULL THEN '&&cs_time_to_default.'
       WHEN LOWER('&cs_entered_time_to.') LIKE '%d%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_to.'), ' '), '-'), 'd')), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_to.') LIKE '%h%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_to.'), ' '), '-'), 'h') / 24), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_to.') LIKE '%m%' THEN TO_CHAR(SYSDATE - TO_NUMBER(REPLACE(REPLACE(REPLACE(LOWER('&cs_entered_time_to.'), ' '), '-'), 'm') / 24 / 60), '&&cs_datetime_full_format.')
       WHEN LOWER('&cs_entered_time_to.') LIKE '%now%' THEN TO_CHAR(SYSDATE, '&&cs_datetime_full_format.')
       ELSE '&cs_entered_time_to.' 
       END cs_sample_time_to 
  FROM DUAL
/
--
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
WITH
max_value AS (
SELECT CASE 
       WHEN '&&cs_sample_time_to.' = '&&cs_time_to_default.' OR (SYSDATE - TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')) / (SYSDATE - TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')) < 0.1 THEN
       TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') + ((TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')) * TO_NUMBER('&&hAxis_maxValue_forecast.'))
       END AS time
  FROM DUAL
)
SELECT CASE 
       WHEN v.time IS NOT NULL THEN
       'maxValue: new Date('||
       TO_CHAR(v.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(v.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(v.time, 'DD')|| /* day */
       ','||TO_CHAR(v.time, 'HH24')|| /* hour */
       ','||TO_CHAR(v.time, 'MI')|| /* minute */
       ','||TO_CHAR(v.time, 'SS')|| /* second */
       '), '
       END AS cs_hAxis_maxValue
  FROM max_value v
/
