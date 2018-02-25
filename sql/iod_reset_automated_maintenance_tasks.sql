----------------------------------------------------------------------------------------
--
-- File name:   iod_reset_automated_maintenance_tasks.sql
--
-- Purpose:     Resets all 3 Automated Maintenance Tasks. It does:
--              1. Enable CBO stats gathering and tuning advisor
--              2. Disables space advisor 
--              3. Disables the automatic creation of SQL Profiles and SPB
--              4. Sets shares to 4 and resource utilization to 10 percent for KIEV plan
--              
--
-- Author:      Carlos Sierra
--
-- Version:     2017/10/01
--
-- Usage:       Execute on CDB$ROOT
--
-- Example:     @iod_reset_automated_maintenance_tasks.sql
--
-- Notes:       It executes anonymous PL/SQL block in all PDBs
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
SPO /tmp/iod_reset_automated_maintenance_tasks_&&report_date..txt;

VAR v_cursor CLOB;

-- PL/SQL block to be executed on each PDB
BEGIN
  :v_cursor := q'[
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_SYSTEM.KSDWRT(3,p_line);
    DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
BEGIN
  DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection', operation => NULL, window_name => NULL);
  DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'sql tuning advisor', operation => NULL, window_name => NULL);
  DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto space advisor', operation => NULL, window_name => NULL);
  DBMS_SPM.SET_EVOLVE_TASK_PARAMETER(task_name => 'SYS_AUTO_SPM_EVOLVE_TASK', parameter => 'ACCEPT_PLANS', value => 'FALSE');
  COMMIT;
END;
  ]';
END;
/

ALTER SESSION SET tracefile_identifier = 'reset_auto_maint_tasks';
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
  put_line('dbe script iod_reset_automated_maintenance_tasks.sql begin');
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode = 'READ WRITE' THEN
    put_line('DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER(''ACCEPT_SQL_PROFILES'',''FALSE'');');
    DBMS_AUTO_SQLTUNE.SET_AUTO_TUNING_TASK_PARAMETER('ACCEPT_SQL_PROFILES', 'FALSE');
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    FOR i IN (SELECT con_id, name 
                FROM v$containers 
               WHERE con_id <> 2 
                 AND name = 'SYNC_TEST'
                 AND open_mode = 'READ WRITE'
               ORDER BY 1)
    LOOP
      put_line('PDB:'||i.name||' CON_ID:'||i.con_id); 
      DBMS_SQL.PARSE
        ( c             => l_cursor_id
        , statement     => :v_cursor
        , language_flag => DBMS_SQL.NATIVE
        , container     => i.name
        );
        l_rows_processed := DBMS_SQL.EXECUTE(c => l_cursor_id);
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  ELSE
    put_line('normal early exit since open_mode "'||l_open_mode||'" is not "READ WRITE"');
  END IF;
  put_line('dbe script iod_reset_automated_maintenance_tasks.sql end');
END;
/

SPO OFF;

EXIT;