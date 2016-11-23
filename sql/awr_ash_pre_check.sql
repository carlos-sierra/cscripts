----------------------------------------------------------------------------------------
--
-- File name:   awr_ash_pre_check.sql
--
-- Purpose:     Pre-check state of Active Session History (ASH) state on Automatic
--              Workload Repository (AWR) before executing eDB360
--
-- Warning:     Execute only if licensed on the Oracle Diagnostics Pack
--
-- Author:      Carlos Sierra
--
-- Version:     2016/11/20
--
-- Usage:       This script validates state of ASH on AWR 
--
-- Example:     @awr_ash_pre_check.sql
--
-- Notes:       Developed and tested on 11.2.0.3
--             
---------------------------------------------------------------------------------------
--
SET TERM ON;
SET HEA ON; 
SET LIN 32767; 
SET NEWP NONE; 
SET PAGES 1000; 
SET LONG 32000; 
SET LONGC 2000; 
SET WRA ON; 
SET TRIMS ON; 
SET TRIM ON; 
SET TI OFF;
SET TIMI OFF;
SET ARRAY 1000; 
SET NUM 20; 
SET SQLBL ON; 
SET BLO .; 
SET RECSEP OFF;
SET ECHO OFF;
SET VER OFF;
SET FEED OFF;

DEF ash_fts_on_edb360 = '250';
DEF ash_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

-- get block_size
COL ash_database_block_size NEW_V ash_database_block_size NOPRI;

SELECT TRIM(TO_NUMBER(value)) ash_database_block_size FROM v$system_parameter2 WHERE name = 'db_block_size';

-- get number of instances
COL number_of_instances NEW_V number_of_instances NOPRI;
SELECT COUNT(*) number_of_instances FROM gv$instance;

COL my_spool_filename NEW_V my_spool_filename NOPRI;
SELECT 'awr_ash_pre_check_'||name||'.txt' my_spool_filename FROM v$database;
SPO &&my_spool_filename.

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO Pre-check ASH on AWR                                      awr_ash_pre_check.sql
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Control
PRO ~~~~~~~
PRO

COL db_name FOR A9;

SELECT dbid, name db_name, db_unique_name, version, &&ash_database_block_size. db_block_size, &&number_of_instances. instances FROM v$database, v$instance
/

COL snap_interval FOR A17;
COL retention FOR A17;
COL last_purge_time NEW_V last_purge_time;
COL days_since_purge NEW_V days_since_purge FOR A16;

PRO
SELECT dbid, snap_interval, retention, 
       TO_CHAR(most_recent_snap_time, '&&ash_date_format.') last_snap_time, 
       TO_CHAR(most_recent_purge_time, '&&ash_date_format.') last_purge_time,
       TO_CHAR(ROUND(SYSDATE - CAST(most_recent_purge_time AS DATE),1)) days_since_purge
  FROM sys.wrm$_wr_control
/

PRO
SELECT dbid, baseline_id, baseline_type, start_snap_id, TO_CHAR(CAST(start_snap_time AS DATE), '&&ash_date_format.') start_snap_date, end_snap_id, TO_CHAR(CAST(end_snap_time AS DATE), '&&ash_date_format.') end_snap_date, moving_window_size
  FROM dba_hist_baseline
/

PRO
SELECT baseline_id, TO_CHAR(creation_time, '&&ash_date_format.') creation_time, baseline_name
  FROM dba_hist_baseline
/

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO CBO Statistics
PRO ~~~~~~~~~~~~~~
PRO

COL locked FOR A6;
COL stale FOR A5;

SELECT table_name, blocks, num_rows, TO_CHAR(last_analyzed, '&&ash_date_format.') last_analyzed, stattype_locked locked, stale_stats stale
  FROM dba_tab_statistics
 WHERE owner = 'SYS'
   AND table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND partition_name IS NULL
/

PRO
SELECT partition_name, blocks, num_rows, TO_CHAR(last_analyzed, '&&ash_date_format.') last_analyzed, stattype_locked locked, stale_stats stale
  FROM dba_tab_statistics
 WHERE owner = 'SYS'
   AND table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND partition_name IS NOT NULL
 ORDER BY
       partition_name
/

COL ash_last_analyzed NEW_V ash_last_analyzed FOR A19;
COL ash_cbo_stats_age_days NEW_V ash_cbo_stats_age_days FOR A22;

PRO
SELECT TO_CHAR(MAX(last_analyzed), '&&ash_date_format.') ash_last_analyzed, TO_CHAR(ROUND(SYSDATE - MAX(last_analyzed),1)) ash_cbo_stats_age_days
  FROM dba_tab_statistics
 WHERE owner = 'SYS'
   AND table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
