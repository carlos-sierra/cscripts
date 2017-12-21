PRO Enter approximate date of incident. If within the past 24hrs then enter nothing. Script will reveiw a 24h window.
ACC date_and_time PROMPT 'Date and Time YYYY-MM-DD"T"HH24:MI:SS (e.g. 2017-11-04T20:15:55) (opt): '
PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
VAR dbid NUMBER;
VAR snap_id_begin NUMBER;
VAR snap_id_end NUMBER;
BEGIN
  SELECT dbid INTO :dbid FROM v$database;
  IF '&&date_and_time.' IS NULL OR TRUNC(TO_DATE('&&date_and_time.', 'YYYY-MM-DD"T"HH24:MI:SS')) >= TRUNC(SYSDATE) THEN
    SELECT MAX(snap_id) INTO :snap_id_end FROM dba_hist_snapshot WHERE dbid = :dbid;
    SELECT MAX(snap_id) INTO :snap_id_begin FROM dba_hist_snapshot WHERE dbid = :dbid AND end_interval_time < SYSDATE - 1;
  ELSE
    SELECT snap_id INTO :snap_id_begin FROM dba_hist_snapshot WHERE dbid = :dbid AND TO_DATE('&&date_and_time.', 'YYYY-MM-DD"T"HH24:MI:SS') - 0.5 BETWEEN begin_interval_time AND end_interval_time;
    SELECT snap_id INTO :snap_id_end FROM dba_hist_snapshot WHERE dbid = :dbid AND TO_DATE('&&date_and_time.', 'YYYY-MM-DD"T"HH24:MI:SS') + 0.5 BETWEEN begin_interval_time AND end_interval_time;
  END IF;
