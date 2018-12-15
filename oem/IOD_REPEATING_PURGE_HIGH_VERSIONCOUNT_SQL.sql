----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL
--
-- Purpose:     Purges SQL with high version count (HVC)
--
-- Author:      Ashish Shanbhag and Carlos Sierra
--
-- Version:     2018/11/27
--
-- Usage:       Execute connected into CDB (expected hourly OEM job)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL.sql
--
-- Notes:       Acts on top SQL as per HVC according to v$sqlarea.loaded_versions
--              Sleeps between consecutive Purge Cursor operations (reduce LC contention)
--              Executes for less then 1h then stops
--
---------------------------------------------------------------------------------------
--
DEF timeout_minutes = '55';
DEF sleep_seconds = '30';
DEF fetch_first_n_rows_only = '100';
DEF loaded_versions_threashold = '2048';
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
--
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET tracefile_identifier = 'iod_purge_hvc';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET HEA ON LIN 2500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
COL zip_file_name NEW_V zip_file_name NOPRI;
COL output_file_name NEW_V output_file_name NOPRI;
SELECT '/tmp/iod_purge_hvc_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SET SERVEROUT ON SIZE UNLIMITED;
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO
PRO &&output_file_name..txt;
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
DECLARE
  l_timeout DATE := SYSDATE + (&&timeout_minutes. / 24 / 60);
BEGIN
  DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' begin');
  SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' begin'); -- write to trace and alert log
  --
  FOR i IN (SELECT SUM(loaded_versions) loaded_versions_sum, COUNT(*) pdb_count, sql_id, address, hash_value, sql_text
              FROM v$sqlarea
             GROUP BY 
                   sql_id, address, hash_value, sql_text
            HAVING SUM(loaded_versions) > &&loaded_versions_threashold.
             ORDER BY
                   loaded_versions_sum DESC
             FETCH FIRST &&fetch_first_n_rows_only. ROWS ONLY)
  LOOP
    DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' sql_id:'||i.sql_id||' address:'||i.address||' hash_value:'||i.hash_value||'('||TRIM(TO_CHAR(i.hash_value, 'xxxxxxxx'))||') loaded_versions:'||i.loaded_versions_sum||' pdbs:'||i.pdb_count||' sql_text:'||i.sql_text);
    SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL sql_id:'||i.sql_id||' hash:'||TRIM(TO_CHAR(i.hash_value, 'xxxxxxxx'))||' hvc:'||i.loaded_versions_sum||' pdbs:'||i.pdb_count||' command:DBMS_SHARED_POOL.purge('''||i.address||','||i.hash_value||''',''c'');'); -- write to trace and alert log
    --
    BEGIN
      DBMS_SHARED_POOL.purge(i.address||','||i.hash_value,'c');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('*** '||SQLERRM);
        SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL *** '||SQLERRM); -- write to trace and alert log
    END;
    --
    IF SYSDATE > l_timeout THEN
      DBMS_OUTPUT.put_line('timeout');
      SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL timeout'); -- write to trace and alert log
      EXIT; -- to be sure it completes before next OEM job cycle (expected to be 1h)
    END IF;
    --
    DBMS_LOCK.SLEEP(&&sleep_seconds.); -- short pause to reduce risk of Library Cache (LC) contention
  END LOOP;
  --
  DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' end');
  SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' end'); -- write to trace and alert log
END;
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO &&output_file_name..txt;
PRO
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
WHENEVER SQLERROR CONTINUE;
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;

