----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL
--
-- Purpose:     Purge Cursors with high version count (HVC)
--
-- Frequency:   Hourly
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/04
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL.sql
--
-- Notes:       Acts on top SQL as per HVC according to v$sqlarea.loaded_versions 
--              and v$sqlarea.version_count.
--              Sleeps between consecutive Purge Cursor operations (reduce LC contention).
--              Executes for less then 1h then stops.
--              v$sqlarea.loaded_versions ~ v$sql.COUNT(*).
--              SUM(DISTINCT v$sqlarea.version_count) ~ v$sql.COUNT(is_obsolete = 'N').
--
---------------------------------------------------------------------------------------
--
DEF report_only = 'N';
DEF timeout_minutes = '55';
DEF sleep_seconds = '10';
DEF fetch_first_n_rows_only = '300';
DEF loaded_versions_threashold = '2048';
DEF version_count_threashold = '1024';
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'casper'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'omr'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'oem'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'telemetry'||CHR(37)
  THEN
    raise_application_error(-20000, '*** Excluded host: "'||l_host_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on unapproved database
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_db_name VARCHAR2(9);
BEGIN
  SELECT name INTO l_db_name FROM v$database;
  IF UPPER(l_db_name) LIKE 'DBE'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'DBTEST'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'IOD'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'KIEV'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'LCS'||CHR(37)
  THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** Unapproved database: "'||l_db_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on a PDB
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Within PDB "'||SYS_CONTEXT('USERENV', 'CON_NAME')||'" ***');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_purge_hvc';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name NOPRI;
COL output_file_name NEW_V output_file_name NOPRI;
SELECT '/tmp/iod_purge_hvc_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, '"d"d"_h"hh24') output_file_name FROM DUAL;
--
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO
PRO &&output_file_name..txt;
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
DECLARE
  l_timeout DATE := SYSDATE + (&&timeout_minutes. / 24 / 60);
  l_message VARCHAR2(4000);
  l_count NUMBER := 0;
  l_mem_mbs NUMBER := 0;
BEGIN
  DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' begin');
  SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' begin'); -- write to trace and alert log
  --
  FOR i IN (WITH hvc 
            AS (
            SELECT SUM(loaded_versions) loaded_versions_sum, 
                   SUM(DISTINCT version_count) version_count_sum, 
                   ROUND(SUM(sharable_mem + persistent_mem + runtime_mem)/POWER(2,20)) mem_mbs_sum,
                   COUNT(*) pdb_count, 
                   sql_id, address, hash_value, sql_text,
                   ROW_NUMBER () OVER (ORDER BY SUM(loaded_versions) DESC) rank_loaded_versions,
                   ROW_NUMBER () OVER (ORDER BY SUM(DISTINCT version_count) DESC) rank_version_count
              FROM v$sqlarea
             WHERE loaded_versions > 0
               AND version_count > 0
             GROUP BY 
                   sql_id, address, hash_value, sql_text
            )
            SELECT rank_loaded_versions, rank_version_count,
                   loaded_versions_sum, version_count_sum, mem_mbs_sum, pdb_count,
                   sql_id, address, hash_value, sql_text
              FROM hvc
             WHERE loaded_versions_sum > TO_NUMBER('&&loaded_versions_threashold.') 
                OR version_count_sum > TO_NUMBER('&&version_count_threashold.')
             ORDER BY
                   CASE
                     WHEN loaded_versions_sum > TO_NUMBER('&&loaded_versions_threashold.') THEN 1
                     WHEN version_count_sum > TO_NUMBER('&&version_count_threashold.') THEN 2
                   END,
                   CASE
                     WHEN loaded_versions_sum > TO_NUMBER('&&loaded_versions_threashold.') THEN rank_loaded_versions
                     WHEN version_count_sum > TO_NUMBER('&&version_count_threashold.') THEN rank_version_count
                   END
             FETCH FIRST TO_NUMBER('&&fetch_first_n_rows_only.') ROWS ONLY)
  LOOP
    l_count := l_count + 1;
    l_mem_mbs := l_mem_mbs + i.mem_mbs_sum;
    l_message := ' rank:'||l_count||', sql_id:'||i.sql_id||', address:'||i.address||', hash_value:'||i.hash_value||'('||TRIM(TO_CHAR(i.hash_value, 'xxxxxxxx'))||'), loaded_versions:'||i.loaded_versions_sum||'(rank:'||i.rank_loaded_versions||'), version_count:'||i.version_count_sum||'(rank:'||i.rank_version_count||'), memory:'||i.mem_mbs_sum||'MBs, pdbs:'||i.pdb_count||', ';
    DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||l_message||'sql_text:'||i.sql_text);
    --
    IF '&&report_only.' = 'Y' THEN
      NULL;
    ELSE -- report_only = N
      SYS.DBMS_SYSTEM.ksdwrt(dest => 3, tst => 'IOD_REPEATING_PURGE_HIGH_VERSIONCOUNT_SQL'||l_message||'command:DBMS_SHARED_POOL.purge('''||i.address||','||i.hash_value||''',''c'');'); -- write to trace and alert log
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
    END IF; 
  END LOOP;
  --
  DBMS_OUTPUT.put_line(TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')||' end (total:'||l_count||', mem:'||TRIM(TO_CHAR(l_mem_mbs,'999,999,990'))||'MBs)');
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
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
--
---------------------------------------------------------------------------------------