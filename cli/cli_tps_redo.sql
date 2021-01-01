SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
-- iodcli sql_exec -y -t PRIMARY file:/Users/csierra/git/bitbucket.oci.oraclecorp.com/dbeng/oratk/sql/cscripts/cli/cli_tps_redo.sql hcg:HC_DATABASE > cli_tps_redo.2020-12-07.txt
-- cut -b 79- cli_tps_redo.2020-12-07.txt | grep "|" | sort -r | uniq > cli_tps_redo.2020-12-07_ordered.txt
--
COL avg_tps FOR 999,990;
COL max_tps FOR 999,990;
COL p99_tps FOR 999,990;
COL avg_redo_mbps FOR 999,990;
COL max_redo_mbps FOR 999,990;
COL p99_redo_mbps FOR 999,990;
COL region FOR A30 TRUNC;
COL rgn FOR A4 TRUNC;
COL locale FOR A6 TRUNC;
COL host_name FOR A64 TRUNC;
COL pdbs FOR 990;
COL host_class FOR A64;
COL db_version FOR A8 TRUNC;
COL u02_total_tb FOR 990.0;
COL u02_used_tb FOR 990.0;
COL u02_used_pct FOR 990;
--
WITH
dbc (
       host_class, version, u02_total_tb, u02_used_tb, u02_used_pct
) AS (
       SELECT host_class, version, ROUND(u02_size * 1024 / POWER(10,12), 1) AS u02_total_tb, ROUND(u02_used * 1024 / POWER(10,12), 1) AS u02_used_tb, CEIL(100 * u02_used / (u02_used + u02_available)) AS u02_used_pct FROM C##IOD.dbc_system, v$instance ORDER BY timestamp DESC NULLS LAST FETCH FIRST 1 ROW ONLY
),
horizon (
        dbid, instance_number, snap_id
) AS (
        SELECT dbid, instance_number, snap_id FROM dba_hist_snapshot WHERE end_interval_time < SYSDATE - 7 ORDER BY end_interval_time DESC FETCH FIRST 1 ROW ONLY
),
sysstat (
       snap_id, end_interval_time, elapsed_sec, stat_value_1, stat_value_2, stat_value_3
) AS (
       SELECT h.snap_id,
              s.end_interval_time,
              (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 86400 AS elapsed_sec,
              SUM(CASE WHEN h.stat_name = 'user commits' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = 'user commits' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_1,
              SUM(CASE WHEN h.stat_name = 'user rollbacks' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = 'user rollbacks' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_2,
              SUM(CASE WHEN h.stat_name = 'redo size' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = 'redo size' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_3
       FROM   horizon w,
              dba_hist_sysstat h,
              dba_hist_snapshot s
       WHERE  h.dbid = w.dbid
       AND h.instance_number = w.instance_number
       AND h.snap_id > w.snap_id
       AND h.stat_name IN ('user commits', 'user rollbacks', 'redo size')
       AND s.snap_id = h.snap_id
       AND s.dbid = h.dbid
       AND s.instance_number = h.instance_number
       GROUP BY
              h.snap_id,
              s.begin_interval_time,
              s.end_interval_time
),
sysstat_per_sec (
       snap_id, end_interval_time, stat_value_1_ps, stat_value_2_ps, stat_value_3_ps
) AS (
       SELECT snap_id,
              end_interval_time,
              CASE WHEN 'user commits' LIKE '%current' THEN stat_value_1 ELSE ROUND(stat_value_1 / elapsed_sec, 3) END stat_value_1_ps,
              CASE WHEN 'user rollbacks' LIKE '%current' THEN stat_value_2 ELSE ROUND(stat_value_2 / elapsed_sec, 3) END stat_value_2_ps,
              CASE WHEN 'redo size' LIKE '%current' THEN stat_value_3 ELSE ROUND(stat_value_3 / elapsed_sec, 3) END stat_value_3_ps
       FROM   sysstat
       WHERE  elapsed_sec > 60 -- ignore snaps too close
         AND stat_value_1 > 0
         AND stat_value_2 > 0
         AND stat_value_3 > 0
)
SELECT  '|' AS "|",
        ROUND(AVG(stat_value_1_ps + stat_value_2_ps)) AS avg_tps,
        ROUND(MAX(stat_value_1_ps + stat_value_2_ps)) AS max_tps,
        ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY stat_value_1_ps + stat_value_2_ps ASC)) AS p99_tps,
        ROUND(AVG(stat_value_3_ps/POWER(10, 6))) AS avg_redo_mbps,
        ROUND(MAX(stat_value_3_ps/POWER(10, 6))) AS max_redo_mbps,
        ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY stat_value_3_ps/POWER(10, 6) ASC)) AS p99_redo_mbps,
        C##IOD.IOD_META_AUX.get_region(i.host_name) AS region,
        C##IOD.IOD_META_AUX.get_region_acronym(C##IOD.IOD_META_AUX.get_region(i.host_name)) AS rgn,
        C##IOD.IOD_META_AUX.get_locale(LOWER(p.value)) AS locale,
        i.host_name,
        c.host_class,
        d.db_unique_name,
        c.version AS db_version,
        (SELECT COUNT(*) FROM v$containers) AS pdbs,
        c.u02_total_tb, 
        c.u02_used_tb, 
        c.u02_used_pct
  FROM  sysstat_per_sec s,
        v$instance i,
        v$database d,
        v$parameter p,
        dbc c
 WHERE  p.name = 'db_domain'
  GROUP BY
        C##IOD.IOD_META_AUX.get_region(i.host_name),
        C##IOD.IOD_META_AUX.get_region_acronym(C##IOD.IOD_META_AUX.get_region(i.host_name)),
        C##IOD.IOD_META_AUX.get_locale(LOWER(p.value)),
        i.host_name,
        c.host_class,
        d.db_unique_name,
        c.version,
        c.u02_total_tb, 
        c.u02_used_tb, 
        c.u02_used_pct
/
