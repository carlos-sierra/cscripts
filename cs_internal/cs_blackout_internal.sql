COL cs_blackout_times NEW_V cs_blackout_times NOPRI;
SELECT CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN 'BLACKOUT_BEGIN:'||TO_CHAR(begin_time, '&&cs_datetime_full_format.')||' BLACKOUT_END:'||TO_CHAR(end_time, '&&cs_datetime_full_format.') END AS cs_blackout_times
  FROM &&cs_stgtab_owner..blackout
/