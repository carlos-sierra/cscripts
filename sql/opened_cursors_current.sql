SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL machine FOR A60;
COL program FOR A40;
COL module FOR A40;

select to_number(a.value) opened_cursors_current, a.con_id, a.inst_id, 
       s.sid, s.serial#, TO_CHAR(s.logon_time, 'YYYY-MM-DD"T"HH24:MI:SS') logon_time,
       s.username, s.machine, s.program, s.module
from gv$sesstat a, gv$statname b, gv$session s
where a.statistic# = b.statistic#  
  and a.inst_id = b.inst_id
  and s.sid=a.sid
  and s.inst_id = a.inst_id
  and b.name = 'opened cursors current'
  and to_number(a.value) < 1.844E+19 -- bug
  and to_number(a.value) > 0
  and to_number(a.value) > 50
order by 1 desc
/

