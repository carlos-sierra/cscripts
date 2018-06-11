----------------------------------------------------------------------------------------
--
-- File name:   top_sql_chart_all.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Charts top SQL (as per a computed metric) for given time range
--
-- Author:      Carlos Sierra
--
-- Version:     2018/04/08
--
-- Usage:       Execute connected into the CDB or PDB of interest.
--
--              Enter range of AWR snapshot (optional)
--              Dafaults to last AWR snapshot
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @top_sql_chart_all.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
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
-- exit graciously if executed from CDB$ROOT
--WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Be aware! You are executing this script connected into CDB$ROOT.');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

DEF default_window_hours = '24';
DEF default_awr_days = '30';
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
PRO How many days back in AWR history we want to display in chart.
PRO Due to performance impact, please be conservative.
PRO Default value is usually right.
PRO
PRO 1. Display AWR Days: [{&&default_awr_days.}|1-60]
DEF display_awr_days = '&1.';

COL display_awr_days NEW_V display_awr_days NOPRI;
SELECT NVL('&&display_awr_days.', '&&default_awr_days.') display_awr_days FROM DUAL
/

COL oldest_snap_id NEW_V oldest_snap_id NOPRI;
SELECT MAX(snap_id) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND end_interval_time < SYSDATE - &&display_awr_days.
/

SELECT snap_id, 
       TO_CHAR(begin_interval_time, '&&date_format.') begin_time, 
       TO_CHAR(end_interval_time, '&&date_format.') end_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id >= &&oldest_snap_id.
 ORDER BY
       snap_id
/

COL snap_id_max_default NEW_V snap_id_max_default NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER(''), MAX(snap_id))) snap_id_max_default 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL snap_id_min_default NEW_V snap_id_min_default NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER(''), MAX(snap_id))) snap_id_min_default 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND ( CASE 
         WHEN '' IS NULL 
         THEN ( CASE 
                WHEN begin_interval_time < (SYSDATE - (TO_NUMBER(NVL('&&default_window_hours.', '0'))/24))
                THEN 1 
                ELSE 0 
                END
              ) 
         ELSE 1 
         END
       ) = 1
/

PRO
PRO Chart extends for &&display_awr_days. days. 
PRO Range of snaps below are to define lower and upper bounds to compute TOP SQL.
PRO
PRO Enter range of snaps to evaluate TOP SQL.
PRO
PRO 2. SNAP_ID FROM: [{&&snap_id_min_default.}|snap_id]
DEF snap_id_from = '&2.';
PRO
PRO 3. SNAP_ID TO: [{&&snap_id_max_default.}|snap_id]
DEF snap_id_to = '&3.';

COL snap_id_max NEW_V snap_id_max NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_to.'), MAX(snap_id))) snap_id_max 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL snap_id_min NEW_V snap_id_min NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_from.'), MAX(snap_id))) snap_id_min 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND ( CASE 
         WHEN '&&snap_id_from.' IS NULL 
         THEN ( CASE 
                WHEN begin_interval_time < (SYSDATE - (TO_NUMBER(NVL('&&default_window_hours.', '0'))/24))
                THEN 1 
                ELSE 0 
                END
              ) 
         ELSE 1 
         END
       ) = 1
/

PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 4. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&4.';

COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 5. KIEV Bucket (optional):
DEF kiev_bucket = '&5.';

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL main_output_file_name NEW_V main_output_file_name NOPRI;
SELECT 'top_sql_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||'_&&snap_id_min._&&snap_id_max.' main_output_file_name FROM DUAL
/

@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "db_time_aas" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "db_time_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "cpu_time_aas" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "cpu_time_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "io_time_aas" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "io_time_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "appl_time_aas" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "appl_time_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "conc_time_aas" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "conc_time_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "parses_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "executions_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "fetches_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "loads" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "invalidations" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "version_count" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "sharable_mem_mb" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "rows_processed_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "rows_processed_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "buffer_gets_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "buffer_gets_exec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "disk_reads_sec" "&&kiev_tx." "&&kiev_bucket."
@@top_sql_chart_one.sql "&&display_awr_days." "&&snap_id_min." "&&snap_id_max." "disk_reads_exec" "&&kiev_tx." "&&kiev_bucket."

HOS zip -m &&main_output_file_name._charts.zip &&main_output_file_name._*.html

PRO
PRO &&main_output_file_name._charts.zip
PRO
CL COL BRE COMP;
UNDEF 1 2 3 4 5;
SET HEA ON PAGES 100;



