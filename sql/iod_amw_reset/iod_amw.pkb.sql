CREATE OR REPLACE PACKAGE BODY &&1..iod_amw AS
/* $Header: iod_amw.pkb.sql 2018-02-05T15:19:48 carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
gk_client_optimizer_stats  CONSTANT VARCHAR2(4000) := 'auto optimizer stats collection';
gk_client_sql_tune_advisor CONSTANT VARCHAR2(4000) := 'sql tuning advisor';
gk_client_segment_advisor  CONSTANT VARCHAR2(4000) := 'auto space advisor';
/* ------------------------------------------------------------------------------------ */
PROCEDURE output (
  p_line IN VARCHAR2
) 
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE (a => p_line);
END output;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE accept_sql_profiles (
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_enable_or_disable IN VARCHAR2 DEFAULT gk_accept_sql_profiles_status
)
IS
  l_parameter_value VARCHAR2(4000);
BEGIN
  IF UPPER(p_enable_or_disable) NOT IN ('ENABLE', 'DISABLE') THEN
    output('*** accept_sql_profiles expects ENABLE or DISABLE, got "'||p_enable_or_disable||'" instead.');
    RETURN;
  END IF;
  --
  SELECT parameter_value
    INTO l_parameter_value
    FROM dba_advisor_parameters
   WHERE task_name      = 'SYS_AUTO_SQL_TUNING_TASK'
     AND parameter_name = 'ACCEPT_SQL_PROFILES';
  --
  IF UPPER(p_enable_or_disable) = 'DISABLE' AND l_parameter_value = 'TRUE' THEN
    output('DISABLE SYS_AUTO_SQL_TUNING_TASK.ACCEPT_SQL_PROFILES with DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER');
    IF p_report_only = 'N' THEN
      DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER('ACCEPT_SQL_PROFILES', 'FALSE');
    END IF;
  ELSIF UPPER(p_enable_or_disable) = 'ENABLE' AND l_parameter_value = 'FALSE' THEN
    output('ENABLE SYS_AUTO_SQL_TUNING_TASK.ACCEPT_SQL_PROFILES with DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER');
    IF p_report_only = 'N' THEN
      DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER('ACCEPT_SQL_PROFILES', 'TRUE');
    END IF;
  END IF;
END accept_sql_profiles;
/* ------------------------------------------------------------------------------------ */
FUNCTION con_id (
 p_pdb_name IN VARCHAR2
)
RETURN NUMBER
IS
  l_con_id NUMBER;
BEGIN
  SELECT con_id INTO l_con_id FROM v$containers WHERE name = UPPER(p_pdb_name);
  RETURN l_con_id;
