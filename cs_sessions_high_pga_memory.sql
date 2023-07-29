rem https://connor-mcdonald.com/2022/03/10/dont-run-tight-on-pga/
select ROUND(st.value/1024/1024/1024, 3) AS gb, s.sid, s.serial#, s.program, s.event, s.sql_id, s.prev_sql_id
from v$session s,
     v$sesstat st,
     v$statname sn
where st.value > 100*1024*1024
and st.sid = s.sid
and st.statistic# = sn.statistic#
and sn.name = 'session pga memory'
order by st.value desc
/

