-- cs_latency_hist_internal_1: used by cs_latency_hist.sql and lah.sql
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
--
DEF cs_small_format = 'HH24:MI:SS';
--
COL cs_dbid NEW_V cs_dbid NOPRI;
COL cs_instance_number NEW_V cs_instance_number NOPRI;
SELECT TRIM(TO_CHAR(d.dbid)) AS cs_dbid, TRIM(TO_CHAR(i.instance_number)) AS cs_instance_number
  FROM v$database d, v$instance i
/
--
@@cs_internal/cs_last_snap.sql
--
COL t_1_snap_id NEW_V t_1_snap_id NOPRI;
COL t_1_snap_begin NEW_V t_1_snap_begin NOPRI;
COL t_1_snap_end NEW_V t_1_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_1_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_1_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_1_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_0_snap_begin NEW_V t_0_snap_begin NOPRI;
COL t_0_snap_end NEW_V t_0_snap_end NOPRI;
SELECT '&&t_1_snap_end.' AS t_0_snap_begin,
       TO_CHAR(SYSDATE, '&&cs_small_format.') AS t_0_snap_end
  FROM DUAL
/
--
COL t_2_snap_id NEW_V t_2_snap_id NOPRI;
COL t_2_snap_begin NEW_V t_2_snap_begin NOPRI;
COL t_2_snap_end NEW_V t_2_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_2_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_2_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_2_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_1_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_3_snap_id NEW_V t_3_snap_id NOPRI;
COL t_3_snap_begin NEW_V t_3_snap_begin NOPRI;
COL t_3_snap_end NEW_V t_3_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_3_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_3_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_3_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_2_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_4_snap_id NEW_V t_4_snap_id NOPRI;
COL t_4_snap_begin NEW_V t_4_snap_begin NOPRI;
COL t_4_snap_end NEW_V t_4_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_4_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_4_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_4_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_3_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_5_snap_id NEW_V t_5_snap_id NOPRI;
COL t_5_snap_begin NEW_V t_5_snap_begin NOPRI;
COL t_5_snap_end NEW_V t_5_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_5_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_5_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_5_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_4_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_6_snap_id NEW_V t_6_snap_id NOPRI;
COL t_6_snap_begin NEW_V t_6_snap_begin NOPRI;
COL t_6_snap_end NEW_V t_6_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_6_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_6_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_6_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_5_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_7_snap_id NEW_V t_7_snap_id NOPRI;
COL t_7_snap_begin NEW_V t_7_snap_begin NOPRI;
COL t_7_snap_end NEW_V t_7_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_7_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_7_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_7_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_6_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_8_snap_id NEW_V t_8_snap_id NOPRI;
COL t_8_snap_begin NEW_V t_8_snap_begin NOPRI;
COL t_8_snap_end NEW_V t_8_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_8_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_8_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_8_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_7_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
COL t_9_snap_id NEW_V t_9_snap_id NOPRI;
COL t_9_snap_begin NEW_V t_9_snap_begin NOPRI;
COL t_9_snap_end NEW_V t_9_snap_end NOPRI;
SELECT TRIM(TO_CHAR(snap_id)) AS t_9_snap_id,
       TRIM(TO_CHAR(begin_interval_time, '&&cs_small_format.')) AS t_9_snap_begin,
       TRIM(TO_CHAR(end_interval_time, '&&cs_small_format.')) AS t_9_snap_end
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id < TO_NUMBER('&&t_8_snap_id.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