END con_id;
/* ------------------------------------------------------------------------------------ */
PROCEDURE auto_spm_evolve (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_enable_or_disable IN VARCHAR2 DEFAULT gk_auto_spm_evolve_status
)
IS
  l_con_id NUMBER;
  l_parameter_value VARCHAR2(4000);
  l_value VARCHAR2(12);
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
BEGIN
  IF UPPER(p_enable_or_disable) NOT IN ('ENABLE', 'DISABLE') THEN
    output('*** auto_spm_evolve expects ENABLE or DISABLE, got "'||p_enable_or_disable||'" instead.');
    RETURN;
  END IF;
  --
  l_con_id := con_id(p_pdb_name);
  --
  SELECT parameter_value
    INTO l_parameter_value
    FROM cdb_advisor_parameters
   WHERE task_name      = 'SYS_AUTO_SPM_EVOLVE_TASK'
     AND parameter_name = 'ACCEPT_PLANS'
     AND con_id         = l_con_id;
  --
  IF UPPER(p_enable_or_disable) = 'DISABLE' AND l_parameter_value = 'TRUE' THEN
    l_value := 'FALSE';
  ELSIF UPPER(p_enable_or_disable) = 'ENABLE' AND l_parameter_value = 'FALSE' THEN
    l_value := 'TRUE';
  END IF;
  --
  IF l_value IS NOT NULL THEN
    output(UPPER(p_enable_or_disable)||' SYS_AUTO_SPM_EVOLVE_TASK.ACCEPT_PLANS with DBMS_SPM.SET_EVOLVE_TASK_PARAMETER');
  END IF;
  --
  IF l_value IS NOT NULL AND p_report_only = 'N' THEN
    l_statement := 
    q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
    q'[DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(task_name => :task_name, parameter => :parameter, value => :value); ]'||CHR(10)||
    q'[COMMIT; END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_pdb_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':task_name', value => 'SYS_AUTO_SPM_EVOLVE_TASK');
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':parameter', value => 'ACCEPT_PLANS');
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':value', value => l_value);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  END IF;  
END auto_spm_evolve;
/* ------------------------------------------------------------------------------------ */
PROCEDURE scheduler_window (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_enable_or_disable IN VARCHAR2
)
IS
  l_con_id NUMBER;
  l_parameter_value VARCHAR2(4000);
  l_value VARCHAR2(12);
  l_2nd_param VARCHAR2(4000);
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
BEGIN
  IF UPPER(p_enable_or_disable) NOT IN ('ENABLE', 'DISABLE') THEN
    output('*** scheduler_window "'||p_window_name||'" expects ENABLE or DISABLE, got "'||p_enable_or_disable||'" instead.');
    RETURN;
  END IF;
  --
  l_con_id := con_id(p_pdb_name);
  --
  SELECT enabled
    INTO l_parameter_value
    FROM cdb_scheduler_windows
   WHERE owner = 'SYS'
     AND window_name = p_window_name
     AND con_id = l_con_id;
  --
  IF UPPER(p_enable_or_disable) = 'DISABLE' AND l_parameter_value = 'TRUE' THEN
    l_value := 'DISABLE';
    l_2nd_param := ', force => TRUE';
  ELSIF UPPER(p_enable_or_disable) = 'ENABLE' AND l_parameter_value = 'FALSE' THEN
    l_value := 'ENABLE';
    l_2nd_param := NULL;
  END IF;
  --
  IF l_value IS NOT NULL THEN
    output(UPPER(p_enable_or_disable)||' scheduler_window "'||p_window_name||'" with DBMS_SCHEDULER.'||l_value);
  END IF;
  -- cdb_scheduler_windows
  IF l_value IS NOT NULL AND p_report_only = 'N' THEN
    l_statement := 
    q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
    q'[DBMS_SCHEDULER.]'||l_value||q'[(name => :name]'||l_2nd_param||q'[); ]'||CHR(10)||
    q'[COMMIT; END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_pdb_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':name', value => p_window_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  END IF;  
