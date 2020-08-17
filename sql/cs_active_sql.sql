SET FEED ON VER OFF HEA ON LIN 32767 PAGES 100 TIMI OFF LONG 80 LONGC 80 TRIMS ON AUTOT OFF;
COL current_time NEW_V current_time FOR A15 NOPRI;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
SPO active_sql_&&current_time..txt
--
COL sql_text FOR A60 TRUNC;
COL sesion FOR A12 HEA 'SESSION';
COL module FOR A25 TRUNC;
COL action FOR A25 TRUNC;
COL executions FOR 999,999,999,990;
COL elapsed_time_secs FOR 9,999,990.000 HEA 'SQL ET|SECS TOT';
COL ms_per_exec FOR 999,999,990.000 HEA 'MS PER|EXEC AVG';
COL last_call_et FOR 9,999,990.000 HEA 'SESS LAST|CALL SECS';
--
SELECT /* exclude_me */
       se.last_call_et,
       sq.elapsed_time/1e6 AS elapsed_time_secs,
       sq.executions,
       sq.elapsed_time/1e3/NULLIF(sq.executions,0) AS ms_per_exec,
       se.sid||','||se.serial# AS sesion,
       se.type,
       se.module,
       se.action,
       sq.sql_id,
       sq.sql_text
  FROM v$session se,
       v$sql sq
 WHERE se.status = 'ACTIVE'
   AND se.sid <> SYS_CONTEXT('USERENV', 'SID')
   AND se.sql_id IS NOT NULL
   AND sq.sql_id(+) = se.sql_id
   AND sq.child_number(+) = se.sql_child_number
 ORDER BY
       se.last_call_et
/
--   
SPO OFF;
