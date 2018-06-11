CREATE OR REPLACE PACKAGE BODY &&1..iod_rsrc_mgr AS
/* $Header: iod_rsrc_mgr.pkb.sql 2018-06-09T02:40:30 carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
FUNCTION core_util_perc (
  p_days                   IN NUMBER   DEFAULT gk_core_util_days_default
)
RETURN NUMBER
IS
  l_core_util_perc NUMBER;
BEGIN
  WITH 
  snaps_per_day AS (
  SELECT 24 * 60 / (
         -- awr_snap_interval_minutes
         24 * 60 * EXTRACT(day FROM snap_interval) + 
         60 * EXTRACT(hour FROM snap_interval) + 
         EXTRACT(minute FROM snap_interval) 
         )
         value 
    FROM dba_hist_wr_control
  ),
  threads_per_core AS (
  SELECT (t.value / c.value) value
    FROM v$osstat c, v$osstat t
   WHERE c.con_id = 0
     AND c.stat_name = 'NUM_CPU_CORES' 
     AND t.con_id = c.con_id
     AND t.stat_name = 'NUM_CPUS'
  ),
  busy_time_ts AS (
  SELECT o.snap_id,
         ROW_NUMBER() OVER (ORDER BY o.snap_id DESC) row_number,
         CAST(s.startup_time AS DATE) - (LAG(CAST(s.startup_time AS DATE)) OVER (ORDER BY o.snap_id)) startup_gap,
         ((o.value - LAG(o.value) OVER (ORDER BY o.snap_id)) / 100) /
         ((CAST(s.end_interval_time AS DATE) - CAST(LAG(s.end_interval_time) OVER (ORDER BY o.snap_id) AS DATE)) * 24 * 60 * 60)
         cpu_utilization
    FROM dba_hist_osstat o,
         dba_hist_snapshot s
   WHERE o.dbid = (SELECT dbid FROM v$database)
     AND o.instance_number = SYS_CONTEXT('USERENV', 'INSTANCE')
     AND o.stat_name = 'BUSY_TIME'
     AND s.snap_id = o.snap_id
     AND s.dbid = o.dbid
     AND s.instance_number = o.instance_number
  ),
  avg_cpu_util AS (
  SELECT AVG(cpu_utilization) value
    FROM busy_time_ts
   WHERE startup_gap = 0
     AND row_number <= NVL(GREATEST(p_days * (SELECT value FROM snaps_per_day), 1), 1)
  )
  SELECT ROUND(u.value * t.value) core_util_perc
    INTO l_core_util_perc
    FROM avg_cpu_util u, threads_per_core t;
  --
  RETURN l_core_util_perc;
END core_util_perc;
/* ------------------------------------------------------------------------------------ */
FUNCTION core_util_forecast_date (
  p_core_util_perc         IN NUMBER   DEFAULT gk_core_util_perc_default,
  p_history_days           IN NUMBER   DEFAULT gk_history_days_default
)
RETURN DATE
IS
  l_core_util_forecast_date DATE;
