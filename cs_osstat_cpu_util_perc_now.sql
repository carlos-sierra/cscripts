----------------------------------------------------------------------------------------
--
-- File name:   cs_osstat_cpu_util_perc_now.sql
--
-- Purpose:     CPU Utilization Percent - Now
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/31
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_osstat_cpu_util_perc_now.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
SELECT ROUND(100 * os.busy_time / (os.busy_time + os.idle_time), 2) AS cpu_util_perc
FROM (
SELECT NULLIF(GREATEST(busy_t2.value - busy_t1.value, 0), 0) AS busy_time, NULLIF(GREATEST(idle_t2.value - idle_t1.value, 0), 0) AS idle_time
FROM
(SELECT value FROM dba_hist_osstat WHERE stat_name = 'BUSY_TIME' ORDER BY snap_id DESC NULLS LAST FETCH FIRST 1 ROW ONLY) busy_t1,
(SELECT value FROM dba_hist_osstat WHERE stat_name = 'IDLE_TIME' ORDER BY snap_id DESC NULLS LAST FETCH FIRST 1 ROW ONLY) idle_t1,
(SELECT value FROM v$osstat WHERE stat_name = 'BUSY_TIME') busy_t2,
(SELECT value FROM v$osstat WHERE stat_name = 'IDLE_TIME') idle_t2
) os
/
