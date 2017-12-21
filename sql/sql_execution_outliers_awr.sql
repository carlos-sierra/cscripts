SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET FEED ON;

ACC date_time_from PROMPT 'Date and Time FROM (i.e. 2017-11-09T17:22:00): ';
ACC date_time_to PROMPT 'Date and Time TO (i.e. 2017-11-09T22:22:13): ';
PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | O=Other | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC+Other
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
ACC sql_id PROMPT 'SQL_ID (opt): ';

COL dbid NEW_V dbid;
SELECT dbid FROM v$database;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_execution_outliers_awr_&&kiev_tx._&&sql_id._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO DATE_TIME_FROM: &&date_time_from.
PRO DATE_TIME_TO: &&date_time_to.
PRO KIEV_TX: &&kiev_tx.
PRO SQL_ID: &&sql_id.

COL instance_number FOR 9999 HEA 'INST';
COL session_id FOR 99999 HEA 'SID';
COL session_serial# FOR 999999 HEA 'SERIAL';
COL sql_plan_hash_value FOR 9999999999 HEA 'PHV';
COL sql_exec_id FOR 999999999 HEA 'SQL|EXEC_ID';
COL sql_exec_start FOR A19;
COL machine FOR A60;
COL con_id FOR 999999;
COL approx_execution_secs FOR 99,990 HEA 'APPROX|EXEC|SECS';
COL samples FOR 9999 HEA 'ASH|SMPL';
COL approx_start_time FOR A19;
COL approx_end_time FOR A19;
COL max_pga_allocated FOR 990.000 HEA 'PGA|ALLOC|GB';
COL max_temp_space_allocated FOR 9,990.000 HEA 'TEMP|SPACE|ALLOC';
COL sql_text_100 FOR A100 HEA 'SQL TEXT';
COL application_module FOR A6 HEA 'KIEV|TX';
COL sql_id FOR A13;
COL pdb_name FOR A30;

