SET FEED ON VER OFF HEA ON LIN 32767 PAGES 100 TIMI OFF LONG 80 LONGC 80 TRIMS ON AUTOT OFF;
COL current_time NEW_V current_time FOR A15 NOPRI;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
SPO active_sql_&&current_time..txt

COL sql_text_60 FOR A60;
COL sesion FOR A10 HEA 'SESSION';
COL module_25 FOR A25;
COL action_25 FOR A25;
COL executions FOR 999,999,999,990;
COL elapsed_time_secs FOR 9,999,990 HEA 'ET SECS';
COL ms_per_exec FOR 999,999,990.000 HEA 'MS PER EXEC';

SELECT /* exclude_me */
       ROUND(SUM(sq.elapsed_time)/1e6) elapsed_time_secs,
       SUM(sq.executions) executions,
       ROUND(SUM(sq.elapsed_time)/1e3/(CASE SUM(sq.executions) WHEN 0 THEN NULL ELSE SUM(sq.executions) END),3) ms_per_exec,
       se.sid||','||se.serial# sesion,
       SUBSTR(se.module, 1, 25) module_25,
       SUBSTR(se.action, 1, 25) action_25,
       sq.sql_id,
       SUBSTR(sq.sql_text, 1, 60) sql_text_60
  FROM v$session se,
       v$sql sq
 WHERE se.status = 'ACTIVE'
   AND se.sid <> USERENV('SID')
   AND sq.sql_id = se.sql_id
   AND sq.child_number = se.sql_child_number
   AND sq.sql_text NOT LIKE '%/* exclude_me */%'
 GROUP BY
       sq.sql_id,
       se.sid,
       se.serial#,
       SUBSTR(sq.sql_text, 1, 60),
       SUBSTR(se.module, 1, 25),
       SUBSTR(se.action, 1, 25)
 ORDER BY
       1 DESC,
       2 DESC
/
       
SPO OFF;
