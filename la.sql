DEF cs_top = '20';
--
COL cs_last_snap_mins NEW_V cs_last_snap_mins NOPRI;
SELECT TRIM(TO_CHAR(ROUND((SYSDATE - CAST(end_interval_time AS DATE)) * 24 * 60, 1), '99990.0')) cs_last_snap_mins
  FROM dba_hist_snapshot
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
@@cs_internal/cs_latency_internal.sql