CREATE OR REPLACE PACKAGE BODY &&1..iod_rsrc_mgr AS
/* $Header: iod_rsrc_mgr.pkb.sql 2018-02-05T15:19:48 carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
PROCEDURE reset (
  p_report_only IN VARCHAR2 DEFAULT gk_report_only,
  p_plan        IN VARCHAR2 DEFAULT gk_plan,
  p_switch_plan IN VARCHAR2 DEFAULT gk_switch_plan
)
IS
  k_date_format CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
  k_pdb_age_days CONSTANT NUMBER := 7;
  k_autotask_shares CONSTANT NUMBER := 1;
  k_shares_low CONSTANT NUMBER := 1;
  k_shares_high CONSTANT NUMBER := 10;
  k_shares_default CONSTANT NUMBER := ROUND((k_shares_low + k_shares_high) / 2);
  k_utilization_limit_low CONSTANT NUMBER := 10;
  k_utilization_limit_high CONSTANT NUMBER := 50;
  k_utilization_limit_default CONSTANT NUMBER := ROUND((k_utilization_limit_low + k_utilization_limit_high) / 2);
  k_parallel_server_limit_low CONSTANT NUMBER := 50;
  k_parallel_server_limit_high CONSTANT NUMBER := 100;
  k_parallel_server_limit_def CONSTANT NUMBER := 50;
--
  l_report_only VARCHAR2(1) := UPPER(TRIM(p_report_only));
  l_plan VARCHAR2(128) := UPPER(TRIM(p_plan));
  l_switch_plan VARCHAR2(1) := UPPER(TRIM(p_switch_plan));
--
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_new_plan BOOLEAN := FALSE;
  l_new_pdb_directive BOOLEAN;
  l_plan_rec dba_cdb_rsrc_plans%ROWTYPE;
  l_directive_rec dba_cdb_rsrc_plan_directives%ROWTYPE;
  l_dbid NUMBER;
  l_instance_number NUMBER;
  l_num_cpu_cores NUMBER;
  l_num_cpu_cores_adjusted NUMBER;
  l_num_cpu_cores_reserved NUMBER;
  l_value VARCHAR2(4000);
  l_count NUMBER;
--
PROCEDURE output (
  p_line IN VARCHAR2
) 
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE (a => p_line);
END output;
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
  output('--');
  SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
  output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  SELECT value INTO l_value FROM v$parameter WHERE name = 'cpu_count';
  output ('Current cpu_count: '||NVL(l_value, 'null'));
  SELECT value INTO l_value FROM v$parameter WHERE name = 'parallel_servers_target';
  output ('Current parallel_servers_target: '||NVL(l_value, 'null'));
  --
  l_num_cpu_cores_reserved := 2;
  SELECT dbid INTO l_dbid FROM v$database;
  SELECT instance_number INTO l_instance_number FROM v$instance;
  SELECT value INTO l_num_cpu_cores FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES';
  output ('Current NUM_CPU_CORES: '||l_num_cpu_cores);
  l_num_cpu_cores_adjusted := l_num_cpu_cores - l_num_cpu_cores_reserved;
  -- read plan
  output('--');
  output('CDB plan: '||l_plan||' - validate');
  BEGIN
    SELECT * INTO l_plan_rec FROM dba_cdb_rsrc_plans WHERE plan = l_plan;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_new_plan := TRUE;
  END;
  -- create plan
  IF l_new_plan THEN
    IF l_report_only = 'Y' THEN
      output('CDB plan: '||l_plan||' - does not exist');
      output('--');
      RETURN;
    END IF;
    --
    output('CDB plan: '||l_plan||' - create');
    --
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    --
    DBMS_RESOURCE_MANAGER.create_cdb_plan (
      plan    => l_plan,
      comment => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, k_date_format)
    );
    --
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
    --
    SELECT * INTO l_plan_rec FROM dba_cdb_rsrc_plans WHERE plan = l_plan;
  END IF;
  -- autotask_directive
  SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_plan AND directive_type = 'AUTOTASK' AND pluggable_database = 'ORA$AUTOTASK' AND mandatory = 'YES';
  IF l_directive_rec.shares <> k_shares_low OR l_directive_rec.utilization_limit <> k_utilization_limit_low OR l_directive_rec.parallel_server_limit <> k_parallel_server_limit_low THEN
    output('CDB autotask_directive shares is: '||l_directive_rec.shares||', expecting: '||k_shares_low);
    output('CDB autotask_directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||k_utilization_limit_low);
    output('CDB autotask_directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||k_parallel_server_limit_low);
    --
    IF l_report_only = 'N' THEN
      output('CDB plan: '||l_plan||' - update autotask_directives');
      DBMS_RESOURCE_MANAGER.clear_pending_area;
      DBMS_RESOURCE_MANAGER.create_pending_area;
      --
      DBMS_RESOURCE_MANAGER.update_cdb_autotask_directive (
        plan                      => l_plan,
        new_shares                => k_shares_low,
        new_utilization_limit     => k_utilization_limit_low,
        new_parallel_server_limit => k_parallel_server_limit_low
      );
      --
      DBMS_RESOURCE_MANAGER.validate_pending_area;
      DBMS_RESOURCE_MANAGER.submit_pending_area;
    END IF;
  END IF;
  -- default_directive
  SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_plan AND directive_type = 'DEFAULT_DIRECTIVE' AND pluggable_database = 'ORA$DEFAULT_PDB_DIRECTIVE' AND mandatory = 'YES';
  IF l_directive_rec.shares <> k_shares_default OR l_directive_rec.utilization_limit <> k_utilization_limit_default OR l_directive_rec.parallel_server_limit <> k_parallel_server_limit_def THEN
    output('CDB default_directive shares is: '||l_directive_rec.shares||', expecting: '||k_shares_default);
    output('CDB default_directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||k_utilization_limit_default);
    output('CDB default_directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||k_parallel_server_limit_def);
    --
    IF l_report_only = 'N' THEN
      output('CDB plan: '||l_plan||' - update default_directives');
      DBMS_RESOURCE_MANAGER.clear_pending_area;
      DBMS_RESOURCE_MANAGER.create_pending_area;
      --
      DBMS_RESOURCE_MANAGER.update_cdb_default_directive (
        plan                      => l_plan,
        new_shares                => k_shares_default,
        new_utilization_limit     => k_utilization_limit_default,
        new_parallel_server_limit => k_parallel_server_limit_def
      );
      --
      DBMS_RESOURCE_MANAGER.validate_pending_area;
      DBMS_RESOURCE_MANAGER.submit_pending_area;
    END IF;
  END IF;
  -- for all existing pdbs
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
       AND con_id != 2
     GROUP BY
           con_id,
           sample_id
    ),
    aas_on_cpu AS (
    SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ash_on_spu) */ -- disjoint for perf reasons
           con_id,
           MIN(min_sample_date) min_sample_date,
           COUNT(*) data_points,
           ROUND(AVG(aas_on_cpu), 3) aas_avg,
           MEDIAN(aas_on_cpu) aas_median,
           PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p90,
           PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p95,
           PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p97,
           PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p99,
           PERCENTILE_DISC(0.999) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p999,
           PERCENTILE_DISC(0.9999) WITHIN GROUP (ORDER BY aas_on_cpu) aas_p9999,
           MAX(aas_on_cpu) aas_max
      FROM ash
     GROUP BY
            con_id
    )
    SELECT p.con_id,
           p.pdb_name,
           TO_CHAR(h.creation_date, k_date_format) creation_date,
           TO_CHAR(a.min_sample_date, k_date_format) min_sample_date,
           a.data_points,
           a.aas_p95,
           a.aas_p99,
           CASE 
             WHEN SYSDATE - h.creation_date < k_pdb_age_days THEN k_shares_default
             WHEN SYSDATE - a.min_sample_date < k_pdb_age_days THEN k_shares_default
             WHEN a.aas_p95 IS NULL THEN k_shares_default
             WHEN a.aas_p95 >= l_num_cpu_cores_adjusted THEN k_shares_high
             WHEN a.aas_p95 <= 1 THEN k_shares_low
             ELSE k_shares_low + ROUND((k_shares_high - k_shares_low) * a.aas_p95 / l_num_cpu_cores_adjusted)
           END shares,
           CASE
             WHEN SYSDATE - h.creation_date < k_pdb_age_days THEN k_utilization_limit_default
             WHEN SYSDATE - a.min_sample_date < k_pdb_age_days THEN k_utilization_limit_default
             WHEN a.aas_p99 IS NULL THEN k_utilization_limit_default
             WHEN a.aas_p99 >= l_num_cpu_cores_adjusted THEN k_utilization_limit_high
             WHEN a.aas_p99 <= 1 THEN k_utilization_limit_low
             ELSE k_utilization_limit_low + ROUND((k_utilization_limit_high - k_utilization_limit_low) * a.aas_p99 * 2 / l_num_cpu_cores_adjusted, -1) / 2
           END  utilization_limit
      FROM pdbs p,
           pdbs_hist h,
           aas_on_cpu a
     WHERE h.con_id = p.con_id
       AND a.con_id(+) = p.con_id
     ORDER BY
           con_id)
  LOOP
    output('--');
    output('PDB: '||i.pdb_name||'('||i.con_id||') - validate');
    -- pdb_directive
    BEGIN
      SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_plan AND directive_type = 'PDB' AND pluggable_database = i.pdb_name AND mandatory = 'NO';
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
      output('PDB directive parallel_server_limit: '||k_parallel_server_limit_def);
      IF l_report_only = 'N' THEN
        output('PDB: '||i.pdb_name||'('||i.con_id||') - create directive');
        --
        DBMS_RESOURCE_MANAGER.clear_pending_area;
        DBMS_RESOURCE_MANAGER.create_pending_area;
        -- 
        DBMS_RESOURCE_MANAGER.create_cdb_plan_directive (
          plan                      => l_plan,
          pluggable_database        => i.pdb_name,
          comment                   => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, k_date_format),
          shares                    => i.shares,
          utilization_limit         => i.utilization_limit,
          parallel_server_limit     => k_parallel_server_limit_def
        );
        --
        DBMS_RESOURCE_MANAGER.validate_pending_area;
        DBMS_RESOURCE_MANAGER.submit_pending_area;
      END IF;
    END IF;
    -- update pdb_directive
    SELECT * INTO l_directive_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_plan AND directive_type = 'PDB' AND pluggable_database = i.pdb_name AND mandatory = 'NO';
    IF l_directive_rec.shares <> i.shares OR l_directive_rec.utilization_limit <> i.utilization_limit OR l_directive_rec.parallel_server_limit <> k_parallel_server_limit_def THEN
      output('PDB directive shares is: '||l_directive_rec.shares||', expecting: '||i.shares);
      output('PDB directive utilization_limit is: '||l_directive_rec.utilization_limit||', expecting: '||i.utilization_limit);
      output('PDB directive parallel_server_limit is: '||l_directive_rec.parallel_server_limit||', expecting: '||k_parallel_server_limit_def);
      --
      IF l_report_only = 'N' THEN
        output('PDB: '||i.pdb_name||'('||i.con_id||') - update directive');
        --
        DBMS_RESOURCE_MANAGER.clear_pending_area;
        DBMS_RESOURCE_MANAGER.create_pending_area;
        --
        DBMS_RESOURCE_MANAGER.update_cdb_plan_directive (
          plan                      => l_plan,
          pluggable_database        => i.pdb_name,
          new_comment               => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, k_date_format),
          new_shares                => i.shares,
          new_utilization_limit     => i.utilization_limit,
          new_parallel_server_limit => k_parallel_server_limit_def
        );
        --
        DBMS_RESOURCE_MANAGER.validate_pending_area;
        DBMS_RESOURCE_MANAGER.submit_pending_area;
      END IF;
    END IF;
  END LOOP;
  -- for all non-existing pdbs
  FOR i IN (SELECT pluggable_database, 
                   shares, 
                   utilization_limit,
                   parallel_server_limit
              FROM dba_cdb_rsrc_plan_directives
             WHERE plan = l_plan
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
    IF l_report_only = 'N' THEN
      output('PDB: '||i.pluggable_database||' - delete');
      --
      DBMS_RESOURCE_MANAGER.clear_pending_area;
      DBMS_RESOURCE_MANAGER.create_pending_area;
      -- 
      DBMS_RESOURCE_MANAGER.delete_cdb_plan_directive (
        plan                      => l_plan,
        pluggable_database        => i.pluggable_database
      );
      --
      DBMS_RESOURCE_MANAGER.validate_pending_area;
      DBMS_RESOURCE_MANAGER.submit_pending_area;
    END IF;
  END LOOP;
  --
  output('--');
  SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
  output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  IF l_switch_plan = 'Y' AND l_report_only = 'N' AND NVL(l_value, 'null') <> 'FORCE:'||l_plan THEN
    output('--');
    output('CDB plan: '||l_plan||' - switch');
    --EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = ''FORCE:'||l_plan||''';';
    DBMS_RESOURCE_MANAGER.switch_plan (
      plan_name                     => l_plan,
      allow_scheduler_plan_switches => FALSE
    );
    SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
    output ('Active resource_manager_plan: '||NVL(l_value, 'null'));
  END IF;
  output('--');
END reset;
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset_iod_cdb_plan
IS
BEGIN
  iod_rsrc_mgr.reset (
    p_report_only => 'N',
    p_plan        => 'IOD_CDB_PLAN',
    p_switch_plan => 'Y'
  );
END reset_iod_cdb_plan;
/* ------------------------------------------------------------------------------------ */  
END iod_rsrc_mgr;
/
