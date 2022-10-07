--
DEF cs_snap_id_from = '';
DEF cs_snap_id_to = '';
COL cs_snap_id_from NEW_V cs_snap_id_from NOPRI;
COL cs_snap_id_to NEW_V cs_snap_id_to NOPRI;
--
SELECT TO_CHAR(snap_id) cs_snap_id_from 
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND CAST(begin_interval_time AS DATE) <= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND CAST(end_interval_time AS DATE) > TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND begin_interval_time <> startup_time -- filter out bogus data
   AND end_interval_time <> startup_time -- filter out bogus data
/
SELECT TO_CHAR(snap_id) cs_snap_id_to 
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND CAST(begin_interval_time AS DATE) < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND CAST(end_interval_time AS DATE) >= TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND begin_interval_time <> startup_time -- filter out bogus data
   AND end_interval_time <> startup_time -- filter out bogus data
/
SELECT COALESCE('&&cs_snap_id_from.', TO_CHAR(MIN(snap_id))) AS cs_snap_id_from,
       COALESCE('&&cs_snap_id_to.', TO_CHAR(MAX(snap_id))) AS cs_snap_id_to 
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND begin_interval_time <> startup_time -- filter out bogus data
   AND end_interval_time <> startup_time -- filter out bogus data
/
--
DEF cs_begin_date_from = '&&cs_sample_time_from.';
DEF cs_end_date_to = '&&cs_sample_time_to.';
COL cs_begin_date_from NEW_V cs_begin_date_from NOPRI;
COL cs_end_date_to NEW_V cs_end_date_to NOPRI;
--
SELECT TO_CHAR(begin_interval_time, '&&cs_datetime_full_format.') cs_begin_date_from
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id = TO_NUMBER('&&cs_snap_id_from.')
/
SELECT TO_CHAR(end_interval_time, '&&cs_datetime_full_format.') cs_end_date_to
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id = TO_NUMBER('&&cs_snap_id_to.')
/
--
COL cs_begin_end_seconds NEW_V cs_begin_end_seconds NOPRI;
SELECT TRIM(TO_CHAR(ROUND((TO_DATE('&&cs_end_date_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_begin_date_from.', '&&cs_datetime_full_format.')) * 24 * 3600))) AS cs_begin_end_seconds FROM DUAL
/
--
COL cs_from_to_seconds NEW_V cs_from_to_seconds NOPRI;
SELECT TRIM(TO_CHAR(ROUND((TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')) * 24 * 3600))) AS cs_from_to_seconds FROM DUAL
/
--
COL cs_snap_id_max NEW_V cs_snap_id_max NOPRI;
COL cs_end_interval_time_max NEW_V cs_end_interval_time_max NOPRI;
SELECT TO_CHAR(snap_id) AS cs_snap_id_max, TO_CHAR(end_interval_time, '&&cs_timestamp_full_format.') AS cs_end_interval_time_max
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND end_interval_time < SYSTIMESTAMP
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROWS ONLY
/
--
