select all_objects.object_name,
       all_objects.object_type,
       v$locked_object.session_id,
       v$session.serial#,
       v$lock.type lock_type,  -- Type or system/user lock
       lmode lock_mode, -- lock mode in which session holds lock
       CASE
           WHEN lmode = 0 THEN 'NONE: lock requested but not yet obtained'
           WHEN lmode = 1 THEN 'NULL'
           WHEN lmode = 2 THEN 'ROWS_S (SS): Row Share Lock'
           WHEN lmode = 3 THEN 'ROW_X (SX): Row Exclusive Table Lock'
           WHEN lmode = 4 THEN 'SHARE (S): Share Table Lock'
           WHEN lmode = 5 THEN 'S/ROW-X (SSX): Share Row Exclusive Table Lock'
           WHEN lmode = 6 THEN 'Exclusive (X): Exclusive Table Lock'
       END Lock_description,
       v$lock.request,
       v$lock.block,
       ctime, -- Time since current mode was granted
       'alter system disconnect session ''' || v$locked_object.session_id || ',' || v$session.serial# || ''' immediate;' killcmd
from v$locked_object,
     all_objects,
     v$lock,
     v$session
where v$locked_object.object_id = all_objects.object_id
  AND v$lock.id1 = all_objects.object_id
  AND v$lock.sid = v$locked_object.session_id
  and v$session.sid = v$lock.sid
order by session_id, ctime desc, object_name;