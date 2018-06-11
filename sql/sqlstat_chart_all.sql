----------------------------------------------------------------------------------------
--
-- File name:   sqlstat_chart_all.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Charts all metric groups for a set of SQL statements matching filters
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/19
--
-- Usage:       Execute connected into the CDB or PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sqlstat_chart_all.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
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

DEF default_awr_days = '14';
DEF date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL dbid NEW_V dbid NOPRI;
COL db_name NEW_V db_name NOPRI;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number NOPRI;
COL host_name NEW_V host_name NOPRI;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') con_name FROM DUAL
/

COL con_id NEW_V con_id NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') con_id FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 1. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&1.';

COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 2. SQL Text piece (optional):
DEF sql_text_piece = '&2.';


PRO
PRO 3. Enter SQL_ID (optional):
DEF sql_id = '&3.';

PRO
PRO 4. Enter Plan Hash Value (optional):
DEF phv = '&4.';

PRO
PRO 5. Enter Parsing Schema Name (optional):
DEF parsing_schema_name = '&5.';

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL main_output_file_name NEW_V main_output_file_name NOPRI;
SELECT 'sqlstat_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||(CASE WHEN '&&kiev_tx.' IS NOT NULL THEN REPLACE('_&&kiev_tx.', ' ') END)||(CASE WHEN '&&sql_text_piece.' IS NOT NULL THEN REPLACE('_&&sql_text_piece.', ' ') END)||(CASE WHEN '&&sql_id.' IS NOT NULL THEN '_&&sql_id.' END)||(CASE WHEN '&&phv.' IS NOT NULL THEN '_&&phv.' END)||(CASE WHEN '&&parsing_schema_name.' IS NOT NULL THEN '_&&parsing_schema_name.' END) main_output_file_name FROM DUAL
/

@@sqlstat_chart_one.sql "latency" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "db_time" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "calls" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "rows_sec" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "rows_exec" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "reads_sec" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "reads_exec" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "cursors" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
@@sqlstat_chart_one.sql "memory" "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."

COL current_time NEW_V current_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

HOS zip -m &&main_output_file_name._&&current_time..zip &&main_output_file_name._*.html

PRO
PRO &&main_output_file_name._charts.zip
PRO
CL COL BRE COMP;
UNDEF 1 2 3 4;
SET HEA ON PAGES 100;
