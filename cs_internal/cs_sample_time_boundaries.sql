COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT TO_CHAR(SYSDATE - &&cs_sqlstat_days., '&&cs_datetime_full_format.') AS cs_sample_time_from, TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_sample_time_to FROM DUAL
/