BEGIN
  WITH 
  snaps_per_day AS (
  SELECT 24 * 60 / (
         -- awr_snap_interval_minutes
         24 * 60 * EXTRACT(day FROM snap_interval) + 
         60 * EXTRACT(hour FROM snap_interval) + 
         EXTRACT(minute FROM snap_interval) 
         )
         value 
    FROM dba_hist_wr_control
  ),
  threads_per_core AS (
  SELECT (t.value / c.value) value
    FROM v$osstat c, v$osstat t
   WHERE c.con_id = 0
     AND c.stat_name = 'NUM_CPU_CORES' 
     AND t.con_id = c.con_id
     AND t.stat_name = 'NUM_CPUS'
  ),
  busy_time_ts AS (
  SELECT o.snap_id,
         CAST(s.end_interval_time AS DATE) end_date_time,
         ROW_NUMBER() OVER (ORDER BY o.snap_id DESC) row_number_desc,
         CAST(s.startup_time AS DATE) - (LAG(CAST(s.startup_time AS DATE)) OVER (ORDER BY o.snap_id)) startup_gap,
         ((o.value - LAG(o.value) OVER (ORDER BY o.snap_id)) / 100) /
         ((CAST(s.end_interval_time AS DATE) - CAST(LAG(s.end_interval_time) OVER (ORDER BY o.snap_id) AS DATE)) * 24 * 60 * 60)
         cpu_utilization
    FROM dba_hist_osstat o,
         dba_hist_snapshot s
   WHERE o.dbid = (SELECT dbid FROM v$database)
     AND o.instance_number = SYS_CONTEXT('USERENV', 'INSTANCE')
     AND o.stat_name = 'BUSY_TIME'
     AND s.snap_id = o.snap_id
     AND s.dbid = o.dbid
     AND s.instance_number = o.instance_number
  ),
  cpu_util_ts1 AS (
  SELECT u.snap_id,
         u.end_date_time,
         u.row_number_desc,
         ROW_NUMBER() OVER (ORDER BY u.end_date_time ASC) row_number_asc,
         u.cpu_utilization * t.value y1,
         AVG(u.cpu_utilization * t.value) OVER (ORDER BY u.snap_id ROWS BETWEEN ROUND(s.value) PRECEDING AND CURRENT ROW) y2
    FROM busy_time_ts u,
         threads_per_core t,
         snaps_per_day s
   WHERE 1 = 1
     AND u.startup_gap = 0
     AND u.row_number_desc <= NVL(GREATEST(p_history_days * s.value, 1), 1)
  ),
  lower_bound AS (
  SELECT end_date_time, y1, y2
    FROM cpu_util_ts1
   WHERE row_number_asc = 1
  ),
  upper_bound AS (
  SELECT end_date_time, y1, y2
    FROM cpu_util_ts1
   WHERE row_number_desc = 1
  ),
  cpu_util_ts2 AS (
  SELECT u.snap_id,
         u.end_date_time,
         u.row_number_desc,
         u.row_number_asc,
         (u.end_date_time - b.end_date_time) x,
         u.y1, u.y2 
    FROM cpu_util_ts1 u,
         lower_bound b
  ),
  linear_regr_ts AS (
  SELECT snap_id,
         end_date_time, 
         row_number_desc,
         row_number_asc,
         x,
         y1, y2,
         REGR_SLOPE(y1, x) OVER () m,
         REGR_INTERCEPT(y1, x) OVER () b
    FROM cpu_util_ts2
  ),
  linear_regr AS (
  SELECT m, -- slope
         b -- intercept
    FROM linear_regr_ts
   WHERE row_number_desc = 1 -- it does not matter which row we get (first, last, or anything in between)
  )
  SELECT (u.end_date_time + ((p_core_util_perc - u.y2) / r.m)) forecast_date /* y = (m * x) + b. then x = (y - b) / m */
    INTO l_core_util_forecast_date
    FROM upper_bound u, linear_regr r;
  --
  RETURN l_core_util_forecast_date;
END core_util_forecast_date;
/* ------------------------------------------------------------------------------------ */
FUNCTION core_util_forecast_days (
  p_core_util_perc         IN NUMBER   DEFAULT gk_core_util_perc_default,
  p_history_days           IN NUMBER   DEFAULT gk_history_days_default
)
RETURN NUMBER
IS
BEGIN
  RETURN 
  core_util_forecast_date (
    p_core_util_perc => p_core_util_perc,
    p_history_days   => p_history_days
  ) - SYSDATE;
END core_util_forecast_days;
/* ------------------------------------------------------------------------------------ */
PROCEDURE output (
  p_line       IN VARCHAR2,
  p_spool_file IN VARCHAR2 DEFAULT 'Y',
  p_alert_log  IN VARCHAR2 DEFAULT 'N'
) 
IS
BEGIN
  IF p_spool_file = 'Y' THEN
    SYS.DBMS_OUTPUT.PUT_LINE (a => p_line); -- write to spool file
  END IF;
  IF p_alert_log = 'Y' THEN
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => p_line); -- write to alert log
  END IF;
