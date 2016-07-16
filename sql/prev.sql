SET PAGES 24;
COL sid FOR A6;
SELECT 
SYS_CONTEXT('USERENV', 'SID') sid, 
prev_sql_id sql_id, 
prev_child_number child
FROM v$session 
WHERE sid = SYS_CONTEXT('USERENV', 'SID')
/