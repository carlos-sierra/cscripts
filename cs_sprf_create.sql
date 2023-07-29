----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_create.sql
--
-- Purpose:     Create a SQL Profile for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2023/02/10
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID and PLAN_HASH_VALUE when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_create.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sprf_create';
--
PRO 1. Source SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/&&cs_zapper_managed.
--
@@cs_internal/cs_plans_performance.sql 
@@cs_internal/cs_sprf_internal_list.sql
--
PRO
PRO 2. PLAN_HASH_VALUE (required) 
DEF cs_plan_hash_value = "&2.";
UNDEF 2;
--
PRO
PRO 3. Target SQL_ID: [{&&cs_sql_id.}|SQL_ID]
DEF cs_sql_id2 = '&3.';
UNDEF 3;
COL cs_sql_id2 NEW_V cs_sql_id2 NOPRI;
SELECT COALESCE('&&cs_sql_id2.', '&&cs_sql_id.') AS cs_sql_id2 FROM DUAL
/
--
VAR cs_signature2 NUMBER;
VAR cs_sql_text2 CLOB;
BEGIN
  SELECT sql_fulltext INTO :cs_sql_text2 FROM v$sqlstats WHERE sql_id = '&&cs_sql_id2.' AND ROWNUM = 1;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    SELECT sql_text INTO :cs_sql_text2 FROM dba_hist_sqltext WHERE sql_id = '&&cs_sql_id2.' AND ROWNUM = 1;
END;
/
EXEC :cs_signature2 := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:cs_sql_text2);
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." "&&cs_sql_id2."
@@cs_internal/cs_spool_id.sql
--
PRO SOURCE_SQL_ID: &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO TABLE_OWNER  : &&table_owner.
PRO TABLE_NAME   : &&table_name.
PRO PLAN_HASH_VAL: &&cs_plan_hash_value. 
PRO TARGET_SQL_ID: &&cs_sql_id2.
--
SET HEA OFF;
PRO
PRO Source &&cs_sql_id.
PRO ~~~~~~
PRINT :cs_sql_text
PRO Target &&cs_sql_id2.
PRO ~~~~~~
PRINT :cs_sql_text2
SET HEA ON;
--
SET SERVEROUT ON;
DECLARE
  l_other_xml CLOB;
  l_hint VARCHAR2(32767);
  l_index INTEGER := 1;
  l_pos INTEGER;
  l_count INTEGER;
  l_profile_attr SYS.SQLPROF_ATTR := SYS.SQLPROF_ATTR('BEGIN_OUTLINE_DATA');
BEGIN
  BEGIN
    SELECT other_xml INTO l_other_xml FROM v$sql_plan WHERE sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.') AND other_xml IS NOT NULL ORDER BY id FETCH FIRST 1 ROW ONLY;
    DBMS_OUTPUT.put_line('got other_xml from v$sql_plan');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT other_xml INTO l_other_xml FROM dba_hist_sql_plan WHERE sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.') AND dbid = TO_NUMBER('&&cs_dbid.') AND other_xml IS NOT NULL ORDER BY id FETCH FIRST 1 ROW ONLY;
      DBMS_OUTPUT.put_line('got other_xml from dba_hist_sql_plan');
  END;
  --
  FOR i IN (SELECT x.outline_hint FROM XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(l_other_xml) COLUMNS outline_hint VARCHAR2(4000) PATH '.') x)
  LOOP
    l_hint := i.outline_hint;
    WHILE l_hint IS NOT NULL
    LOOP
      IF LENGTH(l_hint) <= 500 THEN
        l_index := l_index + 1;
        l_profile_attr.EXTEND; 
        l_profile_attr(l_index) := l_hint;
        l_hint := NULL;
      ELSE
        l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
        l_index := l_index + 1;
        l_profile_attr.EXTEND; 
        l_profile_attr(l_index) := SUBSTR(l_hint, 1, l_pos);
        l_hint := SUBSTR(l_hint, l_pos);
      END IF;
    END LOOP;
  END LOOP;
  DBMS_OUTPUT.put_line('got '||(l_index - 1)||' hints');
  --
  l_index := l_index + 1;
  l_profile_attr.EXTEND; 
  l_profile_attr(l_index) := 'END_OUTLINE_DATA';  
  --
  -- FOR i IN (SELECT name FROM dba_sql_profiles WHERE signature = TO_NUMBER('&&cs_signature.') AND name <> 'cs_&&cs_sql_id._&&cs_sql_id2.') 
  -- LOOP
  --   DBMS_SQLTUNE.drop_sql_profile(name => i.name); 
  --   DBMS_OUTPUT.put_line('dropped '||i.name);
  -- END LOOP;
  -- 
  SELECT COUNT(*) INTO l_count FROM dba_sql_profiles WHERE signature = TO_NUMBER('&&cs_signature.') AND name = 'cs_&&cs_sql_id._&&cs_sql_id2.';
  IF l_count = 0 THEN
    DBMS_SQLTUNE.import_sql_profile(
        sql_text    => :cs_sql_text2,
        profile     => l_profile_attr,
        name        => 'cs_&&cs_sql_id._&&cs_sql_id2.',
        description => 'cs_sprf_create.sql &&cs_sql_id. &&cs_plan_hash_value. &&cs_sql_id2. &&cs_reference_sanitized. &&who_am_i.',
        category    => 'DEFAULT',
        validate    => TRUE,
        replace     => TRUE
    );
    DBMS_OUTPUT.put_line('created cs_&&cs_sql_id._&&cs_sql_id2.');
  ELSE
    DBMS_OUTPUT.put_line('profile already exists cs_&&cs_sql_id._&&cs_sql_id2.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line('created nothing!');
    RETURN;
END;
/
SET SERVEROUT OFF;
--
EXEC :cs_signature := :cs_signature2;
@@cs_internal/cs_sprf_internal_list.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." "&&cs_sql_id2."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--