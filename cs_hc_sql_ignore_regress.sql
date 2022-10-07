----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_sql_ignore_regress.sql
--
-- Purpose:     Add SQL_ID to REGRESS exclusion list (HC SQL to ignore such SQL_ID)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/19
--
-- Usage:       Connecting into PDB or CDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_sql_ignore_regress.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_sql_ignore_regress';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO Number of Days to ignore Regressions on this SQL_ID. Passing a value of "0" removes this SQL from the "SQL HC REGRESS ignore" list.
PRO
PRO 2. DAYS: [{0}|0-3650]
DEF cs_days = '&2.';
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_days."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO DAYS         : "&&cs_days." [{0}|0-3650]
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
MERGE INTO &&cs_tools_schema..regress_ignore_sql o
  USING (SELECT TRIM('&&cs_sql_id.') AS sql_id, SYSDATE + TO_NUMBER(NVL(TRIM('&&cs_days.'), '0')) AS end_date, '&&cs_reference.' AS reference FROM DUAL WHERE LENGTH(TRIM('&&cs_sql_id.')) = 13) i
  ON (o.sql_id = i.sql_id)
WHEN MATCHED THEN
  UPDATE SET 
  o.end_date = i.end_date,
  o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_id, end_date, reference)
  VALUES (i.sql_id, i.end_date, i.reference)
/
DELETE &&cs_tools_schema..regress_ignore_sql WHERE sql_id = TRIM('&&cs_sql_id.') AND TO_NUMBER(NVL(TRIM('&&cs_days.'), '0')) = 0
/
COMMIT
/
--
PRO
PRO ALL EXCLUDED SQL &&cs_tools_schema..regress_ignore_sql
PRO ~~~~~~~~~~~~~~~~
SELECT sql_id, end_date, reference 
  FROM &&cs_tools_schema..regress_ignore_sql 
 ORDER BY sql_id
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_days."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