END scheduler_window;
/* ------------------------------------------------------------------------------------ */
PROCEDURE autotask (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2,
  p_client_name       IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_enable_or_disable IN VARCHAR2
)
IS
  l_con_id NUMBER;
  l_parameter_value VARCHAR2(4000);
  l_value VARCHAR2(12);
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
BEGIN
  IF UPPER(p_enable_or_disable) NOT IN ('ENABLE', 'DISABLE') THEN
    output('*** autotask "'||p_client_name||'" expects ENABLE or DISABLE, got "'||p_enable_or_disable||'" instead.');
    RETURN;
  ELSIF LOWER(p_client_name) NOT IN (gk_client_optimizer_stats, gk_client_sql_tune_advisor, gk_client_segment_advisor) THEN
    output('*** autotask "'||p_client_name||'" is invalid.');  
    RETURN;
  END IF;
  --
  l_con_id := con_id(p_pdb_name);
  --
  IF p_window_name IS NULL THEN
    SELECT status
      INTO l_parameter_value
      FROM cdb_autotask_client
     WHERE client_name = p_client_name
       AND con_id      = l_con_id;
  ELSE
    SELECT CASE p_client_name
           WHEN gk_client_optimizer_stats  THEN optimizer_stats
           WHEN gk_client_sql_tune_advisor THEN sql_tune_advisor
           WHEN gk_client_segment_advisor  THEN segment_advisor
           END
      INTO l_parameter_value
      FROM cdb_autotask_window_clients
     WHERE window_name = p_window_name
       AND con_id      = l_con_id;
  END IF;
  --
  IF UPPER(p_enable_or_disable) = 'DISABLE' AND l_parameter_value = 'ENABLED' THEN
    l_value := 'DISABLE';
  ELSIF UPPER(p_enable_or_disable) = 'ENABLE' AND l_parameter_value = 'DISABLED' THEN
    l_value := 'ENABLE';
  END IF;
  --
  IF l_value IS NOT NULL THEN
    IF p_window_name IS NULL THEN
      output(UPPER(p_enable_or_disable)||' autotask "'||p_client_name||'" with DBMS_AUTO_TASK_ADMIN.'||l_value);
    ELSE
      output(UPPER(p_enable_or_disable)||' autotask "'||p_client_name||'" for "'||p_window_name||'" with DBMS_AUTO_TASK_ADMIN.'||l_value);
    END IF;
  END IF;
  --
  IF l_value IS NOT NULL AND p_report_only = 'N' THEN
    IF p_window_name IS NOT NULL THEN 
      scheduler_window (
        p_pdb_name          => p_pdb_name,
        p_report_only       => p_report_only,
        p_window_name       => p_window_name,
        p_enable_or_disable => 'DISABLE'
      );
    END IF;
    l_statement := 
    q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
    q'[DBMS_AUTO_TASK_ADMIN.]'||l_value||q'[(client_name => :client_name, operation => NULL, window_name => :window_name); ]'||CHR(10)||
    q'[COMMIT; END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_pdb_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':client_name', value => p_client_name);
    --DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':operation', value => NULL);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':window_name', value => p_window_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    IF p_window_name IS NOT NULL THEN 
      scheduler_window (
        p_pdb_name          => p_pdb_name,
        p_report_only       => p_report_only,
        p_window_name       => p_window_name,
        p_enable_or_disable => 'ENABLE'
      );
    END IF;
  END IF;  
END autotask;
/* ------------------------------------------------------------------------------------ */
PROCEDURE optimizer_stats (
  p_pdb_name          IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_enable_or_disable IN VARCHAR2 DEFAULT gk_optimizer_stats_status
)
IS
BEGIN
  autotask (
    p_pdb_name          => p_pdb_name,
    p_report_only       => p_report_only,
    p_client_name       => gk_client_optimizer_stats,
    p_window_name       => p_window_name,
    p_enable_or_disable => p_enable_or_disable
  );
END optimizer_stats;
/* ------------------------------------------------------------------------------------ */
PROCEDURE sql_tune_advisor (
  p_pdb_name          IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_enable_or_disable IN VARCHAR2 DEFAULT gk_sql_tune_advisor_status
)
IS
BEGIN
  autotask (
    p_pdb_name          => p_pdb_name,
    p_report_only       => p_report_only,
    p_client_name       => gk_client_sql_tune_advisor,
    p_window_name       => p_window_name,
    p_enable_or_disable => p_enable_or_disable
  );
END sql_tune_advisor;
/* ------------------------------------------------------------------------------------ */
PROCEDURE segment_advisor (
  p_pdb_name          IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_enable_or_disable IN VARCHAR2 DEFAULT gk_segment_advisor_status
)
IS
BEGIN
  autotask (
    p_pdb_name          => p_pdb_name,
    p_report_only       => p_report_only,
    p_client_name       => gk_client_segment_advisor,
    p_window_name       => p_window_name,
    p_enable_or_disable => p_enable_or_disable
  );
