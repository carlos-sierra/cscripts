SET HEA OFF PAGES 0 FEED OFF VER OFF ECHO OFF;

SPO kill_sessions_driver.sql;
select 'alter system kill session '''||s.sid||','||s.serial#||''' immediate;' 
from gv$sesstat a, gv$statname b, gv$session s
where a.statistic# = b.statistic#  
  and a.inst_id = b.inst_id
  and s.sid=a.sid
  and s.inst_id = a.inst_id
  and b.name = 'opened cursors current'
  and to_number(a.value) < 1.844E+19 -- bug
  and to_number(a.value) > 0
  and to_number(a.value) > 50
/
SPO OFF;

PRO Execute kill_sessions_driver.sql