/

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO CBO Table Modifications
PRO ~~~~~~~~~~~~~~~~~~~~~~~
PRO

COL table_or_partition FOR A30;
COL percent_of_inserts NEW_V percent_of_inserts FOR A7 HEA '% INS';

SELECT CASE WHEN m.partition_name IS NULL THEN 'T' ELSE 'P' END t,
       CASE WHEN m.partition_name IS NULL THEN m.table_name ELSE m.partition_name END table_or_partition,
       TO_CHAR(CASE WHEN s.num_rows > 0 THEN ROUND(100 * m.inserts / s.num_rows, 1) END) percent_of_inserts,
       m.inserts, s.num_rows, 
       TO_CHAR(m.timestamp, '&&ash_date_format.') time_stamp
  FROM dba_tab_modifications m,
       dba_tab_statistics s
 WHERE m.table_owner = 'SYS'
   AND m.table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND m.subpartition_name IS NULL
   AND s.owner = 'SYS'
   AND s.table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND NVL(s.partition_name, '-666') = NVL(m.partition_name, '-666')
   AND s.subpartition_name IS NULL
 ORDER BY
       1 DESC, 2
/

PRO
SELECT TO_CHAR(CASE WHEN SUM(s.num_rows) > 0 THEN ROUND(100 * SUM(m.inserts) / SUM(s.num_rows),1) END) percent_of_inserts,
       SUM(m.inserts) inserts, SUM(s.num_rows) num_rows
  FROM dba_tab_modifications m,
       dba_tab_statistics s
 WHERE m.table_owner = 'SYS'
   AND m.table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND m.subpartition_name IS NULL
   AND s.owner = 'SYS'
   AND s.table_name = 'WRH$_ACTIVE_SESSION_HISTORY'
   AND NVL(s.partition_name, '-666') = NVL(m.partition_name, '-666')
   AND s.subpartition_name IS NULL
/

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Table Segments
PRO ~~~~~~~~~~~~~~
PRO

COL size_gb FOR A12;
COL partition_name FOR A30;

SELECT CASE segment_type WHEN 'TABLE' THEN 'T' ELSE 'P' END t, partition_name, blocks,
       TO_CHAR(ROUND(blocks * &&ash_database_block_size. / POWER(10,9),1), '9,990.0')||' GBs' size_gb
  FROM dba_segments
 WHERE owner = 'SYS'
   AND segment_name = 'WRH$_ACTIVE_SESSION_HISTORY'
 ORDER BY
       segment_type, partition_name
/

COL all_segments FOR A30;
COL ash_size_gb NEW_V ash_size_gb FOR A12;

PRO
SELECT segment_name all_segments, SUM(blocks) blocks,
       TRIM(TO_CHAR(ROUND(SUM(blocks) * &&ash_database_block_size. / POWER(10,9),1), '9,990.0'))||' GBs' ash_size_gb
  FROM dba_segments
 WHERE owner = 'SYS'
   AND segment_name = 'WRH$_ACTIVE_SESSION_HISTORY'
 GROUP BY
       segment_name
/

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Objects
PRO ~~~~~~~
PRO

COL ash_object FOR A30;
COL last_ddl_time NEW_V last_ddl_time  FOR A19;

SELECT CASE object_type WHEN 'TABLE' THEN 'T' ELSE 'P' END t, NVL(subobject_name, object_name) ash_object, TO_CHAR(created, '&&ash_date_format.') created, TO_CHAR(last_ddl_time, '&&ash_date_format.') last_ddl_time
  FROM dba_objects
 WHERE owner = 'SYS'
   AND object_name = 'WRH$_ACTIVE_SESSION_HISTORY'
 ORDER BY
       object_type, subobject_name
/

COL last_ddl_age_days NEW_V last_ddl_age_days FOR A17;
COL seg_last_ddl_time NEW_V seg_last_ddl_time FOR A30;

PRO
SELECT TO_CHAR(MAX(last_ddl_time), '&&ash_date_format.') seg_last_ddl_time, TO_CHAR(ROUND(SYSDATE - MAX(last_ddl_time),1)) last_ddl_age_days
  FROM dba_objects
 WHERE owner = 'SYS'
   AND object_name = 'WRH$_ACTIVE_SESSION_HISTORY'
/

PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Range of Snapshots per Partition
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO please wait...
PRO

VAR ash_total_db_time_days NUMBER;
VAR ash_days_of_history NUMBER;
VAR ash_med_sample_date VARCHAR2(30);
VAR ash_median_age_days NUMBER;
VAR ash_time_t0 NUMBER;

EXEC :ash_time_t0 := DBMS_UTILITY.get_time;

SET SERVEROUT ON;

DECLARE
  l_date_format VARCHAR2(30) := '&&ash_date_format.';
  l_query VARCHAR2(4000) := 
