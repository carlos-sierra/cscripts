SPO kill_sessions_driver.sql;
select 'alter system kill session '''||sid||','||serial#||''' immediate;' 
from v$session 
where sql_id='&sql_id.' 
and sql_child_number=&sql_child_number.;
SPO OFF;
