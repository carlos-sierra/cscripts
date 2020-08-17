ALTER SESSION SET container = CDB$ROOT;
--
COL uom FOR A6;
COL value FOR 999,999,990.0;
COL threshold_violation_factor FOR 999,990.0 HEA 'VIOLATION|FACTOR';
COL message FOR A200 TRUNC;
--
PRO
PRO ME$SQLPERF ALERTS for past &&cs_me_days. days (&&cs_stgtab_owner..alerts_hist)
PRO ~~~~~~~~~~~~~~~~~
--
SELECT snap_time AS alert_time,
       alert_type||CASE WHEN severity IS NOT NULL THEN ' ['||severity||'] ' END||key_value AS message,
       threshold_violation_factor
  FROM &&cs_stgtab_owner..alerts_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
   AND snap_time > SYSDATE - &&cs_me_days.
 ORDER BY
       alert_time,
       alert_type
/
--
COL sql_exec_start FOR A19;
COL sql_exec_id FOR 99999999999;
COL sql_plan_hash_value FOR 9999999999 HEA 'PLAN|HASH_VALUE';
COL sql_plan_line_id FOR 99999 HEA 'PLAN|LINE';
COL last_update_time FOR A19;
COL elapsed_seconds FOR 999,990 HEA 'ELAPSED|SECONDS';
COL sid FOR 99999;
COL serial# FOR 9999999;
COL elapsed_seconds_threshold FOR 999,990 HEA 'SECONDS|THRESHOLD';
COL times_threshold FOR 999,990.0 HEA 'ELAPSED|FACTOR';
COL pdb_name FOR A30 TRUNC;
COL source FOR A6;
COL top FOR 990;
--
PRO
PRO LONG EXECUTIONS top &&cs_me_top. and last &&cs_me_last. for past &&cs_me_days. days (&&cs_stgtab_owner..longexecs_hist_v1)
PRO ~~~~~~~~~~~~~~~
--
WITH
snaps AS (
SELECT sql_exec_start,
       sql_exec_id,
       sql_plan_hash_value,
       sql_plan_line_id,
       last_update_time,
       elapsed_seconds,
       elapsed_seconds_threshold,
       times_threshold,
       source,
       pdb_name,
       sid,
       serial#,
       ROW_NUMBER() OVER (ORDER BY sql_exec_start DESC, sql_exec_id DESC, last_update_time DESC) AS rn1,
       ROW_NUMBER() OVER (ORDER BY elapsed_seconds DESC, times_threshold DESC) AS rn2,
       ROW_NUMBER() OVER (ORDER BY times_threshold DESC, elapsed_seconds DESC) AS rn3
  FROM &&cs_stgtab_owner..longexecs_hist_v1
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
   AND sql_exec_start > SYSDATE - &&cs_me_days.
)
SELECT sql_exec_start,
       CASE WHEN rn2 <= &&cs_me_top. THEN rn2 END AS top,
       sql_exec_id,
       sql_plan_hash_value,
       sql_plan_line_id,
       last_update_time,
       elapsed_seconds,
       elapsed_seconds_threshold,
       times_threshold,
       source,
       pdb_name,
       sid,
       serial#
  FROM snaps
 WHERE rn1 <= &&cs_me_last.
    OR rn2 <= &&cs_me_top.
    OR rn3 <= &&cs_me_top.
 ORDER BY
       sql_exec_start,
       sql_exec_id