END segment_advisor;
/* ------------------------------------------------------------------------------------ */
PROCEDURE set_scheduler_attribute (
  p_pdb_name          IN VARCHAR2,
  p_attribute         IN VARCHAR2,
  p_value             IN VARCHAR2
)
IS
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
BEGIN
  -- dba_scheduler_global_attribute
  l_statement := 
  q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
  q'[DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE(attribute => :attribute, value => :value); ]'||CHR(10)||
  q'[COMMIT; END;]';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_pdb_name);
  DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':attribute', value => p_attribute);
  DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':value', value => p_value);
  l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
END set_scheduler_attribute;
/* ------------------------------------------------------------------------------------ */
PROCEDURE scheduler_window_attribute (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_attribute         IN VARCHAR2,
  p_value             IN VARCHAR2
)
IS
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
BEGIN
  IF LOWER(p_attribute) NOT IN ('repeat_interval', 'duration') THEN
    output('*** scheduler_window "'||p_window_name||'" expects "repeat_interval" or "duration", got "'||p_attribute||'" instead.');
    RETURN;
  ELSE
    output('RESET "'||p_attribute||'" to "'||p_value||'" for "'||p_window_name||'" with DBMS_SCHEDULER.SET_ATTRIBUTE (DISABLE -> RESET -> ENABLE)');
  END IF;
  -- cdb_scheduler_windows
  IF p_report_only = 'N' THEN
    scheduler_window (
      p_pdb_name          => p_pdb_name,
      p_report_only       => p_report_only,
      p_window_name       => p_window_name,
      p_enable_or_disable => 'DISABLE'
    );
    --
    output('RESET window:"'||p_window_name||'", attribute:"'||p_attribute||'", value:"'||p_value||'"');
    l_statement := 
    q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
    q'[DBMS_SCHEDULER.SET_ATTRIBUTE(name => :name, attribute => :attribute, value => :value); ]'||CHR(10)||
    q'[COMMIT; END;]';
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => p_pdb_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':name', value => p_window_name);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':attribute', value => p_attribute);
    DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':value', value => p_value);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    --
    scheduler_window (
      p_pdb_name          => p_pdb_name,
      p_report_only       => p_report_only,
      p_window_name       => p_window_name,
      p_enable_or_disable => 'ENABLE'
    );
  END IF;  
END scheduler_window_attribute;
/* ------------------------------------------------------------------------------------ */
PROCEDURE window_repeat_interval (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_repeat_interval   IN cdb_scheduler_windows.repeat_interval%TYPE
)
IS
  l_con_id NUMBER;
  l_repeat_interval cdb_scheduler_windows.repeat_interval%TYPE;
BEGIN
  l_con_id := con_id(p_pdb_name);
  --
  SELECT repeat_interval
    INTO l_repeat_interval
    FROM cdb_scheduler_windows
   WHERE owner = 'SYS'
     AND window_name = p_window_name
     AND con_id = l_con_id;
  --
  IF l_repeat_interval <> p_repeat_interval THEN
    output('Current "repeat_interval" for "'||p_window_name||'" is "'||l_repeat_interval||'"');
    output('SET "repeat_interval" to "'||p_repeat_interval||'" for "'||p_window_name||'" with DBMS_SCHEDULER.SET_ATTRIBUTE');
    IF p_report_only = 'N' THEN
      scheduler_window_attribute (
        p_pdb_name    => p_pdb_name,
        p_report_only => p_report_only,
        p_window_name => p_window_name,
        p_attribute   => 'repeat_interval',
        p_value       => p_repeat_interval
      );
    END IF;
  END IF;
END window_repeat_interval;
/* ------------------------------------------------------------------------------------ */
PROCEDURE window_duration (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2,
  p_window_name       IN VARCHAR2,
  p_duration          IN cdb_scheduler_windows.duration%TYPE
)
IS
  l_con_id NUMBER;
  l_duration cdb_scheduler_windows.duration%TYPE;
