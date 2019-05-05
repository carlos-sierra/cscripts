----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_SPM_FPZ_CDB
--
-- Purpose:     Plan Stability using SQL Plan Management (El Zapper)
--
-- Frequency:   Every 3 hours
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/19
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_SPM_FPZ_CDB.sql
--
-- Notes:       Creates SQL Plan Baselines on application SQL that complies with a
--              set of rules.
--              Disables Baselines on application SQL if performance regressed. 
--              FPZ stands for Flipping Plan Zapper.
--
---------------------------------------------------------------------------------------
--
-- to use these parameters below, uncomment also the call to c##iod.iod_spm.fpz that references them
DEF p_report_only = 'N';
DEF p_pdb_name = 'ALL';
DEF p_sql_id = 'ALL';
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
-- remove traces older than 1 day
DEF diag_trace = 'non-existent-directory-prefix-in-case-select-below-returns-null';
COL diag_trace NEW_V diag_trace;
SELECT value diag_trace FROM v$diag_info WHERE name = 'Diag Trace';
HOS find &&diag_trace./ -type f -name '*iod_spm*.tr*' -mtime +1 -exec rm {} \;;
HOS find /tmp/iod* -type f -name 'iod_spm_*.txt' -mtime +1 -exec rm {} \;;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_spm_zapper';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_spm_zapper_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, '"d"d"_h"hh24') output_file_name FROM DUAL;
COL trace_file NEW_V trace_file;
--
SPO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
PRO Execute cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql for SQL_ID details
PRO &&output_file_name..txt;
--
--EXEC c##iod.iod_spm.fpz(p_report_only => '&&p_report_only.', p_pdb_name => '&&p_pdb_name.', p_sql_id => '&&p_sql_id.');
EXEC c##iod.iod_spm.fpz;
--
PRO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
PRO Execute cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql for SQL_ID details
SPO OFF;
--
--HOS tkprof &&trace_file. &&output_file_name._tkprof_nosort.txt
HOS tkprof &&trace_file. &&output_file_name._tkprof_sort.txt sort=exeela,fchela
HOS zip -mj &&zip_file_name..zip &&output_file_name.*.txt
HOS unzip -l &&zip_file_name..zip
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
--
---------------------------------------------------------------------------------------