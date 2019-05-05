SET LINES 300;
COL sid_serial# FOR A20;
SELECT ROUND(m.allocated/POWER(2,30),1) allocated_gb, m.category,
       s.sid||','||s.serial# sid_serial#, s.sql_id, 
       TO_CHAR(s.logon_time,'YYYY-MM-DD"T"HH24:MI:SS') logon_time,
       TO_CHAR(s.sql_exec_start,'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       q.sql_text
  FROM v$process_memory m,
       v$process p,
       v$session s,
       v$sql q
 WHERE m.allocated > POWER(2,30) /* >1GB PGA */
   AND p.pid = m.pid
   AND p.con_id = m.con_id
   AND s.paddr = p.addr
   AND s.con_id = p.con_id
   AND q.sql_id(+) = s.sql_id
   AND q.child_number(+) = s.sql_child_number
   AND q.con_id(+) = s.con_id
 ORDER BY
       allocated_gb DESC
/

SELECT ROUND(m.allocated/POWER(2,30),1) allocated_gb, m.category,
       s.sid||','||s.serial# sid_serial#, s.sql_id, 
       TO_CHAR(s.logon_time,'YYYY-MM-DD"T"HH24:MI:SS') logon_time
  FROM v$process_memory m,
       v$process p,
       v$session s
 WHERE m.allocated > POWER(2,30) /* >1GB PGA */
   AND p.pid = m.pid
   AND p.con_id = m.con_id
   AND s.paddr = p.addr
   AND s.con_id = p.con_id
 ORDER BY
       allocated_gb DESC
/