BEGIN
  l_con_id := con_id(p_pdb_name);
  --
  SELECT duration
    INTO l_duration
    FROM cdb_scheduler_windows
   WHERE owner = 'SYS'
     AND window_name = p_window_name
     AND con_id = l_con_id;
  --
  IF l_duration <> p_duration THEN
    output('Current "duration" for "'||p_window_name||'" is "'||l_duration||'"');
    output('SET "duration" to "'||TO_CHAR(p_duration)||'" for "'||p_window_name||'" with DBMS_SCHEDULER.SET_ATTRIBUTE');
    IF p_report_only = 'N' THEN
      scheduler_window_attribute (
        p_pdb_name    => p_pdb_name,
        p_report_only => p_report_only,
        p_window_name => p_window_name,
        p_attribute   => 'duration',
        p_value       => TO_CHAR(p_duration)
      );
    END IF;
  END IF;
END window_duration;
/* ------------------------------------------------------------------------------------ */
PROCEDURE default_timezone (
  p_pdb_name          IN VARCHAR2,
  p_report_only       IN VARCHAR2 DEFAULT gk_report_only,
  p_value             IN VARCHAR2 DEFAULT gk_default_timezone
)
IS
  l_con_id NUMBER;
  l_parameter_value VARCHAR2(4000);
BEGIN
  l_con_id := con_id(p_pdb_name);
  --
  SELECT value
    INTO l_parameter_value
    FROM cdb_scheduler_global_attribute
   WHERE attribute_name = 'DEFAULT_TIMEZONE'
     AND con_id         = l_con_id;
  --
  IF l_parameter_value <> p_value THEN
    output('SET DEFAULT_TIMEZONE to "'||p_value||'" with DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE');
    IF p_report_only = 'N' THEN
      set_scheduler_attribute (
        p_pdb_name  => p_pdb_name,
        p_attribute => 'DEFAULT_TIMEZONE',
        p_value     => p_value
      );
    END IF;
  END IF;
END default_timezone;
/* ------------------------------------------------------------------------------------ */
PROCEDURE schedule_window (
  p_opening_window_size_hours   IN  NUMBER, -- time (in hours) during which we will open all windows (e.g. 2)
  p_first_window_offset_hours   IN  NUMBER, -- time (in hh24) whene we will open 1st window (e.g. 12)
  p_total_number_of_pdbs        IN  NUMBER, -- total number of windows to schedule between p_first_window_offset_hours and during the following p_opening_window_size_hours
  p_pdb_enumerator              IN  NUMBER, -- window number we want to schedule (between 1 and p_total_number_of_pdbs)
  x_hh24                        OUT NUMBER, -- hour
  x_mi                          OUT NUMBER, -- minute
  x_ss                          OUT NUMBER -- second
)
IS
  l_gap_between_pdbs_in_hours NUMBER;
  l_first_window_start_time   DATE;
  l_window_start_time         DATE;
BEGIN
  l_gap_between_pdbs_in_hours := p_opening_window_size_hours / p_total_number_of_pdbs;
  l_first_window_start_time := TRUNC(SYSDATE) + p_first_window_offset_hours / 24;
  l_window_start_time := l_first_window_start_time + ((p_pdb_enumerator - 1) * l_gap_between_pdbs_in_hours / 24);
  x_hh24 := TO_NUMBER(TO_CHAR(l_window_start_time, 'HH24'));
  x_mi := TO_NUMBER(TO_CHAR(l_window_start_time, 'MI'));
  x_ss := TO_NUMBER(TO_CHAR(l_window_start_time, 'SS'));
END schedule_window;
/* ------------------------------------------------------------------------------------ */
FUNCTION schedule_all_windows (
  p_opening_window_size_hours   IN NUMBER, -- time (in hours) during which we will open all windows (e.g. 2)
  p_first_window_offset_hours   IN NUMBER, -- time (in hh24) whene we will open 1st window (e.g. 12)
  p_maintenance_windows_per_day IN NUMBER, -- times we will open windows during one day (e.g. 4) must be 1, 2, 3 or 4
  p_total_number_of_pdbs        IN NUMBER, -- total number of windows to schedule between p_first_window_offset_hours and during the following p_opening_window_size_hours
  p_pdb_enumerator              IN NUMBER -- window number we want to schedule (between 1 and p_total_number_of_pdbs)
)
RETURN VARCHAR2
IS
  l_hh24 NUMBER;
  l_mi NUMBER;
  l_ss NUMBER;
  l_byhour VARCHAR2(4000);
  l_byminute VARCHAR2(4000);
  l_bysecond VARCHAR2(4000);
