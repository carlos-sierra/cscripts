COL timestamp FOR A19 HEA 'Timestamp';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
--
PRO
PRO PLANS IN AWR (dba_hist_sql_plan)
PRO ~~~~~~~~~~~~
SELECT TO_CHAR(timestamp, '&&cs_datetime_full_format.') timestamp,
       plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&cs_sql_id.'
   AND ('&&cs_plan_hash_value.' IS NULL OR plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.'))
   AND id = 0
 ORDER BY
       timestamp
/
