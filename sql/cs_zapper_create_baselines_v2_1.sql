SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON HEA OFF PAGES 0 TIMI ON TIM ON;
--
VAR b_report_only VARCHAR2(1);
VAR b_debug VARCHAR2(1);
VAR x_plans_create NUMBER;
VAR x_plans_disable NUMBER;
VAR x_output CLOB;
--
EXEC :b_report_only := 'Y';
EXEC :b_debug := 'Y';
--
/* ------------------------------------------------------------------------------------ */
DECLARE /* ZAPPER-19 v2.1 CREATE */
  -- input and output variables
  l_report_only                 VARCHAR2(1)     := :b_report_only; /* [N|Y] */
  l_debug                       VARCHAR2(1)     := :b_debug; /* [N|Y] */
  x_plans_create                NUMBER          := NULL;
  x_plans_disable               NUMBER          := NULL;
  x_output                      CLOB            := NULL;
  -- global thresholds to qualify for create baseline 
  l_cursor_age_days             NUMBER := 3/24; -- cursor must be older than this threshold to qualify (i.e. cursor is mature)
  l_last_active_time_in_days    NUMBER := 3/24; -- cursor must have been active within this threshold to qualify (rationale: cursor is still in use, so most probably it will remain in shared pool while baseline is created, avoiding ORA-13831)
  -- row-by-row profile (rbr)
  l_r_c_rows_per_exec           NUMBER := 2000; -- for row-by-row processing, up to how many rows per execution to qualify
  l_r_c_table_rows              NUMBER := 500; -- for row-by-row processing, number of rows on largest table must be higher than this threshold to qualify
  l_r_c_executions              NUMBER := 1000; -- for row-by-row processing, sum of number of executions must be higher than this threshold to qualify
  -- set profile (set)
  l_s_c_table_rows              NUMBER := 5000; -- for set processing, number of rows on largest table must be higher than this threshold to qualify
  l_s_c_executions              NUMBER := 10; -- for set processing, sum of number of executions mus be higher than this threshold to qualify
  -- row-by-row thresholds to qualify for create baseline
  l_r_c_bg_per_row_or_exec      NUMBER := 25; -- for row-by-row processing, buffer gets per row (or buffer gets per execution when average rows per execution is less than 1) must be less than this threshold to qualify
  l_r_c_us_per_row_or_exec      NUMBER := 500; -- for row-by-row processing, cpu microseconds per row (or cpu microseconds per execution when average rows per execution is less than 1) must be less than this threshold to qualify
  l_r_c_us_per_exec             NUMBER := 1 * POWER(10, 6); -- for row-by-row processing processing, cpu microseconds per per execution must be less than this threshold to qualify
  l_r_c_aas_on_cpu              NUMBER := 2.5; -- for row-by-row processing, up to how many sessions on cpu to qualify
  -- set thresholds to qualify for create baseline
  l_s_c_us_per_exec             NUMBER := 20 * POWER(10, 6); -- for set processing, cpu microseconds per per execution must be less than this threshold to qualify
  l_s_c_bg_per_exec_factor      NUMBER := 2.5; -- for set processing, buffer gets per execution must be less than: this threshold times the number of blocks on largest tables to qualify (e.g.: largest accessed tables is 10,000 blocks, then 1 execution should consume less buffer gets than THIS FACTOR times 10,000)
  l_s_c_aas_on_cpu              NUMBER := 1; -- for set processingg, up to how many sessions on cpu to qualify
  -- staging variables
  l_count                       INTEGER;
  l_time                        DATE;
  l_plans                       NUMBER;
  l_plans_create                NUMBER := 0;
  l_plans_disable               NUMBER := 0;
  l_description                 VARCHAR2(4000);
  l_ORA_13831                   VARCHAR2(1); /* [N|Y] */
  l_ORA_06512                   VARCHAR2(1); /* [N|Y] */
  -- most recent awr snapshot
  l_snap_id                     NUMBER;
  l_dbid                        NUMBER;
  l_instance_number             NUMBER;
  l_snap_interval_seconds       NUMBER;
  -- staging arrays with selected plans for baseline creation
  l_signature                   DBMS_UTILITY.number_array;  -- associative array
  l_sql_id                      DBMS_UTILITY.name_array;    -- associative array
  l_plan_hash_value             DBMS_UTILITY.number_array;  -- associative array
  l_table_rows                  DBMS_UTILITY.number_array;  -- associative array
  l_table_block                 DBMS_UTILITY.number_array;  -- associative array
  l_aas_on_cpu                  DBMS_UTILITY.number_array;  -- associative array
  l_matches_rbr_profile         DBMS_UTILITY.name_array;    -- associative array
  l_matches_set_profile         DBMS_UTILITY.name_array;    -- associative array
  l_create_rbr_qualify          DBMS_UTILITY.name_array;    -- associative array
  l_create_set_qualify          DBMS_UTILITY.name_array;    -- associative array
  l_is_cursor_mature            DBMS_UTILITY.name_array;    -- associative array
  l_is_cursor_active            DBMS_UTILITY.name_array;    -- associative array
  --
  PROCEDURE output_line (
    p_line       IN VARCHAR2,
    p_spool_file IN VARCHAR2 DEFAULT 'Y',
    p_alert_log  IN VARCHAR2 DEFAULT 'N'
  ) 
  IS
  BEGIN
    IF p_spool_file = 'Y' THEN
      x_output := x_output||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line||CHR(10); -- return clob
    END IF;
    IF p_alert_log = 'Y' THEN
      SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line); -- write to alert log
    END IF;
  END output_line;