BEGIN
  schedule_window (
    p_opening_window_size_hours => NVL(p_opening_window_size_hours, gk_opening_window_size_hours), 
    p_first_window_offset_hours => NVL(p_first_window_offset_hours, gk_first_window_offset_hours),
    p_total_number_of_pdbs      => p_total_number_of_pdbs,
    p_pdb_enumerator            => p_pdb_enumerator,
    x_hh24                      => l_hh24,
    x_mi                        => l_mi,
    x_ss                        => l_ss
  );
  --
  l_byhour   := ';BYHOUR='  ||l_hh24;
  l_byminute := ';BYMINUTE='||l_mi;
  l_bysecond := ';BYSECOND='||l_ss;
  --
  IF p_maintenance_windows_per_day = 2 THEN
    l_byhour   := l_byhour||','||(l_hh24 + 12);
  END IF;
  --
  IF p_maintenance_windows_per_day = 3 THEN
    l_byhour   := l_byhour||','||(l_hh24 + 8)||','||(l_hh24 + 16);
  END IF;
  --
  IF p_maintenance_windows_per_day = 4 THEN
    l_byhour   := l_byhour||','||(l_hh24 + 6)||','||(l_hh24 + 12)||','||(l_hh24 + 18);
  END IF;
  --
  RETURN l_byhour||l_byminute||l_bysecond;
