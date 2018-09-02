-- IOD_REPEATING_SPACE_MAINTENANCE
-- Purge Recyclebin, Online Table Redefinition and Online Index Rebuild
--
DEF report_only = 'N';
DEF only_if_ref_by_full_scans = 'Y';
DEF min_size_mb = '10';
DEF min_savings_perc = '25';
DEF min_ts_used_percent = '85';
DEF preserve_recyclebin_days = '8';
DEF min_obj_age_days = '8';
DEF sleep_seconds = '120';
DEF timeout_hours = '4';
DEF pdb_name = '';
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
-- exit graciously if package does not exist
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  DBMS_OUTPUT.PUT_LINE('API version: '||c##iod.iod_space.gk_package_version);
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET tracefile_identifier = 'iod_space_maintenance';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
COL zip_file_name NEW_V zip_file_name NOPRI;
COL output_file_name NEW_V output_file_name NOPRI;
SELECT '/tmp/iod_space_maintenance_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SET SERVEROUT ON SIZE UNLIMITED;
COL used_space_gbs FOR 999,990.000;
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO
PRO &&output_file_name..txt;
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
SET RECSEP OFF;
PRO
CLEAR BREAK COMPUTE;
COL pdb_tablespace_name1 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL pdb_tablespace_name2 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL used_space_gbs1 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL used_space_gbs2 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL max_size_gbs1 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL max_size_gbs2 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL used_percent1 FOR 990.000 HEA 'USED|PERCENT';
COL used_percent2 FOR 990.000 HEA 'USED|PERCENT';
PRO
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF used_space_gbs1 max_size_gbs1 used_space_gbs2 max_size_gbs2 ON REPORT; 
PRO
WITH 
t AS (
SELECT c.name||'('||c.con_id||')' pdb,
       m.tablespace_name,
       ROUND(m.used_percent, 3) used_percent, -- as per maximum size (considering auto extend)
       ROUND(m.used_space * t.block_size / POWER(2, 30), 3) used_space_gbs,
       ROUND(m.tablespace_size * t.block_size / POWER(2, 30), 3) max_size_gbs,
       ROW_NUMBER() OVER (ORDER BY c.name, m.tablespace_name) row_number1,
       ROW_NUMBER() OVER (ORDER BY m.used_percent DESC, m.used_space * t.block_size DESC, m.tablespace_size * t.block_size DESC) row_number2
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
)
SELECT t1.pdb||CHR(10)||'   '||
       t1.tablespace_name pdb_tablespace_name1,
       t1.used_percent used_percent1,
       t1.used_space_gbs used_space_gbs1,
       t1.max_size_gbs max_size_gbs1,
       '|'||CHR(10)||'|' "|",
       t2.used_percent used_percent2,
       t2.used_space_gbs used_space_gbs2,
       t2.max_size_gbs max_size_gbs2,
       t2.pdb||CHR(10)||'   '||
       t2.tablespace_name pdb_tablespace_name2
  FROM t t1, t t2
 WHERE t1.row_number1 = t2.row_number2
 ORDER BY
       t1.row_number1
/
PRO
CLEAR BREAK COMPUTE;
SET RECSEP WR;
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO Application Tablespaces pro-active resizing
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC c##iod.iod_space.tablespaces_resize;
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO CDB Application Space (begin)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT ROUND(SUM(m.used_space * t.block_size) / POWER(2, 30), 3) used_space_gbs
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO c##iod.iod_space.purge_recyclebin
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
PRO Segments in recyclebin (before)
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) 
  FROM cdb_segments
 WHERE segment_name LIKE 'BIN$'||CHR(37)
