COL value HEA 'Cursors';
COL username FOR A30;
COL sid FOR 99999;
COL serial# FOR 99999999;
--
select a.value, s.username, s.sid, s.serial#
from v$sesstat a, v$statname b, v$session s
where a.statistic# = b.statistic#  and s.sid=a.sid
and b.name = 'opened cursors current'
order by a.value DESC
/

