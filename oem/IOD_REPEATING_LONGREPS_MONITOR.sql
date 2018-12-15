-- IOD_REPEATING_LONGREPS_MONITOR (hourly) KIEV
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Must execute on PRIMARY ***');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
DEF seconds_threshold = '1200';
DEF end_time_threshold_secs = '3600';
--
COL pdb_name FOR A35;
COL sql_id FOR A13;
COL sql_text FOR A120;
COL start_time FOR A19;
COL end_time FOR A19;
COL command_type FOR A12;
DEF statements_over_threshold = '0';
DEF executions_over_threshold = '0';
COL statements_over_threshold NEW_V statements_over_threshold NOPRI;
COL executions_over_threshold NEW_V executions_over_threshold NOPRI;
--
PRO
PRO MONITORED SQL (taking over &&seconds_threshold. to execute)
PRO ~~~~~~~~~~~~~
WITH 
slow AS (
SELECT c.name||'('||r.con_id||')' pdb_name,
       r.key1 sql_id,
       TO_CHAR(r.period_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') start_time,
       TO_CHAR(r.period_end_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_time,
       (r.period_end_time - r.period_start_time) * 24 * 3600 seconds,
       (SELECT a.name FROM v$sql s, audit_actions a  WHERE s.sql_id = r.key1 AND a.action = s.command_type AND ROWNUM = 1) command_type,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = r.key1 AND ROWNUM = 1) sql_text,
       TO_CHAR(COUNT(DISTINCT r.key1) OVER ()) statements_over_threshold,
       TO_CHAR(COUNT(*) OVER ()) executions_over_threshold
  FROM cdb_hist_reports r,
       v$containers c
 WHERE r.component_name = 'sqlmonitor'
   AND r.con_id > 2
   AND (r.period_end_time - r.period_start_time) * 24 * 3600 > TO_NUMBER('&&seconds_threshold.')
   AND r.period_end_time > SYSDATE - (TO_NUMBER('&&end_time_threshold_secs.') / 24 / 3600)
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
)
SELECT pdb_name,
       sql_id,
       start_time,
       end_time,
       seconds,
       command_type,
       sql_text,
       statements_over_threshold,
       executions_over_threshold
  FROM slow
 WHERE command_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
 ORDER BY
       pdb_name,
       sql_id,
       start_time,
       end_time
/
--
WHENEVER SQLERROR EXIT FAILURE;
BEGIN
  IF TO_NUMBER(NVL('&&statements_over_threshold.', '0')) > 0 THEN
    raise_application_error(-20000, '*** &&executions_over_threshold. execution(s) of &&statements_over_threshold. monitored SQL statement(s) exceeded &&seconds_threshold. seconds over the last &&end_time_threshold_secs. seconds ***');
  END IF;
END;
/
--
WHENEVER SQLERROR CONTINUE;