/
PRO
EXEC c##iod.iod_space.purge_recyclebin (p_preserve_recyclebin_days => '&&preserve_recyclebin_days.', p_timeout => SYSDATE + (&&timeout_hours./24));
PRO
PRO Segments in recyclebin (after)
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) 
  FROM cdb_segments
 WHERE segment_name LIKE 'BIN$'||CHR(37)
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO CDB Application Space (so far)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT ROUND(SUM(m.used_space * t.block_size) / POWER(2, 30), 3) used_space_gbs
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO c##iod.iod_space.table_redefinition
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
EXEC c##iod.iod_space.table_redefinition(p_report_only => '&&report_only.', p_only_if_ref_by_full_scans => '&&only_if_ref_by_full_scans.', p_min_size_mb => TO_NUMBER('&&min_size_mb.'), p_min_savings_perc => TO_NUMBER('&&min_savings_perc.'), p_min_ts_used_percent => TO_NUMBER('&&min_ts_used_percent.'), p_min_obj_age_days => TO_NUMBER('&&min_obj_age_days.'), p_sleep_seconds => TO_NUMBER('&&sleep_seconds.'), p_timeout => SYSDATE + (&&timeout_hours./24));
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO CDB Application Space (so far)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT ROUND(SUM(m.used_space * t.block_size) / POWER(2, 30), 3) used_space_gbs
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO c##iod.iod_space.index_rebuild
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
EXEC c##iod.iod_space.index_rebuild(p_report_only => '&&report_only.', p_only_if_ref_by_full_scans => '&&only_if_ref_by_full_scans.', p_min_size_mb => TO_NUMBER('&&min_size_mb.'), p_min_savings_perc => TO_NUMBER('&&min_savings_perc.'), p_min_obj_age_days => TO_NUMBER('&&min_obj_age_days.'), p_sleep_seconds => TO_NUMBER('&&sleep_seconds.'), p_timeout => SYSDATE + (&&timeout_hours./24));
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
PRO CDB Application Space (end)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT ROUND(SUM(m.used_space * t.block_size) / POWER(2, 30), 3) used_space_gbs
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
/
PRO
PRO /* ------------------------------------------------------------------------------------ */
PRO
SET RECSEP OFF;
PRO
CLEAR BREAK COMPUTE;
COL pdb_tablespace_name1 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL pdb_tablespace_name2 FOR A35 HEA 'PDB|TABLESPACE_NAME';
COL used_space_gbs1 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL used_space_gbs2 FOR 999,990.000 HEA 'USED_SPACE|(GBs)';
COL max_size_gbs1 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL max_size_gbs2 FOR 999,990.000 HEA 'MAX_SIZE|(GBs)';
COL used_percent1 FOR 990.000 HEA 'USED|PERCENT';
COL used_percent2 FOR 990.000 HEA 'USED|PERCENT';
PRO
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF used_space_gbs1 max_size_gbs1 used_space_gbs2 max_size_gbs2 ON REPORT; 
PRO
WITH 
t AS (
SELECT c.name||'('||c.con_id||')' pdb,
       m.tablespace_name,
       ROUND(m.used_percent, 3) used_percent, -- as per maximum size (considering auto extend)
       ROUND(m.used_space * t.block_size / POWER(2, 30), 3) used_space_gbs,
       ROUND(m.tablespace_size * t.block_size / POWER(2, 30), 3) max_size_gbs,
       ROW_NUMBER() OVER (ORDER BY c.name, m.tablespace_name) row_number1,
       ROW_NUMBER() OVER (ORDER BY m.used_percent DESC, m.used_space * t.block_size DESC, m.tablespace_size * t.block_size DESC) row_number2
  FROM cdb_tablespace_usage_metrics m,
       cdb_tablespaces t,
       v$containers c
 WHERE t.con_id = m.con_id
   AND t.tablespace_name = m.tablespace_name
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND c.con_id = m.con_id
   AND c.open_mode = 'READ WRITE'
)
SELECT t1.pdb||CHR(10)||'   '||
       t1.tablespace_name pdb_tablespace_name1,
       t1.used_percent used_percent1,
       t1.used_space_gbs used_space_gbs1,
       t1.max_size_gbs max_size_gbs1,
       '|'||CHR(10)||'|' "|",
       t2.used_percent used_percent2,
       t2.used_space_gbs used_space_gbs2,
       t2.max_size_gbs max_size_gbs2,
       t2.pdb||CHR(10)||'   '||
       t2.tablespace_name pdb_tablespace_name2
  FROM t t1, t t2
 WHERE t1.row_number1 = t2.row_number2
 ORDER BY
       t1.row_number1
/
PRO
CLEAR BREAK COMPUTE;
SET RECSEP WR;
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

