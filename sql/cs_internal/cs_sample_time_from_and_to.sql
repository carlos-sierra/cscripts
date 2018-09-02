--
PRO
COL cs_time_from_default NEW_V cs_time_from_default NOPRI;
COL cs_time_to_default NEW_V cs_time_to_default NOPRI;
SELECT TO_CHAR(SYSDATE-(&&cs_hours_range_default./24),'&&cs_datetime_full_format.') cs_time_from_default, TO_CHAR(SYSDATE,'&&cs_datetime_full_format.') cs_time_to_default FROM DUAL
/
--
SELECT snap_id, 
       TO_CHAR(CAST(begin_interval_time AS DATE), '&&cs_datetime_full_format.') begin_time, 
       TO_CHAR(CAST(end_interval_time AS DATE), '&&cs_datetime_full_format.') end_time
  FROM dba_hist_snapshot
 WHERE dbid = &&cs_dbid.
   AND instance_number = &&cs_instance_number.
   AND end_interval_time > SYSDATE - (&&cs_hours_range_default./24)
 ORDER BY
       snap_id
/
--
PRO
PRO Current time: &&cs_date_time.
PRO
PRO 1. Enter time FROM (default &&cs_time_from_default. i.e.: &&cs_hours_range_default.h ago):
COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
SELECT NVL('&1.','&&cs_time_from_default.') cs_sample_time_from FROM DUAL
/
PRO
PRO 2. Enter time TO (default &&cs_time_to_default. i.e.: now):
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT NVL('&2.','&&cs_time_to_default.') cs_sample_time_to FROM DUAL
/
--
