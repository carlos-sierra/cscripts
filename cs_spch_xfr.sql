----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_xfr.sql
--
-- Purpose:     Transfers a SQL Patch for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2023/02/10
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spch_xfr.sql
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
DEF cs_script_name = 'cs_spch_xfr';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
-- get CBO Hint(s)
VAR cs_hint_text VARCHAR2(500);
BEGIN
  SELECT CAST(EXTRACTVALUE(VALUE(x), '/hint') AS VARCHAR2(500)) 
    INTO :cs_hint_text
    FROM XMLTABLE('/outline_data/hint' 
  PASSING (SELECT XMLTYPE(d.comp_data) xml 
             FROM sys.sqlobj$data d
            WHERE d.obj_type = 3 /* 1:profile, 2:baseline, 3:patch */ 
              AND d.signature = :cs_signature)) x;
END;
/
COL cs_hint_text NEW_V cs_hint_text NOPRI;
SELECT :cs_hint_text AS cs_hint_text FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO CBO_HINTS    : &&cs_hint_text.
--
@@cs_internal/cs_print_sql_text.sql
--
-- create content of xfr script
VAR xfr CLOB;
-- BEGIN
--   :xfr :=
--   '--'||CHR(10)||
--   '-- cs_spch_xfr_&&cs_sql_id..sql'||CHR(10)||
--   '-- execute on target: cs_spch_xfr_<sql_id>.sql script.'||CHR(10)||
--   '--'||CHR(10)||
--   'VAR signature NUMBER;'||CHR(10)||
--   'VAR sql_id VARCHAR2(13);'||CHR(10)||
--   'VAR sql_text CLOB;'||CHR(10)||
--   'VAR hint_text VARCHAR2(500);'||CHR(10)||
--   '--'||CHR(10)||
--   'BEGIN'||CHR(10)||
--   '  :signature := &&cs_signature.;'||CHR(10)||
--   '  :sql_id := ''&&cs_sql_id.'';'||CHR(10)||
--   '  :sql_text := '||CHR(10)||
--   q'{  q'[}'||:cs_sql_text||q'{]';}'||CHR(10)||
--   '  :hint_text := '||CHR(10)||
--   q'{  q'[}'||:cs_hint_text||q'{]';}'||CHR(10)||
--   '  --'||CHR(10)||
--   '  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = :signature)'||CHR(10)||
--   '  LOOP'||CHR(10)||
--   '    DBMS_SQLDIAG.drop_sql_patch(name => i.name);'||CHR(10)||
--   '  END LOOP;'||CHR(10)||
--   '  --'||CHR(10)||
--   '  DBMS_SQLDIAG_INTERNAL.i_create_patch('||CHR(10)||
--   '    sql_text    => :sql_text,'||CHR(10)||
--   '    hint_text   => :hint_text,'||CHR(10)||
--   '    name        => ''spch_''||:sql_id||''_xfr'','||CHR(10)||
--   '    description => ''cs_spch_xfr.sql /*+ ''||:hint_text||'' */ &&cs_reference_sanitized. &&who_am_i.'''||CHR(10)||
--   '  );'||CHR(10)||
--   'END;'||CHR(10)||
--   '/';
-- END;
-- /
BEGIN
  :xfr :=
  '--'||CHR(10)||
  '-- cs_spch_xfr_&&cs_sql_id..sql'||CHR(10)||
  '-- execute on target: cs_spch_xfr_<sql_id>.sql script.'||CHR(10)||
  '--'||CHR(10)||
  'DECLARE '||CHR(10)||
  '  l_signature NUMBER;'||CHR(10)||
  '  l_sql_id VARCHAR2(13);'||CHR(10)||
  '  l_sql_text CLOB;'||CHR(10)||
  '  l_hint_text VARCHAR2(500);'||CHR(10)||
  '  l_name VARCHAR2(64);'||CHR(10)||
  '--'||CHR(10)||
  'BEGIN'||CHR(10)||
  '  l_signature := &&cs_signature.;'||CHR(10)||
  '  l_sql_id := ''&&cs_sql_id.'';'||CHR(10)||
  '  l_sql_text := '||CHR(10)||
  q'{  q'[}'||:cs_sql_text||q'{]';}'||CHR(10)||
  '  l_hint_text := '||CHR(10)||
  q'{  q'[}'||:cs_hint_text||q'{]';}'||CHR(10)||
  '  --'||CHR(10)||
  '  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = l_signature)'||CHR(10)||
  '  LOOP'||CHR(10)||
  '    DBMS_SQLDIAG.drop_sql_patch(name => i.name);'||CHR(10)||
  '  END LOOP;'||CHR(10)||
  '  --'||CHR(10)||
  '  $IF DBMS_DB_VERSION.ver_le_12_1'||CHR(10)||
  '  $THEN'||CHR(10)||
  '    DBMS_SQLDIAG_INTERNAL.i_create_patch('||CHR(10)||
  '      sql_text    => l_sql_text,'||CHR(10)||
  '      hint_text   => l_hint_text,'||CHR(10)||
  '      name        => ''spch_''||l_sql_id||''_xfr'','||CHR(10)||
  '      description => ''cs_spch_xfr.sql /*+ ''||l_hint_text||'' */ &&cs_reference_sanitized. &&who_am_i.'''||CHR(10)||
  '    ); --12c'||CHR(10)||
  '  $ELSE'||CHR(10)||
  '    l_name := DBMS_SQLDIAG.create_sql_patch('||CHR(10)||
  '      sql_text    => l_sql_text,'||CHR(10)||
  '      hint_text   => l_hint_text,'||CHR(10)||
  '      name        => ''spch_''||l_sql_id||''_xfr'','||CHR(10)||
  '      description => ''cs_spch_xfr.sql /*+ ''||l_hint_text||'' */ &&cs_reference_sanitized. &&who_am_i.'''||CHR(10)||
  '    ); -- 19c'||CHR(10)||
  '  $END'||CHR(10)||
  'END;'||CHR(10)||
  '/';
END;
/
-- outputs script
SET HEA OFF;
SPO cs_spch_xfr_&&cs_sql_id..sql
PRINT :xfr
SPO OFF;
SET HEA ON;
--
-- continues with original spool
SPO &&cs_file_name..txt APP
PRO
SET HEA OFF;
PRINT :xfr
SET HEA ON;
--
PRO
PRO Script cs_spch_xfr_&&cs_sql_id..sql was created.
PRO Execute on target system: cs_spch_xfr_<sql_id>.sql script.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--