END schedule_all_windows;
/* ------------------------------------------------------------------------------------ */
PROCEDURE autotasks_and_maint_windows (
  p_report_only                 IN VARCHAR2 DEFAULT gk_report_only,
  p_pdb_name                    IN VARCHAR2 DEFAULT NULL,
  p_default_timezone            IN VARCHAR2 DEFAULT gk_default_timezone,
  p_accept_sql_profiles         IN VARCHAR2 DEFAULT gk_accept_sql_profiles_status,
  p_auto_spm_evolve             IN VARCHAR2 DEFAULT gk_auto_spm_evolve_status,
  p_optimizer_stats             IN VARCHAR2 DEFAULT gk_optimizer_stats_status,
  p_sql_tune_advisor            IN VARCHAR2 DEFAULT gk_sql_tune_advisor_status,
  p_segment_advisor             IN VARCHAR2 DEFAULT gk_segment_advisor_status,
  p_mon_fri_maintenance_windows IN NUMBER   DEFAULT gk_mon_fri_maintenance_windows,
  p_mon_fri_first_window_offset IN NUMBER   DEFAULT gk_mon_fri_first_window_offset,
  p_mon_fri_opening_window_size IN NUMBER   DEFAULT gk_mon_fri_opening_window_size,
  p_mon_fri_window_duration_in  IN NUMBER   DEFAULT gk_mon_fri_window_duration_in,
  p_sat_sun_maintenance_windows IN NUMBER   DEFAULT gk_sat_sun_maintenance_windows,
  p_sat_sun_first_window_offset IN NUMBER   DEFAULT gk_sat_sun_first_window_offset,
  p_sat_sun_opening_window_size IN NUMBER   DEFAULT gk_sat_sun_opening_window_size,
  p_sat_sun_window_duration_in  IN NUMBER   DEFAULT gk_sat_sun_window_duration_in 
)
IS 
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_total_number_of_pdbs NUMBER;
  l_window_acronym VARCHAR2(3);
  l_maintenance_windows_per_day NUMBER;
  l_first_window_offset_hours NUMBER;
  l_opening_window_size_hours NUMBER;
  l_window_duration_in_hours NUMBER;
  l_bytime VARCHAR2(4000);
  l_repeat_interval VARCHAR2(4000);
  l_pdb_count NUMBER := 0;
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output ('*** to be executed on DG primary only ***');
    RETURN;
  END IF;
  IF p_pdb_name IS NULL THEN -- all pdbs
    -- begin (only when executed for all pdbs)
    output(LPAD('~',35,'~'));
    output('CDB: '||l_db_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
    output(LPAD('~',35,'~'));
    -- auto tasks at cdb level (only when executed for all pdbs)
    accept_sql_profiles (
      p_report_only       => p_report_only,
      p_enable_or_disable => p_accept_sql_profiles
    );
  END IF;
  -- how many pdbs on cdb?
  SELECT COUNT(*)
    INTO l_total_number_of_pdbs
    FROM v$containers
   WHERE open_mode = 'READ WRITE';
  -- all pdbs
  FOR i IN (SELECT ROW_NUMBER() OVER (ORDER BY con_id) pdb_enumerator,
                   con_id,
                   name pdb_name
              FROM v$containers
             WHERE open_mode = 'READ WRITE'
               --AND name = p_pdb_name -- have to read all pdbs so we can compute correct pdb_enumerator
             ORDER BY
                   con_id)
  LOOP
    IF p_pdb_name IS NULL OR i.pdb_name = p_pdb_name THEN
      l_pdb_count := l_pdb_count + 1;
      output(LPAD('~',35,'~'));
      output('PDB: '||i.pdb_name||'('||i.con_id||')');
      output(LPAD('~',35,'~'));
      -- reset auto tasks at pdb level
      default_timezone (
        p_pdb_name          => i.pdb_name,
        p_report_only       => p_report_only,
        p_value             => p_default_timezone
      );
      auto_spm_evolve (
        p_pdb_name          => i.pdb_name,
        p_report_only       => p_report_only,
        p_enable_or_disable => p_auto_spm_evolve
      );
      optimizer_stats (
        p_pdb_name          => i.pdb_name,
        p_window_name       => NULL,
        p_report_only       => p_report_only,
        p_enable_or_disable => p_optimizer_stats
      );
      sql_tune_advisor (
        p_pdb_name          => i.pdb_name,
        p_window_name       => NULL,
        p_report_only       => p_report_only,
        p_enable_or_disable => p_sql_tune_advisor
      );
      segment_advisor (
        p_pdb_name          => i.pdb_name,
        p_window_name       => NULL,
        p_report_only       => p_report_only,
        p_enable_or_disable => p_segment_advisor
      );
      -- disable autotast windows not recognized
      FOR j IN (SELECT window_name
                  FROM cdb_autotask_window_clients
                 WHERE con_id = i.con_id
                   AND window_name NOT IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW')
                 ORDER BY
                       window_name)
      LOOP
        scheduler_window (
          p_pdb_name          => i.pdb_name,
          p_report_only       => p_report_only,
          p_window_name       => j.window_name,
          p_enable_or_disable => 'DISABLE'
        );
      END LOOP;
      -- enable autotast windows currently disabled
      FOR j IN (SELECT window_name
                  FROM cdb_scheduler_windows
                 WHERE con_id = i.con_id
                   AND window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW')
                   AND enabled = 'FALSE'
                 ORDER BY
                       window_name)
      LOOP
        scheduler_window (
          p_pdb_name          => i.pdb_name,
          p_report_only       => p_report_only,
          p_window_name       => j.window_name,
          p_enable_or_disable => 'ENABLE'
        );
      END LOOP;
      -- modify all expected autotask maintenance windows
      FOR j IN (SELECT window_name
                  FROM cdb_autotask_window_clients
                 WHERE con_id = i.con_id
                   AND window_name IN ('MONDAY_WINDOW', 'TUESDAY_WINDOW', 'WEDNESDAY_WINDOW', 'THURSDAY_WINDOW', 'FRIDAY_WINDOW', 'SATURDAY_WINDOW', 'SUNDAY_WINDOW')
                 ORDER BY
                       window_name)
      LOOP
        output(j.window_name||' - verify');
        -- reset auto tasks at window level
        optimizer_stats (
          p_pdb_name          => i.pdb_name,
          p_window_name       => j.window_name,
          p_report_only       => p_report_only,
          p_enable_or_disable => p_optimizer_stats
        );
        sql_tune_advisor (
          p_pdb_name          => i.pdb_name,
          p_window_name       => j.window_name,
          p_report_only       => p_report_only,
          p_enable_or_disable => p_sql_tune_advisor
        );
        segment_advisor (
          p_pdb_name          => i.pdb_name,
          p_window_name       => j.window_name,
          p_report_only       => p_report_only,
          p_enable_or_disable => p_segment_advisor
        );
        l_window_acronym := SUBSTR(j.window_name, 1, 3);
        -- windows configuration
        IF l_window_acronym IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
          l_maintenance_windows_per_day := p_mon_fri_maintenance_windows;
          l_first_window_offset_hours   := p_mon_fri_first_window_offset;
          l_opening_window_size_hours   := p_mon_fri_opening_window_size;
          l_window_duration_in_hours    := p_mon_fri_window_duration_in;
        ELSIF l_window_acronym IN ('SAT', 'SUN') THEN
          l_maintenance_windows_per_day := p_sat_sun_maintenance_windows;
          l_first_window_offset_hours   := p_sat_sun_first_window_offset;
          l_opening_window_size_hours   := p_sat_sun_opening_window_size;
          l_window_duration_in_hours    := p_sat_sun_window_duration_in;
        ELSE
          l_maintenance_windows_per_day := NULL;
          l_first_window_offset_hours   := NULL;
          l_opening_window_size_hours   := NULL;
          l_window_duration_in_hours    := NULL;
        END IF;
        -- reset window duration
        window_duration (
          p_pdb_name        => i.pdb_name,
          p_report_only     => p_report_only,
          p_window_name     => j.window_name,
          p_duration        => NUMTODSINTERVAL(l_window_duration_in_hours, 'HOUR')
        );
        -- time(s) when the window should open
        l_bytime := 
        schedule_all_windows (
          p_opening_window_size_hours   => l_opening_window_size_hours,
          p_first_window_offset_hours   => l_first_window_offset_hours,
          p_maintenance_windows_per_day => l_maintenance_windows_per_day,
          p_total_number_of_pdbs        => l_total_number_of_pdbs,
          p_pdb_enumerator              => i.pdb_enumerator
        );
        -- reset window repeat_interval
        l_repeat_interval := 'FREQ=DAILY;BYDAY='||l_window_acronym||l_bytime;
        window_repeat_interval (
          p_pdb_name        => i.pdb_name,
          p_report_only     => p_report_only,
          p_window_name     => j.window_name,
          p_repeat_interval => l_repeat_interval
        );
        -- enable back only current autotask windows (as per cdb_scheduler_windows)
        IF p_report_only = 'Y' THEN
          output('ENABLE scheduler_window "'||j.window_name||'" with DBMS_SCHEDULER.ENABLE');
        END IF;
        scheduler_window (
          p_pdb_name          => i.pdb_name,
          p_report_only       => p_report_only,
          p_window_name       => j.window_name,
          p_enable_or_disable => 'ENABLE'
        );
      END LOOP;
    END IF; -- p_pdb_name IS NULL OR i.pdb_name = p_pdb_name
  END LOOP;
  output(LPAD('~',35,'~'));
  output('PDB COUNT: '||l_pdb_count||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
  output(LPAD('~',35,'~'));
END autotasks_and_maint_windows;
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset (
  p_report_only IN VARCHAR2 DEFAULT gk_report_only,
  p_pdb_name    IN VARCHAR2 DEFAULT NULL
)
IS
BEGIN
  autotasks_and_maint_windows (
    p_report_only => p_report_only,
    p_pdb_name    => p_pdb_name
  );
END reset;
/* ------------------------------------------------------------------------------------ */
END iod_amw;
/
