----------------------------------------------------------------------------------------
--
-- File name:   reset_automated_maintenance_windows.sql
--
-- Purpose:     Sets staggered maintenance windows for all PDBs in order to avoid CPU
--              spikes caused by all PDBs starting their maintenance window at the same
--              time
--
-- Author:      Carlos Sierra
--
-- Version:     2017/07/25
--
-- Usage:       Execute as SYS on CDB
--
-- Example:     @reset_automated_maintenance_windows.sql
--
-- Notes:       Stagger PDBs maintenance windows to start at different times in order to 
--              reduce CPU spikes, for example: all PDBs start their maintenance window 
--              between 8AM PST and 10AM PST (2 hours), and each window lasts 4 hour, 
--              so all maintenance tasks are executed between 8AM and 2PM PST.
--              Notice that in such example, 1st window opens at 8AM and last one opens 
--              at 10AM. First closes at 12NOON and last at 2PM
--              Be aware that default cursor invalidation may happen a few hours (3 or 4) 
--              after a maintenance window closes. Then, since most PDBs process their 
--              tasks fast, actual cursor invalidation may happen between 11AM and 1PM.
--
---------------------------------------------------------------------------------------
WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;

WHENEVER SQLERROR EXIT FAILURE;
SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300;

COL report_date NEW_V report_date;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') report_date FROM DUAL;
SPO /tmp/pdb_window_&&report_date..txt;

-- hour of the day (military format) when first maintenance window for a PDB may open during week days
-- i.e. if dbtimezone is UCT and we want to open 1st at 8AM PST we set to 15
VAR weekday_start_hh24 NUMBER; 
EXEC :weekday_start_hh24 := 15;
-- for how many hours we want to open maintenance windows for PDBs during week days
-- i.e. if we want to open windows during a 2 hours interval we set to 2
VAR weekday_hours NUMBER;
EXEC :weekday_hours := 2;
-- how long we want the maintenance window to last for each PDB during week days
-- i.e. if we want each PDB to have a window of 4 hours then we set to 4
VAR weekday_duration NUMBER;
EXEC :weekday_duration := 4;

-- hour of the day (military format) when first maintenance window for a PDB may open during weekends
-- i.e. if dbtimezone is UCT and we want to open 1st at 8AM PST we set to 15
VAR weekend_start_hh24 NUMBER; 
EXEC :weekend_start_hh24 := 15;
-- for how many hours we want to open maintenance windows for PDBs during weekends
-- i.e. if we want to open windows for 2 hours interval we set to 2
VAR weekend_hours NUMBER;
EXEC :weekend_hours := 2;
-- how long we want the maintenance window to last for each PDB during weekends
-- i.e. if we want each PDB to have a window of 8 hours then we set to 8
VAR weekend_duration NUMBER;
EXEC :weekend_duration := 8;

VAR v_cursor CLOB;

