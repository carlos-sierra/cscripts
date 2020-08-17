SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON HEA OFF PAGES 0;
--
VAR b_report_only VARCHAR2(1);
VAR b_window_duration_in_hours NUMBER;
VAR b_bytime VARCHAR2(128);
VAR x_output CLOB;
--
EXEC :b_report_only := 'Y';
EXEC :b_window_duration_in_hours := 4;
EXEC :b_bytime := ';BYHOUR=0,6,12,18;BYMINUTE=0;BYSECOND=0';
--
/* ------------------------------------------------------------------------------------ */
DECLARE /* IOD_AMW v2.1 */
  l_report_only               VARCHAR2(1)     := :b_report_only;              /* [N|Y] */
  l_window_duration_in_hours  NUMBER          := :b_window_duration_in_hours; /* must be >= 4, 4 is recommended (all pdbs have same maintenance window duration) */
  l_bytime                    VARCHAR2(128)   := :b_bytime;                   /* e.g.: ;BYHOUR=0,6,12,18;BYMINUTE=0;BYSECOND=0 */
  x_output                    CLOB            := NULL;
  --
  PROCEDURE output_line (
    p_line       IN VARCHAR2,
    p_spool_file IN VARCHAR2 DEFAULT 'Y',
    p_alert_log  IN VARCHAR2 DEFAULT 'N'
  ) 
  IS
  BEGIN
    IF p_spool_file = 'Y' THEN
      --DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line);
      IF x_output IS NOT NULL THEN x_output := x_output||CHR(10); END IF;
      x_output := x_output||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line;
    END IF;
    IF p_alert_log = 'Y' THEN
      SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' '||p_line); -- write to alert log
    END IF;
  END output_line;