/
--
COL snap_time FOR A19;
COL awr_snapshot_end_time FOR A19 HEA 'AWR_SNAP_ENDTIME';
COL db_secs_per_exec_delta FOR 999,990.0 HEA 'SECONDS|PER_EXEC';
COL threshold_violation_factor FOR 999,990.0 HEA 'REGRESSION|FACTOR';
COL db_time_regression_01d FOR 999,990.0 HEA 'DB_TIME|REGR_01d|FACTOR';
COL db_time_regression_07d FOR 999,990.0 HEA 'DB_TIME|REGR_07d|FACTOR';
COL db_time_regression_30d FOR 999,990.0 HEA 'DB_TIME|REGR_30d|FACTOR';
COL db_time_regression_60d FOR 999,990.0 HEA 'DB_TIME|REGR_60d|FACTOR';
COL cpu_time_regression_01d FOR 999,990.0 HEA 'CPU_TIME|REGR_01d|FACTOR';
COL cpu_time_regression_07d FOR 999,990.0 HEA 'CPU_TIME|REGR_07d|FACTOR';
COL cpu_time_regression_30d FOR 999,990.0 HEA 'CPU_TIME|REGR_30d|FACTOR';
COL cpu_time_regression_60d FOR 999,990.0 HEA 'CPU_TIME|REGR_60d|FACTOR';
COL pdb_name FOR A30 TRUNC;
COL top FOR 990;
COL dummy FOR A2 HEA '';
--
PRO
PRO PERFORMANCE REGRESSION top &&cs_me_top. and last &&cs_me_last. for past &&cs_me_days. days (&&cs_stgtab_owner..regress_hist)
PRO ~~~~~~~~~~~~~~~~~~~~~~
--
WITH
snaps AS (
SELECT snap_time,
       GREATEST(db_time_regression_01d, db_time_regression_07d, db_time_regression_30d, db_time_regression_60d, cpu_time_regression_01d, cpu_time_regression_07d, cpu_time_regression_30d, cpu_time_regression_60d) AS threshold_violation_factor,
       db_time_regression_01d,
       db_time_regression_07d,
       db_time_regression_30d,
       db_time_regression_60d,
       cpu_time_regression_01d,
       cpu_time_regression_07d,
       cpu_time_regression_30d,
       cpu_time_regression_60d,
       pdb_name,
       db_secs_per_exec_delta,
       awr_snapshot_end_time,
       ROW_NUMBER() OVER (ORDER BY snap_time DESC, pdb_name) AS rn1,
       ROW_NUMBER() OVER (ORDER BY GREATEST(db_time_regression_01d, db_time_regression_07d, db_time_regression_30d, db_time_regression_60d, cpu_time_regression_01d, cpu_time_regression_07d, cpu_time_regression_30d, cpu_time_regression_60d) DESC, db_secs_per_exec_delta DESC) AS rn2
  FROM &&cs_stgtab_owner..regress_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
   AND snap_time > SYSDATE - &&cs_me_days.
)
SELECT snap_time,
       CASE WHEN rn2 <= &&cs_me_top. THEN rn2 END AS top,
       threshold_violation_factor,
       db_time_regression_01d,
       CASE WHEN db_time_regression_01d = threshold_violation_factor THEN '<-' END AS dummy,
       db_time_regression_07d,
       CASE WHEN db_time_regression_07d = threshold_violation_factor THEN '<-' END AS dummy,
       db_time_regression_30d,
       CASE WHEN db_time_regression_30d = threshold_violation_factor THEN '<-' END AS dummy,
       db_time_regression_60d,
       CASE WHEN db_time_regression_60d = threshold_violation_factor THEN '<-' END AS dummy,
       cpu_time_regression_01d,
       CASE WHEN cpu_time_regression_01d = threshold_violation_factor THEN '<-' END AS dummy,
       cpu_time_regression_07d,
       CASE WHEN cpu_time_regression_07d = threshold_violation_factor THEN '<-' END AS dummy,
       cpu_time_regression_30d,
       CASE WHEN cpu_time_regression_30d = threshold_violation_factor THEN '<-' END AS dummy,
       cpu_time_regression_60d,
       CASE WHEN cpu_time_regression_60d = threshold_violation_factor THEN '<-' END AS dummy,
       pdb_name,
       awr_snapshot_end_time
  FROM snaps
 WHERE rn1 <= &&cs_me_last.
    OR rn2 <= &&cs_me_top.
 ORDER BY
       snap_time,
       pdb_name
