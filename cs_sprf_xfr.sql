----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_xfr.sql
--
-- Purpose:     Transfers a SQL Profile for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2023/05/29
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID and PLAN_HASH_VALUE when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_xfr.sql
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
DEF cs_script_name = 'cs_sprf_xfr';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_plans_performance.sql 
--
PRO
PRO 2. PLAN_HASH_VALUE (required) 
DEF cs_plan_hash_value = "&2.";
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._&&cs_plan_hash_value.' cs_file_name FROM DUAL;
--
-- get other_xml with hints
VAR cs_other_xml CLOB;
BEGIN
  SELECT other_xml INTO :cs_other_xml FROM v$sql_plan WHERE sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.') AND other_xml IS NOT NULL ORDER BY id FETCH FIRST 1 ROW ONLY;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_other_xml := NULL;
END;
/
BEGIN
  IF :cs_other_xml IS NULL THEN
    SELECT other_xml INTO :cs_other_xml FROM dba_hist_sql_plan WHERE sql_id = '&&cs_sql_id.' AND plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.') AND dbid = TO_NUMBER('&&cs_dbid.') AND other_xml IS NOT NULL ORDER BY id FETCH FIRST 1 ROW ONLY;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :cs_other_xml := NULL;
END;
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
--
PRO PLAN_HASH_VAL: &&cs_plan_hash_value. 
--
@@cs_internal/cs_print_sql_text.sql
--
-- create content of xfr scripts
VAR xfr_1 CLOB;
BEGIN
  :xfr_1 := 
  -- '--'||CHR(10)||
  '-- cs_sprf_xfr_1_&&cs_sql_id..sql'||CHR(10)||
  -- '-- execute on target: one cs_sprf_xfr_1_<sql_id>.sql script, followed by one cs_sprf_xfr_2_<plan_hash_value>.sql script.'||CHR(10)||
  -- '-- this sequence creates a SQL Profile for <sql_id> with <plan_hash_value>.'||CHR(10)||
  -- '-- scripts 1 and 2 can be from two different systems.'||CHR(10)||
  -- '--'||CHR(10)||
  'VAR sql_id_from_xfr_1_to_xfr_2 VARCHAR2(13);'||CHR(10)||
  'VAR sql_text_from_xfr_1_to_xfr_2 CLOB;'||CHR(10)||
  '--'||CHR(10)||
  'BEGIN'||CHR(10)||
  '  :sql_id_from_xfr_1_to_xfr_2 := ''&&cs_sql_id.'';'||CHR(10)||
  '  :sql_text_from_xfr_1_to_xfr_2 := '||CHR(10)||
  q'{  q'[}'||:cs_sql_text||q'{]';}'||CHR(10)||
  'END;'||CHR(10)||
  '/';
END;
/
VAR xfr_2 CLOB;
DECLARE
  l_hint VARCHAR2(32767);
  l_pos INTEGER;
BEGIN
  :xfr_2 := 
  -- '--'||CHR(10)||
  '-- cs_sprf_xfr_2_&&cs_plan_hash_value..sql'||CHR(10)||
  -- '-- execute on target: one cs_sprf_xfr_1_<sql_id>.sql script, followed by one cs_sprf_xfr_2_<plan_hash_value>.sql script.'||CHR(10)||
  -- '-- this sequence creates a SQL Profile for <sql_id> with <plan_hash_value>.'||CHR(10)||
  -- '-- scripts 1 and 2 can be from two different systems.'||CHR(10)||
  -- '--'||CHR(10)||
  'DECLARE'||CHR(10)||
  '  profile_attr SYS.SQLPROF_ATTR;'||CHR(10)||
  'BEGIN'||CHR(10)||
  '  profile_attr := SYS.SQLPROF_ATTR('||CHR(10)||
  q'{  q'[BEGIN_OUTLINE_DATA]',}'||CHR(10);
  -- FOR i IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
  --                  SUBSTR(EXTRACTVALUE(VALUE(d), '/hint'), 1, 4000) outline_hint
  --             FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(:cs_other_xml), '/*/outline_data/hint'))) d)
  FOR i IN (SELECT x.outline_hint
              FROM XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(:cs_other_xml) COLUMNS outline_hint VARCHAR2(4000) PATH '.') x)
  LOOP
    l_hint := i.outline_hint;
    WHILE l_hint IS NOT NULL
    LOOP
      IF LENGTH(l_hint) <= 500 THEN
        :xfr_2 := :xfr_2||q'{  q'[}'||l_hint||q'{]',}'||CHR(10);
        l_hint := NULL;
      ELSE
        l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
        :xfr_2 := :xfr_2||q'{  q'[}'||SUBSTR(l_hint, 1, l_pos)||q'{]',}'||CHR(10);
        l_hint := SUBSTR(l_hint, l_pos);
      END IF;
    END LOOP;
  END LOOP;
  :xfr_2 := 
  :xfr_2||
  q'{  q'[END_OUTLINE_DATA]');}'||CHR(10)||
  '  --'||CHR(10)||
  '  DBMS_SQLTUNE.IMPORT_SQL_PROFILE('||CHR(10)||
  '    sql_text    => :sql_text_from_xfr_1_to_xfr_2,'||CHR(10)||
  '    profile     => profile_attr,'||CHR(10)||
  '    name        => ''xfr_''||:sql_id_from_xfr_1_to_xfr_2||''_&&cs_plan_hash_value.'','||CHR(10)||
  '    description => ''cs_sprf_xfr.sql ''||:sql_id_from_xfr_1_to_xfr_2||'' &&cs_plan_hash_value. &&cs_reference_sanitized. &&who_am_i.'','||CHR(10)||
  '    category    => ''DEFAULT'','||CHR(10)||
  '    validate    => TRUE,'||CHR(10)||
  '    replace     => TRUE,'||CHR(10)||
  '    force_match => FALSE'||CHR(10)||
  '  );'||CHR(10)||
  'END;'||CHR(10)||
  '/';
END;
/
-- -- outputs scripts
-- SET HEA OFF PAGES 0;
-- SPO cs_sprf_xfr_1_&&cs_sql_id..sql
-- PRINT :xfr_1
-- SPO OFF;
-- SPO cs_sprf_xfr_2_&&cs_plan_hash_value..sql
-- PRINT :xfr_2;
-- SPO OFF;
-- SET HEA ON PAGES 100;
--
-- continues with original spool
SPO &&cs_file_name..txt APP
PRO
SET HEA OFF PAGES 0;
PRINT :xfr_1
PRINT :xfr_2;
SET HEA ON PAGES 100;
--
PRO
PRO Scripts cs_sprf_xfr_1_&&cs_sql_id..sql and cs_sprf_xfr_2_&&cs_plan_hash_value..sql were created.
PRO Execute on target system: one cs_sprf_xfr_1_<sql_id>.sql script, followed by one cs_sprf_xfr_2_<plan_hash_value>.sql script.
PRO You can get the first from a SQL X, and the second from a SQL Y (i.e. original and modified versions of "same" SQL).
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
