select max(value)
from v$sesstat
where STATISTIC# in
(select STATISTIC#
from v$statname
where name = 'session cursor cache count')
and con_id > 2;