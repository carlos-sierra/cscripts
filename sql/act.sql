SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 50 TAB OFF TIMI OFF LONG 80000 LONGC 2000 TRIMS ON AUTOT OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO active_sql_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

COL sid_serial FOR A10;
COL sql_id_and_child FOR A16;
COL serv_mod_act_client_info FOR A50;
COL sql_text FOR A80;

-- execute 10 consecutive times
SELECT /* exclude_me */
       s.sid||','||s.serial# sid_serial,
       s.sql_id||','||s.sql_child_number sql_id_and_child,
       SUBSTR(s.service_name||','||s.module||','||s.action||','||s.client_info, 1, 250) serv_mod_act_client_info,
       SUBSTR(q.sql_text, 1, 400) sql_text,
       ROUND(q.elapsed_time/1e6,3) et_secs,
       q.executions,
       CASE WHEN q.executions > 0 THEN ROUND(q.elapsed_time/1e6/q.executions,6) END et_per_exec
  FROM v$session s,
       v$sql q
 WHERE s.status = 'ACTIVE'
   AND s.type = 'USER'
   AND q.con_id(+) = s.con_id
   AND q.sql_id(+) = s.sql_id
   AND q.child_number(+) = s.sql_child_number
   AND q.sql_text(+) NOT LIKE '%/* exclude_me */%'
 ORDER BY
       1,2
/
/
/
/
/

/
/
/
/
/

SPO OFF;