BEGIN
  -- check that both adaptive cursor sharing (acs) and adaptive plans are disabled
  SELECT  COUNT(*) INTO l_count
    FROM  x$ksppi p, x$ksppsv v 
   WHERE  p.ksppinm IN ('optimizer_adaptive_plans', '_optimizer_adaptive_cursor_sharing') AND v.indx = p.indx AND v.ksppstvl = 'TRUE';
  IF l_count > 0 THEN
    :x_output := TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' optimizer_adaptive_plans and/or _optimizer_adaptive_cursor_sharing set to TRUE';
    RETURN;
  END IF;
  --
  WITH
  sn AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            snap_id, dbid, instance_number, (CAST(end_interval_time AS DATE) - CAST(begin_interval_time AS DATE)) * 24 * 3600 AS snap_interval_seconds 
    FROM    dba_hist_snapshot 
    WHERE   end_interval_time < SYSDATE 
    ORDER BY end_interval_time DESC 
    FETCH FIRST 1 ROW ONLY
  ),
  ss AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            h.sql_id, h.plan_hash_value,
            GREATEST(NVL(h.executions_delta, 0), 1) AS awr_executions, 
            h.cpu_time_delta AS awr_cpu_time, 
            h.rows_processed_delta AS awr_rows_processed, 
            h.buffer_gets_delta AS awr_buffer_gets,
            h.cpu_time_delta / POWER(10, 6) / sn.snap_interval_seconds AS awr_aas_on_cpu
    FROM    dba_hist_sqlstat h, sn
    WHERE   h.snap_id = sn.snap_id
    AND     h.dbid = sn.dbid
    AND     h.instance_number = sn.instance_number
  ),
  u AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            u.user_id
    FROM    dba_users u
    WHERE   u.oracle_maintained = 'N'
    AND     u.username NOT LIKE 'C##%'
    GROUP BY
            u.user_id
  ),
  q AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            s.exact_matching_signature AS signature, s.sql_id, s.plan_hash_value, s.sql_plan_baseline AS plan_name,
            s.parsing_user_id, s.parsing_schema_id, s.hash_value, s.address,
            MIN(TO_DATE(s.first_load_time, 'YYYY-MM-DD/HH24:MI:SS')) AS first_load_time,
            MAX(s.last_active_time) AS last_active_time,
            SUM(s.executions) AS cur_executions,
            SUM(s.cpu_time) AS cur_cpu_time,
            SUM(s.rows_processed) AS cur_rows_processed,
            SUM(s.buffer_gets) AS cur_buffer_gets
    FROM    v$sql s
    WHERE   s.sql_plan_baseline IS NULL
    AND     s.parsing_user_id > 0 -- exclude SYS
    AND     s.parsing_schema_id > 0 -- exclude SYS
    AND     s.parsing_schema_name NOT LIKE 'C##%'
    AND     s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
    AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
    AND     s.cpu_time > 0
    AND     s.buffer_gets > 0
    AND     s.object_status = 'VALID'
    AND     s.is_obsolete = 'N'
    AND     s.is_shareable = 'Y'
    AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
    AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
    AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback
    GROUP BY
            s.exact_matching_signature, s.sql_id, s.plan_hash_value, s.sql_plan_baseline,
            s.parsing_user_id, s.parsing_schema_id, s.hash_value, s.address
    HAVING
            SUM(s.executions) > 0
  ),
  s AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            q.signature, q.sql_id, q.plan_hash_value, q.plan_name,
            q.hash_value, q.address,
            q.first_load_time, q.last_active_time,
            q.cur_executions, q.cur_cpu_time, q.cur_rows_processed, q.cur_buffer_gets,
            ss.awr_executions, ss.awr_cpu_time, ss.awr_rows_processed, ss.awr_buffer_gets,
            ss.awr_aas_on_cpu
    FROM    q, u u1, u u2, ss
    WHERE   u1.user_id = q.parsing_user_id
    AND     u2.user_id = q.parsing_schema_id
    AND     ss.sql_id(+) = q.sql_id
    AND     ss.plan_hash_value(+) = q.plan_hash_value
  )
  SELECT  s.signature, s.sql_id, s.plan_hash_value, 
          t.table_num_rows, t.table_blocks, s.awr_aas_on_cpu,
          -- cursor is mature and active
          CASE WHEN s.first_load_time < SYSDATE - l_cursor_age_days THEN 'Y' ELSE 'N' END AS is_cursor_mature,
          CASE WHEN s.last_active_time > SYSDATE - l_last_active_time_in_days THEN 'Y' ELSE 'N' END AS is_cursor_active,
          -- row-by-row processing: profiling and qualification
          CASE -- rbr profiling
            WHEN  s.cur_rows_processed / s.cur_executions <= l_r_c_rows_per_exec -- cursor
            AND   t.table_num_rows >= l_r_c_table_rows                   
            AND   s.cur_executions >= l_r_c_executions -- cursor
            AND   NVL(s.awr_rows_processed / s.awr_executions, 0) <= l_r_c_rows_per_exec -- awr last snapshot
            THEN 'Y' 
            ELSE 'N' 
          END AS matches_rbr_profile,
          CASE -- rbr create qualification
            WHEN  s.cur_buffer_gets / GREATEST(s.cur_rows_processed, s.cur_executions) <= l_r_c_bg_per_row_or_exec -- cursor
            AND   s.cur_cpu_time / GREATEST(s.cur_rows_processed, s.cur_executions) <= l_r_c_us_per_row_or_exec -- cursor
            AND   s.cur_cpu_time / s.cur_executions <= l_r_c_us_per_exec -- cursor
            AND   NVL(s.awr_buffer_gets / GREATEST(s.awr_rows_processed, s.awr_executions), 0) <= l_r_c_bg_per_row_or_exec -- awr last snapshot
            AND   NVL(s.awr_cpu_time / GREATEST(s.awr_rows_processed, s.awr_executions), 0) <= l_r_c_us_per_row_or_exec -- awr last snapshot
            AND   NVL(s.awr_cpu_time / s.awr_executions, 0) <= l_r_c_us_per_exec -- awr last snapshot
            AND   NVL(s.awr_aas_on_cpu, 0) <= l_r_c_aas_on_cpu -- awr last snapshot
            THEN 'Y' 
            ELSE 'N' 
          END AS create_rbr_qualify,
          -- set processing: profiling and qualification
          CASE -- set profiling
            WHEN  t.table_num_rows >= l_s_c_table_rows                   
            AND   s.cur_executions >= l_s_c_executions -- cursor 
            THEN 'Y' 
            ELSE 'N' 
          END AS matches_set_profile,
          CASE -- set create qualification
            WHEN  s.cur_buffer_gets / s.cur_executions <= l_s_c_bg_per_exec_factor * t.table_blocks -- cursor
            AND   s.cur_cpu_time / s.cur_executions <= l_s_c_us_per_exec -- cursor
            AND   NVL(s.awr_buffer_gets / s.awr_executions, 0) <= l_s_c_bg_per_exec_factor * t.table_blocks -- awr last snapshot
            AND   NVL(s.awr_cpu_time / s.awr_executions, 0) <= l_s_c_us_per_exec -- awr last snapshot
            AND   NVL(s.awr_aas_on_cpu, 0) <= l_s_c_aas_on_cpu -- awr last snapshot   
            THEN 'Y' 
            ELSE 'N' 
          END AS create_set_qualify
  BULK COLLECT INTO 
          l_signature, l_sql_id, l_plan_hash_value, 
          l_table_rows, l_table_block, l_aas_on_cpu,
          l_is_cursor_mature, l_is_cursor_active, 
          l_matches_rbr_profile,
          l_create_rbr_qualify, 
          l_matches_set_profile,
          l_create_set_qualify
  FROM    s
          CROSS APPLY (
              SELECT  MAX(t.num_rows) AS table_num_rows, MAX(t.blocks) AS table_blocks -- rows and blocks could be from different tables and that is intended
              FROM    v$object_dependency d, dba_users u, dba_tables t
              WHERE   d.from_hash = s.hash_value
              AND     d.from_address = s.address
              AND     d.to_type = 2 -- table
              AND     d.to_owner <> 'SYS'
              AND     d.to_owner NOT LIKE 'C##%'
              AND     u.username = d.to_owner
              AND     u.oracle_maintained = 'N'
              AND     t.owner = d.to_owner
              AND     t.table_name = d.to_name
          ) t
  ORDER BY -- performance, so in case a sql has more than on plan, the one with better performance creates a baseline, while the second gets rejected
        s.cur_cpu_time / GREATEST(s.cur_rows_processed, s.cur_executions);
  --
  -- process selected cursors and create baseline if a cursor passes filter criteria for row-by-row processing or set processing
  --
  IF l_signature.LAST >= l_signature.FIRST THEN -- some cursors found
    FOR i IN l_signature.FIRST .. l_signature.LAST
    LOOP
      IF l_debug = 'Y' THEN
        output_line(l_signature(i)||' '||l_sql_id(i)||' '||l_plan_hash_value(i)||' r:'||l_table_rows(i)||' b:'||l_table_block(i)||' aas:'||ROUND(l_aas_on_cpu(i),1)||' m:'||l_is_cursor_mature(i)||' a:'||l_is_cursor_active(i)||' rbr:'||l_matches_rbr_profile(i)||'-'||l_create_rbr_qualify(i)||' set:'||l_matches_set_profile(i)||'-'||l_create_set_qualify(i));
      END IF;
      --
      IF l_is_cursor_mature(i) = 'Y' AND l_is_cursor_active(i) = 'Y' AND ((l_matches_rbr_profile(i) = 'Y' AND l_create_rbr_qualify(i) = 'Y') OR (l_matches_set_profile(i) = 'Y' AND l_create_set_qualify(i) = 'Y')) THEN
        IF l_debug = 'N' THEN
          output_line(l_signature(i)||' '||l_sql_id(i)||' '||l_plan_hash_value(i)||' r:'||l_table_rows(i)||' b:'||l_table_block(i)||' aas:'||ROUND(l_aas_on_cpu(i),1)||' m:'||l_is_cursor_mature(i)||' a:'||l_is_cursor_active(i)||' rbr:'||l_matches_rbr_profile(i)||'-'||l_create_rbr_qualify(i)||' set:'||l_matches_set_profile(i)||'-'||l_create_set_qualify(i));
        END IF;
        --
        IF l_report_only = 'Y' THEN
          output_line('report only: skip creation');
        ELSE
          -- check for potential baseline recently created for this sql: goal is to have only one enabled and accepted plan per signature (a second candidate on same signature would be rejected)
          SELECT COUNT(*) INTO l_count FROM dba_sql_plan_baselines WHERE signature = l_signature(i) AND created > SYSDATE - l_last_active_time_in_days AND enabled = 'YES' AND accepted = 'YES';
          IF l_count > 0 THEN
            output_line('there is a recently created, enabled and accepted baseline for this signature');
          ELSE
            l_time := SYSDATE - (1/24/3600); -- horizon 1 second back, else we may not find new plan(s)
            -- create sql plan baseline
            l_plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => l_sql_id(i), plan_hash_value => l_plan_hash_value(i));
            -- a baseline was successfully created
            IF l_plans > 0 THEN
              l_plans_create := l_plans_create + l_plans;
              -- assembly description
              l_description := 'ZAPPER-19';
              IF    l_matches_rbr_profile(i) = 'Y' AND l_create_rbr_qualify(i) = 'Y' THEN l_description := l_description||' [RBR]'; 
              ELSIF l_matches_set_profile(i) = 'Y' AND l_create_set_qualify(i) = 'Y' THEN l_description := l_description||' [SET]'; 
              ELSE  l_description := l_description||' [UNK]'; 
              END IF;
              l_description := l_description||' SQL_ID='||l_sql_id(i)||' PHV='||l_plan_hash_value(i)||' ROWS='||l_table_rows(i)||' BLOCKS='||l_table_block(i)||' AAS='||ROUND(l_aas_on_cpu(i),1)||' CREATED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS');
              -- validate for portantial bugs and update description of plan just created
              FOR j IN (SELECT sql_handle, plan_name FROM dba_sql_plan_baselines WHERE signature = l_signature(i) AND origin LIKE 'MANUAL-LOAD%' AND created >= l_time AND description IS NULL)
              LOOP
                -- detects if new plan can cause ORA-13831
                SELECT CASE COUNT(*) WHEN 0 THEN 'N' ELSE 'Y' END INTO l_ORA_13831 
                FROM sys.sqlobj$plan p 
                WHERE p.signature = l_signature(i) AND p.obj_type = 2 AND p.id = 1 AND p.other_xml IS NOT NULL 
                AND p.plan_id <> CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END;
                -- detects if new plan can cause ORA-06512
                SELECT CASE COUNT(*) WHEN 0 THEN 'N' ELSE 'Y' END INTO l_ORA_06512
                FROM sys.sqlobj$ o 
                WHERE o.signature = l_signature(i) AND o.obj_type = 2 
                AND NOT EXISTS (
                  SELECT NULL FROM sys.sqlobj$plan p
                  WHERE p.signature = o.signature
                  AND p.obj_type = o.obj_type
                  AND p.plan_id = o.plan_id
                );
                -- disables plan if at risk of ORA-13831 or ORA-06512
                IF l_ORA_13831 = 'Y' OR l_ORA_06512 = 'Y' THEN
                  l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => j.sql_handle, plan_name => j.plan_name, attribute_name => 'enabled', attribute_value => 'NO');
                  l_plans_disable := l_plans_disable + l_plans;
                  -- update description
                  IF l_ORA_13831 = 'Y' THEN l_description := l_description||' ORA-13831'; END IF;
                  IF l_ORA_06512 = 'Y' THEN l_description := l_description||' ORA-06512'; END IF;
                  l_description := l_description||' DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS');
                END IF;
                output_line(j.sql_handle||' '||j.plan_name||' '||l_description);
                -- update description on baseline
                l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => j.sql_handle, plan_name => j.plan_name, attribute_name => 'description', attribute_value => l_description);
              END LOOP;
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP;
  END IF;
  --
  :x_plans_create := l_plans_create;
  :x_plans_disable := l_plans_disable;
  :x_output := x_output;
END;
/* ------------------------------------------------------------------------------------ */
/
--
PRINT :x_plans_create;
PRINT :x_plans_disable;
PRINT :x_output;
--
SET SERVEROUT OFF HEA ON PAGES 100 TIMI OFF TIM OFF;
--
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
COL created FOR A19 TRUNC;
COL last_modified FOR A19 TRUNC;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL origin FOR A29;
COL description FOR A300;
--
SELECT created, last_modified, signature, sql_handle, plan_name, origin, description
  FROM dba_sql_plan_baselines
 --WHERE created >= SYSDATE - (1/24/60) -- last 1 min
 ORDER BY
       created, last_modified, signature, sql_handle, plan_name, origin, description
/
