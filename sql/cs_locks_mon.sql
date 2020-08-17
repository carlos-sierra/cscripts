----------------------------------------------------------------------------------------
--
-- File name:   cs_locks_mon.sql
--
-- Purpose:     Locks Summary and Details
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/22
--
-- Usage:       Execute connected to PDB or CDB.
--
--              Specify sleep seconds between iterations, and number of iterations
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_locks_mon.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_locks_mon';
--
PRO
PRO 1. Sleep seconds between Iterations: [{15}|5-60]
DEF sleep_seconds = '&1.';
UNDEF 1;
COL sleep_seconds NEW_V sleep_seconds NOPRI;
SELECT CASE WHEN TO_NUMBER(NVL('&&sleep_seconds.', '15')) > 60 THEN '60' WHEN TO_NUMBER(NVL('&&sleep_seconds.', '15')) < 5 THEN '5' ELSE NVL('&&sleep_seconds.', '15') END AS sleep_seconds FROM DUAL
/
PRO
PRO 2. Iterations: [{5}|1-100]
DEF iterations = '&2.';
UNDEF 2;
COL iterations NEW_V iterations NOPRI;
SELECT CASE WHEN TO_NUMBER(NVL('&&iterations.', '5')) > 100 THEN '100' WHEN TO_NUMBER(NVL('&&iterations.', '5')) < 1 THEN '1' ELSE NVL('&&iterations.', '5') END AS iterations FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&sleep_seconds." "&&iterations."
@@cs_internal/cs_spool_id.sql
--
PRO SLEEP_SECS   : &&sleep_seconds.
PRO ITERATIONS   : &&iterations.
--
VAR results CLOB;
EXEC :results := 'Results'||CHR(10)||'~~~~~~~'||CHR(10);
SPO /tmp/cs_driver.sql;
SET SERVEROUT ON;
BEGIN
  FOR i IN 1..&&iterations.
  LOOP
    DBMS_OUTPUT.put_line(q'[@@cs_internal/cs_locks_mon_internal.sql]');
    DBMS_OUTPUT.put_line(q'[PRO Completed iteration ]'||i||q'[ out of &&iterations..]');
    DBMS_OUTPUT.put_line(q'[EXEC DBMS_LOB.append(:results, ']'||CHR(38)||CHR(38)||q'[cs9_current_time. '||:root_blockers||' root blocker(s) and '||:blockees||' blockee(s).'||CHR(10));]');
    DBMS_OUTPUT.put_line(q'[SET HEA OFF;]');
    DBMS_OUTPUT.put_line(q'[PRINT :results;]');
    DBMS_OUTPUT.put_line(q'[SET HEA ON;]');
    IF i < &&iterations. THEN
      DBMS_OUTPUT.put_line('EXEC DBMS_LOCK.sleep('||&&sleep_seconds.||');');
    END IF;
  END LOOP;
END;
/
SET SERVEROUT OFF;
SPO &&cs_file_name..txt APP;
@/tmp/cs_driver.sql;
--SET HEA OFF;
--PRINT :results;
--SET HEA ON;
--
PRO SQL> @&&cs_script_name..sql "&&sleep_seconds." "&&iterations."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--