END output;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE update_cdb_plan_directive (
  p_plan                   IN VARCHAR2 DEFAULT gk_plan,
  p_pluggable_database     IN VARCHAR2,
  p_comment                IN VARCHAR2 DEFAULT 'UPD:'||TO_CHAR(SYSDATE, gk_date_format)||' MANUAL',
  p_shares                 IN NUMBER   DEFAULT gk_shares_default,
  p_utilization_limit      IN NUMBER   DEFAULT gk_utilization_limit_default,
  p_parallel_server_limit  IN NUMBER   DEFAULT gk_parallel_server_limit_def,
  p_aas_p99                IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_aas_p95                IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_con_id                 IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_snap_time              IN DATE     DEFAULT SYSDATE
)
IS
  l_pdb_directive_hist_rec &&1..rsrc_mgr_pdb_hist%ROWTYPE;
BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
  --
  DBMS_RESOURCE_MANAGER.update_cdb_plan_directive (
    plan                      => UPPER(TRIM(p_plan)),
    pluggable_database        => UPPER(TRIM(p_pluggable_database)),
    new_comment               => UPPER(TRIM(p_comment)),
    new_shares                => NVL(p_shares, gk_shares_default),
    new_utilization_limit     => NVL(p_utilization_limit, gk_utilization_limit_default),
    new_parallel_server_limit => NVL(p_parallel_server_limit, gk_parallel_server_limit_def)
  );
  --
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
  --
  l_pdb_directive_hist_rec                       := NULL;
  l_pdb_directive_hist_rec.plan                  := UPPER(TRIM(p_plan));
  l_pdb_directive_hist_rec.pdb_name              := UPPER(TRIM(p_pluggable_database));
  l_pdb_directive_hist_rec.shares                := NVL(p_shares, gk_shares_default);
  l_pdb_directive_hist_rec.utilization_limit     := NVL(p_utilization_limit, gk_utilization_limit_default);
  l_pdb_directive_hist_rec.parallel_server_limit := NVL(p_parallel_server_limit, gk_parallel_server_limit_def);
  l_pdb_directive_hist_rec.aas_p99               := p_aas_p99;
  l_pdb_directive_hist_rec.aas_p95               := p_aas_p95;
  l_pdb_directive_hist_rec.snap_time             := NVL(p_snap_time, SYSDATE);
  l_pdb_directive_hist_rec.con_id                := p_con_id;
  IF l_pdb_directive_hist_rec.con_id IS NULL THEN
    SELECT con_id INTO l_pdb_directive_hist_rec.con_id FROM v$containers WHERE name = l_pdb_directive_hist_rec.pdb_name;
  END IF;
  INSERT INTO &&1..rsrc_mgr_pdb_hist VALUES l_pdb_directive_hist_rec;
  --
END update_cdb_plan_directive;
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset (
  p_report_only            IN VARCHAR2 DEFAULT gk_report_only,
  p_plan                   IN VARCHAR2 DEFAULT gk_plan,
  p_include_pdb_directives IN VARCHAR2 DEFAULT gk_incl_pdb_directives,
  p_switch_plan            IN VARCHAR2 DEFAULT gk_switch_plan
)
IS
  k_report_only CONSTANT VARCHAR2(1) := UPPER(TRIM(p_report_only));
  k_plan CONSTANT VARCHAR2(128) := UPPER(TRIM(p_plan));
  k_include_pdb_directives CONSTANT VARCHAR2(1) := UPPER(TRIM(p_include_pdb_directives));
  k_switch_plan CONSTANT VARCHAR2(1) := UPPER(TRIM(p_switch_plan));
--
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_new_plan BOOLEAN := FALSE;
  l_new_pdb_directive BOOLEAN;
  l_plan_rec dba_cdb_rsrc_plans%ROWTYPE;
  l_plan_config_rec &&1..rsrc_mgr_plan_config%ROWTYPE;
  l_directive_rec dba_cdb_rsrc_plan_directives%ROWTYPE;
  l_dbid NUMBER;
  l_instance_number NUMBER;
  l_num_cpu_cores NUMBER;
  l_num_cpus NUMBER;
  l_num_cpus_per_core NUMBER;
  l_value VARCHAR2(4000);
  l_count NUMBER;
  l_shares NUMBER;
  l_utilization_limit NUMBER;
  l_parallel_server_limit NUMBER;
  l_comments VARCHAR2(2000);
  l_snap_time DATE := SYSDATE;
  l_high_value DATE;