END;
/
COL dbid NEW_V dbid;
SELECT :dbid dbid FROM DUAL;
COL snap_id_begin NEW_V snap_id_begin;
COL snap_id_end NEW_V snap_id_end;
COL begin_time NEW_V begin_time;
COL end_time NEW_V end_time;
SELECT snap_id snap_id_begin, begin_interval_time begin_time FROM dba_hist_snapshot WHERE dbid = :dbid AND snap_id = :snap_id_begin;
SELECT snap_id snap_id_end, end_interval_time end_time FROM dba_hist_snapshot WHERE dbid = :dbid AND snap_id = :snap_id_end;
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL ash_plans FOR 9999999 HEA 'ASH|PLANS';
COL sta_plans FOR 9999999 HEA 'SQLSTAT|PLANS';
COL ash_et_secs FOR 9999999 HEA 'ASH|ET_SECS';
COL ash_cpu_secs FOR 9999999 HEA 'ASH|CPU_SECS';
COL sta_et_secs FOR 9999999 HEA 'SQLSTAT|ET_SECS';
COL sta_cpu_secs FOR 9999999 HEA 'SQLSTAT|CPU_SECS';
COL et_ms_per_exec FOR 999,999,990.000 HEA 'ET_MILLISECS|PER_EXEC';
COL cpu_ms_per_exec FOR 999,999,990.000 HEA 'CPU_MILLISECS|PER_EXEC';
COL inflection_snap_id NOPRI HEA 'SNAP_SET';
CL BRE;
BREAK ON inst SKIP PAGE ON con_id SKIP PAGE ON sql_id SKIP PAGE ON inflection_snap_id SKIP 1 ON kiev_tx ON kiev_api;
COL kiev_api FOR A100;
COL inst FOR 9999;
SPO flipping_plan_kiev_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SNAP_ID_BEGIN: &&snap_id_begin.
PRO SNAP_ID_END: &&snap_id_end.
PRO BEGIN_TIME: &&begin_time.
PRO END_TIME: &&end_time.
PRO KIEV_TX: &&kiev_tx.
PRO
/****************************************************************************************/
WITH
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id, sql_text FROM v$sql
UNION
SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, sql_text, 
       CASE 
         WHEN sql_text LIKE '/* addTransactionRow('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkStartRowValid('||CHR(37)||') */'||CHR(37) 
         THEN 'BEGIN'
         WHEN sql_text LIKE '/* findMatchingRows('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* readTransactionsSince('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* writeTransactionKeys('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValueByUpdate('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* deleteValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* exists('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* existsUnique('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* updateIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE 'LOCK TABLE '||CHR(37)||'KievTransactions IN EXCLUSIVE MODE'||CHR(37) 
           OR sql_text LIKE '/* getTransactionProgress('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* recordTransactionState('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkEndRowValid('||CHR(37)||') */'||CHR(37)
         THEN 'COMMIT'
         WHEN sql_text LIKE '/* getValues('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* getNextIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* performScanQuery('||CHR(37)||') */'||CHR(37)
         THEN 'READ'
         WHEN sql_text LIKE '/* populateBucketGCWorkspace */'||CHR(37) 
           OR sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* hashBucket */'||CHR(37) 
         THEN 'GC'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%G%' AND application_module = 'GC')
      )
 GROUP BY
       sql_id
),
cpu_secs_per_phv_and_snap AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.dbid,
       h.instance_number,
       h.con_id,
       h.snap_id,
       h.sql_id,
       h.sql_plan_hash_value plan_hash_value,
       10 * COUNT(*) et_secs,
       SUM(CASE h.session_state WHEN 'ON CPU' THEN 10 ELSE 0 END) cpu_secs,
       ROW_NUMBER() OVER (PARTITION BY h.dbid, h.instance_number, h.con_id, h.snap_id, h.sql_id ORDER BY COUNT(*) DESC NULLS LAST, h.sql_plan_hash_value) row_number,
       t.application_module,
       t.sql_text
  FROM dba_hist_active_sess_history h,
       my_tx_sql t
 WHERE h.dbid = :dbid
   AND h.snap_id BETWEEN :snap_id_begin AND :snap_id_end
   AND h.session_state IN ('ON CPU', 'Scheduler')
   AND t.sql_id = h.sql_id
 GROUP BY
       h.dbid,
       h.instance_number,
       h.con_id,
       h.snap_id,
       h.sql_id,
       h.sql_plan_hash_value,
       t.application_module,
       t.sql_text
),
cpu_secs_per_sql_and_snap AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       dbid,
       instance_number,
       con_id,
       snap_id,
       sql_id,
       COUNT(DISTINCT plan_hash_value) plans,
       SUM(et_secs) et_secs,
       SUM(cpu_secs) cpu_secs,
       application_module,
       sql_text
  FROM cpu_secs_per_phv_and_snap
 GROUP BY
       dbid,
       instance_number,
       con_id,
       snap_id,
       sql_id,
       application_module,
       sql_text
),
perf_per_phv_and_snap AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.dbid,
       h.instance_number,
       h.con_id,
       h.snap_id,
       h.sql_id,
       h.plan_hash_value,
       SUM(h.elapsed_time_delta)/1e6 et_secs,
       SUM(h.cpu_time_delta)/1e6 cpu_secs,
       SUM(h.executions_delta) executions,
       ROW_NUMBER() OVER (PARTITION BY h.dbid, h.instance_number, h.con_id, h.snap_id, h.sql_id ORDER BY SUM(h.cpu_time_delta) DESC NULLS LAST, h.plan_hash_value) row_number
  FROM dba_hist_sqlstat h,
       my_tx_sql t
 WHERE h.dbid = :dbid
   AND h.snap_id BETWEEN :snap_id_begin AND :snap_id_end
   AND h.executions_delta > 0
   AND h.elapsed_time_delta > 0
   AND t.sql_id = h.sql_id
 GROUP BY
       h.dbid,
       h.instance_number,
       h.con_id,
       h.snap_id,
       h.sql_id,
       h.plan_hash_value
),
perf_per_sql_and_snap AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       dbid,
       instance_number,
       con_id,
       snap_id,
       sql_id,
       COUNT(DISTINCT plan_hash_value) plans,
       SUM(et_secs) et_secs,
       SUM(cpu_secs) cpu_secs,
       SUM(executions) executions
  FROM perf_per_phv_and_snap
 GROUP BY
       dbid,
       instance_number,
       con_id,
       snap_id,
       sql_id
),
per_sql_and_snap AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ash.dbid,
       ash.instance_number,
       ash.con_id,
       ash.snap_id,
       ash.sql_id,
       ash.plans ash_plans,
       ash_p.plan_hash_value ash_top_phv,
       ash.et_secs ash_et_secs,
       ash.cpu_secs ash_cpu_secs,
       sta.plans sta_plans,
       sta_p.plan_hash_value sta_top_phv,
       ROUND(sta.et_secs) sta_et_secs,
       ROUND(sta.cpu_secs) sta_cpu_secs,
       sta.executions sta_execs,
       CASE WHEN sta.executions > 0 THEN ROUND(1e3*sta.et_secs/sta.executions, 3) END et_ms_per_exec,
       CASE WHEN sta.executions > 0 THEN ROUND(1e3*sta.cpu_secs/sta.executions, 3) END cpu_ms_per_exec,
       ash.application_module appl_module,
       ash.sql_text,
       LAG(ash.snap_id) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_snap_id,
       LAG(ash.plans) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_ash_plans,
       LAG(ash_p.plan_hash_value) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_ash_top_phv,
       LAG(ash.et_secs) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_ash_et_secs,
       LAG(ash.cpu_secs) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_ash_cpu_secs,
       LAG(sta.plans) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sta_plans,
       LAG(sta_p.plan_hash_value) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sta_top_phv,
       LAG(ROUND(sta.et_secs)) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sta_et_secs,
       LAG(ROUND(sta.cpu_secs)) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sta_cpu_secs,
       LAG(sta.executions) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sta_execs,
       LAG(CASE WHEN sta.executions > 0 THEN ROUND(1e3*sta.et_secs/sta.executions, 3) END) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_et_ms_per_exec,
       LAG(CASE WHEN sta.executions > 0 THEN ROUND(1e3*sta.cpu_secs/sta.executions, 3) END) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_cpu_ms_per_exec,
       LAG(ash.application_module) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_appl_module,
       LAG(ash.sql_text) OVER (PARTITION BY ash.dbid, ash.instance_number, ash.con_id, ash.sql_id ORDER BY ash.snap_id NULLS LAST) lag_sql_text
  FROM cpu_secs_per_sql_and_snap ash,
       cpu_secs_per_phv_and_snap ash_p,
       perf_per_sql_and_snap     sta,
       perf_per_phv_and_snap     sta_p
 WHERE ash_p.dbid = ash.dbid
   AND ash_p.instance_number = ash.instance_number
   AND ash_p.con_id = ash.con_id
   AND ash_p.snap_id = ash.snap_id
   AND ash_p.sql_id = ash.sql_id
   AND ash_p.application_module = ash.application_module
   AND ash_p.sql_text = ash.sql_text
   AND ash_p.row_number = 1
   AND sta.dbid(+) = ash.dbid
   AND sta.instance_number(+) = ash.instance_number
   AND sta.con_id(+) = ash.con_id
   AND sta.snap_id(+) = ash.snap_id
   AND sta.sql_id(+) = ash.sql_id
   AND sta_p.dbid(+) = ash.dbid
   AND sta_p.instance_number(+) = ash.instance_number
   AND sta_p.con_id(+) = ash.con_id
   AND sta_p.snap_id(+) = ash.snap_id
   AND sta_p.sql_id(+) = ash.sql_id
   AND sta_p.row_number(+) = 1
),
inflection_points AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ip.dbid,
       ip.instance_number,
       ip.con_id,
       ip.sql_id,
       ip.snap_id,
       ip.lag_snap_id,
       CASE WHEN ip.ash_top_phv <> ip.lag_ash_top_phv AND ip.sta_top_phv <> ip.lag_sta_top_phv THEN 'F' ELSE '?' END flag
  FROM per_sql_and_snap ip
 WHERE 1 = 1
   AND ip.ash_top_phv + NVL(ip.sta_top_phv, ip.ash_top_phv) <> ip.lag_ash_top_phv + NVL(ip.lag_sta_top_phv, ip.lag_ash_top_phv) -- top plan has shifted
   AND ip.ash_cpu_secs + NVL(ip.sta_cpu_secs, ip.ash_cpu_secs) >= 2 * (ip.lag_ash_cpu_secs + NVL(ip.lag_sta_cpu_secs, ip.lag_ash_cpu_secs)) -- performance per execution regressed over 2x
   AND ip.ash_cpu_secs + NVL(ip.sta_cpu_secs, ip.ash_cpu_secs) > 15 -- more than 15 seconds of CPU elapsed time 
),
before_and_after AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ip.instance_number,
       ip.con_id,
       ip.sql_id,
       ip.snap_id inflection_snap_id,
       ba.snap_id,
       -- CASE ba.snap_id WHEN ip.snap_id THEN '*' END f,
       CASE ba.snap_id WHEN ip.snap_id THEN ip.flag END f,
       TO_CHAR(sh.begin_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') begin_interval_time,
       TO_CHAR(sh.end_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_interval_time,
       ba.ash_plans,
       ba.ash_top_phv,
       ba.ash_et_secs,
       ba.ash_cpu_secs,
       ba.sta_plans,
       ba.sta_top_phv,
       ba.sta_et_secs,
       ba.sta_cpu_secs,
       ba.sta_execs,
       ba.et_ms_per_exec,
       ba.cpu_ms_per_exec,
       ba.appl_module,
       ba.sql_text
  FROM inflection_points ip,
       per_sql_and_snap ba,
       dba_hist_snapshot sh
 WHERE ba.dbid = ip.dbid
   AND ba.instance_number = ip.instance_number
   AND ba.con_id = ip.con_id
   AND ba.sql_id = ip.sql_id
   AND ba.snap_id BETWEEN ip.lag_snap_id - 1 AND ip.snap_id + 2
   AND sh.snap_id = ba.snap_id
   AND sh.dbid = ba.dbid
   AND sh.instance_number = ba.instance_number
)
SELECT instance_number inst,
       con_id,
       sql_id,
       inflection_snap_id,
       snap_id,
       f,
       begin_interval_time,
       end_interval_time,
       ash_plans,
       ash_top_phv,
       ash_et_secs,
       ash_cpu_secs,
       sta_plans,
       sta_top_phv,
       sta_et_secs,
       sta_cpu_secs,
       sta_execs,
       et_ms_per_exec,
       cpu_ms_per_exec,
       appl_module kiev_tx,
       CASE WHEN sql_text LIKE 'LOCK TABLE%' THEN sql_text ELSE SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) END kiev_api       
  FROM before_and_after
 ORDER BY
       instance_number,
       con_id,
       sql_id,
       inflection_snap_id,
       snap_id
/
/****************************************************************************************/
SPO OFF;