PRO 
PRO AWR SQL Executions lasting over ~5s
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WITH
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT con_id, sql_id, REPLACE(SUBSTR(sql_text, 1, 100), CHR(10), CHR(32)) sql_text_100 FROM v$sql WHERE '&&sql_id.' IS NULL OR sql_id = '&&sql_id.'
UNION
SELECT DISTINCT con_id, sql_id, REPLACE(DBMS_LOB.SUBSTR(sql_text, 100), CHR(10), CHR(32)) sql_text_100 FROM dba_hist_sqltext WHERE '&&sql_id.' IS NULL OR sql_id = '&&sql_id.'
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, sql_text_100, 
       CASE 
         WHEN sql_text_100 LIKE '/* addTransactionRow('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* checkStartRowValid('||CHR(37)||') */'||CHR(37) 
         THEN 'BEGIN'
         WHEN sql_text_100 LIKE '/* findMatchingRows('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* readTransactionsSince('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* writeTransactionKeys('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* setValueByUpdate('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* setValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* deleteValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* exists('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* existsUnique('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* updateIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE 'LOCK TABLE '||CHR(37)||'KievTransactions IN EXCLUSIVE MODE'||CHR(37) 
           OR sql_text_100 LIKE '/* getTransactionProgress('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* recordTransactionState('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* checkEndRowValid('||CHR(37)||') */'||CHR(37)
         THEN 'COMMIT'
         WHEN sql_text_100 LIKE '/* getValues('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* getNextIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text_100 LIKE '/* performScanQuery('||CHR(37)||') */'||CHR(37)
         THEN 'READ'
         WHEN sql_text_100 LIKE '/* populateBucketGCWorkspace */'||CHR(37) 
           OR sql_text_100 LIKE '/* deleteBucketGarbage */'||CHR(37) 
           OR sql_text_100 LIKE '/* Populate workspace for transaction GC */'||CHR(37) 
           OR sql_text_100 LIKE '/* Delete garbage for transaction GC */'||CHR(37) 
           OR sql_text_100 LIKE '/* Populate workspace in KTK GC */'||CHR(37) 
           OR sql_text_100 LIKE '/* Delete garbage in KTK GC */'||CHR(37) 
           OR sql_text_100 LIKE '/* hashBucket */'||CHR(37) 
         THEN 'GC'
         ELSE 'OTHER'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, MAX(sql_text_100) sql_text_100, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%G%' AND application_module = 'GC') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%O%' AND application_module = 'OTHER')
      )
 GROUP BY
       con_id, sql_id
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_exec_start,
       h.sql_exec_id,
       MIN(h.sample_time) approx_start_time,
       MAX(h.sample_time) approx_end_time,
       ROUND(((CAST(MAX(h.sample_time) AS DATE) - h.sql_exec_start) * 24 * 60 * 60) + 5) approx_execution_secs,
       COUNT(*) samples,
       h.sql_id,
       h.sql_plan_hash_value,
       h.dbid,
       h.con_id,       
       h.instance_number,
       h.session_id,
       h.session_serial#,
       h.machine,
       ROUND(MAX(h.pga_allocated)/POWER(2,30),3) max_pga_allocated,
       ROUND(MAX(h.temp_space_allocated)/POWER(10,9),3) max_temp_space_allocated
  FROM dba_hist_active_sess_history h,
       cdb_users u
 WHERE h.dbid = &&dbid.
   AND h.sql_exec_start BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.session_type = 'FOREGROUND'
   AND h.user_id > 0
   AND h.is_sqlid_current = 'Y'
   AND h.in_sql_execution = 'Y'
   AND h.sql_id IS NOT NULL
   AND h.sql_plan_hash_value > 0
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.')
   AND u.user_id = h.user_id
   AND u.con_id = h.con_id
   AND u.oracle_maintained = 'N'
 GROUP BY
       h.instance_number,
       h.session_id,
       h.session_serial#,
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_exec_id,
       h.sql_exec_start,
       h.machine,
       h.dbid,
       h.con_id
HAVING COUNT(*) > 1
)
SELECT TO_CHAR(h.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       h.sql_exec_id,
       r.report_id,
       h.samples,
       CASE 
         WHEN r.report_id IS NULL THEN h.approx_execution_secs 
         ELSE ROUND((r.period_end_time - r.period_start_time) * 24 * 60 * 60)
       END approx_execution_secs,
       TO_CHAR(h.approx_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_start_time,
       TO_CHAR(h.approx_end_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_end_time,
       h.sql_id,
       h.sql_plan_hash_value,
       h.con_id,  
       p.pdb_name,     
       h.instance_number,
       h.session_id,
       h.session_serial#,
       t.application_module,
       t.sql_text_100,
       h.machine,
       h.max_pga_allocated,
       h.max_temp_space_allocated
  FROM my_query h,
       my_tx_sql t,
       dba_hist_reports r,
       cdb_pdbs p
 WHERE t.con_id = h.con_id
   AND t.sql_id = h.sql_id
   AND r.component_name(+) = 'sqlmonitor'
   AND r.report_name(+) = 'main'
   AND r.dbid(+) = h.dbid
   AND r.instance_number(+) = h.instance_number
   AND r.con_id(+) = h.con_id
   AND r.session_id(+) = h.session_id
   AND r.session_serial#(+) = h.session_serial#
   AND r.key1(+) = h.sql_id
   AND r.key2(+) = TO_CHAR(h.sql_exec_id)
   AND r.key3(+) = TO_CHAR(h.sql_exec_start, 'MM:DD:YYYY HH24:MI:SS')
   AND p.con_id = h.con_id
 UNION ALL   
SELECT TO_CHAR(TO_DATE(r.key3, 'MM:DD:YYYY HH24:MI:SS'), 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       TO_NUMBER(r.key2) sql_exec_id,
       r.report_id,
       TO_NUMBER(NULL) samples,
       ROUND((r.period_end_time - r.period_start_time) * 24 * 60 * 60) approx_execution_secs,
       TO_CHAR(r.period_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_start_time,
       TO_CHAR(r.period_end_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_end_time,
       r.key1 sql_id,
       TO_NUMBER(NULL) sql_plan_hash_value,
       r.con_id,
       p.pdb_name,     
       r.instance_number,
       r.session_id,
       r.session_serial#,
       t.application_module,
       t.sql_text_100,
       NULL machine,
       TO_NUMBER(NULL) max_pga_allocated,
       TO_NUMBER(NULL) max_temp_space_allocated
  FROM dba_hist_reports r,
       my_tx_sql t,
       cdb_pdbs p
 WHERE r.dbid = &&dbid.
   AND r.component_name = 'sqlmonitor'
   AND r.report_name = 'main'
   AND TO_DATE(r.key3, 'MM:DD:YYYY HH24:MI:SS') BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND t.con_id = r.con_id
   AND t.sql_id = r.key1
   AND (r.key1, r.key2, r.key3) NOT IN 
       ( SELECT sql_id,
                TO_CHAR(sql_exec_id),
                TO_CHAR(sql_exec_start, 'MM:DD:YYYY HH24:MI:SS')
           FROM my_query
       )
   AND p.con_id = r.con_id
 ORDER BY
       1, 2
/

PRO Use sql_monitor_report_awr.sql passing REPORT_ID 
SPO OFF;