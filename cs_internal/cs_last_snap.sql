
DEF cs_max_snap_id = '';
COL cs_max_snap_id NEW_V cs_max_snap_id NOPRI;
DEF cs_max_snap_end_time = '';
COL cs_max_snap_end_time NEW_V cs_max_snap_end_time NOPRI;
DEF cs_last_snap_mins = '';
COL cs_last_snap_mins NEW_V cs_last_snap_mins NOPRI;
DEF cs_last_snap_secs = '';
COL cs_last_snap_secs NEW_V cs_last_snap_secs NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) cs_max_snap_id,
       TRIM(TO_CHAR(end_interval_time, '&&cs_datetime_full_format.')) cs_max_snap_end_time,
       TRIM(TO_CHAR(ROUND((SYSDATE - CAST(end_interval_time AS DATE)) * 24 * 60, 1), '99990.0')) AS cs_last_snap_mins,
       TRIM(TO_CHAR(((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - end_interval_time)) + (3600 * EXTRACT(HOUR FROM (systimestamp - end_interval_time))) + (60 * EXTRACT(MINUTE FROM (systimestamp - end_interval_time))) + EXTRACT(SECOND FROM (systimestamp - end_interval_time)))), '9999990.000')) AS cs_last_snap_secs
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/