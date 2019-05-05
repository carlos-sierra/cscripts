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
   --AND TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') BETWEEN begin_interval_time AND end_interval_time
   AND CAST(begin_interval_time AS DATE) <= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND CAST(end_interval_time AS DATE) > TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
/
SELECT TO_CHAR(snap_id) cs_snap_id_to 
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   --AND TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.') BETWEEN begin_interval_time AND end_interval_time
   AND CAST(begin_interval_time AS DATE) < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND CAST(end_interval_time AS DATE) >= TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
/
SELECT NVL('&&cs_snap_id_from.', TO_CHAR(MIN(snap_id))) cs_snap_id_from,
       NVL('&&cs_snap_id_to.', TO_CHAR(MAX(snap_id))) cs_snap_id_to 
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
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
SELECT (TO_DATE('&&cs_end_date_to.', '&&cs_datetime_full_format.') - TO_DATE('&&cs_begin_date_from.', '&&cs_datetime_full_format.')) * 24 * 3600 cs_begin_end_seconds FROM DUAL
/
--


