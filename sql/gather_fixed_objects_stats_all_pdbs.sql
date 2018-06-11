-- gather_fixed_objects_stats_all_pdbs.sql (IOD_IMMEDIATE_FIXED_OBJECTS_STATS)
-- gathers fixed object stats on all pdbs
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF SERVEROUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
SPO gather_fixed_objects_stats_all_pdbs_driver.sql;
BEGIN
  FOR i IN (SELECT name FROM v$containers WHERE open_mode = 'READ WRITE' ORDER BY con_id)
  LOOP
    DBMS_OUTPUT.PUT_LINE('ALTER SESSION SET CONTAINER = '||i.name||';');
    DBMS_OUTPUT.PUT_LINE(q'[SELECT TRUNC(last_analyzed) last_analyzed, COUNT(*) tables FROM dba_tab_statistics WHERE owner = 'SYS' AND object_type = 'FIXED TABLE' GROUP BY TRUNC(last_analyzed) ORDER BY TRUNC(last_analyzed);]');
    DBMS_OUTPUT.PUT_LINE(q'[EXEC DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;]');
    DBMS_OUTPUT.PUT_LINE(q'[EXEC DBMS_STATS.GATHER_TABLE_STATS('SYS','X$KTFBUE');]');
    DBMS_OUTPUT.PUT_LINE(q'[SELECT TRUNC(last_analyzed) last_analyzed, COUNT(*) tables FROM dba_tab_statistics WHERE owner = 'SYS' AND object_type = 'FIXED TABLE' GROUP BY TRUNC(last_analyzed) ORDER BY TRUNC(last_analyzed);]');
  END LOOP;
END;
/
SPO OFF;
SET HEA ON FEED ON ECHO ON VER ON TI ON TIMI ON;
SPO gather_fixed_objects_stats_all_pdbs.txt;
@gather_fixed_objects_stats_all_pdbs_driver.sql;
SPO OFF;
EXIT;