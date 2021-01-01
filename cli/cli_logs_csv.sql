
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
COL line FOR A500;
--
SELECT '.Realm, Rgn, Region, Locale, CDB Name, Host Name, Log File Switch AAS, Primary Log Size GBs, Primary Log Groups, Primary Log Members, Standby Log Size GBs, Standby Log Groups, Standby Log Members, Total Log Size GBs, Log Size if 8GB, Log Size if 16GB, u02 GBs avail, Log Switches per Hour, LSPH if 8GB, LSPH of 16GB' AS line FROM DUAL
UNION ALL
SELECT 
C##IOD.IOD_META_AUX.get_realm(region)||', '||
C##IOD.IOD_META_AUX.get_region_acronym(region)||', '||
region||', '||
C##IOD.IOD_META_AUX.get_locale(db_domain)||', '||
cdb_name||', '||
host_name||', '||
lfs_aas||', '||
p_size_gb||', '||
p_groups||', '||
p_members||', '||
s_size_gb||', '||
s_groups||', '||
s_members||', '||
((p_groups * p_members * p_size_gb) + (s_groups * s_members * s_size_gb))||', '||
((p_groups * p_members * 8) + (s_groups * s_members * 8))||', '||
((p_groups * p_members * 16) + (s_groups * s_members * 16))||', '||
u02_avail_gb||', '||
switches_per_hour||', '||
ROUND(switches_per_hour * p_size_gb / 8, 1)||', '||
ROUND(switches_per_hour * p_size_gb / 16, 1) AS line
FROM 
(
SELECT bytes / POWER(2,30) AS p_size_gb, COUNT(*) AS p_groups, AVG(members) AS p_members
  FROM v$log
GROUP BY bytes / POWER(2,30)
) l,
(
SELECT bytes / POWER(2,30) AS s_size_gb, COUNT(*) AS s_groups, 1 as s_members
  FROM v$standby_log
GROUP BY bytes / POWER(2,30)
) sl,
(
SELECT ROUND(COUNT(*) / 7 / 24, 1) switches_per_hour
  FROM v$log_history
 WHERE first_time BETWEEN TRUNC(SYSDATE) - 7 AND TRUNC(SYSDATE)
) h,
(
SELECT ROUND(count(*) * 10 / (7 * 24 * 3600), 3) lfs_aas
  FROM dba_hist_active_sess_history
 WHERE wait_class = 'Configuration'
   AND event LIKE 'log file switch%'
   AND sample_time > SYSDATE - 7
) a,
(
SELECT TRUNC(u02_available * 1000 / POWER(2, 30)) AS u02_avail_gb
  FROM C##IOD.dbc_system
ORDER BY timestamp DESC
FETCH FIRST 1 ROW ONLY
) d,
(
SELECT C##IOD.IOD_META_AUX.get_region(host_name) AS region, d.name AS cdb_name, host_name, value AS db_domain from v$database d, v$instance, v$parameter p WHERE p.name = 'db_domain'
) i
/