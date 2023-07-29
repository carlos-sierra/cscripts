DECLARE
--
-- create staging table for baselines if it does not exist
--
  l_count NUMBER;
  l_tablespace_name VARCHAR2(128);
  l_max_bytes NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_tables WHERE owner = 'C##IOD' AND table_name = 'IOD_STGTAB_BASELINE';
  IF l_count = 0 THEN
    SELECT default_tablespace INTO l_tablespace_name FROM dba_users WHERE username = 'C##IOD';
    SELECT NVL(MAX(max_bytes), 0) INTO l_max_bytes FROM dba_ts_quotas WHERE username = 'C##IOD' AND tablespace_name = l_tablespace_name;
    IF l_max_bytes <> -1 THEN -- -1 means unlimited
      EXECUTE IMMEDIATE 'ALTER USER C##IOD QUOTA UNLIMITED ON '||l_tablespace_name;
    END IF;
    DBMS_SPM.create_stgtab_baseline(table_name => 'IOD_STGTAB_BASELINE', table_owner => 'C##IOD', tablespace_name => l_tablespace_name);
  END IF;
END;
/
--
VAR x_report CLOB;
EXEC :x_report := NULL;
SET SERVEROUT ON;
DECLARE
  --
  -- this pl/sql block does a spm plan evolution on a sql statement by creating first a whole fresh set of plans on plan history.
  -- the core concept is that we need a fresh set of binds captured into their respective plans so the plan evolution has a chance of avoiding false positives.
  -- a false positive is a plan which spm evolution suggests it performs better when evaluated using outdated binds (with currently no matching rows).
  -- steps:
  -- 0. validates the sql has executed at least 5 times since last awr, and that at least 5 seconds have passed since such last awr, then computes sleep between operations.
  -- 1. create or recreate a sql plan baseline (enabled and accepted) for whatever is the current plan in use.
  -- 2. drop all other plans on plan history (baselines other than current plan) as well as drop all sql profiles and sql patches.
  -- 3. add fresh entries on plan history for known awr historical plans (enabled but not accepted) using staging sql profiles.
  -- 4. add fresh entries on plan history for all iod historical plans using staging sql profiles.
  -- 5. add fresh entries on plan history for known promising cbo hints (enabled but not accepted).
  -- 6. execute spm plan evolution accepting plan(s) that perform better than current (while using fresh bind variable values).
  -- 7. if some plan(s) was/were evolved then disable baseline for current plan so the evolved plan(s) is/are forced to be used.
  -- 8. briefly monitor the performance of the new plan(s) and if it/them under-perform(s) prior plan then disable evolved plan(s) and restore basline for prior plan.
  --
  p_sql_id CONSTANT VARCHAR2(13) := :cs_sql_id;
  p_signature CONSTANT NUMBER := :cs_signature;
  p_sql_text CONSTANT CLOB := :cs_sql_text;
  p_kiev_table_name VARCHAR2(128) := :cs_kiev_table_name;
  --
  k_begin_time CONSTANT TIMESTAMP(6) := SYSTIMESTAMP;
  k_staging_name CONSTANT VARCHAR2(30) := TO_CHAR(k_begin_time, '"S"YYYYMMDD"T"HH24MISS')||'_'||UPPER(p_sql_id);
  --
  l_seconds_since_last_awr NUMBER;
  l_sleep_seconds NUMBER;
  l_current_et_ms_per_exec NUMBER;
  l_current_delta_exec_count NUMBER;
  l_current_sql_plan_baseline VARCHAR2(128);
  l_current_plan_hash_value NUMBER;
  l_current_sql_profile VARCHAR2(128);
  l_current_sql_patch VARCHAR2(128);
  l_basic_filter VARCHAR2(4000);
  l_begin_snap NUMBER;
  l_end_snap NUMBER;
  l_plans PLS_INTEGER;
  l_evolved_plans PLS_INTEGER;
  l_devolved_plans PLS_INTEGER;
  l_verified_plans PLS_INTEGER;
  l_sql_handle VARCHAR2(128);
  l_current_plan_name VARCHAR2(128);
  l_index INTEGER;
  l_pos INTEGER;
  l_hint VARCHAR2(32767);
  l_profile_attr SYS.SQLPROF_ATTR;
  l_leading_clause_kiev VARCHAR2(256);
  l_name VARCHAR2(128);
  l_task_name VARCHAR2(30);
  l_execution_name VARCHAR2(30);
  l_last_active_time DATE;
  --
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_OUTPUT.put_line(TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' '||p_line);
  END put_line;
