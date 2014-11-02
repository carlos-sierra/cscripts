CL COL;

SET FEED ON VER OFF HEA ON LIN 32767 PAGES 100 TIMI OFF LONG 80 LONGC 80 TRIMS ON AUTOT OFF;
COL current_time NEW_V current_time FOR A15 NOPRI;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
SPO active_sql_&&current_time..txt

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