--
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output ('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  SELECT COUNT(*) INTO l_count FROM v$containers;
  -- execute only whene there is more than 1 pdb
  IF l_count < 4 THEN -- consider cdb$root and pdb$seed
    output ('*** to be executed only when there is more than 1 pdb ***');
    RETURN;
  END IF;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_RSRC_MGR','RESET');
  output('--');
  SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
  output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  SELECT value INTO l_value FROM v$parameter WHERE name = 'cpu_count';
  output ('Current cpu_count: '||NVL(l_value, 'null'));
  SELECT value INTO l_value FROM v$parameter WHERE name = 'parallel_servers_target';
  output ('Current parallel_servers_target: '||NVL(l_value, 'null'));
  --
  SELECT dbid INTO l_dbid FROM v$database;
  SELECT instance_number INTO l_instance_number FROM v$instance;
  SELECT value INTO l_num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
  output ('Current NUM_CPU_CORES: '||l_num_cpu_cores);
  --
  SELECT value INTO l_num_cpus FROM v$osstat WHERE stat_name = 'NUM_CPUS';
  l_num_cpus_per_core := ROUND(l_num_cpus / l_num_cpu_cores);
  output('CPU threads per CPU core: '||l_num_cpus_per_core);
  output('Current NUM_CPUS (CPU threads): '||l_num_cpus);
  -- clear pending area from possible prior errors
  -- Avoid "ORA-01422: exact fetch returns more than requested number of rows" on 
  -- SELECT * INTO l_plan_rec FROM dba_cdb_rsrc_plans WHERE plan = k_plan;
  -- when there has been a prior error that left behind a "pending" area, which
  -- may cause duplicate rows on dba_cdb_rsrc_plans.
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  -- read plan
  output('--');
  output('CDB plan: '||k_plan||' - validate');
  BEGIN
    SELECT * INTO l_plan_rec FROM dba_cdb_rsrc_plans WHERE plan = k_plan;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_new_plan := TRUE;
  END;
  -- read plan configuration
  output('--');
  output('CDB plan: '||k_plan||' - configuration');
  BEGIN
    SELECT * INTO l_plan_config_rec FROM &&1..rsrc_mgr_plan_config WHERE plan = k_plan;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_plan_config_rec := NULL;
  END;
  -- create plan
  IF l_new_plan THEN
    IF k_report_only = 'Y' THEN
      output('CDB plan: '||k_plan||' - does not exist');
      output('--');
      RETURN;
    END IF;
    --
    output('CDB plan: '||k_plan||' - create');
    --
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    --
    DBMS_RESOURCE_MANAGER.create_cdb_plan (
      plan    => k_plan,
      comment => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, gk_date_format)
    );
    --
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
    --
    SELECT * INTO l_plan_rec FROM dba_cdb_rsrc_plans WHERE plan = k_plan;
  END IF;
  -- autotask_directive
  l_shares := NVL(l_plan_config_rec.shares_autotask, gk_autotask_shares);
  l_parallel_server_limit := NVL(l_plan_config_rec.parallel_server_limit_autotask, gk_parallel_server_limit_low);
  IF l_num_cpu_cores > 2 THEN
    l_utilization_limit := NVL(l_plan_config_rec.utilization_limit_autotask, gk_utilization_limit_low);
  ELSE
    l_utilization_limit := NVL(l_plan_config_rec.utilization_limit_autotask, gk_utilization_limit_default);
  END IF;
  output('CDB autotask_directive shares target: '||l_shares);
  output('CDB autotask_directive utilization_limit target: '||l_utilization_limit);
  output('CDB autotask_directive parallel_server_limit target: '||l_parallel_server_limit);
  SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = k_plan AND directive_type = 'AUTOTASK' AND pluggable_database = 'ORA$AUTOTASK' AND mandatory = 'YES';
  IF l_directive_rec.shares <> l_shares OR l_directive_rec.utilization_limit <> l_utilization_limit OR l_directive_rec.parallel_server_limit <> l_parallel_server_limit THEN
    output('CDB autotask_directive shares is: '||l_directive_rec.shares||', expecting: '||l_shares);
    output('CDB autotask_directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||l_utilization_limit);
    output('CDB autotask_directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||l_parallel_server_limit);
    --
    IF k_report_only = 'N' THEN
      output('CDB plan: '||k_plan||' - update autotask_directives');
      DBMS_RESOURCE_MANAGER.clear_pending_area;
      DBMS_RESOURCE_MANAGER.create_pending_area;
      --
      DBMS_RESOURCE_MANAGER.update_cdb_autotask_directive (
        plan                      => k_plan,
        new_shares                => l_shares,
        new_utilization_limit     => l_utilization_limit,
        new_parallel_server_limit => l_parallel_server_limit
      );
      --
      DBMS_RESOURCE_MANAGER.validate_pending_area;
      DBMS_RESOURCE_MANAGER.submit_pending_area;
    END IF;
  END IF;
  -- default_directive
  l_shares := NVL(l_plan_config_rec.shares_default, gk_shares_default);
  l_utilization_limit := NVL(l_plan_config_rec.utilization_limit_default, gk_utilization_limit_default);
  l_parallel_server_limit := NVL(l_plan_config_rec.parallel_server_limit_default, gk_parallel_server_limit_def);
  output('CDB default_directive shares target: '||l_shares);
  output('CDB default_directive utilization_limit target: '||l_utilization_limit);
  output('CDB default_directive parallel_server_limit target: '||l_parallel_server_limit);
  SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = k_plan AND directive_type = 'DEFAULT_DIRECTIVE' AND pluggable_database = 'ORA$DEFAULT_PDB_DIRECTIVE' AND mandatory = 'YES';
  IF l_directive_rec.shares <> l_shares OR l_directive_rec.utilization_limit <> l_utilization_limit OR l_directive_rec.parallel_server_limit <> l_parallel_server_limit THEN
    output('CDB default_directive shares is: '||l_directive_rec.shares||', expecting: '||l_shares);
    output('CDB default_directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||l_utilization_limit);
    output('CDB default_directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||l_parallel_server_limit);
    --
    IF k_report_only = 'N' THEN
      output('CDB plan: '||k_plan||' - update default_directives');
      DBMS_RESOURCE_MANAGER.clear_pending_area;
      DBMS_RESOURCE_MANAGER.create_pending_area;
      --
      DBMS_RESOURCE_MANAGER.update_cdb_default_directive (
        plan                      => k_plan,
        new_shares                => l_shares,
        new_utilization_limit     => l_utilization_limit,
        new_parallel_server_limit => l_parallel_server_limit
      );
      --
      DBMS_RESOURCE_MANAGER.validate_pending_area;
      DBMS_RESOURCE_MANAGER.submit_pending_area;
    END IF;
  END IF;
  -- for all existing pdbs
  IF k_include_pdb_directives = 'Y' THEN
    -- delete expired pdb configurations
    IF k_report_only = 'N' THEN
      DELETE &&1..rsrc_mgr_pdb_config WHERE plan = k_plan AND end_date < SYSDATE;
    END IF;
    --
    FOR i IN (WITH
      pdbs AS (
      SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(pdbs) */ -- disjoint for perf reasons
             con_id,
             name pdb_name
        FROM v$containers
       WHERE open_mode = 'READ WRITE'
      ),
      pdbs_hist AS (
      SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(pdbs_hist) */ -- disjoint for perf reasons
             con_id,
             op_timestamp creation_date
        FROM cdb_pdb_history 
       WHERE operation = 'CREATE'
      ),
      ash AS (
      SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ash) */ -- disjoint for perf reasons
             con_id,
             sample_id,
             CAST(MIN(sample_time) AS DATE) min_sample_date,
             SUM(CASE WHEN session_state = 'ON CPU' OR wait_class = 'Scheduler' THEN 1 ELSE 0 END) aas_on_cpu
        FROM dba_hist_active_sess_history
       WHERE dbid = l_dbid
         AND instance_number = l_instance_number
         AND sample_time > SYSDATE - gk_ash_age_days
       GROUP BY
             con_id,
             sample_id
      ),
      aas_on_cpu AS (
      SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ash_on_spu) */ -- disjoint for perf reasons
             con_id,
             MIN(min_sample_date) min_sample_date,
             COUNT(*) data_points,
             PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p95,
             PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p99
        FROM ash
       GROUP BY
              con_id
      )
      SELECT p.con_id,
             p.pdb_name,
             TO_CHAR(h.creation_date, gk_date_format) creation_date,
             TO_CHAR(a.min_sample_date, gk_date_format) min_sample_date,
             a.data_points,
             a.aas_p99,
             a.aas_p95,
             CASE
               WHEN c.utilization_limit IS NOT NULL THEN c.utilization_limit -- pdb configuration
               WHEN SYSDATE - h.creation_date < gk_pdb_age_days OR SYSDATE - a.min_sample_date < gk_pdb_age_days THEN gk_utilization_limit_default -- too recent to know
               WHEN a.aas_p99 IS NULL OR a.aas_p99 <= 1 THEN gk_utilization_limit_low -- pdb is not used
               ELSE GREATEST(LEAST(ROUND(100 * LEAST(a.aas_p99 * gk_utilization_adjust_factor, l_num_cpus) / l_num_cpus), gk_utilization_limit_high), gk_utilization_limit_low) -- bounded
             END  utilization_limit,
             CASE 
               WHEN c.shares IS NOT NULL THEN c.shares  -- pdb configuration
               WHEN SYSDATE - h.creation_date < gk_pdb_age_days OR SYSDATE - a.min_sample_date < gk_pdb_age_days THEN gk_shares_default  -- too recent to know
               WHEN a.aas_p95 IS NULL OR a.aas_p95 <= 1 THEN gk_shares_low -- pdb is not used
               ELSE GREATEST(LEAST(a.aas_p95, gk_shares_high), gk_shares_low) -- bounded
             END shares,
             c.parallel_server_limit
        FROM pdbs p,
             pdbs_hist h,
             aas_on_cpu a,
             &&1..rsrc_mgr_pdb_config c
       WHERE h.con_id = p.con_id
         AND a.con_id(+) = p.con_id
         AND c.plan(+) = k_plan
         AND c.pdb_name(+) = p.pdb_name
       ORDER BY
             con_id)
    LOOP
      output('--');
      output('PDB: '||i.pdb_name||'('||i.con_id||') - validate');
      -- pdb_directive
      BEGIN
        SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = k_plan AND directive_type = 'PDB' AND pluggable_database = i.pdb_name AND mandatory = 'NO';
        l_new_pdb_directive := FALSE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_new_pdb_directive := TRUE;
      END;
      -- create pdb_directive
      IF l_new_pdb_directive THEN
        output('PDB: '||i.pdb_name||'('||i.con_id||') - missing directive');
        output('PDB directive shares: '||i.shares);
        output('PDB directive utilization_limit: '||i.utilization_limit);
        output('PDB directive parallel_server_limit: '||NVL(i.parallel_server_limit, gk_parallel_server_limit_def));
        IF k_report_only = 'N' THEN
          output('PDB: '||i.pdb_name||'('||i.con_id||') - create directive');
          --
          DBMS_RESOURCE_MANAGER.clear_pending_area;
          DBMS_RESOURCE_MANAGER.create_pending_area;
          -- 
          DBMS_RESOURCE_MANAGER.create_cdb_plan_directive (
            plan                      => k_plan,
            pluggable_database        => i.pdb_name,
            comment                   => 'IOD_RSRC_MGR NEW:'||TO_CHAR(SYSDATE, gk_date_format)||' 99th:'||i.aas_p99||' 95th:'||i.aas_p95,
            shares                    => i.shares,
            utilization_limit         => i.utilization_limit,
            parallel_server_limit     => NVL(i.parallel_server_limit, gk_parallel_server_limit_def)
          );
          --
          DBMS_RESOURCE_MANAGER.validate_pending_area;
          DBMS_RESOURCE_MANAGER.submit_pending_area;
        END IF;
      END IF;
      -- update pdb_directive
      SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = k_plan AND directive_type = 'PDB' AND pluggable_database = i.pdb_name AND mandatory = 'NO';
      IF l_directive_rec.shares <> i.shares OR l_directive_rec.utilization_limit <> i.utilization_limit OR l_directive_rec.parallel_server_limit <> NVL(i.parallel_server_limit, gk_parallel_server_limit_def) THEN
        output('PDB directive shares is: '||l_directive_rec.shares||', expecting: '||i.shares);
        output('PDB directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||i.utilization_limit);
        output('PDB directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||NVL(i.parallel_server_limit, gk_parallel_server_limit_def));
        --
        IF k_report_only = 'N' THEN
          output('PDB: '||i.pdb_name||'('||i.con_id||') - update directive');
          --
          l_comments := 'UPD:'||TO_CHAR(l_snap_time, gk_date_format)||' PRIOR_UTIL_LIMIT:'||l_directive_rec.utilization_limit||' PRIOR_SHARES:'||l_directive_rec.shares;
          --
          update_cdb_plan_directive (
            p_plan                  => k_plan,
            p_pluggable_database    => i.pdb_name,
            p_comment               => l_comments,
            p_shares                => i.shares,
            p_utilization_limit     => i.utilization_limit,
            p_parallel_server_limit => NVL(i.parallel_server_limit, gk_parallel_server_limit_def),
            p_aas_p99               => i.aas_p99,
            p_aas_p95               => i.aas_p95,
            p_con_id                => i.con_id,
            p_snap_time             => l_snap_time
          );
        END IF;
      END IF;
    END LOOP;
  END IF; -- k_include_pdb_directives = 'Y'
  -- for all non-existing pdbs
  IF k_include_pdb_directives = 'Y' THEN
    FOR i IN (SELECT pluggable_database, 
                     shares, 
                     utilization_limit,
                     parallel_server_limit
                FROM dba_cdb_rsrc_plan_directives
               WHERE plan = k_plan
                 AND mandatory = 'NO'
                 AND directive_type = 'PDB'
                 AND pluggable_database NOT IN (SELECT name FROM v$containers)       
               ORDER BY 
                     pluggable_database)
    LOOP
      output('--');
      output('PDB: '||i.pluggable_database||' - non-existing');
      output('PDB directive shares: '||i.shares);
      output('PDB directive utilization_limit: '||i.utilization_limit);
      output('PDB directive parallel_server_limit: '||i.parallel_server_limit);
      IF k_report_only = 'N' THEN
        output('PDB: '||i.pluggable_database||' - delete');
        --
        DBMS_RESOURCE_MANAGER.clear_pending_area;
        DBMS_RESOURCE_MANAGER.create_pending_area;
        -- 
        DBMS_RESOURCE_MANAGER.delete_cdb_plan_directive (
          plan                      => k_plan,
          pluggable_database        => i.pluggable_database
        );
        --
        DBMS_RESOURCE_MANAGER.validate_pending_area;
        DBMS_RESOURCE_MANAGER.submit_pending_area;
      END IF;
    END LOOP;
  END IF; -- k_include_pdb_directives = 'Y'
  --
  output('--');
  SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
  output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  IF k_switch_plan = 'Y' AND k_report_only = 'N' AND NVL(l_value, 'null') <> 'FORCE:'||k_plan THEN
    output('--');
    output('CDB plan: '||k_plan||' - switch');
    SELECT value INTO l_value FROM v$parameter WHERE name = 'spfile';
    IF l_value IS NOT NULL THEN
      EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = ''FORCE:'||k_plan||'''';
    END IF;
    -- most probably we dont need this api call below, but oem genetrate ddl produces it as well...
    DBMS_RESOURCE_MANAGER.switch_plan (
      plan_name                     => k_plan,
      allow_scheduler_plan_switches => FALSE
    );
    SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
    output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  END IF;
  output('--');
  --
  -- drop partitions with data older than 2 months (i.e. preserve between 2 and 3 months of history)
  IF k_report_only = 'N' THEN
    FOR i IN (
      SELECT partition_name, high_value, blocks
        FROM dba_tab_partitions
       WHERE table_owner = UPPER('&&1.')
         AND table_name = 'RSRC_MGR_PDB_HIST'
       ORDER BY
             partition_name
    )
    LOOP
      EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
      output('-- PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
        output('-- &&1..IOD_RSRC_MGR.reset: ALTER TABLE &&1..rsrc_mgr_pdb_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
        EXECUTE IMMEDIATE q'[ALTER TABLE &&1..rsrc_mgr_pdb_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
        EXECUTE IMMEDIATE 'ALTER TABLE &&1..rsrc_mgr_pdb_hist DROP PARTITION '||i.partition_name;
      END IF;
    END LOOP;
  END IF;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
END reset;
/* ------------------------------------------------------------------------------------ */
END iod_rsrc_mgr;
/