-- PL/SQL block to be executed on each PDB
BEGIN
  :v_cursor := q'[
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  DBMS_SCHEDULER.SET_SCHEDULER_ATTRIBUTE('DEFAULT_TIMEZONE','+00:00'); 
  DBMS_SCHEDULER.DISABLE('MONDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('MONDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=MON; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('MONDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('MONDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('MONDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('TUESDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('TUESDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=TUE; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('TUESDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('TUESDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('TUESDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('WEDNESDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEDNESDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=WED; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEDNESDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('WEDNESDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('WEDNESDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('THURSDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('THURSDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=THU; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('THURSDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('THURSDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('THURSDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('FRIDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('FRIDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=FRI; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('FRIDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('FRIDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('FRIDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('SATURDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=SAT; byhour='||:b_weekends_hh24||'; byminute='||:b_weekends_mi||'; bysecond='||:b_weekends_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('SATURDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekend_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('SATURDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('SATURDAY_WINDOW');
  DBMS_SCHEDULER.DISABLE('SUNDAY_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW', 'repeat_interval', 'freq=daily; byday=SUN; byhour='||:b_weekends_hh24||'; byminute='||:b_weekends_mi||'; bysecond='||:b_weekends_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('SUNDAY_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekend_duration, 2, '0')||':00:00')); 
  DBMS_SCHEDULER.SET_ATTRIBUTE_NULL('SUNDAY_WINDOW', 'resource_plan'); 
  DBMS_SCHEDULER.ENABLE('SUNDAY_WINDOW');
  -- Weeknight window - for compatibility only - KEEP IT DISABLED
  DBMS_SCHEDULER.DISABLE('WEEKNIGHT_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEEKNIGHT_WINDOW', 'repeat_interval', 'freq=daily; byday=MON,TUE,WED,THU,FRI; byhour='||:b_weekdays_hh24||'; byminute='||:b_weekdays_mi||'; bysecond='||:b_weekdays_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEEKNIGHT_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekday_duration, 2, '0')||':00:00')); 
  --DBMS_SCHEDULER.ENABLE('WEEKNIGHT_WINDOW'); KEEP IT DISABLED - Weeknight window - for compatibility only
  -- Weekend window - for compatibility only - KEEP IT DISABLED
  DBMS_SCHEDULER.DISABLE('WEEKEND_WINDOW', TRUE);
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEEKEND_WINDOW', 'repeat_interval', 'freq=daily; byday=SAT,SUN; byhour='||:b_weekends_hh24||'; byminute='||:b_weekends_mi||'; bysecond='||:b_weekends_ss); 
  DBMS_SCHEDULER.SET_ATTRIBUTE('WEEKEND_WINDOW', 'duration', TO_DSINTERVAL('+000 '||LPAD(:b_weekend_duration, 2, '0')||':00:00')); 
  --DBMS_SCHEDULER.ENABLE('WEEKEND_WINDOW'); KEEP IT DISABLED - Weekend window - for compatibility only
  COMMIT;
END;
  ]';
END;
/

ALTER SESSION SET tracefile_identifier = 'reset_auto_maint_windows';
-- execute connected into CDB$ROOT as SYS
DECLARE
  l_cursor_id INTEGER;
  l_rows_processed INTEGER;
  l_open_mode VARCHAR2(20);
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_SYSTEM.KSDWRT(3,p_line);
    DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
BEGIN
  put_line('dbe script reset_automated_maintenance_windows.sql begin');
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode = 'READ WRITE' THEN
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    FOR i IN (WITH
              pdbs AS ( -- list of PDBs ordered by CON_ID with enumerator as rank_num
              SELECT con_id, name, RANK () OVER (ORDER BY con_id) rank_num FROM v$containers WHERE con_id <> 2
              ),
              slot AS ( -- PDBs count
              SELECT MAX(rank_num) count FROM pdbs
              ),
              start_time AS (
              SELECT con_id, name, 
                     (TRUNC(SYSDATE) + (:weekday_start_hh24 / 24) + ((pdbs.rank_num - 1) * :weekday_hours / (slot.count - 1) / 24)) weekdays,
                     (TRUNC(SYSDATE) + (:weekend_start_hh24 / 24) + ((pdbs.rank_num - 1) * :weekend_hours / (slot.count - 1) / 24)) weekends   
                FROM pdbs, slot
               WHERE slot.count > 1
              )
              SELECT con_id, name, 
                     TO_CHAR(weekdays, 'HH24') weekdays_hh24, TO_CHAR(weekdays, 'MI') weekdays_mi, TO_CHAR(weekdays, 'SS') weekdays_ss,
                     TO_CHAR(weekends, 'HH24') weekends_hh24, TO_CHAR(weekends, 'MI') weekends_mi, TO_CHAR(weekends, 'SS') weekends_ss
                FROM start_time
               ORDER BY
                     con_id)
    LOOP
      put_line('CON_ID:'||i.con_id||' PDB:'||i.name||' open weekdays:'||i.weekdays_hh24||':'||i.weekdays_mi||':'||i.weekdays_ss||' duration:'||:weekday_duration||'h. open weekends:'||i.weekends_hh24||':'||i.weekends_mi||':'||i.weekends_ss||' duration:'||:weekend_duration||'h.'); 
      DBMS_SQL.PARSE(c => l_cursor_id, statement => :v_cursor, language_flag => DBMS_SQL.NATIVE, container => i.name);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekdays_hh24', value => i.weekdays_hh24);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekdays_mi', value => i.weekdays_mi);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekdays_ss', value => i.weekdays_ss);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekday_duration', value => :weekday_duration);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekends_hh24', value => i.weekends_hh24);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekends_mi', value => i.weekends_mi);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekends_ss', value => i.weekends_ss);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_weekend_duration', value => :weekend_duration);
      l_rows_processed := DBMS_SQL.EXECUTE(c => l_cursor_id);
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  ELSE
    put_line('normal early exit since open_mode "'||l_open_mode||'" is not "READ WRITE"');
  END IF;
  put_line('dbe script reset_automated_maintenance_windows.sql end');
END;
/

SPO OFF;

EXIT;