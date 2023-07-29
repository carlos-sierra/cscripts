----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_drop_all.sql
--
-- Purpose:     Drop all SQL Profiles for some SQL Text string on PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/05
--
-- Usage:       Connecting into PDB.
--
--              Confirm when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_drop_all.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
DEF sleep_seconds = '1';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sprf_drop_all';
--
PRO 1. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
COL count_distinct_rf NEW_V count_distinct_rf NOPRI;
COL estimated_seconds_rf NEW_V estimated_seconds_rf NOPRI;
SELECT TO_CHAR(COUNT(DISTINCT name) * TO_NUMBER('&&sleep_seconds.')) AS estimated_seconds_rf, TO_CHAR(COUNT(DISTINCT name)) AS count_distinct_rf FROM dba_sql_profiles WHERE ('&&cs2_sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%')
/
--
PRO
PRO ***
PRO *** You are about to drop &&count_distinct_rf. SQL Profiles on this &&cs_con_name. PDB on SQL text "&&cs2_sql_text_piece."
PRO ***
PRO
PRO 2. Enter "Yes" (case sensitive) to continue, else <ctrl>-C
DEF cs_confirm = '&2.';
UNDEF 2;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs2_sql_text_piece." "&&cs_confirm." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_TEXT     : &&cs2_sql_text_piece.
--
PRO
PRO Drop all &&count_distinct_rf. SQL Profiles which include SQL text "&&cs2_sql_text_piece."
PRO
PRO Estimated Seconds: &&estimated_seconds_rf.
PRO
SET SERVEROUT ON;
DECLARE
  l_total INTEGER := 0;
BEGIN
  IF '&&cs_confirm.' = 'Yes' THEN
    FOR i IN (SELECT DISTINCT name FROM dba_sql_profiles WHERE ('&&cs2_sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE '%'||UPPER(TRIM('&&cs2_sql_text_piece.'))||'%') ORDER BY name)
    LOOP
      DBMS_SQLTUNE.drop_sql_profile(name => i.name); 
      l_total := l_total + 1;
      DBMS_LOCK.sleep(TO_NUMBER('&&sleep_seconds.'));
    END LOOP;
  END IF;
  DBMS_OUTPUT.put_line(' *** SQL Profiles Dropped:'||l_total);
END;
/
SET SERVEROUT OFF;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs2_sql_text_piece." "&&cs_confirm."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
