SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL metric_name FOR A40;
COL metric_dimensions FOR A80;
COL metric_value FOR 999,999,990.000000000;
--
SELECT
'RsrcMgrMetric.'||metric_name AS metric_name,
',"con_name":"'||NVL(con_name, 'null')||'"'||
',"host_shape":"'||NVL(host_shape, 'null')||'"' AS metric_dimensions
, ROUND(metric_value, 9) AS metric_value
FROM (
        SELECT r.con_name, s.host_shape,
            r.running_sessions_limit AS "RunningSessionsLimit",
            r.avg_running_sessions AS "AvgRunningSessions", 
            r.cpu_allotted_util_perc AS "CPUAllottedUtilPerc", 
            r.avg_waiting_sessions AS "AvgWaitingSessions", 
            r.avail_headroom_sessions AS "AvailHeadroomSessions", 
            r.iops AS "IOPS", 
            r.mbps AS "MBPS",
            r.pdbs_count AS "PDBsCount", 
            r.pdb_share AS "PDBShare", 
            r.cpu_consumed_time AS "CPUConsumedTime", 
            r.cpu_share AS "CPUShare", 
            r.io_requests AS "IORequests", 
            r.io_req_share AS "IORequestsShare", 
            r.io_megabytes AS "IOMegabytes", 
            r.io_mb_share AS "IOMegabytesShare",
            t.used_space_gb AS "UsedDiskSpaceGBs", 
            t.space_share AS "UsedDiskSpaceGBsShare", 
            GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share) AS "GreatestShare",
            GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share) / SUM(GREATEST(r.pdb_share, r.cpu_share, r.io_req_share, r.io_mb_share, t.space_share)) OVER() AS "CDBShare",
            --    r.begin_time, r.end_time, 
            r.seconds AS "Seconds"
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
) UNPIVOT (metric_value FOR metric_name IN (
"RunningSessionsLimit",
"AvgRunningSessions", 
"CPUAllottedUtilPerc", 
"AvgWaitingSessions", 
"AvailHeadroomSessions", 
"IOPS", 
"MBPS",
"PDBsCount", 
"PDBShare", 
"CPUConsumedTime", 
"CPUShare", 
"IORequests", 
"IORequestsShare", 
"IOMegabytes", 
"IOMegabytesShare",
"UsedDiskSpaceGBs", 
"UsedDiskSpaceGBsShare", 
"GreatestShare",
"CDBShare",
"Seconds"
))
/