/
--
COL snap_time FOR A19;
COL aas_tot FOR 999,990.0 HEA 'AAS|ON_DB';
COL aas_tot_threshold FOR 999,990.0 HEA 'AAS_ON_DB|THRESHOLD';
COL tot_times_threshold FOR 999,990.0 HEA 'AAS_ON_DB|FACTOR';
COL aas_cpu FOR 999,990.0 HEA 'AAS|ON_CPU';
COL aas_cpu_threshold FOR 999,990.0 HEA 'AAS_ON_CPU|THRESHOLD';
COL cpu_times_threshold FOR 999,990.0 HEA 'AAS_ON_CPU|FACTOR';
COL max_as_tot FOR 9,999,990 HEA 'MAX_CONC|SESSIONS|ON_DB';
COL max_as_cpu FOR 9,999,990 HEA 'MAX_CONC|SESSIONS|ON_CPU';
COL pdb_name FOR A30 TRUNC;
COL username FOR A30 TRUNC;
COL top FOR 990;
COL dummy FOR A2 HEA '';
--
PRO
PRO HIGH AVERAGE ACTIVE SESSIONS (AAS) top &&cs_me_top. and last &&cs_me_last. for past &&cs_me_days. days (&&cs_stgtab_owner..highaas_hist)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
WITH
snaps AS (
SELECT snap_time,
       aas_tot,
       aas_tot_threshold,
       tot_times_threshold,
       aas_cpu,
       aas_cpu_threshold,
       cpu_times_threshold,
       max_as_tot,
       max_as_cpu,
       pdb_name,
       username,
       ROW_NUMBER() OVER (ORDER BY snap_time DESC, pdb_name) AS rn1,
       ROW_NUMBER() OVER (ORDER BY aas_tot DESC, aas_cpu DESC, max_as_tot DESC, max_as_cpu DESC) AS rn2,
       ROW_NUMBER() OVER (ORDER BY aas_cpu DESC, aas_tot DESC, max_as_cpu DESC, max_as_tot DESC) AS rn3
  FROM &&cs_stgtab_owner..highaas_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
   AND snap_time > SYSDATE - &&cs_me_days.
)
SELECT snap_time,
       CASE WHEN rn2 <= &&cs_me_top. THEN rn2 END AS top,
       aas_tot,
       aas_tot_threshold,
       tot_times_threshold,
       CASE WHEN tot_times_threshold > aas_tot_threshold AND rn2 <= &&cs_me_top. THEN '<-' END AS dummy,
       aas_cpu,
       aas_cpu_threshold,
       cpu_times_threshold,
       CASE WHEN cpu_times_threshold > aas_cpu_threshold AND rn3 <= &&cs_me_top. THEN '<-' END AS dummy,
       max_as_tot,
       max_as_cpu,
       pdb_name,
       username
  FROM snaps
 WHERE rn1 <= &&cs_me_last.
    OR rn2 <= &&cs_me_top.
    OR rn3 <= &&cs_me_top.
 ORDER BY
       snap_time,
       pdb_name,
       username
/
--
COL snap_time FOR A19;
COL ms_per_execution FOR 999,999,990 HEA 'MILLISECS|PER_EXEC';
COL ms_per_exec_threshold FOR 999,999,990 HEA 'MS_PE|THRESHOLD';
COL aas_tot FOR 999,990.0 HEA 'AAS|ON_DB';
COL aas_tot_threshold FOR 999,990.0 HEA 'AAS_ON_DB|THRESHOLD';
COL pdb_name FOR A30 TRUNC;
COL top FOR 990;
COL dummy FOR A2 HEA '';
--
PRO
PRO NON SCALABLE PLANS top &&cs_me_top. and last &&cs_me_last. for past &&cs_me_days. days (&&cs_stgtab_owner..non_scalable_plan_hist)
PRO ~~~~~~~~~~~~~~~~~~
--
WITH
snaps AS (
SELECT snap_time,
       ms_per_execution,
       ms_per_exec_threshold,
       aas_tot,
       aas_tot_threshold,
       pdb_name,
       ROW_NUMBER() OVER (ORDER BY snap_time DESC, pdb_name) AS rn1,
       ROW_NUMBER() OVER (ORDER BY ms_per_execution DESC, aas_tot DESC) AS rn2,
       ROW_NUMBER() OVER (ORDER BY aas_tot DESC, ms_per_execution DESC) AS rn3
  FROM &&cs_stgtab_owner..non_scalable_plan_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND sql_id = '&&cs_sql_id.'
   AND snap_time > SYSDATE - &&cs_me_days.
)
SELECT snap_time,
       CASE WHEN rn2 <= &&cs_me_top. THEN rn2 END AS top,
       ms_per_execution,
       ms_per_exec_threshold,
       CASE WHEN ms_per_execution > ms_per_exec_threshold AND rn2 <= &&cs_me_top. THEN '<-' END AS dummy,
       aas_tot,
       aas_tot_threshold,
       CASE WHEN aas_tot > aas_tot_threshold AND rn3 <= &&cs_me_top. THEN '<-' END AS dummy,
       pdb_name
  FROM snaps
 WHERE rn1 <= &&cs_me_last.
    OR rn2 <= &&cs_me_top.
    OR rn3 <= &&cs_me_top.
 ORDER BY
       snap_time,
       pdb_name
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
