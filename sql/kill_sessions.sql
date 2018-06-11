PRO Enter SQL_ID
DEF sql_id = '&1.';
SET HEA OFF PAGES 0 FEED OFF VER OFF ECHO OFF;
SPO kill_sessions_driver.sql;
select 'alter system kill session '''||sid||','||serial#||''' immediate;' 
from v$session 
where sql_id='&sql_id.';
SPO OFF;
PRO Execute kill_sessions_driver.sql