'SELECT dbid, COUNT(*) samples, '||CHR(10)||
'       MIN(snap_id) min_snap_id, CAST(MIN(sample_time) AS DATE) min_sample_time, '||CHR(10)||
'       MAX(snap_id) max_snap_id, CAST(MAX(sample_time) AS DATE) max_sample_time, '||CHR(10)||
'       MEDIAN(snap_id) med_snap_id, CAST(MEDIAN(sample_time) AS DATE) med_sample_time '||CHR(10)||
'  FROM sys.wrh$_active_session_history PARTITION (<PARTITION_NAME>)' ||CHR(10)||
' GROUP BY '||CHR(10)||
'       dbid '||CHR(10)||
' ORDER BY '||CHR(10)||
'       dbid';
  l_samples_count NUMBER := 0;
  l_largest_count NUMBER := 0;
  l_min_sample_date DATE;
  l_max_sample_date DATE;
  l_med_sample_date DATE;
  TYPE part_type IS RECORD (dbid NUMBER, samples NUMBER, min_snap_id NUMBER, min_sample_date DATE, max_snap_id NUMBER, max_sample_date DATE, med_snap_id NUMBER, med_sample_date DATE);
  TYPE part_list IS TABLE OF part_type;
  l_part_list part_list;
BEGIN
  FOR i IN (SELECT partition_name FROM dba_tab_partitions WHERE table_name = 'WRH$_ACTIVE_SESSION_HISTORY' ORDER BY partition_name)
  LOOP
    DBMS_OUTPUT.PUT_LINE(i.partition_name);
    EXECUTE IMMEDIATE REPLACE(l_query, '<PARTITION_NAME>', i.partition_name) BULK COLLECT INTO l_part_list;
    IF l_part_list.COUNT > 0 THEN
      FOR j IN l_part_list.FIRST .. l_part_list.LAST
      LOOP
        l_samples_count := l_samples_count + l_part_list(j).samples;
        l_min_sample_date := LEAST(NVL(l_min_sample_date, l_part_list(j).min_sample_date), l_part_list(j).min_sample_date);
        l_max_sample_date := GREATEST(NVL(l_max_sample_date, l_part_list(j).max_sample_date), l_part_list(j).max_sample_date);
        IF l_part_list(j).samples > l_largest_count THEN
          l_largest_count := l_part_list(j).samples;
          l_med_sample_date := l_part_list(j).med_sample_date;
        END IF;
        DBMS_OUTPUT.PUT_LINE(CHR(9)||'dbid:'||l_part_list(j).dbid||' samples:'||l_part_list(j).samples);
        DBMS_OUTPUT.PUT_LINE(CHR(9)||'min_snap_id:'||l_part_list(j).min_snap_id||' min_sample_date:'||TO_CHAR(l_part_list(j).min_sample_date, l_date_format));
        DBMS_OUTPUT.PUT_LINE(CHR(9)||'med_snap_id:'||l_part_list(j).med_snap_id||' med_sample_date:'||TO_CHAR(l_part_list(j).med_sample_date, l_date_format));
        DBMS_OUTPUT.PUT_LINE(CHR(9)||'max_snap_id:'||l_part_list(j).max_snap_id||' max_sample_date:'||TO_CHAR(l_part_list(j).max_sample_date, l_date_format));
        DBMS_OUTPUT.PUT_LINE('---');
      END LOOP;
    ELSE
        DBMS_OUTPUT.PUT_LINE(CHR(9)||'*** empty ***');
        DBMS_OUTPUT.PUT_LINE('---');
    END IF;
  END LOOP; 
  :ash_total_db_time_days := ROUND(l_samples_count/360/24,1);
  :ash_days_of_history := ROUND(l_max_sample_date - l_min_sample_date,1);
  :ash_med_sample_date := TO_CHAR(l_med_sample_date, l_date_format);
  :ash_median_age_days := ROUND(SYSDATE - l_med_sample_date,1);
  DBMS_OUTPUT.PUT_LINE('total_ash_samples:'||l_samples_count||' (total db_time: '||:ash_total_db_time_days||' days)');
  DBMS_OUTPUT.PUT_LINE('total_days_of_history:'||:ash_days_of_history);
  DBMS_OUTPUT.PUT_LINE('min_sample_date:'||TO_CHAR(l_min_sample_date, l_date_format));
  DBMS_OUTPUT.PUT_LINE('max_sample_date:'||TO_CHAR(l_max_sample_date, l_date_format));
  DBMS_OUTPUT.PUT_LINE('med_sample_date:'||:ash_med_sample_date||' (for largest partition)');
END;
/

SET SERVEROUT OFF;