BEGIN
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 0. validates the sql has executed at least 5 times since last awr, and that at least 5 seconds have passed since such last awr, then computes sleep between operations.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  put_line('sql_id:'||p_sql_id);
  put_line('signature:'||p_signature);
  --
  -- computes a reasonable sleep time in seconds as 5x the average interval between two execution
  -- computes current performance as average milliseconds per execution during the past 
  --
  SELECT w.age_seconds AS seconds_since_last_awr,
         s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS current_et_ms_per_exec,
         s.delta_execution_count AS current_delta_exec_count
    INTO l_seconds_since_last_awr, l_current_et_ms_per_exec, l_current_delta_exec_count
    FROM v$sqlstats s, 
        (SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ 
                ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds 
            FROM dba_hist_snapshot 
          WHERE end_interval_time < SYSTIMESTAMP) w
  WHERE sql_id = p_sql_id;
  put_line('seconds_since_last_awr:'||l_seconds_since_last_awr);
  put_line('current_delta_exec_count:'||l_current_delta_exec_count);
  put_line('current_et_ms_per_exec:'||ROUND(l_current_et_ms_per_exec, 3));
  --
  IF l_current_delta_exec_count < 5 THEN
    put_line('*** not enough executions:'||l_current_delta_exec_count||' (min is 5)');
    RETURN;
  END IF;
  IF l_seconds_since_last_awr < 5 THEN
    put_line('*** too recent awr snapshot:'||l_seconds_since_last_awr||' seconds (min is 5)');
    RETURN;
  END IF;
  --
  l_sleep_seconds := CEIL(10 * l_seconds_since_last_awr / NULLIF(l_current_delta_exec_count, 0)); -- during these many seconds we would expect the sql to execute 10x on average
  put_line('sleep_seconds (computed):'||l_sleep_seconds);
  l_sleep_seconds := GREATEST(l_sleep_seconds, 10); -- sleep at least 10 seconds between changes
  put_line('sleep_seconds (adjusted):'||l_sleep_seconds);
  --
  -- get current sql_plan_baseline if any, together with plan_hash_value, sql_profile and sql_patch
  --
  SELECT sql_plan_baseline, plan_hash_value, sql_profile, sql_patch, 'sql_id = '''||sql_id||''' AND plan_hash_value <> '||plan_hash_value AS basic_filter
    INTO l_current_sql_plan_baseline, l_current_plan_hash_value, l_current_sql_profile, l_current_sql_patch, l_basic_filter
    FROM v$sql
   WHERE sql_id = p_sql_id
   ORDER BY 
         last_active_time DESC
  FETCH FIRST 1 ROW ONLY;
  -- 
  put_line('current_plan_hash_value:'||l_current_plan_hash_value);
  put_line('current_sql_plan_baseline:'||l_current_sql_plan_baseline);
  put_line('current_sql_profile:'||l_current_sql_profile);
  put_line('current_sql_patch:'||l_current_sql_patch);
  put_line('basic_filter:'||l_basic_filter);
  put_line('staging_name:'||k_staging_name);
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 1. create or recreate a sql plan baseline (enabled and accepted) for whatever is the current plan in use.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- create or replace sql_plan_baseline
  --
  l_plans := 
  DBMS_SPM.load_plans_from_cursor_cache (
    sql_id          => p_sql_id,
    plan_hash_value => l_current_plan_hash_value
  );
  IF l_plans > 0 THEN 
    --
    -- get details about new (or re-created) plan
    --
    SELECT sql_handle, plan_name
      INTO l_sql_handle, l_current_plan_name
      FROM dba_sql_Plan_baselines
     WHERE signature = p_signature
       AND created >= k_begin_time
       AND origin = 'MANUAL-LOAD-FROM-CURSOR-CACHE'
       AND description IS NULL;
    --
    put_line('current_sql_handle:'||l_sql_handle);
    put_line('current_plan_name:'||l_current_plan_name);
    --
    -- update description for new (or re-created) plan
    --
    l_plans := 
    DBMS_SPM.alter_sql_plan_baseline (
      sql_handle      => l_sql_handle,
      plan_name       => l_current_plan_name,
      attribute_name  => 'description',
      attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||l_current_plan_hash_value||' STG='||k_staging_name||' USR=&&who_am_i.'
    );
  END IF;
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 2. drop all other plans on plan history (baselines other than current plan) as well as drop all sql profiles and sql patches.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- drop all plans on plan history other than the one just created for current plan_hash_value
  -- this is needed since on plan evolution a plan is executed together with the binds that were caputred at the time the plan was created into plan history, which could be months old
  --
  FOR i IN (SELECT sql_handle, plan_name
              FROM dba_sql_Plan_baselines
             WHERE signature = p_signature
               AND created < k_begin_time)
  LOOP
    --
    -- remove from staging table a possible old version of the plan to be deleted
    --
    DELETE C##IOD.IOD_STGTAB_BASELINE 
     WHERE signature = p_signature 
       AND sql_handle = i.sql_handle 
       AND obj_name = i.plan_name;
    --
    -- back up the plan to be deleted
    --
    l_plans := 
    DBMS_SPM.pack_stgtab_baseline (
      table_name  => 'IOD_STGTAB_BASELINE', 
      table_owner => 'C##IOD', 
      sql_handle  => i.sql_handle, 
      plan_name   => i.plan_name
    );
    put_line('packed plan '||i.plan_name);
    --
    -- delete the plan
    --
    l_plans := 
    DBMS_SPM.drop_sql_plan_baseline (
      sql_handle => i.sql_handle,
      plan_name  => i.plan_name
    );
    put_line('dropped plan '||i.plan_name);
  END LOOP;
  --
  -- drop all profiles
  --
  FOR i IN (SELECT name
              FROM dba_sql_profiles
             WHERE signature = p_signature)
  LOOP
    DBMS_SQLTUNE.drop_sql_profile (
      name => i.name
    );
    put_line('dropped profile '||i.name);
  END LOOP;
  --
  -- drop all patches
  --
  FOR i IN (SELECT name
              FROM dba_sql_patches
             WHERE signature = p_signature)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch (
      name => i.name
    );
    put_line('dropped patch '||i.name);
  END LOOP;
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 3. add fresh entries on plan history for known awr historical plans (enabled but not accepted) using staging sql profiles.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- for known plans on awr, create a staging sql profile so it would produce a fresh non-accepted plan on plan history
  --
  FOR i IN (WITH 
            plans AS (
            SELECT plan_hash_value, other_xml, ROW_NUMBER() OVER(PARTITION BY plan_hash_value ORDER BY id) AS rn
              FROM dba_hist_sql_plan 
            WHERE sql_id = p_sql_id 
              AND plan_hash_value <> l_current_plan_hash_value
              AND other_xml IS NOT NULL 
            )
            SELECT plan_hash_value, other_xml
              FROM plans
            WHERE rn = 1)
  LOOP
    put_line('plan_hash_value:'||i.plan_hash_value);
    l_index := 1;
    l_profile_attr := SYS.SQLPROF_ATTR('BEGIN_OUTLINE_DATA');
    FOR j IN (SELECT x.outline_hint
                FROM XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(i.other_xml) COLUMNS outline_hint VARCHAR2(4000) PATH '.') x)
    LOOP
      l_hint := j.outline_hint;
      WHILE l_hint IS NOT NULL
      LOOP
        l_index := l_index + 1;
        l_profile_attr.EXTEND;
        IF LENGTH(l_hint) <= 500 THEN
          l_profile_attr(l_index) := l_hint;
          l_hint := NULL;
        ELSE
          l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
          l_profile_attr(l_index) := SUBSTR(l_hint, 1, l_pos);
          l_hint := SUBSTR(l_hint, l_pos);
        END IF;
      END LOOP; 
    END LOOP;
    l_index := l_index + 1;
    l_profile_attr.EXTEND;
    l_profile_attr(l_index) := 'END_OUTLINE_DATA';
    -- FOR j IN 1 .. l_index
    -- LOOP
    --   put_line(l_profile_attr(j));
    -- END LOOP;
    -- creates or replace sql_profile
    DBMS_SQLTUNE.import_sql_profile(
      sql_text    => p_sql_text,
      profile     => l_profile_attr,
      name        => k_staging_name,
      description => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||i.plan_hash_value||' USR=&&who_am_i.',
      category    => 'DEFAULT',
      validate    => TRUE,
      replace     => TRUE
    );
    put_line('created sql profile for:'||i.plan_hash_value);
    -- 
    -- sleeps a few seconds to allow a non-accepted sql plan baseline to be created out of a sql profile
    --
    DBMS_LOCK.sleep(l_sleep_seconds);
    --
    -- drop sql profile (after an expected non-accepted sql plan baseline were created)
    --
    DBMS_SQLTUNE.drop_sql_profile (
      name => k_staging_name
    );
    put_line('dropped sql profile for:'||i.plan_hash_value);
  END LOOP;
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 4. add fresh entries on plan history for all iod historical plans using staging sql profiles.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- for known plans on iod history, create a staging sql profile so it would produce a fresh non-accepted plan on plan history
  --
  FOR i IN (WITH 
            plans AS (
            SELECT plan_id, other_xml, ROW_NUMBER() OVER(PARTITION BY plan_id ORDER BY id) AS rn
              FROM C##IOD.IOD_STGTAB_BASELINE 
            WHERE signature = p_signature 
              AND obj_name NOT IN (SELECT plan_name FROM dba_sql_plan_baselines WHERE signature = p_signature)
              AND other_xml IS NOT NULL 
            )
            SELECT plan_id, other_xml
              FROM plans
            WHERE rn = 1)
  LOOP
    put_line('plan_id:'||i.plan_id);
    l_index := 1;
    l_profile_attr := SYS.SQLPROF_ATTR('BEGIN_OUTLINE_DATA');
    FOR j IN (SELECT x.outline_hint
                FROM XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(i.other_xml) COLUMNS outline_hint VARCHAR2(4000) PATH '.') x)
    LOOP
      l_hint := j.outline_hint;
      WHILE l_hint IS NOT NULL
      LOOP
        l_index := l_index + 1;
        l_profile_attr.EXTEND;
        IF LENGTH(l_hint) <= 500 THEN
          l_profile_attr(l_index) := l_hint;
          l_hint := NULL;
        ELSE
          l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
          l_profile_attr(l_index) := SUBSTR(l_hint, 1, l_pos);
          l_hint := SUBSTR(l_hint, l_pos);
        END IF;
      END LOOP; 
    END LOOP;
    l_index := l_index + 1;
    l_profile_attr.EXTEND;
    l_profile_attr(l_index) := 'END_OUTLINE_DATA';
    -- FOR j IN 1 .. l_index
    -- LOOP
    --   put_line(l_profile_attr(j));
    -- END LOOP;
    -- creates or replace sql_profile
    DBMS_SQLTUNE.import_sql_profile(
      sql_text    => p_sql_text,
      profile     => l_profile_attr,
      name        => k_staging_name,
      description => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PLAN_ID='||i.plan_id||' USR=&&who_am_i.',
      category    => 'DEFAULT',
      validate    => TRUE,
      replace     => TRUE
    );
    put_line('created sql profile for:'||i.plan_id);
    -- 
    -- sleeps a few seconds to allow a non-accepted sql plan baseline to be created out of a sql profile
    --
    DBMS_LOCK.sleep(l_sleep_seconds);
    --
    -- drop sql profile (after an expected non-accepted sql plan baseline were created)
    --
    FOR j IN (SELECT name -- using a cursor since some other process (i.e.: zapper) would have dropped the sql profile
                FROM dba_sql_profiles
               WHERE signature = p_signature)
    LOOP
      DBMS_SQLTUNE.drop_sql_profile (
        name => j.name
      );
      put_line('dropped sql profile '||j.name||' for:'||i.plan_id);
    END LOOP;
  END LOOP;
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 5. add fresh entries on plan history for known promising cbo hints (enabled but not accepted).
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- prepares leading_clause_kiev
  --
  IF p_kiev_table_name IS NOT NULL THEN
    l_leading_clause_kiev := ' LEADING(@SEL$1 '||p_kiev_table_name||')';
  END IF;
  --
  -- for a set of known cbo hints, create staging sql patches to produce fresh non-accepted plan(s) on plan history
  --
  FOR i IN (SELECT 'FIRST_ROWS' AS cbo_hints FROM DUAL
             UNION ALL
            SELECT 'FIRST_ROWS(1)' AS cbo_hints FROM DUAL
             UNION ALL
            SELECT 'FIRST_ROWS(1) OPT_PARAM(''_fix_control'' ''5922070:OFF'')'||l_leading_clause_kiev||' OPT_PARAM(''_b_tree_bitmap_plans'' ''FALSE'') OPT_PARAM(''_no_or_expansion'' ''TRUE'')' AS cbo_hints FROM DUAL)
  LOOP
    put_line('cbo_hints: /*+ '||i.cbo_hints||' */');
    $IF DBMS_DB_VERSION.ver_le_12_1
    $THEN
      DBMS_SQLDIAG_INTERNAL.i_create_patch (
        sql_text    => p_sql_text, 
        hint_text   => i.cbo_hints, 
        name        => k_staging_name, 
        description => 'cs_spbl_evolve.sql /*+ '||i.cbo_hints||' */ USR=&&who_am_i.'
      ); -- 12c
    $ELSE
      l_name := 
      DBMS_SQLDIAG.create_sql_patch (
        sql_text    => p_sql_text, 
        hint_text   => i.cbo_hints, 
        name        => k_staging_name, 
        description => 'cs_spbl_evolve.sql /*+ '||i.cbo_hints||' */ USR=&&who_am_i.'
      ); -- 19c
    $END
    put_line('created sql patch '||k_staging_name||' for: /*+ '||i.cbo_hints||' */');
    -- 
    -- sleeps a few seconds to allow a non-accepted sql plan baseline to be created out of a sql patch
    --
    DBMS_LOCK.sleep(l_sleep_seconds);
    --
    -- drop sql patch (after an expected non-accepted sql plan baseline were created)
    --
    FOR j IN (SELECT name -- using a cursor since some other process (i.e.: zapper) would have dropped the sql patch
                FROM dba_sql_patches
               WHERE signature = p_signature)
    LOOP
      DBMS_SQLDIAG.drop_sql_patch (
        name => j.name
      );
      put_line('dropped sql patch '||j.name||' for: /*+ '||i.cbo_hints||' */');
    END LOOP;
  END LOOP;
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 6. execute spm plan evolution accepting plan(s) that perform better than current (while using fresh bind variable values).
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- create spm evolve task
  --
  l_task_name := 
  DBMS_SPM.create_evolve_task (
    sql_handle  => l_sql_handle,
    time_limit  => LEAST(100 * l_sleep_seconds, 1800), -- seconds
    task_name   => k_staging_name,
    description => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' USR=&&who_am_i.'
  );
  put_line('task_name:'||l_task_name);
  --
  -- execute spm evolve task
  --
  l_execution_name := 
  DBMS_SPM.execute_evolve_task (
    task_name       => l_task_name, 
    execution_name  => k_staging_name,
    execution_desc  => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' USR=&&who_am_i.'
  );
  put_line('execution_name:'||l_execution_name);
  --
  -- gets report of executed evolve task
  --
  :x_report := 
  DBMS_SPM.report_evolve_task (
    task_name       => l_task_name,
    type            => 'TEXT', -- TEXT, HTML, XML
    level           => 'TYPICAL', -- BASIC, TYPICAL, ALL
    section         => 'ALL', -- SUMMARY, FINDINGS, PLANS, INFORMATION, ERRORS, ALL
    execution_name  => l_execution_name
  );
  --
  -- implement spm evolved plans
  --
  l_plans := 
  DBMS_SPM.implement_evolve_task (
    task_name       => l_task_name,
    execution_name  => l_execution_name
  );
  put_line('implemented plans:'||l_plans||' (could be overstated)');
  --
  -- drop spm evolve task
  --
  DBMS_SPM.drop_evolve_task (
    task_name => l_task_name
  );
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- 7. if some plan(s) was/were evolved then disable baseline for current plan so the evolved plan(s) is/are forced to be used.
  --
  -- ****************************************************************************************************************************************************************************************************************
  --
  -- check if there are actually any evolved plans
  --
  SELECT COUNT(*)
    INTO l_evolved_plans
    FROM dba_sql_Plan_baselines
   WHERE signature = p_signature
     AND plan_name <> l_current_plan_name
     AND created >= k_begin_time
     AND origin <> 'MANUAL-LOAD-FROM-CURSOR-CACHE'
     AND accepted = 'YES'
     AND description IS NULL;
  put_line('evolved_plans:'||l_evolved_plans);
  --
  -- if there were evolved plan(s) then disable current plan and verify performance of new plan(s)
  --
  IF l_evolved_plans > 0 THEN
    l_last_active_time := SYSDATE;
    --
    -- disable current plan and sleep
    --
    l_plans := 
    DBMS_SPM.alter_sql_plan_baseline (
      sql_handle      => l_sql_handle,
      plan_name       => l_current_plan_name,
      attribute_name  => 'enabled',
      attribute_value => 'NO'
    );
    l_plans := 
    DBMS_SPM.alter_sql_plan_baseline (
      sql_handle      => l_sql_handle,
      plan_name       => l_current_plan_name,
      attribute_name  => 'description',
      attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||l_current_plan_hash_value||' STG='||k_staging_name||' USR=&&who_am_i. DISABLED'
    );
    put_line('disabled current_plan_name:'||l_current_plan_name);
    -- 
    -- sleeps a few seconds to allow evolved plan(s) to spin some executions
    --
    DBMS_LOCK.sleep(2 * l_sleep_seconds);
    --
    -- ****************************************************************************************************************************************************************************************************************
    --
    -- 8. briefly monitor the performance of the new plan(s) and if it/them under-perform(s) prior plan then disable evolved plan(s) and restore basline for prior plan.
    --
    -- ****************************************************************************************************************************************************************************************************************
    --
    -- verifies the performance of evolved plans and if worse than current plan then disable (devolve)
    --
    l_devolved_plans := 0;
    l_verified_plans := 0;
    FOR i IN (SELECT sql_plan_baseline, plan_hash_value,
                     SUM(executions) AS executions,
                     SUM(elapsed_time)/GREATEST(SUM(executions),1)/1e3 AS et_ms_per_exec
                FROM v$sql
               WHERE sql_id = p_sql_id
                 AND sql_plan_baseline IS NOT NULL
                 AND sql_plan_baseline <> l_current_sql_plan_baseline
                 AND last_active_time >= l_last_active_time
               GROUP BY
                     sql_plan_baseline, plan_hash_value)
    LOOP
      put_line('plan:'||i.sql_plan_baseline||' phv:'||i.plan_hash_value||' executions:'||i.executions||' et_ms_per_exec:'||i.et_ms_per_exec);
      --
      -- if new plan has no executions or its performance is worse than current then disable it
      --
      IF i.executions = 0 OR i.et_ms_per_exec > l_current_et_ms_per_exec THEN
        l_plans := 
        DBMS_SPM.alter_sql_plan_baseline (
          sql_handle      => l_sql_handle,
          plan_name       => i.sql_plan_baseline,
          attribute_name  => 'enabled',
          attribute_value => 'NO'
        );
        l_plans := 
        DBMS_SPM.alter_sql_plan_baseline (
          sql_handle      => l_sql_handle,
          plan_name       => i.sql_plan_baseline,
          attribute_name  => 'description',
          attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||i.plan_hash_value||'EXEC='||i.executions||' MS_PER_EXEC:'||ROUND(i.et_ms_per_exec, 3)||' USR=&&who_am_i. DISABLED'
        );
        put_line('disabled evolved_plan_name:'||i.sql_plan_baseline);
        l_devolved_plans := l_devolved_plans + l_plans;
      ELSE -- evolved plan had some executions and its performance is better than current
        --
        -- document this plan has been evolved (and verified)
        --
        l_plans := 
        DBMS_SPM.alter_sql_plan_baseline (
          sql_handle      => l_sql_handle,
          plan_name       => i.sql_plan_baseline,
          attribute_name  => 'description',
          attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||i.plan_hash_value||' EXECS='||i.executions||' MS_PER_EXEC:'||ROUND(i.et_ms_per_exec, 3)||' USR=&&who_am_i. VERIFIED EVOLVED'
        );
        put_line('verified evolved_plan_name:'||i.sql_plan_baseline);
        l_verified_plans := l_verified_plans + l_plans;
      END IF;
    END LOOP;
    put_line('devolved_plans:'||l_devolved_plans);
    put_line('verified_plans:'||l_verified_plans);
    --
    -- if none of the evolved plans passed verification then re-enable current plan
    --
    IF l_verified_plans = 0 THEN
      --
      -- re-enable current plan 
      --
      l_plans := 
      DBMS_SPM.alter_sql_plan_baseline (
        sql_handle      => l_sql_handle,
        plan_name       => l_current_plan_name,
        attribute_name  => 'enabled',
        attribute_value => 'YES'
      );
      l_plans := 
      DBMS_SPM.alter_sql_plan_baseline (
        sql_handle      => l_sql_handle,
        plan_name       => l_current_plan_name,
        attribute_name  => 'description',
        attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' PHV='||l_current_plan_hash_value||' STG='||k_staging_name||' USR=&&who_am_i. RE-ENABLED'
      );
      put_line('re-enabled current_plan_name:'||l_current_plan_name);
    END IF;
    --
    -- disable any other evolved plan that was not verified
    --
    FOR i IN (SELECT plan_name
                FROM dba_sql_Plan_baselines
              WHERE signature = p_signature
                AND created >= k_begin_time
                AND plan_name <> l_current_plan_name
                AND origin <> 'MANUAL-LOAD-FROM-CURSOR-CACHE'
                AND description IS NULL
                AND accepted = 'YES'
                AND enabled = 'YES')
    LOOP
      l_plans := 
      DBMS_SPM.alter_sql_plan_baseline (
        sql_handle      => l_sql_handle,
        plan_name       => i.plan_name,
        attribute_name  => 'enabled',
        attribute_value => 'NO'
      );
      l_plans := 
      DBMS_SPM.alter_sql_plan_baseline (
        sql_handle      => l_sql_handle,
        plan_name       => i.plan_name,
        attribute_name  => 'description',
        attribute_value => 'cs_spbl_evolve.sql SQL_ID='||p_sql_id||' USR=&&who_am_i. UNVERIFIED DISABLED'
      );
      put_line('disabled unverified plan_name:'||i.plan_name);
    END LOOP;
  END IF;
END;
/
--
SET HEA OFF;
PRINT x_report;
SET HEA ON;
SET SERVEROUT OFF;
