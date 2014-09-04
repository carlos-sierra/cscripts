CL COL;
COL sql_text NOPRI;
COL optimizer_env NOPRI;
COL bind_date NOPRI;
COL exact_matching_signature FOR 99999999999999999999;
COL force_matching_signature FOR 99999999999999999999;

SET FEED ON VER OFF HEA ON LIN 32767 PAGES 100 TIMI OFF LONG 80 LONGC 80 TRIMS ON AUTOT OFF;
ALTER SESSION SET nls_date_format='YYYY/MM/DD HH24:MI:SS';
COL current_time NEW_V current_time FOR A15 NOPRI;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
SPO active_sessions_&&current_time..txt

SELECT /* active_sessions */ 
       se.*
  FROM gv$session se,
       gv$sql sq
 WHERE se.status = 'ACTIVE'
   AND sq.inst_id = se.inst_id
   AND sq.sql_id = se.sql_id
   AND sq.child_number = se.sql_child_number
   AND sq.sql_text NOT LIKE 'SELECT /* active_sessions */%'
 ORDER BY
       se.inst_id, se.sid, se.serial#;
   
SELECT /* active_sql */ 
       sq.*
  FROM gv$session se,
       gv$sql sq
 WHERE se.status = 'ACTIVE'
   AND sq.inst_id = se.inst_id
   AND sq.sql_id = se.sql_id
   AND sq.child_number = se.sql_child_number
   AND sq.sql_text NOT LIKE 'SELECT /* active_sql */%'
 ORDER BY
       sq.inst_id, sq.sql_id, sq.child_number;

SET LONG 3000000 LONGC 300;

SELECT /* active_sql */ 
       sq.inst_id, sq.sql_id, sq.child_number,
       sq.sql_fulltext
  FROM gv$session se,
       gv$sql sq
 WHERE se.status = 'ACTIVE'
   AND sq.inst_id = se.inst_id
   AND sq.sql_id = se.sql_id
   AND sq.child_number = se.sql_child_number
   AND sq.sql_text NOT LIKE 'SELECT /* active_sql */%'
 ORDER BY
       sq.inst_id, sq.sql_id, sq.child_number;

COL sql_text PRI;
WITH /* active_sql */ 
unique_sql AS (
SELECT DISTINCT sq.sql_id,
       REPLACE(SUBSTR(sq.sql_text, 1, 60), CHR(10)) sql_text
  FROM gv$session se,
       gv$sql sq
 WHERE se.status = 'ACTIVE'
   AND sq.inst_id = se.inst_id
   AND sq.sql_id = se.sql_id
   AND sq.child_number = se.sql_child_number
   AND sq.sql_text NOT LIKE 'WITH /* active_sql */%'
)
SELECT sql_id, sql_text
  FROM unique_sql
 ORDER BY
       sql_id;

SPO OFF;
SET FEED ON VER ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF;
