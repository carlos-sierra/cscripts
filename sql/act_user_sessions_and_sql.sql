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

SPO act_&&current_time..txt;
PRO DATABASE: &&x_db_name.
PRO PDB: &&x_container.
PRO HOST: &&x_host_name.

COL con_id FOR 999999;
COL sid_serial FOR A12;
COL sql_id_and_child FOR A16;
COL serv_host_client_mod_act FOR A50;
COL current_sql_text FOR A80;
BRE ON con_id SKIP PAGE;

WITH /* exclude_me */
active_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sid,
       serial#,
       sql_id,
       sql_child_number,
       prev_sql_id,
       prev_child_number,
       service_name,
       module,
       action,
       client_info,
       machine
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
   AND sid <> USERENV('SID')
)
SELECT s.con_id,
       LPAD(s.sid||','||s.serial#, 10) sid_serial,
       'C:'||s.sql_id||CHR(10)||'C:'||s.sql_child_number||CHR(10)||'P:'||s.prev_sql_id||CHR(10)||'P:'||s.prev_child_number sql_id_and_child,
       SUBSTR('S:'||s.service_name||CHR(10)||'H:'||s.machine||CHR(10)||'C:'||s.client_info||CHR(10)||'M:'||s.module||CHR(10)||'A:'||s.action, 1, 250) serv_host_client_mod_act,
       SUBSTR(q.sql_text, 1, 800) current_sql_text,
       ROUND(q.elapsed_time/1e6,3) et_secs,
       q.executions,
       CASE WHEN q.executions > 0 THEN ROUND(q.elapsed_time/1e6/q.executions,6) END et_per_exec
  FROM active_sessions s,
       v$sql q
 WHERE s.sql_id IS NOT NULL
   AND q.con_id = s.con_id
   AND q.sql_id = s.sql_id
   AND q.child_number = s.sql_child_number
   AND q.sql_text NOT LIKE '%/* exclude_me */%'
   AND q.is_obsolete = 'N'
   AND q.is_shareable = 'Y'
   AND q.object_status = 'VALID'
 UNION ALL
SELECT s.con_id,
       LPAD(s.sid||','||s.serial#, 10) sid_serial,
       'C:'||s.sql_id||CHR(10)||'C:'||s.sql_child_number||CHR(10)||'P:'||s.prev_sql_id||CHR(10)||'P:'||s.prev_child_number sql_id_and_child,
       SUBSTR('S:'||s.service_name||CHR(10)||'H:'||s.machine||CHR(10)||'C:'||s.client_info||CHR(10)||'M:'||s.module||CHR(10)||'A:'||s.action, 1, 250) serv_host_client_mod_act,
       NULL current_sql_text,
       NULL et_secs,
       NULL executions,
       NULL et_per_exec
  FROM active_sessions s
 WHERE s.sql_id IS NULL
 ORDER BY
       1,2
/

SPO OFF;
CL BRE;



