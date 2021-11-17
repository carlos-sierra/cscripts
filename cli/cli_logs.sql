
COL p_groups FOR 90;
COL p_members FOR 90;
COL p_size_gb FOR 990;
COL s_groups FOR 90;
COL s_members FOR 90;
COL s_size_gb FOR 990;
COL total_gb FOR 9990;
COL switches_per_hour FOR 990.0;
COL sph_if_8gb FOR 990.0;
COL sph_if_16gb FOR 990.0;
COL total_if_8gb FOR 9990;
COL total_if_16gb FOR 9990;
COL lfs_aas FOR 990.000;
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
SELECT 
lfs_aas, 
p_size_gb, 
p_groups, 
p_members, 
s_size_gb, 
s_groups, 
s_members, 
((p_groups * p_members * p_size_gb) + (s_groups * s_members * s_size_gb)) AS total_gb, 
((p_groups * p_members * 8) + (s_groups * s_members * 8)) AS total_if_8gb, 
((p_groups * p_members * 16) + (s_groups * s_members * 16)) AS total_if_16gb, 
u02_avail_gb, 
switches_per_hour, 
ROUND(switches_per_hour * p_size_gb / 8, 1) AS sph_if_8gb, 
ROUND(switches_per_hour * p_size_gb / 16, 1) AS sph_if_16gb
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
) d
/