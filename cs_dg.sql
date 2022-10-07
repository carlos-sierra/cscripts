COL role FOR A10;
COL db_unique_name FOR A15;
COL host_name FOR A64;
--
SELECT r.role, d.db_unique_name, h.host_name
FROM
(SELECT x.value db_unique_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'DATABASE') d,
(SELECT x.value role, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'role') r,
(SELECT x.value host_name, ROW_NUMBER() OVER (ORDER BY x.indx) AS rn FROM x$drc x WHERE x.attribute = 'host') h
WHERE r.rn = d.rn AND h.rn = d.rn
ORDER BY r.role DESC, d.db_unique_name
/
--
COL data_guard_configuration FOR A150;
--
SELECT LISTAGG(x.attribute||':'||x.value, ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY x.indx) AS data_guard_configuration
  FROM x$drc x
 WHERE x.attribute IN ('DRC', 'protection_mode', 'enabled', 'fast_start_failover', 'fsfo_target', 'role_change_detected',
                       'DATABASE', 'enabled', 'role', 'receive_from', 'ship_to', 'FSFOTargetValidity',
                       'host')
 GROUP BY
       x.object_id
 ORDER BY
       x.object_id
/