VAR ash_time_t1 NUMBER;
EXEC :ash_time_t1 := DBMS_UTILITY.get_time;
COL ash_fts_seconds NEW_V ash_fts_seconds NOPRI;
SELECT TO_CHAR(CEIL((:ash_time_t1 - :ash_time_t0) / 100)) ash_fts_seconds FROM DUAL;
COL ash_days_of_history NEW_V ash_days_of_history NOPRI;
SELECT TO_CHAR(:ash_days_of_history) ash_days_of_history FROM DUAL;
COL ash_med_sample_date NEW_V ash_med_sample_date NOPRI;
SELECT :ash_med_sample_date ash_med_sample_date FROM DUAL;
COL ash_median_age_days NEW_V ash_median_age_days NOPRI;
SELECT TO_CHAR(:ash_median_age_days) ash_median_age_days FROM DUAL;
COL edb360_estimated_hrs NEW_V edb360_estimated_hrs NOPRI;
SELECT TO_CHAR(CEIL(&&ash_fts_on_edb360. * &&ash_fts_seconds. * &&number_of_instances. * 3 / 3600)) edb360_estimated_hrs FROM DUAL;

PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Pre-check results
PRO ~~~~~~~~~~~~~~~~~
PRO
PRO If there are outdated AWR baselines, drop them using DBMS_WORKLOAD_REPOSITORY.DROP_BASELINE.
PRO
PRO ASH stats are &&ash_cbo_stats_age_days. days old (&&ash_last_analyzed.).
PRO If older than a week then eDB360 may take long to execute (suboptimal execution plans).
PRO
PRO There are &&ash_days_of_history. days of history in ASH.
PRO If more than a month then eDB360 may take long to execute (default retention is one week, and one month is usually enough).
PRO
PRO Median age of largest ASH partition is &&ash_median_age_days. days (&&ash_med_sample_date).
PRO If older than a month then eDB360 may take long to execute (a median older than 45 days usually means purging not happening).
PRO
PRO ASH size is &&ash_size_gb.
PRO If bigger than 1 GB then eDB360 may take long to execute (eDB360 may timeout after default threshold of 24hrs). 
PRO
PRO Last DDL on ASH objects is &&last_ddl_age_days. days old (&&seg_last_ddl_time.).
PRO If older than a week then eDB360 may take long to execute (automatic partition split may not be happening).
PRO
PRO Max percent of INSERTs into an ASH segment since stats gathering is &&percent_of_inserts.%
PRO If over 50% then eDB360 may take long to execute (statistics may be locked or outdated, thus prone to suboptimal execution plans).
PRO
PRO One full scan of ASH takes &&ash_fts_seconds. seconds on this database.
PRO eDB360 performs over &&ash_fts_on_edb360. full scans on ASH per instance, and access to ASH is about 1/3 of eDB360 work load.
PRO Ballpark execution time for eDB360 is &&edb360_estimated_hrs. hour(s), assuming optimal execution plans (with representative stats).
PRO
PRO If pre-check suggests eDB360 may take long to execute (over 24 hrs), take care first of ASH state:
PRO 1. If stats are outdated, gather fresh stats using edb360-master/sql/gather_stats_wr_sys.sql.
PRO 2. If ASH size is large, or last DDL is old, review references below and proceed to purge and partition ASH.
PRO
PRO References:
PRO WRH$_ACTIVE_SESSION_HISTORY Does Not Get Purged Based Upon the Retention Policy (Doc ID 387914.1)
PRO Bug 14084247 - ORA-1555 or ORA-12571 Failed AWR purge can lead to continued SYSAUX space use (Doc ID 14084247.8)
PRO Manually Purge the Optimizer Statistics and AWR Snaphots to Reduce Space Usage of SYSAUX Tablespace (Doc ID 1965061.1)
PRO
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO

SPO OFF;

COL ash_database_block_size CLE;
COL number_of_instances CLE;
COL my_spool_filename CLE;
COL db_name CLE;
COL snap_interval CLE;
COL retention CLE;
COL last_purge_time CLE;
COL days_since_purge CLE;
COL locked CLE;
COL stale CLE;
COL ash_last_analyzed CLE;
COL ash_cbo_stats_age_days CLE;
COL table_or_partition CLE;
COL percent_of_inserts CLE;
COL size_gb CLE;
COL partition_name CLE;
COL all_segments CLE;
COL ash_size_gb CLE;
COL ash_object CLE;
COL last_ddl_time CLE;
COL last_ddl_age_days CLE;
COL seg_last_ddl_time CLE;
COL ash_fts_seconds CLE;
COL ash_days_of_history CLE;
COL ash_med_sample_date CLE;
COL ash_median_age_days CLE;
COL edb360_estimated_hrs CLE;

