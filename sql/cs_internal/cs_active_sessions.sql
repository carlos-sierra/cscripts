COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
COL child_number FOR 999999 HEA 'Child|Number';
COL sql_exec_start FOR A19 HEA 'SQL Exec Start';
COL current_timed_event FOR A80 HEA 'Current Timed Event';
--
PRO
PRO ACTIVE SESSIONS (v$session)
PRO ~~~~~~~~~~~~~~~
SELECT s.con_id,
       c.name AS pdb_name,
       s.machine,
         s.state||CASE WHEN s.state LIKE 'WAITED%' THEN ' (avg of '||ROUND(AVG(s.wait_time_micro))||'us)' END||
         CASE WHEN s.wait_class IS NOT NULL THEN ' on '||s.wait_class||CASE WHEN s.event IS NOT NULL THEN ' - '||s.event END END AS current_timed_event,
       COUNT(*) AS sessions
  FROM v$session s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND s.status = 'ACTIVE'
   AND c.con_id = s.con_id
 GROUP BY
       s.con_id,
       c.name,
       s.machine,
       s.state,
       s.wait_class,
       s.event
 ORDER BY
       s.con_id,
       s.machine,
       s.state,
       s.wait_class,
       s.event
/
--
--BREAK ON con_id ON pdb_name ON machine SKIP PAGE;
SELECT s.con_id,
       c.name AS pdb_name,
       machine,
       s.sid||','||s.serial# AS sid_serial#,
       s.sql_child_number AS child_number,
       TO_CHAR(s.sql_exec_start, '&&cs_datetime_full_format.') sql_exec_start,
       s.state||CASE WHEN s.state LIKE 'WAITED%' THEN ' ('||s.wait_time_micro||'us)' END||
       CASE WHEN s.wait_class IS NOT NULL THEN ' on '||s.wait_class||CASE WHEN s.event IS NOT NULL THEN ' - '||s.event END END AS current_timed_event
  FROM v$session s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND s.status = 'ACTIVE'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id,
       s.machine,
       s.sql_exec_start
/
--
--CLEAR BREAK;