BEGIN
  --
  -- dba_scheduler_global_attribute: global_attributes: default_timezone and log_history
  --
  FOR i IN (SELECT attribute_name, value FROM dba_scheduler_global_attribute WHERE attribute_name IN ('DEFAULT_TIMEZONE', 'LOG_HISTORY', 'MAX_JOB_SLAVE_PROCESSES') ORDER BY attribute_name)
  LOOP
    -- default_timezone: +00:00
    IF i.attribute_name = 'DEFAULT_TIMEZONE' AND NVL(i.value, '-666') <> '+00:00' THEN
      output_line('default_timezone from "'||i.value||'" to "+00:00"');
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE(attribute => 'default_timezone', value => '+00:00');
      END IF;
    END IF;
    -- log_history: 14
    IF i.attribute_name = 'LOG_HISTORY' AND NVL(i.value, '-666') <> '14' THEN
      output_line('log_history from "'||i.value||'" to "14"');
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE(attribute => 'log_history', value => '14');
      END IF;
    END IF;
    -- max_job_slave_processes: 10
    IF i.attribute_name = 'MAX_JOB_SLAVE_PROCESSES' AND NVL(i.value, '-666') <> '10' THEN
      output_line('max_job_slave_processes from "'||i.value||'" to "10"');
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE(attribute => 'max_job_slave_processes', value => '10');
      END IF;
    END IF;
  END LOOP;
  --
  -- dba_advisor_parameters: spm evolve accept plans and accept_sql_profiles: FALSE
  --
  FOR i IN (SELECT task_name, parameter_name, parameter_value FROM dba_advisor_parameters WHERE task_name IN ('SYS_AUTO_SPM_EVOLVE_TASK', 'SYS_AI_SPM_EVOLVE_TASK', 'SYS_AUTO_SQL_TUNING_TASK') AND parameter_name IN ('ACCEPT_PLANS', 'ACCEPT_SQL_PROFILES') ORDER BY task_name, parameter_name, parameter_value)
  LOOP
    -- SYS_AUTO_SPM_EVOLVE_TASK - ACCEPT_PLANS: FALSE
    IF i.task_name = 'SYS_AUTO_SPM_EVOLVE_TASK' AND i.parameter_name = 'ACCEPT_PLANS' AND NVL(i.parameter_value, '-666') <> 'FALSE' THEN
      output_line('accept_plans for '||i.task_name||' from "'||i.parameter_value||'" to "FALSE"');
      IF l_report_only = 'N' THEN
        DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(task_name => i.task_name, parameter => i.parameter_name, value => 'FALSE');
      END IF;
    END IF;
    -- SYS_AI_SPM_EVOLVE_TASK - ACCEPT_PLANS: FALSE
    IF i.task_name = 'SYS_AI_SPM_EVOLVE_TASK' AND i.parameter_name = 'ACCEPT_PLANS' AND NVL(i.parameter_value, '-666') <> 'FALSE' THEN
      output_line('accept_plans for '||i.task_name||' from "'||i.parameter_value||'" to "FALSE"');
      IF l_report_only = 'N' THEN
        DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(task_name => i.task_name, parameter => i.parameter_name, value => 'FALSE');
      END IF;
    END IF;
    -- SYS_AUTO_SQL_TUNING_TASK - ACCEPT_SQL_PROFILES: FALSE (only for ROOT)
    IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' AND i.task_name = 'SYS_AUTO_SQL_TUNING_TASK' AND i.parameter_name = 'ACCEPT_SQL_PROFILES' AND NVL(i.parameter_value, '-666') <> 'FALSE' THEN
      output_line('accept_sql_profiles for '||i.task_name||' from "'||i.parameter_value||'" to "FALSE"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER(parameter => i.parameter_name, value => 'FALSE');
      END IF;
    END IF;
  END LOOP;
  --
  -- dba_autotask_schedule_control: Auto SPM Task, Auto STS Capture Task
  --
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    NULL; -- dba_autotask_schedule_control is not available on 12c
  $ELSE
    FOR i IN (SELECT task_name, enabled FROM dba_autotask_schedule_control WHERE task_name IN ('Auto SPM Task', 'Auto STS Capture Task') ORDER BY task_name)
    LOOP
      -- Auto SPM Task: FALSE
      IF i.task_name = 'Auto SPM Task' AND NVL(i.enabled, '-666') <> 'FALSE' THEN
        output_line(i.task_name||' from "'||i.enabled||'" to "FALSE"');
        IF l_report_only = 'N' THEN
          DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => i.task_name, operation => NULL, window_name => NULL);
        END IF;
      END IF;
      -- Auto STS Capture Task: FALSE
      IF i.task_name = 'Auto STS Capture Task' AND NVL(i.enabled, '-666') <> 'FALSE' THEN
        output_line(i.task_name||' from "'||i.enabled||'" to "FALSE"');
        IF l_report_only = 'N' THEN
          DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => i.task_name, operation => NULL, window_name => NULL);
        END IF;
      END IF;
    END LOOP;
  $END
  --
  -- dba_autotask_client: auto optimizer stats collection, sql tuning advisor, auto space advisor
  --
  FOR i IN (SELECT client_name, status FROM dba_autotask_client WHERE client_name IN ('auto optimizer stats collection', 'sql tuning advisor', 'auto space advisor') ORDER BY client_name)
  LOOP
    -- auto optimizer stats collection: ENABLED
    IF i.client_name = 'auto optimizer stats collection' AND NVL(i.status, '-666') <> 'ENABLED' THEN
      output_line('auto optimizer stats collection from "'||i.status||'" to "ENABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection', operation => NULL, window_name => NULL);
      END IF;
    END IF;
    -- sql tuning advisor: DISABLED
    IF i.client_name = 'sql tuning advisor' AND NVL(i.status, '-666') <> 'DISABLED' THEN
      output_line('sql tuning advisor from "'||i.status||'" to "DISABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'sql tuning advisor', operation => NULL, window_name => NULL);
      END IF;
    END IF;
    -- auto space advisor: DISABLED
    IF i.client_name = 'auto space advisor' AND NVL(i.status, '-666') <> 'DISABLED' THEN
      output_line('auto space advisor from "'||i.status||'" to "DISABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto space advisor', operation => NULL, window_name => NULL);
      END IF;
    END IF;
  END LOOP;
  --
  -- dba_scheduler_windows: disable or enable autotask windows and modify attributes for all windows: resource manager, duration, repeat_interval
  --
  FOR i IN (SELECT window_name, enabled, resource_plan, duration, repeat_interval FROM dba_scheduler_windows ORDER BY window_name)
  LOOP
    -- enable autotask windows currently disabled
    IF i.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND NVL(i.enabled, '-666') <> 'TRUE' THEN
      output_line('enable window:'||i.window_name);
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.ENABLE(name => i.window_name);
      END IF;
    END IF;
    -- disable autotask windows not recognized
    IF i.window_name NOT IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND NVL(i.enabled, '-666') <> 'FALSE' THEN
      output_line('disable window:'||i.window_name);
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.DISABLE(name => i.window_name, force => TRUE);
      END IF;
    END IF;
    -- disable resource manager plan
    IF i.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND i.resource_plan IS NOT NULL THEN
      output_line('disable resource manager for window:'||i.window_name);
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_ATTRIBUTE_NULL(name => i.window_name, attribute => 'resource_plan');
      END IF;
    END IF;
    -- reset duration
    IF i.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND NVL(i.duration, NUMTODSINTERVAL(0,'HOUR')) <> NUMTODSINTERVAL(l_window_duration_in_hours,'HOUR') THEN
      output_line('reset duration for window:'||i.window_name||' from "'||i.duration||'" to "'||NUMTODSINTERVAL(l_window_duration_in_hours,'HOUR')||'"');
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_ATTRIBUTE(name => i.window_name, attribute => 'duration', value => NUMTODSINTERVAL(l_window_duration_in_hours,'HOUR'));
      END IF;
    END IF;
    -- reset repeat_interval
    IF i.window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') AND NVL(i.repeat_interval, '-666') <>  'FREQ=DAILY;BYDAY='||SUBSTR(i.window_name, 1, 3)||l_bytime THEN
      output_line('reset repeat_interval for window:'||i.window_name||' from "'||i.repeat_interval||'" to "FREQ=DAILY;BYDAY='||SUBSTR(i.window_name, 1, 3)||l_bytime||'"');
      IF l_report_only = 'N' THEN
        DBMS_SCHEDULER.SET_ATTRIBUTE(name => i.window_name, attribute => 'repeat_interval', value => 'FREQ=DAILY;BYDAY='||SUBSTR(i.window_name, 1, 3)||l_bytime);
      END IF;
    END IF;
  END LOOP;
  --
  -- dba_autotask_window_clients: modify all expected autotask maintenance windows
  --
  FOR i IN (SELECT window_name, optimizer_stats, sql_tune_advisor, segment_advisor FROM dba_autotask_window_clients WHERE window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW') ORDER BY window_name)
  LOOP
    -- optimizer_stats
    IF NVL(i.optimizer_stats, '-666') <> 'ENABLED' THEN
      output_line('optimizer_stats for '||i.window_name||' from "'||i.optimizer_stats||'" to "ENABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection', operation => NULL, window_name => i.window_name);
      END IF;
    END IF;
    -- sql_tune_advisor
    IF NVL(i.sql_tune_advisor, '-666') <> 'DISABLED' THEN
      output_line('sql_tune_advisor for '||i.window_name||' from "'||i.sql_tune_advisor||'" to "DISABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'sql tuning advisor', operation => NULL, window_name => i.window_name);
      END IF;
    END IF;
    -- segment_advisor
    IF NVL(i.segment_advisor, '-666') <> 'DISABLED' THEN
      output_line('segment_advisor for '||i.window_name||' from "'||i.segment_advisor||'" to "DISABLED"');
      IF l_report_only = 'N' THEN
        DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto space advisor', operation => NULL, window_name => i.window_name);
      END IF;
    END IF;
  END LOOP;
  --
  :x_output := x_output;
END;
/* ------------------------------------------------------------------------------------ */
/
PRINT :x_output;
DECLARE
  l_position INTEGER := 1;
  l_length INTEGER;
BEGIN
  LOOP
    EXIT WHEN :x_output IS NULL OR l_position > DBMS_LOB.getlength(:x_output);
    l_length := INSTR(:x_output||CHR(10), CHR(10), l_position) - l_position;
    DBMS_OUTPUT.put_line(SUBSTR(:x_output||CHR(10), l_position, l_length));
    l_position := l_position + l_length + 1;
  END LOOP;
END;
/
