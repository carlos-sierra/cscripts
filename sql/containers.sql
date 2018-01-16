SELECT v.con_id,
       v.dbid,
       v.name container_name,
       v.open_mode,
       v.restricted,
       to_char(o.ctime, 'yyyy/mm/dd hh24:mi:ss') created,
       to_char(v.open_time, 'yyyy/mm/dd hh24:mi:ss') open_time,
       v.total_size/1024/1024 total_mb,
       v.block_size
  FROM container$ c, obj$ o, v$containers v
 WHERE o.obj# = c.obj#
   AND v.con_id = c.con_id# 
   AND v.dbid = c.dbid
 ORDER BY
       v.open_mode,
       o.name
/
