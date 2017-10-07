ACC sample_time PROMPT 'Date and Time (i.e. 2017-09-15T18:00:07): ';
PRO KIEV Transaction: C=commitTx | B=beginTx | G=GC | CB=commitTx+beginTx | NULL=commitTx+beginTx+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
ACC sql_id PROMPT 'SQL_ID (opt): ';

SET HEA ON LIN 32767 NEWP 1 PAGES 42 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

BREAK ON sample_date_time SKIP 1 ON machine;
COL sql_text_100_only FOR A100 HEA 'SQL Text';
COL sample_date_time FOR A20 HEA 'Sample Date and Time';
COL samples FOR 999,999 HEA 'Samples';
COL on_cpu_or_wait_class FOR A14 HEA 'ON CPU or|Wait Class';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
COL session_serial FOR A16 HEA 'Session,Serial';
COL machine FOR A40 HEA 'Application Server';

SPO ash_awr_sample_kiev_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SAMPLE_TIME: &&sample_time.

WITH   
my_tx_sql AS (
SELECT DISTINCT sql_id
FROM v$sql
WHERE (SUBSTR(sql_text, 1, 100) LIKE '/* % */%' OR SUBSTR(sql_text, 1, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE')
AND (    (NVL('&&kiev_tx.', 'CBG') LIKE '%C%' AND ( REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'checkEndRowValid',
                                                   'deleteValue',
                                                   'exists',
                                                   'existsUnique',
                                                   'findMatchingRows',
                                                   'getTransactionProgress',
                                                   'readTransactionsSince',
                                                   'recordTransactionState',
                                                   'setValue',
                                                   'writeTransactionKeys'
                                                   )
                                                   OR SUBSTR(sql_text, 1, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE'
                                                  )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%B%' AND REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'addTransactionRow',
                                                   'checkStartRowValid'
                                                   )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%G%' AND REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'flagPartialTransactionRows',
                                                   'Delete'
                                                   )
         )
    )
UNION 
SELECT DISTINCT sql_id
FROM dba_hist_sqltext
WHERE (DBMS_LOB.SUBSTR(sql_text, 100) LIKE '/* % */%' OR DBMS_LOB.SUBSTR(sql_text, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE')
AND (    (NVL('&&kiev_tx.', 'CBG') LIKE '%C%' AND ( REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'checkEndRowValid',
                                                   'deleteValue',
                                                   'exists',
                                                   'existsUnique',
                                                   'findMatchingRows',
                                                   'getTransactionProgress',
                                                   'readTransactionsSince',
                                                   'recordTransactionState',
                                                   'setValue',
                                                   'writeTransactionKeys'
                                                   )
                                                   OR DBMS_LOB.SUBSTR(sql_text, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE'
                                                  )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%B%' AND REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'addTransactionRow',
                                                   'checkStartRowValid'
                                                   )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%G%' AND REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'flagPartialTransactionRows',
                                                   'Delete'
                                                   )
         )
    )
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       COUNT(*) samples, 
       h.sql_id, 
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END on_cpu_or_wait_class,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only
  FROM dba_hist_active_sess_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') - (1/24) AND TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') + (1/24) -- +/- 1h
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
   AND sql_id IN (SELECT sql_id FROM my_tx_sql)
 GROUP BY
       CAST(h.sample_time AS DATE),
       h.sql_id, 
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END
 ORDER BY
       CAST(h.sample_time AS DATE),
       samples DESC,
       h.sql_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class END
/

WITH   
my_tx_sql AS (
SELECT DISTINCT sql_id
FROM v$sql
WHERE (SUBSTR(sql_text, 1, 100) LIKE '/* % */%' OR SUBSTR(sql_text, 1, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE')
AND (    (NVL('&&kiev_tx.', 'CBG') LIKE '%C%' AND ( REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'checkEndRowValid',
                                                   'deleteValue',
                                                   'exists',
                                                   'existsUnique',
                                                   'findMatchingRows',
                                                   'getTransactionProgress',
                                                   'readTransactionsSince',
                                                   'recordTransactionState',
                                                   'setValue',
                                                   'writeTransactionKeys'
                                                   )
                                                   OR SUBSTR(sql_text, 1, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE'
                                                  )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%B%' AND REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'addTransactionRow',
                                                   'checkStartRowValid'
                                                   )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%G%' AND REGEXP_SUBSTR(SUBSTR(sql_text, 1, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'flagPartialTransactionRows',
                                                   'Delete'
                                                   )
         )
    )
UNION 
SELECT DISTINCT sql_id
FROM dba_hist_sqltext
WHERE (DBMS_LOB.SUBSTR(sql_text, 100) LIKE '/* % */%' OR DBMS_LOB.SUBSTR(sql_text, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE')
AND (    (NVL('&&kiev_tx.', 'CBG') LIKE '%C%' AND ( REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'checkEndRowValid',
                                                   'deleteValue',
                                                   'exists',
                                                   'existsUnique',
                                                   'findMatchingRows',
                                                   'getTransactionProgress',
                                                   'readTransactionsSince',
                                                   'recordTransactionState',
                                                   'setValue',
                                                   'writeTransactionKeys'
                                                   )
                                                   OR DBMS_LOB.SUBSTR(sql_text, 100) LIKE 'LOCK TABLE %KievTransactions IN EXCLUSIVE MODE'
                                                  )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%B%' AND REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'addTransactionRow',
                                                   'checkStartRowValid'
                                                   )
         )
      OR (NVL('&&kiev_tx.', 'CBG') LIKE '%G%' AND REGEXP_SUBSTR(DBMS_LOB.SUBSTR(sql_text, 100), '[^(^/* )]\w+') IN 
                                                   (
                                                   'flagPartialTransactionRows',
                                                   'Delete'
                                                   )
         )
    )
)
SELECT TO_CHAR(CAST(h.sample_time AS DATE), 'YYYY-MM-DD"T"HH24:MI:SS') sample_date_time,
       h.machine,
       h.session_id||','||h.session_serial# session_serial,
       h.sql_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END on_cpu_or_wait_event,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only
  FROM dba_hist_active_sess_history h
 WHERE CAST(h.sample_time AS DATE) BETWEEN TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') - 60/(24*60*60) AND TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') + 60/(24*60*60)
   AND sql_id IN (SELECT sql_id FROM my_tx_sql)
 ORDER BY
       CAST(h.sample_time AS DATE),
       h.machine,
       h.session_id,
       h.session_serial#,
       h.sql_id
/

SPO OFF;
