-- act.sql: active sql

SET lin 300;
COL inst FOR 9999;
COL sid_serial FOR A10;
COL sql_id_and_child FOR A16;
COL serv_mod_act_client_info FOR A64;
COL sql_text FOR A40;
COL execs FOR 99999;
COL et_secs FOR A11;

SELECT /* exclude_me */
       s.inst_id inst,
       s.sid||','||s.serial# sid_serial,
       s.sql_id||','||s.sql_child_number sql_id_and_child,
       s.service_name||','||s.module||','||s.action||','||s.client_info serv_mod_act_client_info,
       SUBSTR(q.sql_text, 1, 40) sql_text,
       q.executions execs,
       TO_CHAR(ROUND(q.elapsed_time/1e6,3),'99,990.000') et_secs
  FROM gv$session s,
       gv$sql q
 WHERE s.status = 'ACTIVE'
   AND q.inst_id = s.inst_id
   AND q.sql_id = s.sql_id
   AND q.child_number = s.sql_child_number
   AND q.sql_text NOT LIKE '%/* exclude_me */%'
 ORDER BY
       1,2,3;