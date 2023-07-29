SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL con_id FOR 990 HEA 'Con|ID';
COL con_name FOR A30 HEA 'PDB Name';
COL host_shape FOR A20 HEA 'Host Shape';
COL running_sessions_limit FOR 990.000 HEA 'Running|Sessions|Limit';
COL avg_running_sessions FOR 990.000 HEA 'Avg|Running|Sessions';
COL cpu_allotted_util_perc FOR 990.0 HEA 'CPU|Allotted|Perc';
COL avg_waiting_sessions FOR 9,990.000 HEA 'Avg|Waiting|Sessions';
COL avail_headroom_sessions FOR 990.000 HEA 'Avail|Headroom|Sessions';
COL iops FOR 990;
COL mbps FOR 990.0;
COL pdbs_count FOR 990 HEA 'PDBs|Count';
COL pdb_share FOR 0.000 HEA 'PDB|Share';
COL cpu_consumed_time FOR 9,990.000 HEA 'CPU|Consumed|Seconds';
COL cpu_share FOR 0.000 HEA 'CPU|Share';
COL io_requests FOR 999,990 HEA 'IO|Requests';
COL io_req_share FOR 0.000 HEA 'IO Req|Share';
COL io_megabytes FOR 9,999,990 HEA 'IO|MegaBytes';
COL io_mb_share FOR 0.000 HEA 'IO MBs|Share';
COL used_space_gb FOR 99,990.000 HEA 'Used Disk|Space GBs';
COL space_share FOR 0.000 HEA 'Space|Share';
COL greatest_share FOR 90.000 HEA 'Greatest|Share';
COL cdb_share FOR 0.000 HEA 'CDB|Share';
COL begin_time FOR A19 HEA 'Begin Time';
COL end_time FOR A19 HEA 'End Time';
COL seconds FOR 990 HEA 'Secs';
--
BREAK ON REPORT;
COMPUTE SUM OF running_sessions_limit avg_running_sessions avg_waiting_sessions avail_headroom_sessions iops mbps pdb_share cpu_consumed_time cpu_share io_requests io_req_share io_megabytes io_mb_share used_space_gb space_share greatest_share cdb_share ON REPORT;
--
SELECT r.con_id, r.con_name, s.host_shape,
       r.pdbs_count, r.pdb_share, 
       r.running_sessions_limit, r.avg_running_sessions, r.avg_waiting_sessions, r.avail_headroom_sessions, 
       r.cpu_allotted_util_perc, r.cpu_consumed_time, r.cpu_share, 
       r.iops, r.mbps, r.io_requests, r.io_req_share, r.io_megabytes, r.io_mb_share,
       t.used_space_gb, t.space_share, 
       GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share) AS greatest_share,
       GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share) / SUM(GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share)) OVER() AS cdb_share,
       r.begin_time, r.end_time, r.seconds
  FROM 
    (
            SELECT 
                r.con_id, 
                c.name AS con_name,
                MAX(r.running_sessions_limit) AS running_sessions_limit,
                SUM(r.avg_running_sessions) AS avg_running_sessions,
                NVL(ROUND(100 * SUM(r.avg_running_sessions) / NULLIF(MAX(r.running_sessions_limit), 0), 1), 0) AS cpu_allotted_util_perc,
                SUM(r.avg_waiting_sessions) AS avg_waiting_sessions,
                GREATEST(MAX(r.running_sessions_limit) - SUM(r.avg_running_sessions) - SUM(r.avg_waiting_sessions), 0) AS avail_headroom_sessions,
                SUM(r.io_requests) / (r.end_time - r.begin_time) / 24 / 3600 AS iops,
                SUM(r.io_megabytes) / (r.end_time - r.begin_time) / 24 / 3600 AS mbps,
                COUNT(*) OVER() AS pdbs_count,
                1 / COUNT(*) OVER() AS pdb_share,
                SUM(cpu_consumed_time) / 1000 AS cpu_consumed_time, 
                SUM(cpu_consumed_time) / SUM(SUM(cpu_consumed_time)) OVER() AS cpu_share,
                SUM(io_requests) AS io_requests, 
                SUM(io_requests) / SUM(SUM(io_requests)) OVER() AS io_req_share,
                SUM(io_megabytes) AS io_megabytes,
                SUM(io_megabytes) / SUM(SUM(io_megabytes)) OVER() AS io_mb_share,
                r.begin_time, r.end_time, (r.end_time - r.begin_time) * 24 * 3600 AS seconds
            FROM v$rsrcmgrmetric r, v$containers c
            WHERE r.con_id > 2
            AND c.con_id = r.con_id
            GROUP BY
                r.con_id,
                c.name,
                r.begin_time,
                r.end_time
    ) r,
    (
            SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
                t.con_id,
                SUM(t.used_space * s.block_size) / POWER(10,9) AS used_space_gb,
                SUM(t.used_space * s.block_size) / SUM(SUM(t.used_space * s.block_size)) OVER() AS space_share
            FROM cdb_tablespace_usage_metrics t, cdb_tablespaces s
            WHERE t.con_id > 2
            AND s.con_id = t.con_id
            AND s.tablespace_name = t.tablespace_name
            GROUP BY
                t.con_id
    ) t,
    (
            SELECT s.host_shape
            FROM C##IOD.dbc_system s
            ORDER BY s.timestamp DESC
            FETCH FIRST 1 ROW ONLY
    ) s
WHERE t.con_id = r.con_id
ORDER BY r.con_id
/
--
CLEAR BREAK COMPUTE COLUMNS;
