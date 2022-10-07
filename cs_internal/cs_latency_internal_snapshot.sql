-- sets the start point of search space
COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
SELECT TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_sample_time_from FROM DUAL
/
--
VAR cs_time_cs_begin NUMBER;
EXEC :cs_time_cs_begin := DBMS_UTILITY.get_time;
PRO Begin Snapshot... please wait...
EXEC &&cs_tools_schema..iod_sqlstats.snapshot_sqlstats(p_snap_type => '&&cs_snap_type.', p_sid => TO_NUMBER('&&cs_sid.'));
PRO Sleeping &&cs_snapshot_seconds. seconds... please wait...
EXEC DBMS_LOCK.sleep(seconds => &&cs_snapshot_seconds. - LEAST(TRUNC((DBMS_UTILITY.get_time - :cs_time_cs_begin)/100), &&cs_snapshot_seconds.));
PRO End Snapshot... please wait...
EXEC &&cs_tools_schema..iod_sqlstats.snapshot_sqlstats(p_snap_type => '&&cs_snap_type.', p_sid => TO_NUMBER('&&cs_sid.'));
--
-- sets the end point of search space
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_sample_time_to FROM DUAL
/